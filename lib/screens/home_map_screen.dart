import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' show Epsg3857, LatLngBounds;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../data/mock_reportes.dart';
import '../features/heatmap/data/risk_report.dart';
import '../features/heatmap/domain/heat_geojson.dart';
import '../features/heatmap/domain/heat_grid.dart';
import '../features/heatmap/domain/heat_weighting.dart';
import '../features/heatmap/domain/heatmap_controller.dart';
import '../features/heatmap/presentation/heat_cell_sheet.dart';
import '../features/heatmap/presentation/heat_controls.dart';
import '../features/map/domain/map_engine_controller.dart';
import '../features/map/domain/map_style.dart';
import '../features/map/domain/offline_maps_controller.dart';
import '../features/map/presentation/map_setup_card.dart';
import '../models/reporte.dart';
import '../models/tipo_hecho.dart';
import '../state/filtro_mapa_provider.dart';
import '../state/reportes_provider.dart';
import '../state/ubicacion_usuario_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/status_pill.dart';
import 'search_place_screen.dart';

const _centroBogota = ml.LatLng(4.6600, -74.0800);
const _zoomInicial = 11.5;

/// Límite de la cámara: bbox de Colombia con San Andrés (igual al de `regions.json`).
final _limiteColombia = ml.LatLngBounds(southwest: const ml.LatLng(-4.39, -81.85), northeast: const ml.LatLng(13.45, -66.73));

