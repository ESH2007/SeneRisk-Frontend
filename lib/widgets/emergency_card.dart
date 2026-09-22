import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusCard);
    return Semantics(
      button: true,
      label: 'Emergencias: llamar al 123',
      child: Material(
        color: AppColors.redSoft,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: AppColors.red.withValues(alpha: 0.35),
            width: AppDimens.borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => launchUrl(Uri.parse('tel:123')),
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.call, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergencias: llamar al 123',
                        style: AppTextStyles.inter(size: 12, weight: FontWeight.w700, color: AppColors.red),
                      ),
                      Text(
                        'Policía, ambulancia y bomberos',
                        style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 14, color: AppColors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
