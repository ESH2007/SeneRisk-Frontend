import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'pmtiles_tile_provider.dart';

/// Servidor HTTP en loopback que alimenta a MapLibre con los PMTiles locales, glifos y
/// sprites. Funciona sin red (127.0.0.1) y reutiliza los lectores de la app.
///
/// Rutas: `/base/{z}/{x}/{y}.mvt`, `/detail/{z}/{x}/{y}.mvt`,
/// `/fonts/{fontstack}/{range}.pbf`, `/sprites/{file}`.
class TileServer {
  TileServer._(this._server);

  final HttpServer _server;

  /// Archivos de la base; para cada tile se usa el primero cuyo rango de zoom lo contiene.
  List<PmTilesReader> base = const [];
  CompositeDetailProvider? detail;

  int get port => _server.port;
  String get url => 'http://127.0.0.1:$port';

  static Future<TileServer> start() async {
    final s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final ts = TileServer._(s);
    s.listen(ts._handle);
    return ts;
  }

  Future<void> close() => _server.close(force: true);

  static final _tile = RegExp(r'^/(base|detail)/(\d+)/(\d+)/(\d+)\.mvt$');
  static final _font = RegExp(r'^/fonts/([^/]+)/(\d+-\d+)\.pbf$');
  static final _sprite = RegExp(r'^/sprites/([\w@.]+)$');

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    try {
      final path = Uri.decodeComponent(req.uri.path);
      if (_tile.firstMatch(path) case final m?) {
        final z = int.parse(m[2]!), x = int.parse(m[3]!), y = int.parse(m[4]!);
        final bytes = m[1] == 'base' ? await _baseTile(z, x, y) : await detail?.tile(z, x, y);
        return _send(res, bytes, 'application/vnd.mapbox-vector-tile');
      }
      if (_font.firstMatch(path) case final m?) {
        // Solo hay glifos latinos empaquetados; cualquier otra fuente cae a Noto Sans Regular.
        var stack = m[1]!;
        if (!stack.startsWith('Noto Sans ') || stack.contains('Devanagari')) stack = 'Noto Sans Regular';
        return _send(res, await _asset('assets/maps/fonts/$stack/${m[2]}.pbf'), 'application/x-protobuf');
      }
      if (_sprite.firstMatch(path) case final m?) {
        final f = m[1]!;
        return _send(res, await _asset('assets/maps/sprites/$f'), f.endsWith('.png') ? 'image/png' : 'application/json');
      }
      res.statusCode = HttpStatus.notFound;
    } catch (_) {
      res.statusCode = HttpStatus.internalServerError;
    } finally {
      await res.close();
    }
  }

  Future<Uint8List?> _baseTile(int z, int x, int y) async {
    for (final r in base) {
      if (z >= r.minZoom && z <= r.maxZoom) return r.tile(z, x, y);
    }
    return null;
  }

  Future<Uint8List?> _asset(String path) async {
    try {
      return (await rootBundle.load(path)).buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void _send(HttpResponse res, Uint8List? bytes, String type) {
    if (bytes == null) {
      res.statusCode = HttpStatus.noContent; // MapLibre lo trata como tile vacío
      return;
    }
    res.headers.contentType = ContentType.parse(type);
    res.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    res.add(bytes);
  }
}