String _hex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key, this.centrarLat, this.centrarLng});

  final double? centrarLat;
  final double? centrarLng;

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ml.MapLibreMapController? _mapa;
  bool _styleReady = false;
  bool _sinDetalle = false;
  List<Reporte>? _reportesEnMapa;
  List<RiskReport>? _calorEnMapa;
  LatLng _ubicacionEnMapa = ubicacionSimulada;

  ml.LatLng? get _centroInicial => widget.centrarLat != null && widget.centrarLng != null
      ? ml.LatLng(widget.centrarLat!, widget.centrarLng!)
      : null;

  Future<void> _irAMiUbicacion() async {
    final u = await ref.read(ubicacionUsuarioProvider.future);
    await _mapa?.animateCamera(ml.CameraUpdate.newLatLngZoom(ml.LatLng(u.latitude, u.longitude), 14));
  }

  Future<void> _abrirBusqueda() async {
    final r = await context.push<String>('/search');
    if (r == resultadoMiUbicacion) await _irAMiUbicacion();
  }

  // ---- capas de datos sobre el estilo -------------------------------------------------

  bool _configurandoEstilo = false;

  Future<void> _onStyleLoaded() async {
    final c = _mapa!;
    if (_configurandoEstilo) return; // el plugin puede avisar dos veces del mismo estilo
    _configurandoEstilo = true;
    try {
      await _agregarCapas(c);
    } on PlatformException catch (e) {
      // Cambió el estilo a mitad de camino (nueva revisión): se volverá a llamar.
      debugPrint('capas: ${e.message}');
      return;
    } finally {
      _configurandoEstilo = false;
    }
    _styleReady = true;
    _reportesEnMapa = null;
    _calorEnMapa = null;
    _refrescarDatos();
  }

  Future<void> _agregarCapas(ml.MapLibreMapController c) async {
    await c.addGeoJsonSource('heat', heatFeatureCollection(const [], const HeatWeighting(), DateTime.now()));
    await c.addHeatmapLayer(
      'heat',
      'heat',
      ml.HeatmapLayerProperties(
        heatmapWeight: ['get', 'w'],
        heatmapIntensity: ['interpolate', ['linear'], ['zoom'], 9, 0.5, 16, 1.2],
        // El radio crece con el zoom y se congela a partir de z16.
        heatmapRadius: ['interpolate', ['linear'], ['zoom'], 9, 12, 16, 36],
        heatmapColor: [
          'interpolate', ['linear'], ['heatmap-density'],
          0, 'rgba(0,0,0,0)',
          0.15, _hex(AppColors.heatLow),
          0.5, _hex(AppColors.heatMid),
          1, _hex(AppColors.heatHigh),
        ],
        heatmapOpacity: 0.75,
      ),
      minzoom: 9,
    );
    await c.addGeoJsonSource('me', _puntoGeoJson(_ubicacionEnMapa));
    await c.addCircleLayer('me', 'me', ml.CircleLayerProperties(
      circleRadius: 6, circleColor: _hex(AppColors.userDot), circleStrokeColor: '#FFFFFF', circleStrokeWidth: 2,
    ));
    await c.addGeoJsonSource('reports', _reportesGeoJson(const []));
    await c.addCircleLayer('reports', 'reports', ml.CircleLayerProperties(
      circleRadius: 9, circleColor: ['get', 'color'], circleStrokeColor: '#FFFFFF', circleStrokeWidth: 2,
    ));
  }

  Map<String, dynamic> _puntoGeoJson(LatLng p) => {
        'type': 'FeatureCollection',
        'features': [
          {'type': 'Feature', 'geometry': {'type': 'Point', 'coordinates': [p.longitude, p.latitude]}, 'properties': {}},
        ],
      };

  Map<String, dynamic> _reportesGeoJson(List<Reporte> rs) => {
        'type': 'FeatureCollection',
        'features': [
          for (final r in rs)
            {
              'type': 'Feature',
              'id': r.id, // es lo que entrega onFeatureTapped
              'geometry': {'type': 'Point', 'coordinates': [r.lng, r.lat]},
              'properties': {'color': _hex(r.tipo.color)},
            },
        ],
      };

  /// Empuja al mapa lo que cambió desde la última vez (reportes, calor, ubicación).
  void _refrescarDatos() {
    final c = _mapa;
    if (c == null || !_styleReady) return;
    final visibles = filtrarMapa(ref.read(reportesProvider), ref.read(filtroMapaProvider));
    if (!identical(visibles, _reportesEnMapa)) {
      _reportesEnMapa = visibles;
      c.setGeoJsonSource('reports', _reportesGeoJson(visibles));
    }
    final calor = ref.read(heatReportsProvider).value ?? const <RiskReport>[];
    if (!identical(calor, _calorEnMapa)) {
      _calorEnMapa = calor;
      c.setGeoJsonSource('heat', heatFeatureCollection(calor, const HeatWeighting(), DateTime.now()));
    }
    final u = ref.read(ubicacionUsuarioProvider).value ?? ubicacionSimulada;
    if (u != _ubicacionEnMapa) {
      _ubicacionEnMapa = u;
      c.setGeoJsonSource('me', _puntoGeoJson(u));
    }
  }

  // ---- cámara y toques ------------------------------------------------------------------

  Future<void> _onCameraIdle() async {
    final c = _mapa;
    final cam = c?.cameraPosition;
    if (c == null || cam == null) return;
    final vr = await c.getVisibleRegion();
    ref.read(heatmapProvider.notifier).setBounds(LatLngBounds(
          LatLng(vr.southwest.latitude, vr.southwest.longitude),
          LatLng(vr.northeast.latitude, vr.northeast.longitude),
        ));
    final detail = ref.read(mapEngineProvider).detail;
    final falta = cam.zoom >= detailMinZoom && !detail.hasDetailAt(LatLng(cam.target.latitude, cam.target.longitude));
    if (falta != _sinDetalle && mounted) setState(() => _sinDetalle = falta);
  }

  void _onMapCreated(ml.MapLibreMapController c) {
    _mapa = c;
    // Toque sobre un marcador de reporte (capa interactiva; el plugin no llama a onMapClick).
    c.onFeatureTapped.add((_, _, id, layerId, _) {
      if (layerId == 'reports' && id.isNotEmpty && id != 'null' && mounted) context.push('/report/$id');
    });
  }

  Future<void> _onTap(Point<double> p, ml.LatLng ll) async {
    final c = _mapa;
    final cam = c?.cameraPosition;
    if (c == null || cam == null) return;
    // Zona caliente: agregación en rejilla al vuelo (datos agregados, nunca un reporte).
    final calor = _calorEnMapa;
    if (calor == null || calor.isEmpty || !ref.read(heatmapProvider).visible) return;
    const crs = Epsg3857();
    final centro = crs.latLngToOffset(LatLng(ll.latitude, ll.longitude), cam.zoom);
    final grid = buildHeatGrid(HeatGridRequest(
      reports: calor,
      zoom: cam.zoom,
      cellSizePx: 24,
      pixelBounds: Rect.fromCenter(center: centro, width: 200, height: 200),
      weighting: const HeatWeighting(),
      now: DateTime.now(),
    ));
    final cell = grid.cellAt(centro);
    if (cell != null && mounted) await showHeatCellSheet(context, cell);
  }

  @override
  void didUpdateWidget(HomeMapScreen old) {
    super.didUpdateWidget(old);
    final c = _centroInicial;
    if (c != null && (old.centrarLat != widget.centrarLat || old.centrarLng != widget.centrarLng)) {
      _mapa?.animateCamera(ml.CameraUpdate.newLatLngZoom(c, 15));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtro = ref.watch(filtroMapaProvider);
    ref.watch(reportesProvider);
    ref.watch(heatReportsProvider);
    ref.watch(ubicacionUsuarioProvider);
    final maps = ref.watch(offlineMapsProvider);
    final engine = ref.watch(mapEngineProvider);
    final safeTop = MediaQuery.paddingOf(context).top;

    ref.listen(mapEngineProvider, (prev, next) {
      // Cambió algo en disco (base, regiones): estilo nuevo con URLs nuevas → MapLibre vuelve a pedir tiles.
      if (next.style != null && next.style != prev?.style) {
        _styleReady = false;
        _mapa?.setStyle(next.style!);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refrescarDatos());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(paginaActual: 'mapa'),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (engine.style == null)
              const ColoredBox(color: AppColors.mapBase)
            else
              ml.MapLibreMap(
                styleString: engine.style!,
                initialCameraPosition: ml.CameraPosition(
                  target: _centroInicial ?? _centroBogota,
                  zoom: _centroInicial == null ? _zoomInicial : 15,
                ),
                minMaxZoomPreference: const ml.MinMaxZoomPreference(5, 19),
                cameraTargetBounds: ml.CameraTargetBounds(_limiteColombia),
                compassEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                trackCameraPosition: true,
                attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                onCameraIdle: _onCameraIdle,
                onMapClick: _onTap,
              ),
            if (maps.ready && !engine.baseReady) const Center(child: MapSetupCard()),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppDimens.pagePadding, 8, AppDimens.pagePadding, 0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: AppDimens.touchTarget,
                          height: AppDimens.touchTarget,
                          child: IconButton(
                            tooltip: 'Menú',
                            onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                            icon: const Icon(Icons.menu, size: 22, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _SearchBarButton(onTap: _abrirBusqueda)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ChipRow(
                    children: [
                      _chip('Todos', 'todos', null, filtro),
                      _chip('Bloqueos', 'bloqueo', Icons.construction, filtro),
                      _chip('Protestas', 'protesta', Icons.campaign_outlined, filtro),
                      _chip('Incendios', 'incendio', Icons.local_fire_department_outlined, filtro),
                      _chip('Agresiones', 'agresion', Icons.back_hand_outlined, filtro),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: safeTop + 92,
              child: const StatusPill.elevated('Actualizado hace 2 min'),
            ),
            if (_sinDetalle && engine.baseReady)
              Positioned(left: 14, right: 14, bottom: 196, child: Center(child: _AvisoSinDetalle())),
            const Positioned(left: 14, bottom: 92, child: HeatControls()),
            Positioned(
              right: 14,
              bottom: 92,
              child: Semantics(
                button: true,
                label: 'Mi ubicación',
                child: Material(
                  color: AppColors.paper,
                  shape: CircleBorder(side: BorderSide(color: AppColors.line, width: AppDimens.borderWidth)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _irAMiUbicacion,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.my_location, size: 18, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 34,
              left: 0,
              right: 0,
              child: Center(child: _FloatingReportButton(onTap: () => context.push('/report/new'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String valor, IconData? icon, String actual) => AppFilterChip(
        label: label,
        icon: icon,
        selected: actual == valor,
        onTap: () => ref.read(filtroMapaProvider.notifier).set(valor),
      );
}

/// Aviso discreto a zoom de calles en una zona sin región descargada.
class _AvisoSinDetalle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paper,
      shape: StadiumBorder(side: BorderSide(color: AppColors.line, width: AppDimens.borderWidth)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/maps'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_outlined, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Descarga esta zona para ver calles sin conexión',
                  style: AppTextStyles.label.copyWith(fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBarButton extends StatelessWidget {
  const _SearchBarButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buscar ubicación o reporte',
      child: Material(
        color: AppColors.paper,
        shape: StadiumBorder(side: BorderSide(color: AppColors.line, width: AppDimens.borderWidth)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Buscar ubicación o reporte',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingReportButton extends StatelessWidget {
  const _FloatingReportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Reportar hecho',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          boxShadow: AppDimens.floatingShadow,
        ),
        child: Material(
          color: AppColors.primary,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            overlayColor: WidgetStatePropertyAll(AppColors.cream.withValues(alpha: 0.1)),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 15, color: AppColors.cream),
                  const SizedBox(width: 6),
                  Text(
                    'Reportar hecho',
                    style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w700, color: AppColors.cream),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

