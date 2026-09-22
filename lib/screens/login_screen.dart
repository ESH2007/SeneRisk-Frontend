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
import '../widgets/scroll_column.dart';
import '../widgets/snack.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  bool _cargando = false;

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate() || _cargando) return;
    setState(() => _cargando = true);
    try {
      await ref.read(usuarioProvider.notifier).iniciarSesion(_correo.text.trim(), _contrasena.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppTopBar(onLeading: () => context.go('/')),
      body: Form(
        key: _formKey,
        child: ScrollColumn(
          horizontalPadding: AppDimens.authPadding,
          children: [
            const SizedBox(height: 6),
            Text('Bienvenido\nde nuevo', style: AppTextStyles.display),
            const SizedBox(height: 6),
            Text('Ingresa para recibir alertas cerca de ti.', style: AppTextStyles.label),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Correo electrónico',
              hint: 'nombre@correo.com',
              prefixIcon: Icons.mail_outline,
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              action: TextInputAction.next,
              validator: validarCorreo,
            ),
            const SizedBox(height: 10),
            AppTextField(
              label: 'Contraseña',
              prefixIcon: Icons.lock_outline,
              controller: _contrasena,
              obscure: true,
              showObscureToggle: true,
              action: TextInputAction.done,
              validator: validarContrasena,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _Enlace(
                '¿Olvidaste tu contraseña?',
                peso: FontWeight.w600,
                onTap: () => mostrarAviso(context, 'Pronto podrás recuperar tu contraseña desde aquí.'),
              ),
            ),
            const Spacer(),
            AppButton(label: 'Ingresar', onPressed: _ingresar),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('¿No tienes cuenta? ', style: AppTextStyles.label),
                _Enlace('Crear cuenta', peso: FontWeight.w700, onTap: () => context.push('/register')),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _Enlace extends StatelessWidget {
  const _Enlace(this.texto, {required this.peso, required this.onTap});

  final String texto;
  final FontWeight peso;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(0, AppDimens.touchTarget),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        texto,
        style: AppTextStyles.inter(size: 12, weight: peso, color: AppColors.primary).copyWith(
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}
