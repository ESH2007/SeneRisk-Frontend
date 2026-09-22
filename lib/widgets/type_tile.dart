import 'package:flutter/material.dart';

import '../models/tipo_hecho.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class TypeTile extends StatelessWidget {
  const TypeTile({
    super.key,
    required this.tipo,
    required this.selected,
    required this.onTap,
    this.hasError = false,
  });

  final TipoHecho tipo;
  final bool selected;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.cream : AppColors.ink;
    final borderColor = selected
        ? AppColors.primary
        : hasError
            ? AppColors.red.withValues(alpha: 0.55)
            : AppColors.line;
    final radius = BorderRadius.circular(AppDimens.radiusTile);
    return Semantics(
      button: true,
      selected: selected,
      label: tipo.etiqueta,
      child: Material(
        color: selected ? AppColors.primary : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: borderColor, width: AppDimens.borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tipo.icono, size: 18, color: selected ? AppColors.cream : AppColors.primary),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    tipo.etiqueta,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppTextStyles.inter(
                      size: 10.5,
                      weight: FontWeight.w600,
                      color: fg,
                      height: 1.05,
                    ),
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
