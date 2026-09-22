import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

final _correoRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? Function(String?) requerido(String mensaje) =>
    (v) => (v ?? '').trim().isEmpty ? mensaje : null;

String? validarCorreo(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Escribe tu correo';
  if (!_correoRegex.hasMatch(t)) return 'El correo no tiene un formato válido';
  return null;
}

String? validarContrasena(String? v) {
  final t = v ?? '';
  if (t.isEmpty) return 'Escribe tu contraseña';
  if (t.length < 8) return 'Mínimo 8 caracteres';
  return null;
}

String? validarNombre(String? v) {
  final palabras = (v ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return palabras.length < 2 ? 'Escribe tu nombre y apellido' : null;
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.controller,
    this.obscure = false,
    this.showObscureToggle = false,
    this.keyboardType = TextInputType.text,
    this.minLines = 1,
    this.maxLines = 1,
    this.validator,
    this.errorText,
    this.action,
    this.onChanged,
    this.autofocus = false,
  });

  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextEditingController? controller;
  final bool obscure;
  final bool showObscureToggle;
  final TextInputType keyboardType;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final String? errorText;
  final TextInputAction? action;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.obscure;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1;
    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.controller?.text,
      autovalidateMode: AutovalidateMode.disabled,
      builder: (field) {
        final error = widget.errorText ?? field.errorText;
        final borderColor = error != null
            ? AppColors.red
            : _focus.hasFocus
                ? AppColors.primary
                : AppColors.line;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: AppDimens.fieldMinHeight),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppDimens.radiusField),
                border: Border.all(color: borderColor, width: AppDimens.borderWidth),
              ),
              child: Row(
                crossAxisAlignment:
                    multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  if (widget.prefixIcon != null) ...[
                    Padding(
                      padding: EdgeInsets.only(top: multiline ? 4 : 0),
                      child: Icon(widget.prefixIcon, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.label.isNotEmpty)
                          Text(
                            widget.label,
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                          ),
                        TextField(
                          controller: widget.controller,
                          focusNode: _focus,
                          autofocus: widget.autofocus,
                          obscureText: _obscure,
                          keyboardType:
                              multiline ? TextInputType.multiline : widget.keyboardType,
                          textInputAction: widget.action,
                          minLines: widget.minLines,
                          maxLines: _obscure ? 1 : widget.maxLines,
                          onChanged: (v) {
                            field.didChange(v);
                            widget.onChanged?.call(v);
                          },
                          style: AppTextStyles.inter(
                            size: 15,
                            weight: FontWeight.w500,
                            color: AppColors.ink,
                          ),
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            isDense: true,
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: widget.hint,
                            hintStyle: AppTextStyles.inter(
                              size: 15,
                              weight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showObscureToggle)
                    IconButton(
                      tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    )
                  else if (widget.suffix != null)
                    widget.suffix!,
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      error,
                      style: AppTextStyles.caption.copyWith(color: AppColors.red),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
