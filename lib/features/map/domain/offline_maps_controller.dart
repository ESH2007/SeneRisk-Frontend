import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/map_download_service.dart';
import '../data/map_manifest.dart';
import '../data/map_storage.dart';

/// Base del bucket de mapas: `flutter run --dart-define=MAPS_BASE_URL=https://...`.
const mapsBaseUrl = String.fromEnvironment('MAPS_BASE_URL', defaultValue: 'https://maps.example.com/tiles');

enum MapStatus { notInstalled, downloading, installed, updateAvailable }

class OfflineMapsState {
  const OfflineMapsState({
    this.manifest,
    this.installed = const {},
    this.progress = const {},
    this.errors = const {},
    this.soloWifi = true,
    this.detalleRemoto = false,
    this.ready = false,
  });

  final MapManifest? manifest;

  /// `{id: build}` en disco.
  final Map<String, String> installed;

  /// `{id: bytes recibidos}` de las descargas en curso.
  final Map<String, int> progress;
  final Map<String, String> errors;
  final bool soloWifi;

  /// Pedir calles por internet (archivo nacional) donde no haya región descargada.
  final bool detalleRemoto;

  /// `true` cuando ya se leyó el disco y el manifest (remoto, caché o asset).
  final bool ready;

  bool get baseInstalled => manifest != null && manifest!.baseFiles.every((f) => installed.containsKey(f.id));

  /// Bytes recibidos de todas las partes de la base (para la tarjeta de primera configuración).
  int get baseProgress => manifest == null
      ? 0
      : manifest!.baseFiles.fold(0, (s, f) => s + (installed.containsKey(f.id) ? f.bytes : (progress[f.id] ?? 0)));
  bool get baseDownloading => manifest != null && manifest!.baseFiles.any((f) => progress.containsKey(f.id));

  MapStatus statusOf(MapFile f) {
    if (progress.containsKey(f.id)) return MapStatus.downloading;
    final b = installed[f.id];
    if (b == null) return MapStatus.notInstalled;
    return b == f.build ? MapStatus.installed : MapStatus.updateAvailable;
  }

  /// Archivo en disco de [f] (el build instalado, aunque haya uno más nuevo disponible).
  bool isInstalled(String id) => installed.containsKey(id);

  OfflineMapsState copyWith({
    MapManifest? manifest,
    Map<String, String>? installed,
    Map<String, int>? progress,
    Map<String, String>? errors,
    bool? soloWifi,
    bool? detalleRemoto,
    bool? ready,
  }) =>
      OfflineMapsState(
        manifest: manifest ?? this.manifest,
        installed: installed ?? this.installed,
        progress: progress ?? this.progress,
        errors: errors ?? this.errors,
        soloWifi: soloWifi ?? this.soloWifi,
        detalleRemoto: detalleRemoto ?? this.detalleRemoto,
        ready: ready ?? this.ready,
      );
}

class OfflineMapsController extends Notifier<OfflineMapsState> {
  static const _kSoloWifi = 'maps_solo_wifi';
  static const _kDetalleRemoto = 'maps_detalle_remoto';

  late MapStorage storage;
  final _service = MapDownloadService();
  final _subs = <String, StreamSubscription<int>>{};

  @override
  OfflineMapsState build() {
    ref.onDispose(() {
      for (final s in _subs.values) {
        s.cancel();
      }
    });
    _init();
    return const OfflineMapsState();
  }

  Future<void> _init() async {
    try {
      storage = await MapStorage.open();
    } catch (_) {
      // Sin path_provider (tests): directorio temporal.
      storage = MapStorage(await Directory('${Directory.systemTemp.path}/senerisk_maps').create());
    }
    var soloWifi = true;
    var detalleRemoto = false;
    try {
      final p = await SharedPreferences.getInstance();
      soloWifi = p.getBool(_kSoloWifi) ?? true;
      detalleRemoto = p.getBool(_kDetalleRemoto) ?? false;
    } catch (_) {}
    state = state.copyWith(
      installed: storage.installed(),
      manifest: await _loadManifest(),
      soloWifi: soloWifi,
      detalleRemoto: detalleRemoto,
      ready: true,
    );
  }

