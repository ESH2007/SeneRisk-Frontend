import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_top_bar.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/scroll_column.dart';
import '../../../widgets/section_label.dart';
import '../../../widgets/setting_row.dart';
import '../data/map_manifest.dart';
import '../domain/offline_maps_controller.dart';

class OfflineMapsScreen extends ConsumerWidget {
  const OfflineMapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(offlineMapsProvider);
    final c = ref.read(offlineMapsProvider.notifier);
    final m = s.manifest;

    return Scaffold(
      appBar: const AppTopBar(title: 'Mapas offline'),
      body: !s.ready
          ? const Center(child: CircularProgressIndicator())
          : m == null
              ? const Center(child: Text('No se pudo cargar la lista de mapas'))
              : ScrollColumn(
                  children: [
                    SettingGroup(children: [
                      SettingRow(
                        icon: Icons.wifi,
                        title: 'Descargar solo con Wi‑Fi',
                        trailing: Switch(value: s.soloWifi, onChanged: c.setSoloWifi),
                      ),
                      if (m.nationalDetail != null)
                        SettingRow(
                          icon: Icons.cloud_outlined,
                          title: 'Calles por internet',
                          subtitle: 'Donde no tengas región descargada (consume datos)',
                          trailing: Switch(value: s.detalleRemoto, onChanged: c.setDetalleRemoto),
                        ),
                    ]),
                    const SectionLabel('Mapa base'),
                    SettingGroup(children: [for (final f in m.baseFiles) _MapRow(f, s, c, deletable: false)]),
                    const SectionLabel('Detalle de calles por región'),
                    SettingGroup(children: [for (final r in m.regions) _MapRow(r, s, c)]),
                    const SizedBox(height: 8),
                    Text('Versión de mapas: ${m.build}', style: AppTextStyles.caption.copyWith(fontSize: 9.5)),
                  ],
                ),
    );
  }
}

class _MapRow extends StatelessWidget {
  const _MapRow(this.f, this.s, this.c, {this.deletable = true});

  final MapFile f;
  final OfflineMapsState s;
  final OfflineMapsController c;
  final bool deletable;

  @override
  Widget build(BuildContext context) {
    final status = s.statusOf(f);
    final err = s.errors[f.id];
    final subtitle = switch (status) {
      MapStatus.downloading => '${((s.progress[f.id] ?? 0) / 1048576).toStringAsFixed(1)} / ${f.sizeLabel}',
      MapStatus.installed => '${f.sizeLabel} · descargado',
      MapStatus.updateAvailable => '${f.sizeLabel} · actualización disponible',
      MapStatus.notInstalled => f.sizeLabel,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingRow(
          icon: switch (status) {
            MapStatus.installed => Icons.check_circle_outline,
            MapStatus.updateAvailable => Icons.update,
            _ => Icons.map_outlined,
          },
          title: f.name,
          subtitle: err ?? subtitle,
          trailing: switch (status) {
            MapStatus.downloading => SizedBox(
                width: 36,
                height: 36,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(value: (s.progress[f.id] ?? 0) / f.bytes, strokeWidth: 3),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    onPressed: () => c.cancel(f.id),
                  ),
                ]),
              ),
            MapStatus.installed => deletable
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.red),
                    onPressed: () async {
                      final ok = await showConfirmDialog(
                        context,
                        titulo: '¿Borrar ${f.name}?',
                        mensaje: 'Liberas ${f.sizeLabel}. Podrás descargarlo de nuevo cuando quieras.',
                        textoAccion: 'Borrar',
                      );
                      if (ok) c.delete(f.id);
                    },
                  )
                : const SizedBox(width: 40),
            _ => IconButton(
                icon: Icon(status == MapStatus.updateAvailable ? Icons.system_update_alt : Icons.download_outlined,
                    color: AppColors.primary),
                onPressed: () => c.download(f.id),
              ),
          },
        ),
        if (status == MapStatus.downloading)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(value: (s.progress[f.id] ?? 0) / f.bytes, minHeight: 3),
          ),
      ],
    );
  }
}
