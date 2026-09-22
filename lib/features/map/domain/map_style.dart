import 'dart:convert';

/// Zoom desde el que dibuja la capa de detalle (y desde el que la base deja de etiquetar).
const detailMinZoom = 13;

/// Construye el estilo MapLibre a partir de las capas Protomaps v4 (`assets/maps/light_v4.json`,
/// generadas sin recortes por `tools/maps/gen_style.mjs`) con dos fuentes servidas por [serverUrl]:
///
/// - `base` (z0–12, sobreampliada por encima): todas las capas.
/// - `detail` (z13–15): las mismas capas sin `background`, para que donde no haya tile se vea la base.
///
/// Las capas de símbolos de la base terminan en z13: dentro de una región las etiquetas vienen del
/// detalle y no se duplican; fuera, se ven las vías ampliadas sin nombre y el aviso de descarga.
String buildMapStyle({
  required String serverUrl,
  required List<dynamic> protomapsLayers,
  required List<double> bounds,
  required int revision,
  int baseMaxZoom = 12,
}) {
  final tiles = '?v=$revision';
  Map<String, dynamic> copy(Map<String, dynamic> l, String source) => {
        ...l,
        'id': '${source}_${l['id']}',
        if (l['source'] != null) 'source': source,
      };
  final base = <Map<String, dynamic>>[];
  final detail = <Map<String, dynamic>>[];
  for (final raw in protomapsLayers) {
    final l = raw as Map<String, dynamic>;
    final b = copy(l, 'base');
    if (l['type'] == 'symbol') {
      final mz = (l['maxzoom'] as num?) ?? 24;
      b['maxzoom'] = mz < detailMinZoom ? mz : detailMinZoom;
    }
    base.add(b);
    if (l['type'] != 'background') detail.add(copy(l, 'detail'));
  }
  return jsonEncode({
    'version': 8,
    'glyphs': '$serverUrl/fonts/{fontstack}/{range}.pbf',
    'sprite': '$serverUrl/sprites/light',
    'sources': {
      'base': {'type': 'vector', 'tiles': ['$serverUrl/base/{z}/{x}/{y}.mvt$tiles'], 'minzoom': 0, 'maxzoom': baseMaxZoom, 'bounds': bounds},
      'detail': {'type': 'vector', 'tiles': ['$serverUrl/detail/{z}/{x}/{y}.mvt$tiles'], 'minzoom': detailMinZoom, 'maxzoom': 15, 'bounds': bounds},
    },
    'layers': [...base, ...detail],
  });
}
