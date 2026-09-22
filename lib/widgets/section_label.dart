import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.labelStrong.copyWith(
          fontSize: 11,
          color: error ? AppColors.red : AppColors.muted,
        ),
      ),
    );
  }
}
