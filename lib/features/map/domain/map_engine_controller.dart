import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/map_manifest.dart';
import '../data/pmtiles_tile_provider.dart';
import '../data/tile_server.dart';
import 'map_style.dart';
import 'offline_maps_controller.dart';

/// Estado del motor de mapa: servidor local + lectores abiertos + estilo MapLibre listo.
class MapEngine {
  const MapEngine({required this.detail, this.style, this.baseReady = false, this.revision = 0});

  final CompositeDetailProvider detail;

  /// JSON de estilo para `MapLibreMap.styleString`; `null` mientras arranca.
  final String? style;
  final bool baseReady;

  /// Sube con cada cambio en disco; va en la URL de los tiles para que MapLibre los vuelva a pedir.
  final int revision;
}

class MapEngineController extends Notifier<MapEngine> {
  TileServer? _server;
  List<dynamic>? _layers;

  /// `id.build` de cada archivo de base abierto, para reabrir solo cuando cambie.
  String _baseKey = '';

  @override
  MapEngine build() {
    final detail = CompositeDetailProvider();
    ref.onDispose(() {
      for (final r in _server?.base ?? const <PmTilesReader>[]) {
        r.close();
      }
      detail.dispose();
      _server?.close();
    });
    _start(detail);
    return MapEngine(detail: detail);
  }

  Future<void> _start(CompositeDetailProvider detail) async {
    _layers = (jsonDecode(await rootBundle.loadString('assets/maps/light_v4.json')) as Map<String, dynamic>)['layers'] as List;
    _server = await TileServer.start()..detail = detail;
    ref.listen(offlineMapsProvider, (_, s) => _sync(s), fireImmediately: true);
  }

  Future<void> _sync(OfflineMapsState s) async {
    final m = s.manifest;
    final server = _server;
    if (!s.ready || m == null || server == null) return;
    final storage = ref.read(offlineMapsProvider.notifier).storage;

    final baseReady = s.baseInstalled;
    final baseKey = baseReady ? m.baseFiles.map((f) => '${f.id}.${s.installed[f.id]}').join(',') : '';
    if (baseKey != _baseKey) {
      for (final r in server.base) {
        await r.close();
      }
      server.base = [
        if (baseReady)
          for (final f in m.baseFiles) await PmTilesReader.open(storage.fileFor(f.id, s.installed[f.id]!)),
      ];
      _baseKey = baseKey;
    }

    final regions = <String, (MapFile, File)>{
      for (final r in m.regions)
        if (s.installed[r.id] != null) r.id: (r, storage.fileFor(r.id, s.installed[r.id]!)),
    };
    final detail = state.detail
      ..remoteEnabled = s.detalleRemoto
      ..setRemote(m.nationalDetail == null ? null : Uri.parse(m.nationalDetail!.url));
    await detail.sync(regions);

    final revision = state.revision + 1;
    state = MapEngine(
      detail: detail,
      baseReady: baseReady,
      revision: revision,
      style: buildMapStyle(
        serverUrl: server.url,
        protomapsLayers: _layers!,
        bounds: m.base.bbox,
        revision: revision,
        baseMaxZoom: m.baseFiles.map((f) => f.maxzoom).reduce((a, b) => a > b ? a : b),
      ),
    );
  }
}

final mapEngineProvider = NotifierProvider<MapEngineController, MapEngine>(MapEngineController.new);
