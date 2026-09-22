import 'package:flutter/material.dart';

import '../../../models/reporte.dart' show horaRelativa;
import '../../../models/tipo_hecho.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../domain/heat_grid.dart';

/// Mínimo de reportes en la celda para mostrar el resumen: con menos, el "agregado"
/// sería en la práctica un reporte individual.
const heatCellMinReports = 3;

/// Resumen agregado de una zona caliente; nunca muestra reportes individuales.
Future<void> showHeatCellSheet(BuildContext context, HeatCell cell) {
  if (cell.count < heatCellMinReports) return Future.value();
  String etiqueta(String c) =>
      TipoHecho.values.where((t) => t.name == c).map((t) => t.etiqueta).firstOrNull ?? c;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Zona con ${cell.count} reportes', style: AppTextStyles.titleSmall),
          const SizedBox(height: 4),
          if (cell.latest != null)
            Text('Último: ${horaRelativa(cell.latest!)}', style: AppTextStyles.caption),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final e in cell.topCategories.take(3))
                Chip(
                  label: Text('${etiqueta(e.key)} · ${e.value}', style: AppTextStyles.label.copyWith(fontSize: 11)),
                  backgroundColor: AppColors.blueSoft,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
