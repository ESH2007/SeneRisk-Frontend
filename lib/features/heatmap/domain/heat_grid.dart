import 'dart:math';
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/risk_report.dart';
import 'heat_weighting.dart';

/// Una celda de la rejilla: datos agregados, nunca reportes individuales.
class HeatCell {
  HeatCell({required this.cx, required this.cy});

  /// Índices de celda en píxeles‑mundo al zoom de la rejilla.
  final int cx;
  final int cy;
  double weight = 0;
  int count = 0;
  DateTime? latest;
  final categories = <String, int>{};

  /// 0..1 tras normalizar por percentil.
  double intensity = 0;

  /// Categorías por cantidad, de mayor a menor.
  List<MapEntry<String, int>> get topCategories =>
      categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

class HeatGrid {
  const HeatGrid({required this.zoom, required this.cellSizePx, required this.cells, required this.normalizer});

  final double zoom;
  final double cellSizePx;
  final List<HeatCell> cells;

  /// Valor que mapea a intensidad 1 (percentil de los pesos visibles).
  final double normalizer;

  static const empty = HeatGrid(zoom: 0, cellSizePx: 1, cells: [], normalizer: 1);

  /// Centro de la celda en píxeles‑mundo al [zoom] de la rejilla.
  Offset centerOf(HeatCell c) => Offset((c.cx + 0.5) * cellSizePx, (c.cy + 0.5) * cellSizePx);

  /// Celda bajo [p] (en píxeles‑mundo a [zoom]), si existe.
  HeatCell? cellAt(Offset p) {
    final cx = (p.dx / cellSizePx).floor(), cy = (p.dy / cellSizePx).floor();
    for (final c in cells) {
      if (c.cx == cx && c.cy == cy) return c;
    }
    return null;
  }
}

/// Parámetros de agregación; sendable a un isolate con `compute`.
class HeatGridRequest {
  const HeatGridRequest({
    required this.reports,
    required this.zoom,
    required this.cellSizePx,
    required this.pixelBounds,
    required this.weighting,
    required this.now,
    this.percentile = 0.95,
  });

  final List<RiskReport> reports;
  final double zoom;
  final double cellSizePx;

  /// Área visible (con margen) en píxeles‑mundo a [zoom]; lo de fuera se ignora.
  final Rect pixelBounds;
  final HeatWeighting weighting;
  final DateTime now;
  final double percentile;
}

/// Agrupa los reportes en celdas de [HeatGridRequest.cellSizePx] y normaliza por percentil.
/// Función de nivel superior para poder correr en `compute`.
HeatGrid buildHeatGrid(HeatGridRequest q) {
  const crs = Epsg3857();
  final byKey = <int, HeatCell>{};
  for (final r in q.reports) {
    final p = crs.latLngToOffset(LatLng(r.lat, r.lng), q.zoom);
    if (!q.pixelBounds.contains(p)) continue;
    final cx = (p.dx / q.cellSizePx).floor(), cy = (p.dy / q.cellSizePx).floor();
    final cell = byKey.putIfAbsent(cx * 1000003 + cy, () => HeatCell(cx: cx, cy: cy));
    cell.weight += q.weighting.weight(r, q.now);
    cell.count++;
    cell.categories.update(r.category, (n) => n + 1, ifAbsent: () => 1);
    if (cell.latest == null || r.createdAt.isAfter(cell.latest!)) cell.latest = r.createdAt;
  }
  final cells = byKey.values.toList(growable: false);
  if (cells.isEmpty) return HeatGrid(zoom: q.zoom, cellSizePx: q.cellSizePx, cells: cells, normalizer: 1);
  final sorted = cells.map((c) => c.weight).toList()..sort();
  final norm = max(sorted[((sorted.length - 1) * q.percentile).round()], 1e-9);
  for (final c in cells) {
    c.intensity = min(c.weight / norm, 1);
  }
  return HeatGrid(zoom: q.zoom, cellSizePx: q.cellSizePx, cells: cells, normalizer: norm);
}
