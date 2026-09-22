import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.iniciales,
    this.size = 64,
    this.editable = false,
    this.imagen,
    this.onEditar,
  });

  final String iniciales;
  final double size;
  final bool editable;
  final ImageProvider? imagen;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    final circulo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        image: imagen == null ? null : DecorationImage(image: imagen!, fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: imagen != null
          ? null
          : iniciales.isEmpty
              ? Icon(Icons.person_outline, size: size * 0.5, color: AppColors.cream)
              : Text(
                  iniciales,
                  style: AppTextStyles.inter(
                    size: size * 0.34,
                    weight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
    );
    if (!editable) return circulo;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          circulo,
          Positioned(
            right: -2,
            bottom: -2,
            child: Semantics(
              button: true,
              label: 'Cambiar foto',
              child: Material(
                color: AppColors.paper,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.primary, width: AppDimens.borderWidth),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onEditar,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: Icon(Icons.photo_camera_outlined, size: 12, color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
