import 'package:latlong2/latlong.dart';

import '../models/reporte.dart';
import '../models/tipo_hecho.dart';

const ubicacionSimulada = LatLng(4.6760, -74.0480);

const usuarioMockNombre = 'Juan Pérez';
const usuarioMockCorreo = 'juan.perez@email.com';

const estadisticasMock = (reportes: '12', confirmaciones: '34', fiabilidad: '92 %');

const busquedasRecientesIniciales = [
  'Calle 100, Bogotá',
  'Parque de la 93',
  'Aeropuerto El Dorado',
];

const lugaresBusqueda = [
  'Calle 100 con Cra 15 — Bogotá',
  'Calle 13 con Cra 50 — Bogotá',
  'Parque de la 93 — Bogotá',
  'Aeropuerto El Dorado — Bogotá',
  'Calle 26 con Cra 7 — Bogotá',
  'Autopista Norte con Calle 80 — Bogotá',
  'Portal Norte — Bogotá',
  'Universidad de los Andes — Bogotá',
];

List<Reporte> reportesMock() {
  final ahora = DateTime.now();
  return [
    Reporte(
      id: 'r1',
      tipo: TipoHecho.agresion,
      titulo: 'Agresión reportada',
      descripcion:
          'Riña entre varias personas frente al centro comercial. Se recomienda evitar la zona.',
      lugar: 'Cra 15 con Calle 100',
      lat: 4.6836,
      lng: -74.0480,
      creadoEn: ahora.subtract(const Duration(minutes: 5)),
      distanciaKm: 1.2,
      anonimo: true,
    ),
    Reporte(
      id: 'r2',
      tipo: TipoHecho.bloqueo,
      titulo: 'Bloqueo de vía',
      descripcion:
          'Cierre total en sentido norte-sur por manifestación de conductores. Tráfico detenido.',
      lugar: 'Autopista Norte con Calle 80',
      lat: 4.6700,
      lng: -74.0560,
      creadoEn: ahora.subtract(const Duration(minutes: 32)),
      distanciaKm: 3.5,
      confirmaciones: 4,
      anonimo: false,
    ),
    Reporte(
      id: 'r3',
      tipo: TipoHecho.protesta,
      titulo: 'Protesta en Calle 26',
      descripcion:
          'Manifestación pacífica en la intersección principal. Aproximadamente 50 personas. Tráfico parcialmente detenido.',
      lugar: 'Calle 26 con Cra 7',
      lat: 4.6141,
      lng: -74.0700,
      creadoEn: ahora.subtract(const Duration(minutes: 46)),
      distanciaKm: 3.5,
      confirmaciones: 3,
      desmentidos: 1,
      anonimo: true,
      fotoAsset: 'assets/mock/protesta.jpg',
    ),
    Reporte(
      id: 'r4',
      tipo: TipoHecho.bloqueo,
      titulo: 'Bloqueo de vía',
      descripcion: 'Carril cerrado por accidente. Paso lento.',
      lugar: 'Calle 13 con Cra 50',
      lat: 4.6170,
      lng: -74.1030,
      creadoEn: ahora.subtract(const Duration(hours: 1)),
      distanciaKm: 1.2,
      confirmaciones: 2,
      anonimo: true,
    ),
    Reporte(
      id: 'r5',
      tipo: TipoHecho.incendio,
      titulo: 'Incendio en local comercial',
      descripcion: 'Incendio controlado por bomberos. Humo en la zona, calle cerrada.',
      lugar: 'Calle 72 con Cra 11',
      lat: 4.6580,
      lng: -74.0590,
      creadoEn: ahora.subtract(const Duration(hours: 2)),
      distanciaKm: 4.8,
      confirmaciones: 5,
      anonimo: false,
    ),
    Reporte(
      id: 'r6',
      tipo: TipoHecho.vandalismo,
      titulo: 'Vandalismo en estación',
      descripcion: 'Vidrios rotos en la estación de TransMilenio. Servicio normal.',
      lugar: 'Av. Caracas con Calle 45',
      lat: 4.6320,
      lng: -74.0700,
      creadoEn: ahora.subtract(const Duration(hours: 3)),
      distanciaKm: 2.1,
      confirmaciones: 1,
      desmentidos: 2,
      anonimo: true,
    ),
  ];
}
