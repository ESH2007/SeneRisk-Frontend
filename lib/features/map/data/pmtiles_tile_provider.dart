import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:pmtiles/pmtiles.dart';

import 'map_manifest.dart';

/// Lee tiles vectoriales de un archivo PMTiles (local o remoto por HTTP Range).
class PmTilesReader {
  PmTilesReader._(this._archive);

  final PmTilesArchive _archive;
  int get minZoom => _archive.minZoom;
  int get maxZoom => _archive.maxZoom;

  static Future<PmTilesReader> open(File f) async => PmTilesReader._(await PmTilesArchive.fromFile(f));
  static Future<PmTilesReader> openUri(Uri u) async => PmTilesReader._(await PmTilesArchive.fromUri(u));

  /// Bytes MVT descomprimidos, o `null` si el tile no existe.
  Future<Uint8List?> tile(int z, int x, int y) async {
    final t = await _archive.tile(ZXY(z, x, y).toTileId());
    try {
      return Uint8List.fromList(t.bytes());
    } on TileNotFoundException {
      return null;
    }
  }

  Future<void> close() => _archive.close();
}

/// Proveedor de detalle z13–15: busca cada tile en las regiones descargadas; si ninguna lo
/// tiene y el modo remoto está activo, lo pide al archivo nacional por HTTP; si no, `null`.
class CompositeDetailProvider {
  CompositeDetailProvider({this.minimumZoom = 13, this.maximumZoom = 15});

  final int minimumZoom;
  final int maximumZoom;

  final _regions = <String, (MapFile, PmTilesReader)>{};
  PmTilesReader? _remote;
  Uri? _remoteUri;
  bool remoteEnabled = false;

  /// Abre las regiones nuevas y cierra las que ya no están. [installed] es `{id: (MapFile, archivo)}`.
  Future<void> sync(Map<String, (MapFile, File)> installed) async {
    for (final id in _regions.keys.toList()) {
      if (!installed.containsKey(id)) await _regions.remove(id)!.$2.close();
    }
    for (final e in installed.entries) {
      if (!_regions.containsKey(e.key)) {
        _regions[e.key] = (e.value.$1, await PmTilesReader.open(e.value.$2));
      }
    }
  }

  void setRemote(Uri? uri) {
    if (uri != _remoteUri) {
      _remote?.close();
      _remote = null;
      _remoteUri = uri;
    }
  }

  Future<void> dispose() async {
    await sync({});
    setRemote(null);
  }

  /// `true` si en [p] se verán calles: hay región descargada o el modo remoto está activo.
  bool hasDetailAt(LatLng p) =>
      (remoteEnabled && _remoteUri != null) ||
      _regions.values.any((r) => r.$1.contains(p.latitude, p.longitude));

  Future<Uint8List?> tile(int z, int x, int y) async {
    if (z < minimumZoom || z > maximumZoom) return null;
    final b = tileBounds(z, x, y);
    for (final (f, r) in _regions.values) {
      final inter = b[0] < f.bbox[2] && b[2] > f.bbox[0] && b[1] < f.bbox[3] && b[3] > f.bbox[1];
      if (!inter) continue;
      final bytes = await r.tile(z, x, y);
      if (bytes != null) return bytes; // si es null, el tile está en el borde: seguir buscando
    }
    if (remoteEnabled && _remoteUri != null) {
      _remote ??= await PmTilesReader.openUri(_remoteUri!);
      return _remote!.tile(z, x, y);
    }
    return null;
  }

  /// `[minLng, minLat, maxLng, maxLat]` del tile (Web Mercator).
  static List<double> tileBounds(int z, int x, int y) {
    final n = 1 << z;
    double lng(int x) => x / n * 360 - 180;
    double lat(int y) => atan(_sinh(pi * (1 - 2 * y / n))) * 180 / pi;
    return [lng(x), lat(y + 1), lng(x + 1), lat(y)];
  }

  static double _sinh(double x) => (exp(x) - exp(-x)) / 2;
}
