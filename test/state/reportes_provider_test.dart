import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/models/reporte.dart';
import 'package:senerisk_app/models/tipo_hecho.dart';
import 'package:senerisk_app/state/reportes_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  List<String> ids() => container.read(reportesProvider).map((r) => r.id).toList();

  test('inicia con los 6 reportes de prueba ordenados por fecha desc', () {
    expect(ids(), ['r1', 'r2', 'r3', 'r4', 'r5', 'r6']);
  });

  test('agregar deja el nuevo reporte de primero', () {
    final nuevo = Reporte(
      id: 'nuevo',
      tipo: TipoHecho.bloqueo,
      titulo: 'Bloqueo en X',
      descripcion: 'd',
      lugar: 'X',
      lat: 4.67,
      lng: -74.05,
      creadoEn: DateTime.now(),
      distanciaKm: 0.3,
    );
    container.read(reportesProvider.notifier).agregar(nuevo);
    expect(ids().first, 'nuevo');
    expect(ids().length, 7);
  });

  test('confirmar y desmentir incrementan contadores', () {
    final n = container.read(reportesProvider.notifier);
    n.confirmar('r1');
    n.desmentir('r1');
    n.desmentir('r1');
    final r1 = n.porId('r1')!;
    expect(r1.confirmaciones, 1);
    expect(r1.desmentidos, 2);
  });

  test('porId devuelve null si no existe', () {
    expect(container.read(reportesProvider.notifier).porId('zzz'), isNull);
  });

  group('filtrarAlertas', () {
    List<Reporte> todos() => container.read(reportesProvider);

    test('cerca con radio 5 km incluye r1..r6', () {
      final ids = filtrarAlertas(todos(), 'cerca', radioKm: 5).map((r) => r.id);
      expect(ids, ['r1', 'r2', 'r3', 'r4', 'r5', 'r6']);
    });
    test('cerca con radio 2 km deja r1 y r4', () {
      final ids = filtrarAlertas(todos(), 'cerca', radioKm: 2).map((r) => r.id);
      expect(ids, ['r1', 'r4']);
    });
    test('bloqueo deja los dos bloqueos', () {
      final ids = filtrarAlertas(todos(), 'bloqueo', radioKm: 5).map((r) => r.id);
      expect(ids, ['r2', 'r4']);
    });
    test('mas devuelve todos', () {
      expect(filtrarAlertas(todos(), 'mas', radioKm: 1).length, 6);
    });
  });

  test('reportesPorVerificar: confirmaciones < 3 por distancia asc', () {
    final ids = reportesPorVerificar(container.read(reportesProvider)).map((r) => r.id);
    expect(ids, ['r1', 'r4', 'r6']);
  });

  test('filtrarMapa por tipo', () {
    final todos = container.read(reportesProvider);
    expect(filtrarMapa(todos, 'todos').length, 6);
    expect(filtrarMapa(todos, 'bloqueo').length, 2);
    expect(filtrarMapa(todos, 'agresion').map((r) => r.id), ['r1']);
  });
}
