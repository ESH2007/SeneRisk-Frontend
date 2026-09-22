import 'package:flutter/material.dart';

import '../models/reporte.dart';
import '../models/tipo_hecho.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.reporte, required this.onTap});

  final Reporte reporte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sinConfirmar = reporte.confirmaciones == 0;
    final estadoColor = sinConfirmar ? AppColors.amber : AppColors.green;
    final estadoTexto = sinConfirmar
        ? 'Sin confirmar aún'
        : reporte.confirmaciones == 1
            ? '1 vecino confirmó'
            : '${reporte.confirmaciones} vecinos confirmaron';
    final radius = BorderRadius.circular(AppDimens.radiusCard);
    return Semantics(
      button: true,
      label: reporte.titulo,
      child: Material(
        color: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppColors.lineSoft, width: AppDimens.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: reporte.tipo.colorSuave,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(reporte.tipo.icono, size: 18, color: reporte.tipo.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reporte.titulo,
                        style: AppTextStyles.inter(
                          size: 14.5,
                          weight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${reporte.lugar}, ${reporte.horaTexto}, a ${reporte.distanciaTexto}',
                        style: AppTextStyles.label.copyWith(fontSize: 11.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            sinConfirmar ? Icons.schedule : Icons.check,
                            size: 11,
                            color: estadoColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            estadoTexto,
                            style: AppTextStyles.inter(
                              size: 11,
                              weight: FontWeight.w600,
                              color: estadoColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
