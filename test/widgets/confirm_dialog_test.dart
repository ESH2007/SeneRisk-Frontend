import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/widgets/confirm_dialog.dart';

import 'pump.dart';

void main() {
  Future<Future<bool>> abrir(WidgetTester t, {bool destructivo = true}) async {
    late Future<bool> resultado;
    await pumpApp(
      t,
      Builder(
        builder: (ctx) => TextButton(
          onPressed: () => resultado = showConfirmDialog(
            ctx,
            titulo: '¿Cerrar sesión?',
            mensaje: 'Dejarás de recibir alertas.',
            textoAccion: 'Cerrar sesión',
            destructivo: destructivo,
          ),
          child: const Text('abrir'),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    return resultado;
  }

  testWidgets('muestra título, mensaje y ambos botones', (t) async {
    await abrir(t);
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    expect(find.text('Dejarás de recibir alertas.'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('confirmar devuelve true', (t) async {
    final r = await abrir(t);
    await t.tap(find.text('Cerrar sesión'));
    await t.pumpAndSettle();
    expect(await r, isTrue);
  });

  testWidgets('cancelar devuelve false', (t) async {
    final r = await abrir(t);
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(await r, isFalse);
  });

  testWidgets('tocar fuera devuelve false', (t) async {
    final r = await abrir(t);
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();
    expect(await r, isFalse);
  });
}
