import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:senerisk_app/data/api_client.dart';
import 'package:senerisk_app/models/reporte.dart';
import 'package:senerisk_app/models/tipo_hecho.dart';

void main() {
  test('Reporte.fromJson/toJson con la forma del backend', () {
    final r = Reporte.fromJson({
      'id': 7, 'tipo': 'agresion', 'titulo': 'Riña', 'descripcion': null, 'lugar': 'Cra 15', 'lat': 4.68, 'lng': -74.05,
      'creadoEn': '2026-09-21T15:00:00Z', 'anonimo': true, 'foto': 'http://x/media/f.png', 'confirmaciones': 2, 'desmentidos': 1,
    }, distanciaKm: 1.5);
    expect((r.id, r.tipo, r.descripcion, r.distanciaKm, r.confirmaciones, r.fotoAsset), ('7', TipoHecho.agresion, '', 1.5, 2, 'http://x/media/f.png'));
    expect(r.creadoEn.toUtc(), DateTime.utc(2026, 9, 21, 15));
    expect(Reporte.fromJson(r.toJson()), r);
  });

  test('ApiClient: token, JSON, errores DRF aplanados y multipart', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final peticiones = <HttpRequest>[];
    server.listen((req) async {
      peticiones.add(req);
      final body = await utf8.decoder.bind(req).join();
      final res = req.response..headers.contentType = ContentType.json;
      switch (req.uri.path) {
        case '/api/me/':
          res.write(jsonEncode({'nombre': 'Ana', 'auth': req.headers.value('authorization')}));
        case '/api/auth/login/':
          res.statusCode = 400;
          res.write(jsonEncode({'non_field_errors': ['Correo o contraseña incorrectos.']}));
        case '/api/reportes/':
          res.statusCode = 201;
          res.write(jsonEncode({'multipart': req.headers.contentType?.mimeType == 'multipart/form-data', 'len': body.length}));
        default:
          res.statusCode = 404;
          res.write(jsonEncode({'detail': 'No encontrado'}));
      }
      await res.close();
    });
    // El cliente usa apiBaseUrl (const vacío en tests): se apunta con un http.Client que reescribe la URL.
    final base = 'http://127.0.0.1:${server.port}/api';
    final api = ApiClient(client: _Rewrite(base));
    api.token = 'abc';

    final me = await api.get('/me/');
    expect(me['auth'], 'Token abc');

    await expectLater(
      api.send('POST', '/auth/login/', body: {'correo': 'a', 'password': 'b'}),
      throwsA(isA<ApiException>().having((e) => e.message, 'msg', 'Correo o contraseña incorrectos.').having((e) => e.status, 'status', 400)),
    );
    await expectLater(api.get('/nada/'), throwsA(isA<ApiException>().having((e) => e.message, 'msg', 'No encontrado')));

    final tmp = File('${Directory.systemTemp.path}/foto_test.png')..writeAsBytesSync(List.filled(100, 1));
    final r = await api.multipart('/reportes/', {'titulo': 'x'}, archivoCampo: 'foto', archivoRuta: tmp.path);
    expect(r['multipart'], isTrue);
    expect(r['len'], greaterThan(100));
    expect(mensajeDeError(const SocketException('x')), 'Sin conexión con el servidor');
    await server.close(force: true);
  });
}

/// Sustituye el prefijo vacío de `apiBaseUrl` por el del servidor de prueba.
class _Rewrite extends http.BaseClient {
  _Rewrite(this.base);
  final String base;
  final _inner = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final uri = Uri.parse('$base${request.url}');
    http.BaseRequest copia;
    if (request is http.Request) {
      copia = http.Request(request.method, uri)..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      copia = http.MultipartRequest(request.method, uri)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else {
      copia = http.Request(request.method, uri);
    }
    copia.headers.addAll(request.headers);
    return _inner.send(copia);
  }
}
