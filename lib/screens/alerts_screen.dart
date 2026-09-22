import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/reporte.dart';
import '../state/configuracion_provider.dart';
import '../state/reportes_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/alert_card.dart';
import '../widgets/app_button.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/snack.dart';
import '../widgets/status_pill.dart';

/// Lista de alertas. [VerifyReportsScreen] reutiliza esta misma pantalla con otra configuración.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({
    super.key,
    this.titulo = 'Alertas recientes',
    this.paginaActual = 'alertas',
    this.conChips = true,
    this.intro,
    this.conVerMas = true,
    this.seleccionar,
  });

  final String titulo;
  final String paginaActual;
  final bool conChips;
  final String? intro;
  final bool conVerMas;

  /// Si se indica, reemplaza el filtro por chips.
  final List<Reporte> Function(List<Reporte>)? seleccionar;

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _filtro = 'cerca';

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(reportesProvider);
    final radio = ref.watch(configuracionProvider.select((c) => c.radioKm));
    final lista = widget.seleccionar?.call(todos) ?? filtrarAlertas(todos, _filtro, radioKm: radio);

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(paginaActual: widget.paginaActual),
      appBar: AppTopBar(
        title: widget.titulo,
        leadingIcon: Icons.menu,
        onLeading: () => _scaffoldKey.currentState!.openDrawer(),
        actions: [
          IconButton(
            tooltip: 'Buscar',
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.search, size: 22, color: AppColors.ink),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StatusPill('En línea, actualizado hace 1 min'),
              const SizedBox(height: 8),
              if (widget.conChips) ...[
                SizedBox(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip('Cerca de mí', 'cerca', Icons.my_location),
                      const SizedBox(width: 6),
                      _chip('Bloqueos', 'bloqueo', Icons.construction),
                      const SizedBox(width: 6),
                      _chip('Protestas', 'protesta', Icons.campaign_outlined),
                      const SizedBox(width: 6),
                      _chip('Más', 'mas', null),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (widget.intro != null) ...[
                Text(widget.intro!, style: AppTextStyles.label),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: lista.isEmpty
                    ? Center(child: Text('No hay alertas con este filtro', style: AppTextStyles.label))
                    : ListView.separated(
                        itemCount: lista.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => AlertCard(
                          reporte: lista[i],
                          onTap: () => context.push('/report/${lista[i].id}'),
                        ),
                      ),
              ),
              if (widget.conVerMas) ...[
                const SizedBox(height: 8),
                Center(
                  child: AppButton(
                    label: 'Ver más alertas',
                    variant: AppButtonVariant.secondary,
                    small: true,
                    expand: false,
                    onPressed: () => mostrarAviso(context, 'Ya estás viendo todas las alertas de prueba'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String valor, IconData? icon) => AppFilterChip(
        label: label,
        icon: icon,
        selected: _filtro == valor,
        onTap: () => setState(() => _filtro = valor),
      );
}
