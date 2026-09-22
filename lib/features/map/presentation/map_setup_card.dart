import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_button.dart';
import '../domain/offline_maps_controller.dart';

/// Tarjeta sobre el mapa mientras no está descargado el mapa base de Colombia.
class MapSetupCard extends ConsumerWidget {
  const MapSetupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(offlineMapsProvider);
    final c = ref.read(offlineMapsProvider.notifier);
    final m = s.manifest;
    final base = m?.base;
    final downloading = s.baseDownloading;
    final received = s.baseProgress;
    final total = m?.baseBytes ?? 1;
    final sizeLabel = '${(total / 1048576).toStringAsFixed(1)} MB';
    final error = m?.baseFiles.map((f) => s.errors[f.id]).whereType<String>().firstOrNull;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        boxShadow: AppDimens.floatingShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.map_outlined, size: 40, color: AppColors.primary),
          const SizedBox(height: 10),
          Text('Mapa de Colombia', textAlign: TextAlign.center, style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text(
            !s.ready || base == null
                ? 'Cargando la lista de mapas…'
                : 'Se descarga una sola vez ($sizeLabel) para usar el mapa sin internet.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          if (downloading) ...[
            LinearProgressIndicator(value: received / total),
            const SizedBox(height: 6),
            Text('${(received / 1048576).toStringAsFixed(1)} / $sizeLabel',
                textAlign: TextAlign.center, style: AppTextStyles.caption),
            const SizedBox(height: 12),
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                for (final f in m!.baseFiles) {
                  c.cancel(f.id);
                }
              },
            ),
          ] else ...[
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(error, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.red)),
              ),
            AppButton(
              label: 'Descargar',
              onPressed: base == null
                  ? null
                  : () {
                      for (final f in m!.baseFiles) {
                        if (!s.installed.containsKey(f.id)) c.download(f.id);
                      }
                    },
            ),
          ],
        ],
      ),
    );
  }
}
