import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;

import '../../../data/api_client.dart';
import 'risk_report.dart';

/// `GET /reportes/calor/` con la misma caché por bbox redondeado + filtros que el mock,
/// así el pan no repite consultas y en modo avión responde con lo último descargado.
class ApiReportsRepository implements ReportsRepository {
  ApiReportsRepository(this._api);

  final ApiClient _api;
  final _cache = <String, List<RiskReport>>{};

  @override
  Future<List<RiskReport>> fetch({
    required LatLngBounds bounds,
    required DateTimeRange range,
    Set<String>? categories,
  }) async {
    final b = MockReportsRepository.roundBounds(bounds);
    final cats = categories == null ? '' : (categories.toList()..sort()).join(',');
    // Vista amplia (≈ zoom < 11): el servidor agrega por celdas (PostGIS) y manda ~100 puntos en vez de miles.
    final ancho = b.east - b.west;
    final celda = ancho > 0.6 ? (ancho / 80).toStringAsFixed(4) : null;
    final key = '${b.south},${b.west},${b.north},${b.east}|${range.start.day}-${range.end.day}|$cats|$celda';
    final cached = _cache[key];
    try {
      final r = await _api.get('/reportes/calor/', query: {
        'bbox': '${b.west},${b.south},${b.east},${b.north}',
        'desde': range.start.toUtc().toIso8601String(),
        'hasta': range.end.toUtc().toIso8601String(),
        if (cats.isNotEmpty) 'categorias': cats,
        'celda': ?celda,
      });
      return _cache[key] = [
        for (final j in r as List)
          RiskReport(
            id: j['id'].toString(),
            lat: (j['lat'] as num).toDouble(),
            lng: (j['lng'] as num).toDouble(),
            createdAt: DateTime.parse(j['createdAt'] as String).toLocal(),
            severity: (j['severity'] as num).toInt(),
            validations: (j['validations'] as num).toInt(),
            category: j['category'] as String,
          ),
      ];
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }
}
