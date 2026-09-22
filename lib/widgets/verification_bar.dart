import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class VerificationBar extends StatelessWidget {
  const VerificationBar({
    super.key,
    required this.confirmaciones,
    required this.desmentidos,
  });

  final int confirmaciones;
  final int desmentidos;

  @override
  Widget build(BuildContext context) {
    final total = confirmaciones + desmentidos;
    final fraccion = total == 0 ? 0.0 : confirmaciones / total;
    final porcentaje = (fraccion * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                total == 0
                    ? 'Nadie lo ha verificado todavía'
                    : '$confirmaciones de $total vecinos lo confirmaron',
                style: AppTextStyles.inter(
                  size: 12,
                  weight: FontWeight.w700,
                  color: total == 0 ? AppColors.amber : AppColors.green,
                ),
              ),
            ),
            Text('$porcentaje %', style: AppTextStyles.label.copyWith(fontSize: 10)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraccion,
            minHeight: 7,
            backgroundColor: AppColors.greenSoft,
            color: AppColors.green,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Confirma solo si estás cerca y lo viste.',
          style: AppTextStyles.caption.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
