import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/models/reporte.dart';
import 'package:senerisk_app/models/tipo_hecho.dart';
import 'package:senerisk_app/models/usuario.dart';

void main() {
  final ahora = DateTime(2026, 9, 17, 12, 0);

  group('horaRelativa', () {
    test('menos de 1 min → ahora', () {
      expect(horaRelativa(ahora.subtract(const Duration(seconds: 30)), ahora: ahora), 'ahora');
    });
    test('menos de 60 → hace N min', () {
      expect(horaRelativa(ahora.subtract(const Duration(minutes: 5)), ahora: ahora), 'hace 5 min');
      expect(horaRelativa(ahora.subtract(const Duration(minutes: 59)), ahora: ahora), 'hace 59 min');
    });
    test('menos de 24 h → hace N h', () {
      expect(horaRelativa(ahora.subtract(const Duration(hours: 1)), ahora: ahora), 'hace 1 h');
      expect(horaRelativa(ahora.subtract(const Duration(hours: 23)), ahora: ahora), 'hace 23 h');
    });
    test('24 h o más → hace N d', () {
      expect(horaRelativa(ahora.subtract(const Duration(days: 2)), ahora: ahora), 'hace 2 d');
    });
  });

  group('Reporte', () {
    final base = Reporte(
      id: 'x',
      tipo: TipoHecho.protesta,
      titulo: 't',
      descripcion: 'd',
      lugar: 'l',
      lat: 0,
      lng: 0,
      creadoEn: ahora,
      distanciaKm: 3.5,
    );

    test('porcentajeVerificacion con total 0 es 0', () {
      expect(base.porcentajeVerificacion, 0);
    });
    test('porcentajeVerificacion 3 de 4 es 0.75', () {
      expect(base.copyWith(confirmaciones: 3, desmentidos: 1).porcentajeVerificacion, 0.75);
    });
    test('distanciaTexto usa coma decimal', () {
      expect(base.distanciaTexto, '3,5 km');
    });
    test('copyWith y == comparan por valor', () {
      expect(base.copyWith(), base);
      expect(base.copyWith(confirmaciones: 1) == base, isFalse);
    });
  });

  group('Usuario.iniciales', () {
    test('dos palabras', () {
      expect(const Usuario(nombre: 'Juan Pérez', correo: '', tieneCuenta: true).iniciales, 'JP');
    });
    test('una palabra', () {
      expect(const Usuario(nombre: 'ana', correo: '', tieneCuenta: true).iniciales, 'A');
    });
    test('tres palabras toma las dos primeras', () {
      expect(const Usuario(nombre: 'María José López', correo: '', tieneCuenta: true).iniciales, 'MJ');
    });
  });
}
