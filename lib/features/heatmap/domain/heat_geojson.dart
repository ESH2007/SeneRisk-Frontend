import 'dart:math';

import '../data/risk_report.dart';
import 'heat_weighting.dart';

/// FeatureCollection para la capa `heatmap` de MapLibre. Cada punto lleva `w` (peso normalizado
/// por el percentil [percentile] de los pesos visibles, 0..1) para que un caso extremo no apague al resto.
Map<String, dynamic> heatFeatureCollection(
  List<RiskReport> reports,
  HeatWeighting weighting,
  DateTime now, {
  double percentile = 0.95,
}) {
  final weights = [for (final r in reports) weighting.weight(r, now)];
  var norm = 1.0;
  if (weights.isNotEmpty) {
    final sorted = [...weights]..sort();
    norm = max(sorted[((sorted.length - 1) * percentile).round()], 1e-9);
  }
  return {
    'type': 'FeatureCollection',
    'features': [
      for (var i = 0; i < reports.length; i++)
        {
          'type': 'Feature',
          'geometry': {'type': 'Point', 'coordinates': [reports[i].lng, reports[i].lat]},
          'properties': {'w': min(weights[i] / norm, 1.0)},
        },
    ],
  };
}
