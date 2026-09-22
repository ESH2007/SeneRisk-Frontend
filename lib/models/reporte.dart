import 'package:intl/intl.dart';

import 'tipo_hecho.dart';

class Reporte {
  const Reporte({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.lugar,
    required this.lat,
    required this.lng,
    required this.creadoEn,
    required this.distanciaKm,
    this.confirmaciones = 0,
    this.desmentidos = 0,
    this.anonimo = true,
    this.fotoAsset,
  });

  final String id;
  final TipoHecho tipo;
  final String titulo;
  final String descripcion;
  final String lugar;
  final double lat;
  final double lng;
  final DateTime creadoEn;
  final double distanciaKm;
  final int confirmaciones;
  final int desmentidos;
  final bool anonimo;
  final String? fotoAsset;

  /// `id` numérico del backend o `r1` mock. [fotoAsset] puede ser URL, ruta local o asset.
  factory Reporte.fromJson(Map<String, dynamic> j, {double distanciaKm = 0}) => Reporte(
        id: j['id'].toString(),
        tipo: TipoHecho.values.firstWhere((t) => t.name == j['tipo'], orElse: () => TipoHecho.vandalismo),
        titulo: j['titulo'] as String,
        descripcion: (j['descripcion'] as String?) ?? '',
        lugar: j['lugar'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        creadoEn: DateTime.parse(j['creadoEn'] as String).toLocal(),
        distanciaKm: (j['distanciaKm'] as num?)?.toDouble() ?? distanciaKm,
        confirmaciones: (j['confirmaciones'] as num?)?.toInt() ?? 0,
        desmentidos: (j['desmentidos'] as num?)?.toInt() ?? 0,
        anonimo: (j['anonimo'] as bool?) ?? true,
        fotoAsset: j['foto'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.name,
        'titulo': titulo,
        'descripcion': descripcion,
        'lugar': lugar,
        'lat': lat,
        'lng': lng,
        'creadoEn': creadoEn.toUtc().toIso8601String(),
        'distanciaKm': distanciaKm,
        'confirmaciones': confirmaciones,
        'desmentidos': desmentidos,
        'anonimo': anonimo,
        'foto': fotoAsset,
      };

  String get horaTexto => horaRelativa(creadoEn);

  String get distanciaTexto => '${formatoKm.format(distanciaKm)} km';

  double get porcentajeVerificacion {
    final total = confirmaciones + desmentidos;
    return total == 0 ? 0 : confirmaciones / total;
  }

  Reporte copyWith({
    String? id,
    TipoHecho? tipo,
    String? titulo,
    String? descripcion,
    String? lugar,
    double? lat,
    double? lng,
    DateTime? creadoEn,
    double? distanciaKm,
    int? confirmaciones,
    int? desmentidos,
    bool? anonimo,
    String? fotoAsset,
  }) =>
      Reporte(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        titulo: titulo ?? this.titulo,
        descripcion: descripcion ?? this.descripcion,
        lugar: lugar ?? this.lugar,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        creadoEn: creadoEn ?? this.creadoEn,
        distanciaKm: distanciaKm ?? this.distanciaKm,
        confirmaciones: confirmaciones ?? this.confirmaciones,
        desmentidos: desmentidos ?? this.desmentidos,
        anonimo: anonimo ?? this.anonimo,
        fotoAsset: fotoAsset ?? this.fotoAsset,
      );

  @override
  bool operator ==(Object other) =>
      other is Reporte &&
      other.id == id &&
      other.tipo == tipo &&
      other.titulo == titulo &&
      other.descripcion == descripcion &&
      other.lugar == lugar &&
      other.lat == lat &&
      other.lng == lng &&
      other.creadoEn == creadoEn &&
      other.distanciaKm == distanciaKm &&
      other.confirmaciones == confirmaciones &&
      other.desmentidos == desmentidos &&
      other.anonimo == anonimo &&
      other.fotoAsset == fotoAsset;

  @override
  int get hashCode => Object.hash(id, tipo, titulo, descripcion, lugar, lat,
      lng, creadoEn, distanciaKm, confirmaciones, desmentidos, anonimo, fotoAsset);
}

final formatoKm = NumberFormat('0.0', 'es_CO');

String horaRelativa(DateTime creadoEn, {DateTime? ahora}) {
  final diff = (ahora ?? DateTime.now()).difference(creadoEn);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return 'hace ${diff.inDays} d';
}
