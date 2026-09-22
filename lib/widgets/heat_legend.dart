import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class HeatLegend extends StatelessWidget {
  const HeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.inter(size: 10, weight: FontWeight.w500, color: AppColors.ink);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 9),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lineSoft, width: AppDimens.borderWidth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Bajo', style: style),
          const SizedBox(width: 6),
          Container(
            width: 44,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [AppColors.heatLow, AppColors.heatMid, AppColors.heatHigh],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('Alto', style: style),
        ],
      ),
    );
  }
}
