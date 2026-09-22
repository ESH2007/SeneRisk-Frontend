import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:senerisk_app/features/map/data/map_manifest.dart';
import 'package:senerisk_app/features/map/data/pmtiles_tile_provider.dart';
import 'package:senerisk_app/features/map/data/tile_server.dart';

// Usa los archivos generados por tools/maps/build_tiles.sh (no están en el repo).
const _out = '../tools/maps/out';

(int, int, int) _tile(double lat, double lng, int z) {
  final n = 1 << z;
  final x = ((lng + 180) / 360 * n).floor();
  final r = lat * pi / 180;
  final y = ((1 - log(tan(r) + 1 / cos(r)) / pi) / 2 * n).floor();
  return (z, x, y);
}

MapFile _file(String id, List<double> bbox) => MapFile(
    id: id, name: id, bbox: bbox, minzoom: 13, maxzoom: 15, bytes: 0, sha256: '', build: '0', url: '');

void main() {
  final bogota = File('$_out/bogota_sabana.pmtiles');
  final medellin = File('$_out/medellin.pmtiles');
  final skip = bogota.existsSync() && medellin.existsSync() ? false : 'faltan los PMTiles en $_out';
  final chapinero = _tile(4.65, -74.06, 14);
  final medCentro = _tile(6.25, -75.57, 15);

  test('PmTilesReader: tile presente y ausente', () async {
    final p = await PmTilesReader.open(bogota);
    expect((p.minZoom, p.maxZoom), (13, 15));
    expect((await p.tile(chapinero.$1, chapinero.$2, chapinero.$3))!.length, greaterThan(1000));
    expect(await p.tile(medCentro.$1, medCentro.$2, medCentro.$3), isNull);
    await p.close();
  }, skip: skip);

  test('CompositeDetailProvider: elige la región por bbox y avisa dónde hay detalle', () async {
    final c = CompositeDetailProvider();
    await c.sync({'bogota_sabana': (_file('bogota_sabana', [-74.35, 4.45, -73.95, 4.95]), bogota)});
    expect(c.hasDetailAt(const LatLng(4.65, -74.06)), isTrue);
    expect(c.hasDetailAt(const LatLng(6.25, -75.57)), isFalse);
    expect(await c.tile(chapinero.$1, chapinero.$2, chapinero.$3), isNotNull);
    expect(await c.tile(medCentro.$1, medCentro.$2, medCentro.$3), isNull);
    expect(await c.tile(12, 0, 0), isNull, reason: 'fuera de z13–15');

    await c.sync({
      'bogota_sabana': (_file('bogota_sabana', [-74.35, 4.45, -73.95, 4.95]), bogota),
      'medellin': (_file('medellin', [-75.72, 6.05, -75.40, 6.40]), medellin),
    });
    expect(await c.tile(medCentro.$1, medCentro.$2, medCentro.$3), isNotNull);

    await c.sync({});
    expect(c.hasDetailAt(const LatLng(4.65, -74.06)), isFalse);
    await c.dispose();
  }, skip: skip);

  test('TileServer sirve tiles (200), vacíos (204) y 404 para rutas desconocidas', () async {
    final server = await TileServer.start();
    final detail = CompositeDetailProvider();
    await detail.sync({'bogota_sabana': (_file('bogota_sabana', [-74.35, 4.45, -73.95, 4.95]), bogota)});
    server.detail = detail;
    final http = HttpClient();
    Future<HttpClientResponse> get(String path) async => (await http.getUrl(Uri.parse('${server.url}$path'))).close();

    final ok = await get('/detail/${chapinero.$1}/${chapinero.$2}/${chapinero.$3}.mvt');
    expect(ok.statusCode, 200);
    expect(ok.headers.contentType?.mimeType, 'application/vnd.mapbox-vector-tile');
    expect((await ok.fold<int>(0, (n, c) => n + c.length)), greaterThan(1000));

    expect((await get('/detail/${medCentro.$1}/${medCentro.$2}/${medCentro.$3}.mvt')).statusCode, 204);
    expect((await get('/base/5/9/15.mvt')).statusCode, 204, reason: 'sin base abierta');
    expect((await get('/nada')).statusCode, 404);
    await detail.dispose();
    await server.close();
  }, skip: skip);
}
