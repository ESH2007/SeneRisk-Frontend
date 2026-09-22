import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/features/map/data/map_download_service.dart';
import 'package:senerisk_app/features/map/data/map_manifest.dart';

/// Servidor que sirve [data] con soporte de `Range` y cuenta los bytes enviados.
class _FakeServer {
  _FakeServer(this.data);
  final List<int> data;
  late HttpServer server;
  /// Bytes enviados por cada request, en orden.
  final sent = <int>[];
  bool ignoreRange = false;

  Future<String> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final idx = sent.length;
      sent.add(0);
      var from = 0;
      final range = req.headers.value(HttpHeaders.rangeHeader);
      if (range != null && !ignoreRange) {
        from = int.parse(range.substring('bytes='.length, range.length - 1));
        req.response.statusCode = HttpStatus.partialContent;
        req.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $from-${data.length - 1}/${data.length}');
      }
      // Trozos pequeños para que la cancelación caiga a mitad de camino.
      try {
        for (var i = from; i < data.length; i += 1024) {
          final chunk = data.sublist(i, min(i + 1024, data.length));
          req.response.add(chunk);
          sent[idx] += chunk.length;
          await req.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        await req.response.close();
      } catch (_) {
        // el cliente cerró la conexión (cancelación)
      }
    });
    return 'http://${server.address.address}:${server.port}/f.pmtiles';
  }
}

void main() {
  late Directory tmp;
  late _FakeServer srv;
  late MapFile file;
  late File dest;
  final data = List<int>.generate(64 * 1024, (i) => (i * 31 + 7) & 0xff);
  final sha = sha256.convert(data).toString();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('maps_test');
    srv = _FakeServer(data);
    final url = await srv.start();
    file = MapFile(
      id: 'x', name: 'x', bbox: const [0, 0, 1, 1], minzoom: 13, maxzoom: 15,
      bytes: data.length, sha256: sha, build: '1', url: url,
    );
    dest = File('${tmp.path}/x.1.pmtiles');
  });
  tearDown(() async {
    await srv.server.close(force: true);
    await tmp.delete(recursive: true);
  });

  test('descarga completa, verifica sha256 y renombra el .part', () async {
    final progress = await MapDownloadService().download(file, dest).toList();
    expect(progress.last, data.length);
    expect(dest.existsSync(), isTrue);
    expect(File('${dest.path}.part').existsSync(), isFalse);
    expect(dest.readAsBytesSync(), data);
  });

  test('cancelar conserva el .part y no crea el destino', () async {
    final sub = MapDownloadService().download(file, dest).listen(null);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await sub.cancel();
    final part = File('${dest.path}.part');
    expect(part.existsSync(), isTrue);
    expect(part.lengthSync(), inExclusiveRange(0, data.length));
    expect(dest.existsSync(), isFalse);
  });

  test('reanuda con Range desde el .part y pide solo lo que falta', () async {
    final sub = MapDownloadService().download(file, dest).listen(null);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await sub.cancel();
    final have = File('${dest.path}.part').lengthSync();
    await MapDownloadService().download(file, dest).drain<void>();
    expect(srv.sent.length, 2);
    expect(srv.sent[1], data.length - have);
    expect(dest.readAsBytesSync(), data);
  });

  test('si el servidor ignora Range (200), reinicia desde cero', () async {
    File('${dest.path}.part').writeAsBytesSync(List.filled(100, 0));
    srv.ignoreRange = true;
    await MapDownloadService().download(file, dest).drain<void>();
    expect(dest.readAsBytesSync(), data);
  });

  test('sha256 incorrecto: lanza ChecksumException y borra el .part', () async {
    final bad = MapFile(
      id: 'x', name: 'x', bbox: file.bbox, minzoom: 13, maxzoom: 15,
      bytes: file.bytes, sha256: 'deadbeef', build: '1', url: file.url,
    );
    await expectLater(MapDownloadService().download(bad, dest).drain<void>(), throwsA(isA<ChecksumException>()));
    expect(File('${dest.path}.part').existsSync(), isFalse);
    expect(dest.existsSync(), isFalse);
  });

  test('servidor inalcanzable lanza SocketException', () async {
    final missing = MapFile(
      id: 'x', name: 'x', bbox: file.bbox, minzoom: 13, maxzoom: 15,
      bytes: 10, sha256: sha, build: '1', url: 'http://127.0.0.1:1/nope',
    );
    await expectLater(MapDownloadService().download(missing, dest).drain<void>(), throwsA(isA<SocketException>()));
  });
}
