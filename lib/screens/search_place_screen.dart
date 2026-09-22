import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_reportes.dart';
import '../state/busquedas_provider.dart';
import '../state/filtro_mapa_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/section_label.dart';

/// Resultado devuelto al mapa cuando el usuario elige el atajo "Mi ubicación".
const resultadoMiUbicacion = 'mi_ubicacion';

class SearchPlaceScreen extends ConsumerStatefulWidget {
  const SearchPlaceScreen({super.key});

  @override
  ConsumerState<SearchPlaceScreen> createState() => _SearchPlaceScreenState();
}

class _SearchPlaceScreenState extends ConsumerState<SearchPlaceScreen> {
  final _consulta = TextEditingController();

  @override
  void dispose() {
    _consulta.dispose();
    super.dispose();
  }

  void _elegir(String lugar) {
    ref.read(busquedasRecientesProvider.notifier).agregar(lugar);
    context.pop();
  }

  void _atajoFiltro(String filtro) {
    ref.read(filtroMapaProvider.notifier).set(filtro);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final q = _consulta.text.trim();
    final recientes = ref.watch(busquedasRecientesProvider);
    final resultados = q.isEmpty
        ? const <String>[]
        : lugaresBusqueda.where((l) => l.toLowerCase().contains(q.toLowerCase())).take(5).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, AppDimens.pagePadding, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Atrás',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, size: 22, color: AppColors.ink),
                  ),
                  Expanded(
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                        border: Border.all(color: AppColors.line, width: AppDimens.borderWidth),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 15, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _consulta,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (v) {
                                if (v.trim().isNotEmpty) _elegir(v.trim());
                              },
                              style: AppTextStyles.inter(size: 13, weight: FontWeight.w500, color: AppColors.ink),
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Buscar ubicación o reporte',
                                hintStyle: AppTextStyles.label.copyWith(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppDimens.pagePadding),
                children: [
                  if (q.isNotEmpty) ...[
                    const SectionLabel('Resultados'),
                    if (resultados.isEmpty)
                      Text('Sin resultados para "$q"', style: AppTextStyles.label)
                    else
                      for (final r in resultados) _ResultadoFila(lugar: r, onTap: () => _elegir(r)),
                  ],
                  if (recientes.isNotEmpty) ...[
                    Row(
                      children: [
                        const SectionLabel('Recientes'),
                        const Spacer(),
                        TextButton(
                          onPressed: () => ref.read(busquedasRecientesProvider.notifier).limpiar(),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(AppDimens.touchTarget, AppDimens.touchTarget),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Borrar',
                            style: AppTextStyles.inter(size: 10, weight: FontWeight.w600, color: AppColors.primary)
                                .copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    for (var i = 0; i < recientes.length; i++)
                      _RecienteFila(
                        texto: recientes[i],
                        onTap: () => context.pop(),
                        onQuitar: () => ref.read(busquedasRecientesProvider.notifier).quitar(i),
                      ),
                  ],
                  const SectionLabel('Atajos'),
                  SizedBox(
                    height: 30,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        AppFilterChip(
                          label: 'Mi ubicación',
                          icon: Icons.my_location,
                          selected: false,
                          onTap: () => context.pop(resultadoMiUbicacion),
                        ),
                        const SizedBox(width: 6),
                        AppFilterChip(
                          label: 'Bloqueos',
                          icon: Icons.construction,
                          selected: false,
                          onTap: () => _atajoFiltro('bloqueo'),
                        ),
                        const SizedBox(width: 6),
                        AppFilterChip(
                          label: 'Protestas',
                          icon: Icons.campaign_outlined,
                          selected: false,
                          onTap: () => _atajoFiltro('protesta'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultadoFila extends StatelessWidget {
  const _ResultadoFila({required this.lugar, required this.onTap});

  final String lugar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final partes = lugar.split(' — ');
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 17, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partes.first, style: AppTextStyles.titleSmall.copyWith(fontSize: 12)),
                      if (partes.length > 1)
                        Text(partes.last, style: AppTextStyles.caption.copyWith(fontSize: 9.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _RecienteFila extends StatelessWidget {
  const _RecienteFila({required this.texto, required this.onTap, required this.onQuitar});

  final String texto;
  final VoidCallback onTap;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 17, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(texto, style: AppTextStyles.titleSmall.copyWith(fontSize: 12))),
                IconButton(
                  tooltip: 'Quitar',
                  onPressed: onQuitar,
                  icon: const Icon(Icons.close, size: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
