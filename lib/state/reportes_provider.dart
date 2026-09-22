import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import '../data/mock_reportes.dart';
import '../models/reporte.dart';
import '../models/tipo_hecho.dart';
import 'ubicacion_usuario_provider.dart';

class ReportesNotifier extends Notifier<List<Reporte>> {
  static const _kCache = 'reportes_cache';
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  List<Reporte> build() {
    if (!usaApi) return _ordenar(reportesMock());
    // La distancia se recalcula aquí cuando llega la ubicación real.
    ref.listen(ubicacionUsuarioProvider, (_, _) => state = _conDistancias(state));
    _cargar();
    return const [];
  }

  static List<Reporte> _ordenar(List<Reporte> lista) =>
      [...lista]..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

  LatLng get _origen => ref.read(ubicacionUsuarioProvider).value ?? ubicacionSimulada;

  List<Reporte> _conDistancias(List<Reporte> lista) {
    final o = _origen;
    const d = Distance();
    return [for (final r in lista) r.copyWith(distanciaKm: d.as(LengthUnit.Kilometer, o, LatLng(r.lat, r.lng)))];
  }

  List<Reporte> _desdeJson(List lista) => _conDistancias([for (final j in lista) Reporte.fromJson(j as Map<String, dynamic>)]);

  /// Descarga del backend; si falla, muestra la última lista guardada (modo avión).
  Future<void> _cargar() async {
    try {
      final r = await _api.get('/reportes/', query: {'limit': '500'});
      final lista = r['results'] as List;
      state = _ordenar(_desdeJson(lista));
      (await SharedPreferences.getInstance()).setString(_kCache, jsonEncode(lista));
    } catch (e) {
      debugPrint('reportes: usando caché ($e)');
      try {
        final raw = (await SharedPreferences.getInstance()).getString(_kCache);
        if (raw != null) state = _ordenar(_desdeJson(jsonDecode(raw) as List));
      } catch (_) {}
    }
  }

  Future<void> recargar() => usaApi ? _cargar() : Future.value();

  /// Publica un reporte. En modo API sube [fotoRuta] y devuelve el reporte con id del servidor.
  Future<Reporte> agregar(Reporte reporte, {String? fotoRuta}) async {
    var nuevo = reporte;
    if (usaApi) {
      final j = await _api.multipart(
        '/reportes/',
        {
          'tipo': reporte.tipo.name,
          'titulo': reporte.titulo,
          'descripcion': reporte.descripcion,
          'lugar': reporte.lugar,
          'lat': reporte.lat.toString(),
          'lng': reporte.lng.toString(),
          'anonimo': reporte.anonimo.toString(),
        },
        archivoCampo: 'foto',
        archivoRuta: fotoRuta,
      );
      nuevo = _conDistancias([Reporte.fromJson(j as Map<String, dynamic>)]).single;
    }
    state = _ordenar([...state, nuevo]);
    return nuevo;
  }

  Future<void> confirmar(String id) => _validar(id, true);

  Future<void> desmentir(String id) => _validar(id, false);

  /// Optimista: actualiza local y luego sincroniza; si el servidor rechaza, revierte.
  Future<void> _validar(String id, bool confirma) async {
    final antes = state;
    _actualizar(id, (r) => confirma
        ? r.copyWith(confirmaciones: r.confirmaciones + 1)
        : r.copyWith(desmentidos: r.desmentidos + 1));
    if (!usaApi) return;
    try {
      final j = await _api.send('POST', '/reportes/$id/${confirma ? 'confirmar' : 'desmentir'}/');
      final actual = _conDistancias([Reporte.fromJson(j as Map<String, dynamic>)]).single;
      _actualizar(id, (_) => actual);
    } catch (_) {
      state = antes;
      rethrow;
    }
  }

  Reporte? porId(String id) {
    for (final r in state) {
      if (r.id == id) return r;
    }
    return null;
  }

  void _actualizar(String id, Reporte Function(Reporte) cambio) =>
      state = [for (final r in state) r.id == id ? cambio(r) : r];
}

final reportesProvider =
    NotifierProvider<ReportesNotifier, List<Reporte>>(ReportesNotifier.new);

/// Filtros de la lista de alertas: "cerca" | "bloqueo" | "protesta" | "mas".
List<Reporte> filtrarAlertas(
  List<Reporte> reportes,
  String filtro, {
  required double radioKm,
}) {
  final lista = switch (filtro) {
    'cerca' => reportes.where((r) => r.distanciaKm <= radioKm),
    'bloqueo' => reportes.where((r) => r.tipo == TipoHecho.bloqueo),
    'protesta' => reportes.where((r) => r.tipo == TipoHecho.protesta),
    _ => reportes,
  };
  return lista.toList()..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
}

/// Reportes con pocas confirmaciones, del más cercano al más lejano.
List<Reporte> reportesPorVerificar(List<Reporte> reportes) =>
    reportes.where((r) => r.confirmaciones < 3).toList()
      ..sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));

/// Filtro del mapa: "todos" o el nombre de un [TipoHecho].
List<Reporte> filtrarMapa(List<Reporte> reportes, String filtro) =>
    filtro == 'todos'
        ? reportes
        : reportes.where((r) => r.tipo.name == filtro).toList();
