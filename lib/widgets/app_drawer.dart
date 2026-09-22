import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/usuario_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'confirm_dialog.dart';
import 'user_avatar.dart';

/// [paginaActual]: "mapa" | "alertas" | "crear" | "verificar" | "config" | "ayuda".
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.paginaActual});

  final String paginaActual;

  void _ir(BuildContext context, String ruta, {bool push = false}) {
    Navigator.of(context).pop();
    push ? context.push(ruta) : context.go(ruta);
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    // El drawer se desmonta al cerrarse: se conservan referencias que sobreviven al diálogo.
    final router = GoRouter.of(context);
    final usuario = ref.read(usuarioProvider.notifier);
    final raiz = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    if (!ref.read(usuarioProvider).tieneCuenta) {
      router.go('/'); // invitado: no hay sesión que perder
      return;
    }
    final ok = await showConfirmDialog(
      raiz,
      titulo: '¿Cerrar sesión?',
      mensaje:
          'Dejarás de recibir alertas de riesgo en tiempo real hasta que vuelvas a entrar.',
      textoAccion: 'Cerrar sesión',
    );
    if (!ok) return;
    usuario.cerrarSesion();
    router.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioProvider);
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 52, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Cabecera(
              nombre: usuario.tieneCuenta ? usuario.nombre : 'Invitado',
              accion: usuario.tieneCuenta ? 'Ver mi perfil' : 'Crear cuenta',
              iniciales: usuario.tieneCuenta ? usuario.iniciales : '',
              onTap: () => _ir(context, usuario.tieneCuenta ? '/profile' : '/register',
                  push: true),
            ),
            const Divider(),
            const SizedBox(height: 6),
            _Item(
              icon: Icons.map_outlined,
              text: 'Mapa de calor',
              activo: paginaActual == 'mapa',
              onTap: () => _ir(context, '/home'),
            ),
            _Item(
              icon: Icons.notifications_none,
              text: 'Alertas recientes',
              activo: paginaActual == 'alertas',
              onTap: () => _ir(context, '/alerts'),
            ),
            _Item(
              icon: Icons.add,
              text: 'Crear reporte',
              activo: paginaActual == 'crear',
              onTap: () => _ir(context, '/report/new', push: true),
            ),
            _Item(
              icon: Icons.fact_check_outlined,
              text: 'Verificar reportes',
              activo: paginaActual == 'verificar',
              onTap: () => _ir(context, '/verify'),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
            _Item(
              icon: Icons.settings_outlined,
              text: 'Configuración',
              activo: paginaActual == 'config',
              onTap: () => _ir(context, '/settings', push: true),
            ),
            _Item(
              icon: Icons.help_outline,
              text: 'Ayuda',
              activo: paginaActual == 'ayuda',
              onTap: () => _ir(context, '/help', push: true),
            ),
            const Spacer(),
            _Item(
              icon: Icons.logout,
              text: usuario.tieneCuenta ? 'Cerrar sesión' : 'Salir',
              color: AppColors.red,
              onTap: () => _cerrarSesion(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.nombre,
    required this.accion,
    required this.iniciales,
    required this.onTap,
  });

  final String nombre;
  final String accion;
  final String iniciales;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: accion,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Row(
            children: [
              UserAvatar(iniciales: iniciales, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.inter(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      accion,
                      style: AppTextStyles.inter(
                        size: 10,
                        weight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.text,
    required this.onTap,
    this.activo = false,
    this.color,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool activo;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? (activo ? AppColors.primary : AppColors.ink);
    return Material(
      color: activo ? AppColors.blueSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color ?? AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontSize: 12.5,
                    color: fg,
                    fontWeight: activo ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
