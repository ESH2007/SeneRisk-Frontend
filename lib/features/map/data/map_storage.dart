import 'dart:io';

import 'package:disk_space_2/disk_space_2.dart';
import 'package:path_provider/path_provider.dart';

/// Rutas de los PMTiles en disco. Cada archivo se llama `<id>.<build>.pmtiles`,
/// así "hay actualización" es simplemente que el build instalado ≠ el del manifest.
class MapStorage {
  MapStorage(this.dir);

  final Directory dir;

  static Future<MapStorage> open() async {
    final docs = await getApplicationDocumentsDirectory();
    return MapStorage(await Directory('${docs.path}/maps').create(recursive: true));
  }

  static final _name = RegExp(r'^([a-z0-9_]+)\.(\d+)\.pmtiles$');

  File fileFor(String id, String build) => File('${dir.path}/$id.$build.pmtiles');

  File get manifestCache => File('${dir.path}/manifest.json');

  /// `{id: build}` de los archivos completos (no `.part`) presentes en disco.
  Map<String, String> installed() {
    final out = <String, String>{};
    for (final e in dir.listSync()) {
      final m = _name.firstMatch(e.uri.pathSegments.last);
      if (m != null) out[m[1]!] = m[2]!;
    }
    return out;
  }

  /// Borra todos los builds de [id], incluido un `.part` a medias.
  Future<void> delete(String id) async {
    for (final e in dir.listSync()) {
      final n = e.uri.pathSegments.last;
      if (n.startsWith('$id.') && (n.endsWith('.pmtiles') || n.endsWith('.part'))) {
        await e.delete();
      }
    }
  }

  /// Bytes libres en el volumen, o `null` si la plataforma no lo informa.
  Future<int?> freeBytes() async {
    try {
      final mib = await DiskSpace.getFreeDiskSpaceForPath(dir.path);
      return mib == null ? null : (mib * 1048576).round();
    } catch (_) {
      return null;
    }
  }
}
