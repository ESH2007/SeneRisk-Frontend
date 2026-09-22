import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, danger, dangerOutline, onBlue, ghostOnBlue }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.small = false,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final bool small;
  final double? height;

  Color get _background => switch (variant) {
        AppButtonVariant.primary => AppColors.primary,
        AppButtonVariant.danger => AppColors.red,
        AppButtonVariant.onBlue => AppColors.cream,
        _ => Colors.transparent,
      };

  Color get _foreground => switch (variant) {
        AppButtonVariant.primary => AppColors.cream,
        AppButtonVariant.secondary => AppColors.primary,
        AppButtonVariant.danger => Colors.white,
        AppButtonVariant.dangerOutline => AppColors.red,
        AppButtonVariant.onBlue => AppColors.primary,
        AppButtonVariant.ghostOnBlue => AppColors.cream,
      };

  Color get _border => switch (variant) {
        AppButtonVariant.primary || AppButtonVariant.secondary => AppColors.primary,
        AppButtonVariant.danger || AppButtonVariant.dangerOutline => AppColors.red,
        AppButtonVariant.onBlue => AppColors.cream,
        AppButtonVariant.ghostOnBlue => AppColors.cream.withValues(alpha: 0.7),
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final textStyle = AppTextStyles.button.copyWith(
      color: _foreground,
      fontSize: small ? 13 : 15,
    );
    final shape = StadiumBorder(
      side: BorderSide(color: _border, width: AppDimens.borderWidth),
    );

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: _foreground),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis),
        ),
      ],
    );

    child = SizedBox(
      height: height ?? (small ? AppDimens.buttonSmall : AppDimens.buttonHeight),
      width: expand ? double.infinity : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
        child: child,
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: _background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: shape,
          overlayColor: WidgetStatePropertyAll(_foreground.withValues(alpha: 0.10)),
          child: child,
        ),
      ),
    );
  }
}
