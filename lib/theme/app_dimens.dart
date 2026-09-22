import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppDimens {
  static const pagePadding = 16.0;
  static const authPadding = 24.0;
  static const gap = 10.0;
  static const gapSmall = 6.0;
  static const gapSection = 18.0;
  static const radiusPill = 999.0;
  static const radiusField = 13.0;
  static const radiusCard = 14.0;
  static const radiusTile = 12.0;
  static const radiusDialog = 18.0;
  static const buttonHeight = 48.0;
  static const buttonSmall = 36.0;
  static const fieldMinHeight = 52.0;
  static const borderWidth = 1.5;
  static const iconSize = 20.0;
  static const iconSizeSmall = 14.0;
  static const touchTarget = 44.0;

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
