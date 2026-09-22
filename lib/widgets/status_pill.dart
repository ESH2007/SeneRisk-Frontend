import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key}) : elevated = false;

  const StatusPill.elevated(this.text, {super.key}) : elevated = true;

  final String text;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.inter(size: 10, weight: FontWeight.w600, color: AppColors.green),
        ),
      ],
    );
    if (!elevated) return row;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: row,
    );
  }
}
