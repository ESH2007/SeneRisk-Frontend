import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/models/reporte.dart';
import 'package:senerisk_app/models/tipo_hecho.dart';
import 'package:senerisk_app/theme/app_colors.dart';
import 'package:senerisk_app/widgets/alert_card.dart';
import 'package:senerisk_app/widgets/app_button.dart';
import 'package:senerisk_app/widgets/app_filter_chip.dart';
import 'package:senerisk_app/widgets/app_text_field.dart';
import 'package:senerisk_app/widgets/app_top_bar.dart';
import 'package:senerisk_app/widgets/emergency_card.dart';
import 'package:senerisk_app/widgets/heat_legend.dart';
import 'package:senerisk_app/widgets/meta_item.dart';
import 'package:senerisk_app/widgets/section_label.dart';
import 'package:senerisk_app/widgets/setting_row.dart';
import 'package:senerisk_app/widgets/stat_tile.dart';
import 'package:senerisk_app/widgets/status_pill.dart';
import 'package:senerisk_app/widgets/type_tile.dart';
import 'package:senerisk_app/widgets/user_avatar.dart';
import 'package:senerisk_app/widgets/verification_bar.dart';

import 'pump.dart';

Material _materialOf(WidgetTester t, Finder f) =>
    t.widget<Material>(find.descendant(of: f, matching: find.byType(Material)).first);

