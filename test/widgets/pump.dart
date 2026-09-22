import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:senerisk_app/theme/app_theme.dart';

/// Monta [child] dentro de la app real (tema + ProviderScope) sin ir a la red por fuentes.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  ProviderContainer? container,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final app = MaterialApp(theme: appTheme, home: Scaffold(body: child));
  await tester.pumpWidget(
    container == null
        ? ProviderScope(child: app)
        : UncontrolledProviderScope(container: container, child: app),
  );
}
