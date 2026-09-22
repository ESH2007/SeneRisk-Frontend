import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../state/usuario_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/photo_picker.dart';
import '../widgets/scroll_column.dart';
import '../widgets/snack.dart';
import '../widgets/stat_tile.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: ref.read(usuarioProvider).nombre);
  late final _correo = TextEditingController(text: ref.read(usuarioProvider).correo);
  ImageProvider? _foto;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    super.dispose();
  }

  Future<void> _cambiarFoto() async {
    final f = await elegirFoto(context);
    if (f != null) setState(() => _foto = FileImage(File(f.path)));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(usuarioProvider.notifier).actualizar(_nombre.text.trim(), _correo.text.trim());
    } catch (e) {
      if (mounted) mostrarAviso(context, mensajeDeError(e));
      return;
    }
    if (mounted) mostrarAviso(context, 'Cambios guardados');
  }

  Future<void> _cerrarSesion() async {
    final ok = await showConfirmDialog(
      context,
      titulo: '¿Cerrar sesión?',
      mensaje: 'Dejarás de recibir alertas de riesgo en tiempo real hasta que vuelvas a entrar.',
      textoAccion: 'Cerrar sesión',
    );
    if (!ok || !mounted) return;
    ref.read(usuarioProvider.notifier).cerrarSesion();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(usuarioProvider);
    return Scaffold(
      appBar: const AppTopBar(title: 'Mi perfil'),
      body: usuario.tieneCuenta ? _cuenta(usuario.iniciales, usuario.nombre, usuario.correo) : _invitado(),
    );
  }

  Widget _invitado() {
    return ScrollColumn(
      children: [
        const SizedBox(height: 24),
        const Center(child: UserAvatar(iniciales: '', size: 64)),
        const SizedBox(height: 8),
        Text(
          'Invitado',
          textAlign: TextAlign.center,
          style: AppTextStyles.inter(size: 15, weight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea una cuenta para guardar tus reportes y recibir alertas personalizadas.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(fontSize: 13.5, color: AppColors.muted),
        ),
        const Spacer(),
        AppButton(label: 'Crear cuenta', onPressed: () => context.push('/register')),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _cuenta(String iniciales, String nombre, String correo) {
    final stats = ref.watch(estadisticasProvider).value;
    final editar = Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
    );
    return Form(
      key: _formKey,
      child: ScrollColumn(
        children: [
          const SizedBox(height: 4),
          Center(
            child: UserAvatar(iniciales: iniciales, size: 64, editable: true, imagen: _foto, onEditar: _cambiarFoto),
          ),
          const SizedBox(height: 8),
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(size: 15, weight: FontWeight.w800, color: AppColors.ink),
          ),
          Text(correo, textAlign: TextAlign.center, style: AppTextStyles.label),
          const SizedBox(height: 12),
          Row(
            children: [
              StatTile(value: stats == null ? '—' : '${stats.reportes}', label: 'reportes'),
              const SizedBox(width: 10),
              StatTile(value: stats == null ? '—' : '${stats.confirmaciones}', label: 'confirmaciones'),
              const SizedBox(width: 10),
              StatTile(value: stats == null ? '—' : '${(stats.fiabilidad * 100).round()} %', label: 'fiabilidad'),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Nombre',
            prefixIcon: Icons.person_outline,
            controller: _nombre,
            suffix: editar,
            validator: validarNombre,
          ),
          const SizedBox(height: 10),
          AppTextField(
            label: 'Correo electrónico',
            prefixIcon: Icons.mail_outline,
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            suffix: editar,
            validator: validarCorreo,
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => mostrarAviso(context, 'Disponible cuando conectemos tu cuenta'),
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: AppDimens.touchTarget,
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 17, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Cambiar contraseña', style: AppTextStyles.titleSmall.copyWith(fontSize: 12.5))),
                  const Icon(Icons.chevron_right, size: 14, color: AppColors.muted),
                ],
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
          AppButton(label: 'Guardar cambios', onPressed: _guardar),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cerrarSesion,
            child: Text(
              'Cerrar sesión',
              style: AppTextStyles.inter(size: 12, weight: FontWeight.w600, color: AppColors.red)
                  .copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.red),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
