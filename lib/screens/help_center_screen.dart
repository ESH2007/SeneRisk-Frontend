import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/emergency_card.dart';
import '../widgets/scroll_column.dart';
import '../widgets/section_label.dart';
import '../widgets/snack.dart';

const _preguntas = [
  (
    '¿Cómo reporto un hecho?',
    'Toca Reportar hecho en el mapa, elige el tipo, indica dónde ocurrió, describe lo que ves y publica. Puedes hacerlo de forma anónima.'
  ),
  (
    '¿Cómo veo el historial de alertas?',
    'Abre el menú y entra en Alertas recientes. Ahí están los reportes ordenados por hora, con filtros por tipo y cercanía.'
  ),
  (
    '¿Qué hago si una alerta es falsa?',
    'Ábrela y toca Desmentir. Cuando varias personas desmienten un reporte, deja de mostrarse en el mapa.'
  ),
  (
    '¿Cómo funcionan las confirmaciones?',
    'Cada reporte muestra cuántos vecinos lo confirmaron. Confirma solo lo que hayas visto: así el mapa se mantiene confiable para todos.'
  ),
  (
    '¿Cómo actualizo mi ubicación?',
    'Toca el botón de ubicación en el mapa o revisa el permiso de ubicación en los ajustes de tu teléfono.'
  ),
];

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _q = '';

  Future<void> _contactar() async {
    final ok = await launchUrl(Uri.parse('mailto:soporte@riesgomapa.app?subject=Ayuda%20Riesgo-Mapa'));
    if (!ok && mounted) mostrarAviso(context, 'Escríbenos a soporte@riesgomapa.app');
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _preguntas.where((p) => p.$1.toLowerCase().contains(_q.toLowerCase())).toList();
    return Scaffold(
      appBar: const AppTopBar(title: 'Centro de ayuda'),
      body: ScrollColumn(
        children: [
          const SizedBox(height: 4),
          const EmergencyCard(),
          const SizedBox(height: 10),
          Container(
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
                    onChanged: (v) => setState(() => _q = v.trim()),
                    style: AppTextStyles.inter(size: 13, weight: FontWeight.w500, color: AppColors.ink),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Buscar en la ayuda',
                      hintStyle: AppTextStyles.label.copyWith(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Preguntas frecuentes'),
          for (final p in visibles) _Faq(pregunta: p.$1, respuesta: p.$2),
          const Spacer(),
          const SizedBox(height: 16),
          AppButton(label: 'Contactar soporte', variant: AppButtonVariant.secondary, onPressed: _contactar),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _Faq extends StatefulWidget {
  const _Faq({required this.pregunta, required this.respuesta});

  final String pregunta;
  final String respuesta;

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  bool _abierta = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpansionTile(
          onExpansionChanged: (v) => setState(() => _abierta = v),
          title: Text(widget.pregunta, style: AppTextStyles.titleSmall.copyWith(fontSize: 12.5)),
          trailing: AnimatedRotation(
            turns: _abierta ? 0.25 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.respuesta, style: AppTextStyles.body.copyWith(fontSize: 12.5)),
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}
