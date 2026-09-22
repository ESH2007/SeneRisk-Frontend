import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/state/usuario_provider.dart';
import 'package:senerisk_app/theme/app_colors.dart';
import 'package:senerisk_app/widgets/app_drawer.dart';

import 'pump.dart';

void main() {
  const items = [
    'Mapa de calor',
    'Alertas recientes',
    'Crear reporte',
    'Verificar reportes',
    'Configuración',
    'Ayuda',
  ];

  testWidgets('invitado: cabecera Invitado/Crear cuenta y Salir en vez de Cerrar sesión', (t) async {
    await pumpApp(t, const AppDrawer(paginaActual: 'mapa'));
    expect(find.text('Invitado'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    for (final i in items) {
      expect(find.text(i), findsOneWidget);
    }
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(find.text('Salir'), findsOneWidget);
  });

  testWidgets('con cuenta: iniciales, nombre, Ver mi perfil y Cerrar sesión', (t) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(usuarioProvider.notifier).crearCuenta('Juan Pérez', 'juan.perez@email.com', 'x');
    await pumpApp(t, const AppDrawer(paginaActual: 'alertas'), container: c);
    expect(find.text('JP'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('Ver mi perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('el ítem activo se resalta con blueSoft', (t) async {
    await pumpApp(t, const AppDrawer(paginaActual: 'alertas'));
    final activo = find.ancestor(of: find.text('Alertas recientes'), matching: find.byType(Material)).first;
    expect(t.widget<Material>(activo).color, AppColors.blueSoft);
    final inactivo = find.ancestor(of: find.text('Mapa de calor'), matching: find.byType(Material)).first;
    expect(t.widget<Material>(inactivo).color, Colors.transparent);
  });
}
