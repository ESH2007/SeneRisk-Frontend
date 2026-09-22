import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'snack.dart';

/// Hoja inferior con "Tomar foto" / "Elegir de la galería". Devuelve null si se cancela o falla.
Future<XFile?> elegirFoto(BuildContext context) async {
  final fuente = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusDialog)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
            title: Text('Tomar foto', style: AppTextStyles.titleSmall),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined, color: AppColors.primary),
            title: Text('Elegir de la galería', style: AppTextStyles.titleSmall),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (fuente == null) return null;
  try {
    return await ImagePicker().pickImage(source: fuente, maxWidth: 1600);
  } catch (_) {
    if (context.mounted) {
      mostrarAviso(context, 'No se pudo acceder a la cámara o la galería.');
    }
    return null;
  }
}

class PhotoPicker extends StatelessWidget {
  const PhotoPicker({
    super.key,
    required this.foto,
    required this.onCambiar,
  });

  final XFile? foto;
  final ValueChanged<XFile?> onCambiar;

  @override
  Widget build(BuildContext context) {
    final f = foto;
    if (f == null) {
      return Semantics(
        button: true,
        label: 'Agregar foto (opcional)',
        child: Material(
          color: AppColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusField),
            side: BorderSide(color: AppColors.line, width: AppDimens.borderWidth),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              final elegida = await elegirFoto(context);
              if (elegida != null) onCambiar(elegida);
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Agregar foto (opcional)',
                    style: AppTextStyles.inter(size: 12, weight: FontWeight.w500, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(f.path), width: 56, height: 56, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(f.name, style: AppTextStyles.label, overflow: TextOverflow.ellipsis)),
        IconButton(
          tooltip: 'Quitar foto',
          onPressed: () => onCambiar(null),
          icon: const Icon(Icons.close, size: 18, color: AppColors.muted),
        ),
      ],
    );
  }
}
