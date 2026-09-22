import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextStyle inter({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle get wordmark => GoogleFonts.oswald(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
      );

  static TextStyle get display => inter(
        size: 30,
        weight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
        color: AppColors.primary,
      );

  static TextStyle get headline => inter(
        size: 22,
        weight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.primary,
      );

  static TextStyle get title =>
      inter(size: 17, weight: FontWeight.w700, color: AppColors.ink);

  static TextStyle get titleSmall =>
      inter(size: 15, weight: FontWeight.w600, color: AppColors.ink);

  static TextStyle get body =>
      inter(size: 15, weight: FontWeight.w400, height: 1.45, color: AppColors.ink);

  static TextStyle get label =>
      inter(size: 13, weight: FontWeight.w500, color: AppColors.muted);

  static TextStyle get labelStrong =>
      inter(size: 13, weight: FontWeight.w700, color: AppColors.muted);

  static TextStyle get caption =>
      inter(size: 11, weight: FontWeight.w500, color: AppColors.muted);

  static TextStyle get button => inter(size: 15, weight: FontWeight.w600);
}
