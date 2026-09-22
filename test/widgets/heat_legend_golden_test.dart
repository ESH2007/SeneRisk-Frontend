import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senerisk_app/widgets/heat_legend.dart';

void main() {
  testWidgets('leyenda del mapa de calor (golden)', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(backgroundColor: Color(0xFFEFE9D8), body: Center(child: HeatLegend())),
    ));
    await expectLater(find.byType(HeatLegend), matchesGoldenFile('goldens/heat_legend.png'));
  });
}
