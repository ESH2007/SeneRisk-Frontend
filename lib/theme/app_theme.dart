import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

ThemeData get appTheme {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.cream,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.red,
      secondary: AppColors.ink,
      tertiary: AppColors.green,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      titleTextStyle: AppTextStyles.title,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.display,
      headlineMedium: AppTextStyles.headline,
      titleMedium: AppTextStyles.title,
      titleSmall: AppTextStyles.titleSmall,
      bodyMedium: AppTextStyles.body,
      labelMedium: AppTextStyles.label,
      labelLarge: AppTextStyles.labelStrong,
      labelSmall: AppTextStyles.caption,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.lineSoft,
      thickness: 1,
      space: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.switchTrackOff,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.sliderTrackOff,
      thumbColor: AppColors.primary,
      thumbShape: _OutlinedThumb(),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      showValueIndicator: ShowValueIndicator.never,
      trackHeight: 4,
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primary
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.cream),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.cream),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.green),
    drawerTheme: DrawerThemeData(
      backgroundColor: AppColors.paper,
      scrimColor: AppColors.ink.withValues(alpha: 0.32),
      width: 280,
      shape: const RoundedRectangleBorder(),
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.paper,
      elevation: 0,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      shape: Border(),
      collapsedShape: Border(),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
    ),
    textSelectionTheme:
        const TextSelectionThemeData(cursorColor: AppColors.primary),
  );
}

class _OutlinedThumb extends SliderComponentShape {
  const _OutlinedThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 10, Paint()..color = Colors.white);
    canvas.drawCircle(center, 8, Paint()..color = AppColors.primary);
  }
}
