import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// `--dart-define=API_BASE_URL=http://127.0.0.1:8000/api`. Vacío = modo mock (sin backend).
const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
const usaApi = apiBaseUrl != '';

class ApiException implements Exception {
  const ApiException(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

/// Cliente mínimo del backend: JSON, multipart y token persistido.
class ApiClient {
  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  static const _kToken = 'api_token';
  final http.Client _http;
  String? token;

  Future<void> restaurarToken() async {
    try {
      token = (await SharedPreferences.getInstance()).getString(_kToken);
    } catch (_) {}
  }

  Future<void> guardarToken(String? t) async {
    token = t;
    try {
      final p = await SharedPreferences.getInstance();
      t == null ? await p.remove(_kToken) : await p.setString(_kToken, t);
    } catch (_) {}
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);

  Future<dynamic> get(String path, {Map<String, String>? query}) async =>
      _decode(await _http.get(_uri(path, query), headers: _headers).timeout(const Duration(seconds: 15)));

  Future<dynamic> send(String method, String path, {Object? body}) async {
    final req = http.Request(method, _uri(path))
      ..headers.addAll({..._headers, 'Content-Type': 'application/json'})
      ..body = jsonEncode(body ?? {});
    return _decode(await http.Response.fromStream(await _http.send(req).timeout(const Duration(seconds: 15))));
  }

  Future<dynamic> multipart(String path, Map<String, String> fields, {String? archivoCampo, String? archivoRuta}) async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers)
      ..fields.addAll(fields);
    if (archivoCampo != null && archivoRuta != null) {
      req.files.add(await http.MultipartFile.fromPath(archivoCampo, archivoRuta));
    }
    return _decode(await http.Response.fromStream(await _http.send(req).timeout(const Duration(seconds: 60))));
  }

  dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    throw ApiException(_mensaje(body, r.statusCode), r.statusCode);
  }

  /// Aplana los errores de DRF (`{"campo": ["msg"]}` o `{"detail": "msg"}`) a una línea legible.
  static String _mensaje(dynamic body, int status) {
    if (body is Map) {
      if (body['detail'] is String) return body['detail'] as String;
      final partes = <String>[];
      body.forEach((k, v) {
        final txt = v is List ? v.join(' ') : v.toString();
        partes.add(k == 'non_field_errors' ? txt : '$k: $txt');
      });
      if (partes.isNotEmpty) return partes.join('\n');
    }
    return switch (status) {
      401 => 'Inicia sesión para continuar',
      404 => 'No encontrado',
      >= 500 => 'Error del servidor, intenta más tarde',
      _ => 'Error de conexión ($status)',
    };
  }
}

/// Convierte fallos de red en un mensaje corto para la UI.
String mensajeDeError(Object e) => switch (e) {
      ApiException() => e.message,
      SocketException() || HttpException() => 'Sin conexión con el servidor',
      _ => 'Algo salió mal, intenta de nuevo',
    };

final apiClientProvider = Provider<ApiClient>((_) => ApiClient());
