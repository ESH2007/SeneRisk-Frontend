import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String textoAccion,
  bool destructivo = true,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusDialog)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.radiusDialog),
          boxShadow: AppDimens.floatingShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: AppTextStyles.inter(size: 17, weight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              mensaje,
              style: AppTextStyles.body.copyWith(fontSize: 13.5, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.secondary,
                    small: true,
                    height: 40,
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: textoAccion,
                    variant: destructivo ? AppButtonVariant.danger : AppButtonVariant.primary,
                    small: true,
                    height: 40,
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return resultado ?? false;
}
