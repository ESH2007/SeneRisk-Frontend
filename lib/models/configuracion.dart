class Configuracion {
  const Configuracion({
    this.notificaciones = true,
    this.radioKm = 5,
    this.anonimoPorDefecto = true,
  });

  final bool notificaciones;
  final double radioKm;
  final bool anonimoPorDefecto;

  Configuracion copyWith({
    bool? notificaciones,
    double? radioKm,
    bool? anonimoPorDefecto,
  }) =>
      Configuracion(
        notificaciones: notificaciones ?? this.notificaciones,
        radioKm: radioKm ?? this.radioKm,
        anonimoPorDefecto: anonimoPorDefecto ?? this.anonimoPorDefecto,
      );
}
