import 'dart:math';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

class RiskReport {
  const RiskReport({
    required this.id,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.severity,
    required this.validations,
    required this.category,
  });

  final String id;
  final double lat;
  final double lng;
  final DateTime createdAt;

  /// 1..5
  final int severity;

  /// Confirmaciones de usuarios cercanos.
  final int validations;
  final String category;
}

abstract class ReportsRepository {
  /// Reportes dentro del bbox y rango de fechas. Implementación actual: mock.
  Future<List<RiskReport>> fetch({
    required LatLngBounds bounds,
    required DateTimeRange range,
    Set<String>? categories,
  });
}

/// Datos sintéticos concentrados en barrios de Bogotá y Medellín, con ruido.
/// Deterministas por [seed]; [count] = 100 / 1 000 / 10 000 para pruebas.
class MockReportsRepository implements ReportsRepository {
  MockReportsRepository({this.count = 1000, int seed = 7, DateTime? now})
      : _now = now ?? DateTime.now(),
        _rnd = Random(seed);

  final int count;
  final DateTime _now;
  final Random _rnd;
  List<RiskReport>? _all;

  // ponytail: caché sin límite; con backend real acotarla por tamaño/edad.
  final _cache = <String, List<RiskReport>>{};

  static const categorias = ['bloqueo', 'protesta', 'incendio', 'agresion', 'vandalismo', 'desaparecida'];

  /// (lat, lng, sigma en grados, peso relativo).
  static const _focos = [
    (4.6486, -74.0628, 0.010, 3.0), // Chapinero
    (4.6097, -74.0817, 0.008, 2.5), // Centro / La Candelaria
    (4.6280, -74.1390, 0.020, 2.0), // Kennedy
    (4.7400, -74.0900, 0.020, 1.5), // Suba
    (4.5700, -74.1200, 0.020, 1.5), // Bosa / Usme
    (4.6950, -74.0450, 0.012, 1.0), // Usaquén
    (6.2470, -75.5700, 0.012, 2.0), // Medellín centro
    (6.2900, -75.5600, 0.018, 1.0), // Bello / Robledo
    (6.1700, -75.6000, 0.015, 0.8), // Itagüí / Envigado
  ];

  List<RiskReport> get all => _all ??= _generar();

  List<RiskReport> _generar() {
    final total = _focos.fold(0.0, (s, f) => s + f.$4);
    double gauss() {
      final u = 1 - _rnd.nextDouble(), v = _rnd.nextDouble();
      return sqrt(-2 * log(u)) * cos(2 * pi * v);
    }
    return List.generate(count, (i) {
      var pick = _rnd.nextDouble() * total;
      var f = _focos.last;
      for (final foco in _focos) {
        pick -= foco.$4;
        if (pick <= 0) {
          f = foco;
          break;
        }
      }
      // 10 % de ruido uniforme en un radio amplio alrededor del foco.
      final ruido = _rnd.nextDouble() < 0.1 ? 4.0 : 1.0;
      return RiskReport(
        id: 'm$i',
        lat: f.$1 + gauss() * f.$3 * ruido,
        lng: f.$2 + gauss() * f.$3 * ruido,
        createdAt: _now.subtract(Duration(minutes: (_rnd.nextDouble() * 180 * 24 * 60).round())),
        severity: 1 + _rnd.nextInt(5),
        validations: _rnd.nextDouble() < 0.6 ? 0 : _rnd.nextInt(12),
        category: categorias[_rnd.nextInt(categorias.length)],
      );
    });
  }

  /// bbox redondeado a 0.5° para que pequeños pans reutilicen la respuesta (menos datos).
  static LatLngBounds roundBounds(LatLngBounds bounds) => LatLngBounds(
        LatLng((bounds.south * 2).floor() / 2, (bounds.west * 2).floor() / 2),
        LatLng((bounds.north * 2).ceil() / 2, (bounds.east * 2).ceil() / 2),
      );

  @override
  Future<List<RiskReport>> fetch({
    required LatLngBounds bounds,
    required DateTimeRange range,
    Set<String>? categories,
  }) async {
    final b = roundBounds(bounds);
    final cats = categories == null ? '*' : (categories.toList()..sort()).join(',');
    final key = '${b.south},${b.west},${b.north},${b.east}|${range.start.millisecondsSinceEpoch}-${range.end.millisecondsSinceEpoch}|$cats';
    return _cache[key] ??= all
        .where((r) =>
            r.lat >= b.south && r.lat <= b.north && r.lng >= b.west && r.lng <= b.east &&
            !r.createdAt.isBefore(range.start) && !r.createdAt.isAfter(range.end) &&
            (categories == null || categories.contains(r.category)))
        .toList(growable: false);
  }
}
