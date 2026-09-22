import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:senerisk_app/main.dart';
import 'package:senerisk_app/state/configuracion_provider.dart';
import 'package:senerisk_app/state/filtro_mapa_provider.dart';
import 'package:senerisk_app/state/reportes_provider.dart';
import 'package:senerisk_app/widgets/alert_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recorrido de aceptación manual de SPEC.md §8.7, automatizado a 390×844.
void main() {
  Future<void> toca(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> abrirMenu(WidgetTester t) => toca(t, find.byTooltip('Menú'));

  // Los marcadores viven en una capa nativa de MapLibre (no son widgets): se cuentan los
  // reportes que la pantalla manda al mapa, con el mismo filtro que ella aplica.
  int marcadores(WidgetTester t) {
    final c = ProviderScope.containerOf(t.element(find.byType(RiesgoMapaApp)));
    return filtrarMapa(c.read(reportesProvider), c.read(filtroMapaProvider)).length;
  }

  testWidgets('recorrido completo sin tocar código', (t) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(const ProviderScope(child: RiesgoMapaApp()));
    await t.pumpAndSettle();
    expect(find.text('SENERISK ATLAS'), findsOneWidget);

    // Welcome → Continuar sin cuenta → mapa con 6 marcadores
    await toca(t, find.text('Continuar sin cuenta'));
    expect(marcadores(t), 6);

    // Filtro "Bloqueos" deja 2
    await toca(t, find.text('Bloqueos'));
    expect(marcadores(t), 2);
    await toca(t, find.text('Todos'));
    expect(marcadores(t), 6);

    // Reportar hecho → publicar sin tipo muestra el error en línea
    await toca(t, find.text('Reportar hecho'));
    expect(find.text('Crear reporte'), findsOneWidget);
    await toca(t, find.text('Publicar reporte'));
    expect(find.text('Selecciona el tipo de hecho para continuar'), findsOneWidget);

    // Elegir tipo, ubicación y descripción, publicar → 7 marcadores
    await toca(t, find.text('Protesta'));
    expect(find.text('Selecciona el tipo de hecho para continuar'), findsNothing);
    await t.enterText(find.byType(TextField).at(0), 'Calle 80 con Cra 30');
    await t.enterText(find.byType(TextField).at(1), 'Manifestación en la intersección, unas 50 personas.');
    await toca(t, find.text('Publicar reporte'));
    expect(find.text('Reporte publicado'), findsOneWidget);
    expect(marcadores(t), 7);

    // Menú → Alertas recientes → el nuevo reporte de primero, sin confirmar
    await abrirMenu(t);
    await toca(t, find.text('Alertas recientes'));
    expect(find.text('Alertas recientes'), findsOneWidget);
    final primeraTarjeta = find.byType(AlertCard).first;
    final primera = find.descendant(of: primeraTarjeta, matching: find.text('Protesta en Calle 80 con Cra 30'));
    expect(primera, findsOneWidget);
    expect(find.descendant(of: primeraTarjeta, matching: find.text('Sin confirmar aún')), findsOneWidget);

    // Abrir → Confirmar → "1 vecino confirmó"
    await toca(t, primera);
    expect(find.text('Nadie lo ha verificado todavía'), findsOneWidget);
    await toca(t, find.text('Confirmar este hecho'));
    expect(find.text('Ya confirmaste'), findsOneWidget);
    expect(find.text('1 de 1 vecinos lo confirmaron'), findsOneWidget);
    await toca(t, find.byTooltip('Atrás'));
    expect(find.descendant(of: find.byType(AlertCard).first, matching: find.text('1 vecino confirmó')), findsOneWidget);

    // Menú → Configuración → radio 2 km → Alertas deja solo los cercanos
    await abrirMenu(t);
    await toca(t, find.text('Configuración'));
    expect(find.text('5 km'), findsOneWidget);
    final container = ProviderScope.containerOf(t.element(find.byType(RiesgoMapaApp)));
    container.read(configuracionProvider.notifier).setRadioKm(2);
    await t.pumpAndSettle();
    expect(find.text('2 km'), findsOneWidget);
    await toca(t, find.text('Guardar cambios'));
    expect(find.text('Configuración guardada'), findsOneWidget);
    expect(find.text('Agresión reportada'), findsOneWidget); // r1, 1,2 km
    expect(find.text('Protesta en Calle 80 con Cra 30'), findsOneWidget); // nuevo, 0,3 km
    expect(find.text('Incendio en local comercial'), findsNothing); // r5, 4,8 km

    // Invitado: sin "Cerrar sesión"; perfil muestra Invitado
    await abrirMenu(t);
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(find.text('Invitado'), findsOneWidget);
    await toca(t, find.text('Crear cuenta'));
    expect(find.text('Crea tu cuenta'), findsOneWidget);

    // Crear cuenta → Home → menú con "Juan Pérez"
    await t.enterText(find.byType(TextField).at(0), 'Juan Pérez');
    await t.enterText(find.byType(TextField).at(1), 'juan.perez@email.com');
    await t.enterText(find.byType(TextField).at(2), 'Clave1234');
    await t.enterText(find.byType(TextField).at(3), 'Clave1234');
    await t.pump();
    expect(find.text('Fuerte'), findsOneWidget);
    await toca(t, find.text('Crear cuenta'));
    expect(find.text('Debes aceptar los términos para continuar'), findsOneWidget);
    await toca(t, find.byType(Checkbox));
    await toca(t, find.text('Crear cuenta'));
    expect(marcadores(t), 7);
    await abrirMenu(t);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('JP'), findsOneWidget);

    // Cerrar sesión → diálogo → Welcome
    await toca(t, find.text('Cerrar sesión'));
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    await toca(t, find.text('Cerrar sesión'));
    expect(find.text('SENERISK ATLAS'), findsOneWidget);
  });
}
