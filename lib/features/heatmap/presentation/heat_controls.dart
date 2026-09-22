import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/heat_legend.dart';
import '../domain/heatmap_controller.dart';

/// Leyenda + rango de fechas + mostrar/ocultar, compacto para una esquina del mapa.
class HeatControls extends ConsumerWidget {
  const HeatControls({super.key});

  static const _rangos = [(7, '7 d'), (30, '30 d'), (180, '6 m')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(heatmapProvider);
    final c = ref.read(heatmapProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lineSoft, width: AppDimens.borderWidth),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (d, label) in _rangos)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => c.setRangeDays(d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: f.rangeDays == d ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: AppTextStyles.inter(
                        size: 10,
                        weight: FontWeight.w600,
                        color: f.rangeDays == d ? AppColors.cream : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              IconButton(
                tooltip: f.visible ? 'Ocultar mapa de calor' : 'Mostrar mapa de calor',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: Icon(f.visible ? Icons.visibility : Icons.visibility_off, size: 16, color: AppColors.primary),
                onPressed: c.toggleVisible,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const HeatLegend(),
      ],
    );
  }
}
