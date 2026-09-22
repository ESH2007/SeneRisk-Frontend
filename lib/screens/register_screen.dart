import 'package:flutter/gestures.dart';
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
import '../widgets/snack.dart';
import '../widgets/scroll_column.dart';

/// 0: vacío; 1: <8; 2: ≥8; 3: ≥8 con número; 4: ≥8 con número y símbolo o mayúscula.
int nivelContrasena(String c) {
  if (c.isEmpty) return 0;
  if (c.length < 8) return 1;
  final tieneNumero = c.contains(RegExp(r'\d'));
  if (!tieneNumero) return 2;
  final tieneExtra = c.contains(RegExp(r'[A-Z]')) || c.contains(RegExp(r'[^A-Za-z0-9]'));
  return tieneExtra ? 4 : 3;
}

const _etiquetasNivel = ['', 'Débil', 'Regular', 'Buena', 'Fuerte'];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();
  bool _acepta = false;
  bool _errorTerminos = false;
  int _nivel = 0;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  bool _cargando = false;

  Future<void> _crear() async {
    final valido = _formKey.currentState!.validate();
    setState(() => _errorTerminos = !_acepta);
    if (!valido || !_acepta || _cargando) return;
    setState(() => _cargando = true);
    try {
      await ref.read(usuarioProvider.notifier).crearCuenta(_nombre.text.trim(), _correo.text.trim(), _contrasena.text);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) mostrarAviso(context, mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enlace = AppTextStyles.inter(size: 12, weight: FontWeight.w600, color: AppColors.primary)
        .copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.primary);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppTopBar(onLeading: () => context.go('/')),
      body: Form(
        key: _formKey,
        child: ScrollColumn(
          horizontalPadding: AppDimens.authPadding,
          children: [
            const SizedBox(height: 6),
            Text('Crea tu cuenta', style: AppTextStyles.display),
            const SizedBox(height: 6),
            Text('Tus reportes pueden seguir siendo anónimos.', style: AppTextStyles.label),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Nombre completo',
              prefixIcon: Icons.person_outline,
              controller: _nombre,
              action: TextInputAction.next,
              validator: validarNombre,
            ),
            const SizedBox(height: 10),
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
              action: TextInputAction.next,
              validator: validarContrasena,
              onChanged: (v) => setState(() => _nivel = nivelContrasena(v)),
            ),
            if (_nivel > 0) ...[
              const SizedBox(height: 6),
              _PasswordStrength(nivel: _nivel),
            ],
            const SizedBox(height: 10),
            AppTextField(
              label: 'Confirmar contraseña',
              prefixIcon: Icons.lock_outline,
              controller: _confirmar,
              obscure: true,
              action: TextInputAction.done,
              validator: (v) => v != _contrasena.text ? 'Las contraseñas no coinciden' : null,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _acepta,
                    onChanged: (v) => setState(() {
                      _acepta = v ?? false;
                      if (_acepta) _errorTerminos = false;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.inter(size: 12, weight: FontWeight.w400, color: AppColors.ink),
                        children: [
                          const TextSpan(text: 'Acepto los '),
                          TextSpan(
                            text: 'términos',
                            style: enlace,
                            recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                          ),
                          const TextSpan(text: ' y la '),
                          TextSpan(
                            text: 'política de privacidad',
                            style: enlace,
                            recognizer: TapGestureRecognizer()..onTap = () => context.push('/terms'),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_errorTerminos)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Debes aceptar los términos para continuar',
                  style: AppTextStyles.caption.copyWith(color: AppColors.red),
                ),
              ),
            const Spacer(),
            const SizedBox(height: 16),
            AppButton(label: 'Crear cuenta', onPressed: _crear),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('¿Ya tienes cuenta? ', style: AppTextStyles.label),
                TextButton(
                  onPressed: () => context.push('/login'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, AppDimens.touchTarget),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Ingresar', style: enlace.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.nivel});

  final int nivel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 4; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= nivel ? AppColors.green : AppColors.sliderTrackOff,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        const SizedBox(width: 4),
        Text(
          _etiquetasNivel[nivel],
          style: AppTextStyles.inter(size: 9.5, weight: FontWeight.w600, color: AppColors.green),
        ),
      ],
    );
  }
}
