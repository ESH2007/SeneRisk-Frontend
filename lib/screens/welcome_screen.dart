import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/usuario_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.authPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 11),
                Center(
                  child: Image.asset(
                    'assets/logo/senerisk_logo.png',
                    width: 160,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'SENERISK ATLAS',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.wordmark.copyWith(color: AppColors.cream),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      'Reporta, verifica y evita zonas de riesgo en Colombia',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppTextStyles.inter(
                        size: 12.5,
                        weight: FontWeight.w400,
                        color: AppColors.cream.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 13),
                AppButton(
                  label: 'Iniciar sesión',
                  variant: AppButtonVariant.onBlue,
                  onPressed: () => context.push('/login'),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Crear cuenta',
                  variant: AppButtonVariant.ghostOnBlue,
                  onPressed: () => context.push('/register'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ref.read(usuarioProvider.notifier).continuarSinCuenta();
                    context.go('/home');
                  },
                  child: Text(
                    'Continuar sin cuenta',
                    style: AppTextStyles.inter(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.cream,
                    ).copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.cream),
                  ),
                ),
                const SizedBox(height: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
