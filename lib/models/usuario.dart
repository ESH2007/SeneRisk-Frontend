class Usuario {
  const Usuario({
    required this.nombre,
    required this.correo,
    required this.tieneCuenta,
  });

  const Usuario.invitado() : this(nombre: '', correo: '', tieneCuenta: false);

  final String nombre;
  final String correo;
  final bool tieneCuenta;

  /// "Juan Pérez" → "JP".
  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    return partes
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  Usuario copyWith({String? nombre, String? correo, bool? tieneCuenta}) =>
      Usuario(
        nombre: nombre ?? this.nombre,
        correo: correo ?? this.correo,
        tieneCuenta: tieneCuenta ?? this.tieneCuenta,
      );
}
