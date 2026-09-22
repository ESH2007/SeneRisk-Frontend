// Genera una captura PNG de cada pantalla a 390×844 (dpr 2) para compararla con mockups/.
// Se ejecuta a demanda:  flutter test test/capturas_test.dart --dart-define=CAPTURAS_DIR=/ruta
@Tags(['capturas'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:senerisk_app/app_router.dart';
import 'package:senerisk_app/main.dart';
import 'package:senerisk_app/state/usuario_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dir = String.fromEnvironment('CAPTURAS_DIR');

Future<void> _cargarFuentes() async {
  const fuentes = {
    'Inter_regular': 'Inter-Regular.ttf',
    'Inter_500': 'Inter-Medium.ttf',
    'Inter_600': 'Inter-SemiBold.ttf',
    'Inter_700': 'Inter-Bold.ttf',
    'Inter_800': 'Inter-ExtraBold.ttf',
    'Oswald_600': 'Oswald-SemiBold.ttf',
  };
  for (final e in fuentes.entries) {
    final loader = FontLoader(e.key)..addFont(rootBundle.load('assets/google_fonts/${e.value}'));
    await loader.load();
  }
  // Material Icons no se carga en `flutter test`; se toma del SDK para que los iconos se vean.
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (root != null && icons.existsSync()) {
    final bytes = await icons.readAsBytes();
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

void main() {
  if (_dir.isEmpty) return;
  autoUpdateGoldenFiles = true;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _cargarFuentes();
  });

  testWidgets('capturas de todas las pantallas', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(780, 1688);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    Future<void> asentar() => t.runAsync(() async {
          await t.pumpAndSettle();
          await Future<void>.delayed(const Duration(milliseconds: 400));
          await t.pumpAndSettle();
        });

    Future<void> capturar(String nombre) async {
      await asentar();
      await t.pumpAndSettle();
      await expectLater(
        find.byType(RiesgoMapaApp),
        matchesGoldenFile(Uri.file('$_dir/$nombre.png')),
      );
    }

    Future<void> ir(String ruta) async {
      appRouter.go(ruta);
      await asentar();
    }

    Future<void> toca(Finder f) async {
      await t.ensureVisible(f);
      await t.tap(f);
      await asentar();
    }

    await t.pumpWidget(const ProviderScope(child: RiesgoMapaApp()));
    await t.runAsync(() async {
      final ctx = t.element(find.byType(RiesgoMapaApp));
      await precacheImage(const AssetImage('assets/logo/senerisk_logo.png'), ctx);
      await precacheImage(const AssetImage('assets/mock/protesta.jpg'), ctx);
    });
    await capturar('01-welcome');

    await ir('/login');
    await t.enterText(find.byType(TextField).at(0), 'jcorreo@gmail.com');
    await t.enterText(find.byType(TextField).at(1), 'clave1234');
    FocusManager.instance.primaryFocus?.unfocus();
    await capturar('02-login');

    await ir('/register');
    await t.enterText(find.byType(TextField).at(0), 'Juan Pérez');
    await t.enterText(find.byType(TextField).at(2), 'Clave123');
    await t.enterText(find.byType(TextField).at(3), 'Clave123');
    FocusManager.instance.primaryFocus?.unfocus();
    await capturar('03-register');

    await ir('/terms');
    await capturar('15-terms');

    await ir('/home');
    await capturar('04-home-map');

    await toca(find.text('Buscar ubicación o reporte'));
    await t.enterText(find.byType(TextField), 'Calle 1');
    await asentar();
    await capturar('05-search');
    await toca(find.byTooltip('Atrás'));

    await toca(find.text('Reportar hecho'));
    await toca(find.text('Bloqueo'));
    await t.enterText(find.byType(TextField).at(0), 'Calle 80 con Cra 30');
    FocusManager.instance.primaryFocus?.unfocus();
    await capturar('06-create-report');

    await toca(find.byTooltip('Cerrar'));
    await toca(find.text('Reportar hecho'));
    await t.enterText(find.byType(TextField).at(0), 'Calle 80 con Cra 30');
    await t.enterText(find.byType(TextField).at(1), 'Manifestación en la intersección, unas 50 personas.');
    FocusManager.instance.primaryFocus?.unfocus();
    await toca(find.text('Publicar reporte'));
    await capturar('07-create-report-validation');
    await toca(find.byTooltip('Cerrar'));

    await ir('/report/r3');
    await capturar('08-report-detail');

    final container = ProviderScope.containerOf(t.element(find.byType(RiesgoMapaApp)));
    container.read(usuarioProvider.notifier).crearCuenta('Juan Pérez', 'juan.perez@email.com', 'x');

    await ir('/profile');
    await capturar('09-profile');

    await ir('/settings');
    await capturar('10-settings');

    await ir('/help');
    await capturar('11-help-center');

    await ir('/alerts');
    await capturar('12-alerts');

    await ir('/home');
    await toca(find.byTooltip('Menú'));
    await capturar('13-drawer');

    await toca(find.text('Cerrar sesión'));
    await capturar('14-confirm-dialog');
    await toca(find.text('Cancelar'));

    expect(Directory(_dir).listSync().where((f) => f.path.endsWith('.png')).length, greaterThanOrEqualTo(15));
  });
}
