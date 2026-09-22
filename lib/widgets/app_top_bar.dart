import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.leadingIcon = Icons.arrow_back,
    this.onLeading,
    this.actions = const [],
  });

  final String? title;
  final IconData leadingIcon;
  final VoidCallback? onLeading;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 56,
      leadingWidth: 56,
      leading: Center(
        child: SizedBox(
          width: AppDimens.touchTarget,
          height: AppDimens.touchTarget,
          child: IconButton(
            tooltip: switch (leadingIcon) {
              Icons.close => 'Cerrar',
              Icons.menu => 'Menú',
              _ => 'Atrás',
            },
            onPressed: onLeading ?? () => context.pop(),
            icon: Icon(leadingIcon, size: 22, color: AppColors.ink),
          ),
        ),
      ),
      title: title == null ? null : Text(title!, style: AppTextStyles.title),
      actions: actions,
    );
  }
}
