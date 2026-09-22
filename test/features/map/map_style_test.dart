import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/features/map/domain/map_style.dart';

void main() {
  test('el estilo tiene base completa y detalle sin fondo, etiquetas de base hasta z13', () {
    final layers = (jsonDecode(File('assets/maps/light_v4.json').readAsStringSync()) as Map)['layers'] as List;
    final style = jsonDecode(buildMapStyle(
      serverUrl: 'http://127.0.0.1:1234', protomapsLayers: layers, bounds: [-82, -5, -66, 14], revision: 3,
    )) as Map<String, dynamic>;
    final out = (style['layers'] as List).cast<Map<String, dynamic>>();
    final base = out.where((l) => (l['id'] as String).startsWith('base_')).toList();
    final detail = out.where((l) => (l['id'] as String).startsWith('detail_')).toList();
    expect(base.length, layers.length);
    expect(detail.length, layers.length - 1);
    expect(detail.any((l) => l['type'] == 'background'), isFalse);
    expect(base.where((l) => l['type'] == 'symbol').every((l) => (l['maxzoom'] as num) <= 13), isTrue);
    expect(detail.where((l) => l['type'] == 'symbol').every((l) => (l['maxzoom'] as num?) == null || l['maxzoom'] > 13), isTrue);
    expect(base.every((l) => l['source'] == null || l['source'] == 'base'), isTrue);
    expect((style['sources'] as Map)['detail']['tiles'][0], 'http://127.0.0.1:1234/detail/{z}/{x}/{y}.mvt?v=3');
    expect(style['glyphs'], startsWith('http://127.0.0.1:1234/fonts/'));
  });
}