  /// Remoto → caché local → asset mock, lo primero que funcione.
  Future<MapManifest?> _loadManifest() async {
    try {
      final req = await HttpClient().getUrl(Uri.parse('$mapsBaseUrl/manifest.json'));
      final res = await req.close().timeout(const Duration(seconds: 5));
      if (res.statusCode == HttpStatus.ok) {
        final body = await res.transform(utf8.decoder).join();
        final m = MapManifest.fromJson(jsonDecode(body) as Map<String, dynamic>);
        await storage.manifestCache.writeAsString(body);
        return m;
      }
    } catch (_) {}
    try {
      return MapManifest.fromJson(jsonDecode(await storage.manifestCache.readAsString()) as Map<String, dynamic>);
    } catch (_) {}
    try {
      return MapManifest.fromJson(
          jsonDecode(await rootBundle.loadString('assets/maps/manifest.json')) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshManifest() async {
    final m = await _loadManifest();
    if (m != null) state = state.copyWith(manifest: m);
  }

  void setSoloWifi(bool v) {
    state = state.copyWith(soloWifi: v);
    _saveBool(_kSoloWifi, v);
  }

  void setDetalleRemoto(bool v) {
    state = state.copyWith(detalleRemoto: v);
    _saveBool(_kDetalleRemoto, v);
  }

  void _saveBool(String k, bool v) =>
      SharedPreferences.getInstance().then((p) => p.setBool(k, v)).catchError((_) => false);

  /// Comprueba red y espacio; devuelve el motivo si no se puede descargar.
  Future<String?> _precheck(MapFile f) async {
    final net = await Connectivity().checkConnectivity();
    if (net.contains(ConnectivityResult.none) || net.isEmpty) return 'Sin conexión a internet';
    final wifi = net.contains(ConnectivityResult.wifi) || net.contains(ConnectivityResult.ethernet);
    if (state.soloWifi && !wifi) return 'Solo se descarga con Wi‑Fi (cámbialo arriba)';
    final free = await storage.freeBytes();
    if (free != null && free < f.bytes + 50 * 1048576) return 'Espacio insuficiente: se necesitan ${f.sizeLabel}';
    return null;
  }

  Future<void> download(String id) async {
    final f = state.manifest?.byId(id);
    if (f == null || _subs.containsKey(id)) return;
    final why = await _precheck(f);
    if (why != null) {
      state = state.copyWith(errors: {...state.errors, id: why});
      return;
    }
    state = state.copyWith(progress: {...state.progress, id: 0}, errors: {...state.errors}..remove(id));
    _subs[id] = _service.download(f, storage.fileFor(id, f.build)).listen(
      (n) => state = state.copyWith(progress: {...state.progress, id: n}),
      onDone: () async {
        _subs.remove(id);
        // Solo ahora, con el nuevo verificado, se borra el build anterior.
        final old = state.installed[id];
        if (old != null && old != f.build) {
          try {
            await storage.fileFor(id, old).delete();
          } catch (_) {}
        }
        state = state.copyWith(
          installed: {...state.installed, id: f.build},
          progress: {...state.progress}..remove(id),
        );
      },
      onError: (Object e) {
        _subs.remove(id);
        state = state.copyWith(
          progress: {...state.progress}..remove(id),
          errors: {...state.errors, id: e is ChecksumException ? e.toString() : 'Error de descarga, intenta de nuevo'},
        );
      },
      cancelOnError: true,
    );
  }

  Future<void> cancel(String id) async {
    await _subs.remove(id)?.cancel();
    state = state.copyWith(progress: {...state.progress}..remove(id));
  }

  Future<void> delete(String id) async {
    await cancel(id);
    await storage.delete(id);
    state = state.copyWith(installed: {...state.installed}..remove(id));
  }
}

final offlineMapsProvider =
    NotifierProvider<OfflineMapsController, OfflineMapsState>(OfflineMapsController.new);
