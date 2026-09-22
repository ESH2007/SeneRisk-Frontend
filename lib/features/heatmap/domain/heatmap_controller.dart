import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/filtro_mapa_provider.dart';
import '../../../data/api_client.dart';
import '../data/api_reports_repository.dart';
import '../data/risk_report.dart';

/// Cantidad de puntos mock: `--dart-define=HEAT_MOCK_POINTS=10000` para pruebas de rendimiento.
const heatMockPoints = int.fromEnvironment('HEAT_MOCK_POINTS', defaultValue: 1000);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => usaApi ? ApiReportsRepository(ref.read(apiClientProvider)) : MockReportsRepository(count: heatMockPoints),
);

class HeatmapFilters {
  const HeatmapFilters({this.rangeDays = 30, this.visible = true, this.bounds});

  /// 7 / 30 / 180.
  final int rangeDays;
  final bool visible;

  /// Área visible del mapa (la fija la pantalla al mover la cámara).
  final LatLngBounds? bounds;

  HeatmapFilters copyWith({int? rangeDays, bool? visible, LatLngBounds? bounds}) => HeatmapFilters(
        rangeDays: rangeDays ?? this.rangeDays,
        visible: visible ?? this.visible,
        bounds: bounds ?? this.bounds,
      );
}

class HeatmapController extends Notifier<HeatmapFilters> {
  @override
  HeatmapFilters build() => const HeatmapFilters();

  void setRangeDays(int d) => state = state.copyWith(rangeDays: d);
  void toggleVisible() => state = state.copyWith(visible: !state.visible);
  /// Solo cambia el estado cuando cambia el bbox redondeado a 0.5° (la caché del repositorio
  /// usa la misma rejilla), así un pan pequeño no dispara nada.
  void setBounds(LatLngBounds b) {
    final actual = state.bounds;
    if (actual != null && actual.containsBounds(b)) return; // histéresis: no oscilar en un borde
    state = state.copyWith(bounds: MockReportsRepository.roundBounds(b));
  }
}

final heatmapProvider = NotifierProvider<HeatmapController, HeatmapFilters>(HeatmapController.new);

/// Reportes para la capa: se recalcula al cambiar rango, categoría (chips del mapa) o área.
/// El repositorio cachea por bbox+filtros, así que en modo avión sigue respondiendo.
final heatReportsProvider = FutureProvider<List<RiskReport>>((ref) async {
  final f = ref.watch(heatmapProvider);
  final cat = ref.watch(filtroMapaProvider);
  final bounds = f.bounds;
  if (bounds == null || !f.visible) return const [];
  final now = DateTime.now();
  return ref.read(reportsRepositoryProvider).fetch(
        bounds: bounds,
        range: DateTimeRange(start: now.subtract(Duration(days: f.rangeDays)), end: now),
        categories: cat == 'todos' ? null : {cat},
      );
});
