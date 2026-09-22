/// Modelos de `manifest.json` generado por `tools/maps/build_tiles.sh`.
library;

/// Un archivo PMTiles descargable (la base o una región de detalle).
class MapFile {
  const MapFile({
    required this.id,
    required this.name,
    required this.bbox,
    required this.minzoom,
    required this.maxzoom,
    required this.bytes,
    required this.sha256,
    required this.build,
    required this.url,
  });

  final String id;
  final String name;

  /// `[minLng, minLat, maxLng, maxLat]`.
  final List<double> bbox;
  final int minzoom;
  final int maxzoom;
  final int bytes;
  final String sha256;
  final String build;
  final String url;

  factory MapFile.fromJson(Map<String, dynamic> j) => MapFile(
        id: j['id'] as String,
        name: j['name'] as String,
        bbox: (j['bbox'] as List).cast<num>().map((n) => n.toDouble()).toList(),
        minzoom: j['minzoom'] as int,
        maxzoom: j['maxzoom'] as int,
        bytes: j['bytes'] as int,
        sha256: j['sha256'] as String,
        build: j['build'] as String,
        url: j['url'] as String,
      );

  bool contains(double lat, double lng) =>
      lng >= bbox[0] && lng <= bbox[2] && lat >= bbox[1] && lat <= bbox[3];

  String get sizeLabel => '${(bytes / 1048576).toStringAsFixed(1)} MB';
}

class MapManifest {
  const MapManifest({
    required this.build,
    required this.schema,
    required this.base,
    this.baseParts = const [],
    required this.regions,
    this.nationalDetail,
  });

  final String build;
  final String schema;
  final MapFile base;

  /// Otros archivos de la base (p. ej. z12 aparte por el límite de 50 MB por archivo del bucket).
  final List<MapFile> baseParts;
  final List<MapFile> regions;
  final MapFile? nationalDetail;

  factory MapManifest.fromJson(Map<String, dynamic> j) => MapManifest(
        build: j['build'] as String,
        schema: j['schema'] as String,
        base: MapFile.fromJson(j['base'] as Map<String, dynamic>),
        baseParts: [for (final p in (j['base_parts'] as List?) ?? []) MapFile.fromJson(p as Map<String, dynamic>)],
        regions: (j['regions'] as List)
            .map((r) => MapFile.fromJson(r as Map<String, dynamic>))
            .toList(),
        nationalDetail: j['national_detail'] == null
            ? null
            : MapFile.fromJson(j['national_detail'] as Map<String, dynamic>),
      );

  /// Todos los archivos que forman la base (siempre necesarios).
  List<MapFile> get baseFiles => [base, ...baseParts];

  /// Base + regiones, en el orden en que se muestran.
  List<MapFile> get downloadable => [...baseFiles, ...regions];

  /// Bytes totales de la base.
  int get baseBytes => baseFiles.fold(0, (s, f) => s + f.bytes);

  MapFile? byId(String id) {
    for (final f in downloadable) {
      if (f.id == id) return f;
    }
    return null;
  }
}
