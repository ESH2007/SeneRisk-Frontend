import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_client.dart';
import '../models/tipo_hecho.dart';
import '../state/reportes_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/meta_item.dart';
import '../widgets/scroll_column.dart';
import '../widgets/snack.dart';
import '../widgets/verification_bar.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  bool _yaVoto = false;

  Future<void> _confirmar() async {
    try {
      await ref.read(reportesProvider.notifier).confirmar(widget.id);
    } catch (e) {
      if (mounted) mostrarAviso(context, mensajeDeError(e));
      return;
    }
    if (!mounted) return;
    setState(() => _yaVoto = true);
    mostrarAviso(context, 'Gracias por confirmar este reporte');
  }

  Future<void> _desmentir() async {
    final ok = await showConfirmDialog(
      context,
      titulo: '¿Desmentir este reporte?',
      mensaje: 'Solo hazlo si estás en el lugar y no ocurre lo reportado.',
      textoAccion: 'Desmentir',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(reportesProvider.notifier).desmentir(widget.id);
    } catch (e) {
      if (mounted) mostrarAviso(context, mensajeDeError(e));
      return;
    }
    if (!mounted) return;
    setState(() => _yaVoto = true);
    mostrarAviso(context, 'Gracias por avisar');
  }

  @override
  Widget build(BuildContext context) {
    final reporte = ref.watch(reportesProvider.select((l) => l.where((r) => r.id == widget.id).firstOrNull));
    if (reporte == null) {
      return Scaffold(
        appBar: const AppTopBar(),
        body: Center(child: Text('Reporte no encontrado', style: AppTextStyles.title)),
      );
    }
    final safeTop = MediaQuery.paddingOf(context).top;
    final conFoto = reporte.fotoAsset != null;

    return Scaffold(
      body: ScrollColumn(
        safeTop: false,
        horizontalPadding: 0,
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (conFoto)
                  _fotoReporte(reporte.fotoAsset!)
                else
                  Container(
                    color: AppColors.photoPlaceholder,
                    child: Icon(Icons.image_outlined, size: 40, color: AppColors.cream.withValues(alpha: 0.6)),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 110,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.primary.withValues(alpha: 0.5)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: safeTop + 8,
                  child: Material(
                    color: AppColors.paper.withValues(alpha: 0.92),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.pop(),
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: Tooltip(
                          message: 'Atrás',
                          child: Icon(Icons.arrow_back, size: 17, color: AppColors.ink),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(reporte.tipo.icono, size: 11, color: AppColors.cream),
                        const SizedBox(width: 4),
                        Text(
                          reporte.tipo.etiqueta,
                          style: AppTextStyles.inter(size: 10, weight: FontWeight.w700, color: AppColors.cream),
                        ),
                      ],
                    ),
                  ),
                ),
                if (conFoto)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                      ),
                      child: Text('1 de 1 fotos', style: AppTextStyles.caption.copyWith(fontSize: 9.5, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.pagePadding, 12, AppDimens.pagePadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(reporte.titulo, style: AppTextStyles.headline.copyWith(fontSize: 19)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      MetaItem(icon: Icons.place_outlined, text: reporte.lugar),
                      MetaItem(icon: Icons.schedule, text: reporte.horaTexto),
                      MetaItem(icon: Icons.my_location, text: 'a ${reporte.distanciaTexto}'),
                      if (reporte.anonimo) const MetaItem(icon: Icons.visibility_off_outlined, text: 'Anónimo'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(reporte.descripcion, style: AppTextStyles.body.copyWith(fontSize: 13.5)),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  VerificationBar(confirmaciones: reporte.confirmaciones, desmentidos: reporte.desmentidos),
                  const Spacer(),
                  const SizedBox(height: 16),
                  AppButton(
                    label: _yaVoto ? 'Ya confirmaste' : 'Confirmar este hecho',
                    icon: Icons.check,
                    onPressed: _yaVoto ? null : _confirmar,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'Desmentir',
                    variant: AppButtonVariant.dangerOutline,
                    onPressed: _yaVoto ? null : _desmentir,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => context.go('/home?lat=${reporte.lat}&lng=${reporte.lng}'),
                    child: Text(
                      'Ver en el mapa',
                      style: AppTextStyles.inter(size: 12, weight: FontWeight.w700, color: AppColors.primary)
                          .copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La foto puede venir del servidor (URL), de la galería (ruta local) o de los mocks (asset).
Widget _fotoReporte(String ref) {
  if (ref.startsWith('http')) return Image.network(ref, fit: BoxFit.cover);
  if (ref.startsWith('/')) return Image.file(File(ref), fit: BoxFit.cover);
  return Image.asset(ref, fit: BoxFit.cover);
}
