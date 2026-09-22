import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/features/map/data/map_manifest.dart';

void main() {
  test('parsea el manifest generado por build_tiles.sh', () {
    final m = MapManifest.fromJson(
        jsonDecode(File('assets/maps/manifest.json').readAsStringSync()) as Map<String, dynamic>);
    expect(m.schema, 'v4');
    expect(m.base.maxzoom, 11);
    expect(m.baseParts.single.id, 'colombia_z12');
    expect(m.baseBytes, m.base.bytes + m.baseParts.single.bytes);
    expect(m.regions.map((r) => r.id), contains('bogota_sabana'));
    expect(m.byId('bogota_sabana')!.contains(4.65, -74.06), isTrue); // Chapinero
    expect(m.byId('bogota_sabana')!.contains(6.25, -75.57), isFalse); // Medellín
    expect(m.downloadable.length, 8);
  });
}
