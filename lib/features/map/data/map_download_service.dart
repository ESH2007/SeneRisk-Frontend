import 'dart:io';

import 'package:crypto/crypto.dart';

import 'map_manifest.dart';

class ChecksumException implements Exception {
  const ChecksumException(this.id);
  final String id;
  @override
  String toString() => 'El archivo $id llegó corrupto (sha256 no coincide)';
}

/// Descarga PMTiles con reanudación por HTTP `Range`, escribiendo a `<dest>.part`
/// y renombrando a [dest] solo si el sha256 coincide con el manifest.
class MapDownloadService {
  MapDownloadService({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  /// Emite los bytes acumulados. Cancelar la suscripción detiene la descarga y
  /// conserva el `.part` para reanudar después.
  Stream<int> download(MapFile file, File dest) async* {
    final part = File('${dest.path}.part');
    var have = await part.exists() ? await part.length() : 0;
    if (have > file.bytes) {
      await part.delete();
      have = 0;
    }
    if (have < file.bytes) {
      final req = await _client.getUrl(Uri.parse(file.url));
      if (have > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      final res = await req.close();
      if (res.statusCode == HttpStatus.ok) {
        have = 0; // el servidor ignoró el Range: se empieza de cero
      } else if (res.statusCode != HttpStatus.partialContent) {
        await res.drain<void>();
        throw HttpException('HTTP ${res.statusCode}', uri: Uri.parse(file.url));
      }
      final sink = part.openWrite(mode: have == 0 ? FileMode.write : FileMode.append);
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          have += chunk.length;
          yield have;
        }
      } finally {
        await sink.close();
      }
    }
    final digest = await sha256.bind(part.openRead()).first;
    if (digest.toString() != file.sha256) {
      await part.delete();
      throw ChecksumException(file.id);
    }
    await part.rename(dest.path);
    yield have;
  }
}
