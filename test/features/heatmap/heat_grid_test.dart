import 'dart:ui';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:senerisk_app/features/heatmap/data/risk_report.dart';
import 'package:senerisk_app/features/heatmap/domain/heat_grid.dart';
import 'package:senerisk_app/features/heatmap/domain/heat_weighting.dart';

final _now = DateTime(2026, 9, 21, 12);

RiskReport _r(String id, double lat, double lng, {int sev = 1, int val = 0, int daysAgo = 0, String cat = 'bloqueo'}) =>
    RiskReport(id: id, lat: lat, lng: lng, createdAt: _now.subtract(Duration(days: daysAgo)),
        severity: sev, validations: val, category: cat);

HeatGrid _grid(List<RiskReport> rs, {double zoom = 14, double cell = 24, double percentile = 0.95}) => buildHeatGrid(
    HeatGridRequest(reports: rs, zoom: zoom, cellSizePx: cell, pixelBounds: const Rect.fromLTWH(-1e9, -1e9, 2e9, 2e9),
        weighting: const HeatWeighting(), now: _now, percentile: percentile));

void main() {
  group('HeatWeighting', () {
    const w = HeatWeighting();
    test('severidad × decaimiento × (1 + ln(1 + validaciones))', () {
      expect(w.weight(_r('a', 0, 0, sev: 3), _now), 3);
      expect(w.weight(_r('a', 0, 0, sev: 3, daysAgo: 30), _now), closeTo(1.5, 1e-9)); // vida media
      expect(w.weight(_r('a', 0, 0, sev: 1, val: 2), _now), closeTo(1 + 1.0986, 1e-3));
    });
  });

  group('buildHeatGrid', () {
    test('suma pesos, cuenta, categorías y fecha más reciente en la misma celda', () {
      final g = _grid([
        _r('a', 4.65, -74.06, sev: 2, cat: 'bloqueo'),
        _r('b', 4.65, -74.06, sev: 3, cat: 'protesta', daysAgo: 1),
        _r('c', 4.65, -74.06, sev: 1, cat: 'bloqueo', daysAgo: 60),
      ]);
      expect(g.cells.length, 1);
      final c = g.cells.single;
      expect(c.count, 3);
      expect(c.latest, _now);
      expect(c.topCategories.first.key, 'bloqueo');
      expect(c.weight, closeTo(2 + 3 * 0.9772 + 0.25, 1e-3));
    });

    test('puntos a ambos lados del borde de celda caen en celdas distintas', () {
      const crs = Epsg3857();
      // Centro de una celda y su vecina a la derecha, en píxeles‑mundo a z14.
      final a = crs.offsetToLatLng(const Offset(24 * 100 + 12, 24 * 100 + 12), 14);
      final b = crs.offsetToLatLng(const Offset(24 * 101 + 1, 24 * 100 + 12), 14);
      final g = _grid([_r('a', a.latitude, a.longitude), _r('b', b.latitude, b.longitude)]);
      expect(g.cells.map((c) => (c.cx, c.cy)).toSet(), {(100, 100), (101, 100)});
      expect(g.cellAt(const Offset(24 * 100 + 5, 24 * 100 + 5))!.cx, 100);
      expect(g.cellAt(const Offset(0, 0)), isNull);
    });

    test('ignora lo que está fuera de pixelBounds', () {
      final g = buildHeatGrid(HeatGridRequest(
        reports: [_r('a', 4.65, -74.06), _r('b', 6.25, -75.57)],
        zoom: 12, cellSizePx: 24,
        pixelBounds: Rect.fromCenter(center: const Epsg3857().latLngToOffset(const LatLng(4.65, -74.06), 12), width: 500, height: 500),
        weighting: const HeatWeighting(), now: _now,
      ));
      expect(g.cells.length, 1);
    });

    test('normaliza por percentil: un punto extremo no apaga al resto', () {
      final rs = [
        for (var i = 0; i < 20; i++) _r('n$i', 4.60 + i * 0.01, -74.10, sev: 2),
        _r('x', 4.90, -74.10, sev: 5, val: 200), // peso ≈ 5 × 6.3
      ];
      final g = _grid(rs, zoom: 12);
      final normales = g.cells.where((c) => c.count == 1 && c.weight < 3);
      expect(normales.length, 20);
      expect(normales.every((c) => c.intensity == 1), isTrue, reason: 'p95 de 21 valores es el 2.º más alto: 2');
      expect(g.normalizer, 2);
      expect(g.cells.firstWhere((c) => c.weight > 10).intensity, 1);
      final gMax = _grid(rs, zoom: 12, percentile: 1);
      expect(gMax.cells.firstWhere((c) => c.weight < 3).intensity, lessThan(0.1));
    });

    test('vacío', () {
      expect(_grid([]).cells, isEmpty);
    });
  });

  group('MockReportsRepository', () {
    test('genera la cantidad pedida, determinista, y filtra por bbox/fecha/categoría con caché', () async {
      final repo = MockReportsRepository(count: 1000, now: _now);
      expect(repo.all.length, 1000);
      expect(MockReportsRepository(count: 1000, now: _now).all.first.lat, repo.all.first.lat);
      final bogota = LatLngBounds(const LatLng(4.4, -74.3), const LatLng(4.9, -73.9));
      final r7 = await repo.fetch(bounds: bogota, range: DateTimeRange(start: _now.subtract(const Duration(days: 7)), end: _now));
      final r180 = await repo.fetch(bounds: bogota, range: DateTimeRange(start: _now.subtract(const Duration(days: 180)), end: _now));
      expect(r7.length, lessThan(r180.length));
      expect(r180.length, greaterThan(500));
      expect(r180.every((r) => r.lat >= 4.0 && r.lat <= 5.0), isTrue, reason: "bbox redondeado a 0.5°");
      expect(r180.any((r) => r.lat > 6), isFalse, reason: "Medellín queda fuera");
      final cat = await repo.fetch(bounds: bogota, range: DateTimeRange(start: _now.subtract(const Duration(days: 180)), end: _now), categories: {'incendio'});
      expect(cat.every((r) => r.category == 'incendio'), isTrue);
      expect(identical(r180, await repo.fetch(bounds: bogota, range: DateTimeRange(start: _now.subtract(const Duration(days: 180)), end: _now))), isTrue);
    });

    test('10 000 puntos se agregan en menos de 300 ms', () {
      final repo = MockReportsRepository(count: 10000, now: _now);
      final sw = Stopwatch()..start();
      final g = _grid(repo.all, zoom: 12);
      sw.stop();
      expect(g.cells.length, greaterThan(50));
      expect(sw.elapsedMilliseconds, lessThan(300));
    });
  });
}