void main() {
  group('AppButton', () {
    testWidgets('muestra texto e icono y responde al toque', (t) async {
      var tocado = false;
      await pumpApp(t, AppButton(label: 'Ingresar', icon: Icons.check, onPressed: () => tocado = true));
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      await t.tap(find.text('Ingresar'));
      expect(tocado, isTrue);
    });
    testWidgets('deshabilitado baja la opacidad y no responde', (t) async {
      await pumpApp(t, const AppButton(label: 'X', onPressed: null));
      expect(t.widget<Opacity>(find.byType(Opacity)).opacity, 0.45);
    });
    testWidgets('variantes usan sus colores', (t) async {
      await pumpApp(t, const AppButton(label: 'Peligro', variant: AppButtonVariant.danger, onPressed: _noop));
      expect(_materialOf(t, find.byType(AppButton)).color, AppColors.red);
    });
  });

  group('AppTextField', () {
    testWidgets('muestra etiqueta, hint e icono', (t) async {
      await pumpApp(t, const AppTextField(label: 'Correo', hint: 'a@b.c', prefixIcon: Icons.mail_outline));
      expect(find.text('Correo'), findsOneWidget);
      expect(find.text('a@b.c'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
    });
    testWidgets('errorText muestra la fila de error', (t) async {
      await pumpApp(t, const AppTextField(label: 'X', errorText: 'Escribe tu correo'));
      expect(find.text('Escribe tu correo'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
    testWidgets('el toggle alterna la visibilidad', (t) async {
      await pumpApp(t, const AppTextField(label: 'Pass', obscure: true, showObscureToggle: true));
      expect(t.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
      await t.tap(find.byIcon(Icons.visibility_outlined));
      await t.pump();
      expect(t.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    });
  });

  testWidgets('AppTopBar muestra título e icono', (t) async {
    await pumpApp(t, const Scaffold(appBar: AppTopBar(title: 'Mi perfil', leadingIcon: Icons.close)));
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('SectionLabel en error es rojo', (t) async {
    await pumpApp(t, const SectionLabel('Tipo de hecho', error: true));
    expect(t.widget<Text>(find.text('Tipo de hecho')).style!.color, AppColors.red);
  });

  group('AppFilterChip', () {
    testWidgets('seleccionado tiene fondo primary', (t) async {
      await pumpApp(t, const AppFilterChip(label: 'Todos', icon: Icons.construction, selected: true, onTap: _noop));
      expect(find.text('Todos'), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
      expect(_materialOf(t, find.byType(AppFilterChip)).color, AppColors.primary);
    });
    testWidgets('no seleccionado tiene fondo paper', (t) async {
      await pumpApp(t, const AppFilterChip(label: 'Todos', selected: false, onTap: _noop));
      expect(_materialOf(t, find.byType(AppFilterChip)).color, AppColors.paper);
    });
  });

  group('TypeTile', () {
    testWidgets('muestra etiqueta e icono del tipo', (t) async {
      await pumpApp(t, const TypeTile(tipo: TipoHecho.bloqueo, selected: false, onTap: _noop));
      expect(find.text('Bloqueo'), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
    });
    testWidgets('seleccionado usa fondo primary', (t) async {
      await pumpApp(t, const TypeTile(tipo: TipoHecho.protesta, selected: true, onTap: _noop));
      expect(_materialOf(t, find.byType(TypeTile)).color, AppColors.primary);
    });
    testWidgets('hasError usa borde rojo', (t) async {
      await pumpApp(t, const TypeTile(tipo: TipoHecho.incendio, selected: false, hasError: true, onTap: _noop));
      final shape = _materialOf(t, find.byType(TypeTile)).shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.red.withValues(alpha: 0.55));
    });
  });

  testWidgets('StatusPill muestra el texto en verde', (t) async {
    await pumpApp(t, const StatusPill.elevated('Actualizado hace 2 min'));
    expect(t.widget<Text>(find.text('Actualizado hace 2 min')).style!.color, AppColors.green);
  });

  testWidgets('HeatLegend muestra Bajo y Alto', (t) async {
    await pumpApp(t, const HeatLegend());
    expect(find.text('Bajo'), findsOneWidget);
    expect(find.text('Alto'), findsOneWidget);
  });

  testWidgets('StatTile muestra valor y etiqueta', (t) async {
    await pumpApp(t, const Row(children: [StatTile(value: '92 %', label: 'fiabilidad')]));
    expect(find.text('92 %'), findsOneWidget);
    expect(find.text('fiabilidad'), findsOneWidget);
  });

  testWidgets('MetaItem muestra icono y texto', (t) async {
    await pumpApp(t, const MetaItem(icon: Icons.schedule, text: 'hace 5 min'));
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.text('hace 5 min'), findsOneWidget);
  });

  group('VerificationBar', () {
    testWidgets('3 de 4 → 75 %', (t) async {
      await pumpApp(t, const VerificationBar(confirmaciones: 3, desmentidos: 1));
      expect(find.text('3 de 4 vecinos lo confirmaron'), findsOneWidget);
      expect(find.text('75 %'), findsOneWidget);
      expect(find.text('Confirma solo si estás cerca y lo viste.'), findsOneWidget);
    });
    testWidgets('sin votos → nadie lo ha verificado en ámbar', (t) async {
      await pumpApp(t, const VerificationBar(confirmaciones: 0, desmentidos: 0));
      final txt = find.text('Nadie lo ha verificado todavía');
      expect(t.widget<Text>(txt).style!.color, AppColors.amber);
      expect(find.text('0 %'), findsOneWidget);
    });
  });

  group('AlertCard', () {
    final base = Reporte(
      id: 'r',
      tipo: TipoHecho.bloqueo,
      titulo: 'Bloqueo de vía',
      descripcion: 'd',
      lugar: 'Calle 80 con Cra 30',
      lat: 0,
      lng: 0,
      creadoEn: DateTime.now().subtract(const Duration(minutes: 32)),
      distanciaKm: 3.5,
      confirmaciones: 4,
    );
    testWidgets('con confirmaciones muestra N vecinos confirmaron', (t) async {
      await pumpApp(t, AlertCard(reporte: base, onTap: _noop));
      expect(find.text('Bloqueo de vía'), findsOneWidget);
      expect(find.text('Calle 80 con Cra 30, hace 32 min, a 3,5 km'), findsOneWidget);
      expect(find.text('4 vecinos confirmaron'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
    testWidgets('con 1 confirmación usa singular', (t) async {
      await pumpApp(t, AlertCard(reporte: base.copyWith(confirmaciones: 1), onTap: _noop));
      expect(find.text('1 vecino confirmó'), findsOneWidget);
    });
    testWidgets('sin confirmaciones muestra Sin confirmar aún en ámbar', (t) async {
      await pumpApp(t, AlertCard(reporte: base.copyWith(confirmaciones: 0), onTap: _noop));
      expect(t.widget<Text>(find.text('Sin confirmar aún')).style!.color, AppColors.amber);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });
  });

  testWidgets('SettingRow muestra título, subtítulo y trailing', (t) async {
    await pumpApp(
      t,
      SettingGroup(children: [
        SettingRow(icon: Icons.download_outlined, title: 'Mapas', subtitle: 'sub', trailing: Switch(value: true, onChanged: (_) {})),
      ]),
    );
    expect(find.text('Mapas'), findsOneWidget);
    expect(find.text('sub'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
  });

  testWidgets('EmergencyCard muestra textos e icono', (t) async {
    await pumpApp(t, const EmergencyCard());
    expect(find.text('Emergencias: llamar al 123'), findsOneWidget);
    expect(find.text('Policía, ambulancia y bomberos'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsOneWidget);
  });

  group('UserAvatar', () {
    testWidgets('muestra iniciales y la insignia si es editable', (t) async {
      await pumpApp(t, const UserAvatar(iniciales: 'JP', editable: true));
      expect(find.text('JP'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });
    testWidgets('sin iniciales muestra persona', (t) async {
      await pumpApp(t, const UserAvatar(iniciales: ''));
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });
  });
}

void _noop() {}
