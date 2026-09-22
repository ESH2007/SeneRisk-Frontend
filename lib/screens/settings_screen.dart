import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/configuracion_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/scroll_column.dart';
import '../widgets/section_label.dart';
import '../widgets/setting_row.dart';
import '../widgets/snack.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _restablecer(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      titulo: '¿Restablecer la configuración?',
      mensaje:
          'Volverán los valores iniciales: notificaciones activas, radio de 5 km y anonimato activado.',
      textoAccion: 'Restablecer',
      destructivo: false,
    );
    if (ok) ref.read(configuracionProvider.notifier).restablecer();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(configuracionProvider);
    final n = ref.read(configuracionProvider.notifier);
    final caption = AppTextStyles.caption.copyWith(fontSize: 9.5);

    return Scaffold(
      appBar: const AppTopBar(title: 'Configuración'),
      body: ScrollColumn(
        children: [
          const SectionLabel('Alertas'),
          SettingGroup(
            children: [
              SettingRow(
                icon: Icons.notifications_none,
                title: 'Notificaciones push',
                trailing: Switch(value: cfg.notificaciones, onChanged: n.setNotificaciones),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingRow(
                    icon: Icons.my_location,
                    title: 'Radio de alertas',
                    trailing: Text(
                      '${cfg.radioKm.round()} km',
                      style: AppTextStyles.inter(size: 10, weight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                  Slider(
                    min: 1,
                    max: 10,
                    divisions: 9,
                    value: cfg.radioKm,
                    onChanged: n.setRadioKm,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('1 km', style: caption), Text('10 km', style: caption)],
                  ),
                ],
              ),
            ],
          ),
          const SectionLabel('Mapa'),
          SettingGroup(
            children: [
              SettingRow(
                icon: Icons.download_outlined,
                title: 'Mapas sin conexión',
                subtitle: 'Descarga tu zona para usarla sin datos',
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                  onPressed: () => context.push('/maps'),
                ),
              ),
            ],
          ),
          const SectionLabel('Privacidad'),
          SettingGroup(
            children: [
              SettingRow(
                icon: Icons.visibility_off_outlined,
                title: 'Publicar siempre como anónimo',
                trailing: Switch(value: cfg.anonimoPorDefecto, onChanged: n.setAnonimoPorDefecto),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 16),
          AppButton(
            label: 'Guardar cambios',
            onPressed: () {
              mostrarAviso(context, 'Configuración guardada');
              context.pop();
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _restablecer(context, ref),
            child: Text(
              'Restablecer valores',
              style: AppTextStyles.inter(size: 12, weight: FontWeight.w600, color: AppColors.primary)
                  .copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
