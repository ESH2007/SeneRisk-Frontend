import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

import '../data/api_client.dart';
import '../data/mock_reportes.dart';
import '../models/reporte.dart';
import '../models/tipo_hecho.dart';
import '../state/configuracion_provider.dart';
import '../state/reportes_provider.dart';
import '../state/ubicacion_usuario_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/photo_picker.dart';
import '../widgets/section_label.dart';
import '../widgets/snack.dart';
import '../widgets/type_tile.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tipoKey = GlobalKey();
  final _ubicacion = TextEditingController();
  final _descripcion = TextEditingController();
  TipoHecho? _tipo;
  bool _mostrarErrorTipo = false;
  late bool _anonimo = ref.read(configuracionProvider).anonimoPorDefecto;
  XFile? _foto;
  LatLng? _coordenadas;

  @override
  void dispose() {
    _ubicacion.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _miUbicacion() {
    _ubicacion.text = 'Mi ubicación actual';
    _coordenadas = ref.read(ubicacionUsuarioProvider).value ?? ubicacionSimulada;
  }

  Future<void> _publicar() async {
    final tipo = _tipo;
    if (tipo == null) {
      setState(() => _mostrarErrorTipo = true);
      Scrollable.ensureVisible(_tipoKey.currentContext!, duration: const Duration(milliseconds: 250));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final base = _coordenadas ?? ref.read(ubicacionUsuarioProvider).value ?? ubicacionSimulada;
    final rnd = Random();
    double jitter() => (rnd.nextDouble() * 2 - 1) * 0.003;
    final ubicacion = _ubicacion.text.trim();
    final reporte = Reporte(
      id: 'r${DateTime.now().millisecondsSinceEpoch}',
      tipo: tipo,
      titulo: '${tipo.etiqueta} en $ubicacion',
      descripcion: _descripcion.text.trim(),
      lugar: ubicacion,
      lat: base.latitude + jitter(),
      lng: base.longitude + jitter(),
      creadoEn: DateTime.now(),
      distanciaKm: 0.3,
      anonimo: _anonimo,
      fotoAsset: _foto?.path,
    );
    try {
      await ref.read(reportesProvider.notifier).agregar(reporte, fotoRuta: _foto?.path);
    } catch (e) {
      if (mounted) mostrarAviso(context, mensajeDeError(e));
      return;
    }
    if (!mounted) return;
    mostrarAviso(context, 'Reporte publicado');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final errorTipo = _mostrarErrorTipo && _tipo == null;
    return Scaffold(
      appBar: AppTopBar(title: 'Crear reporte', leadingIcon: Icons.close, onLeading: () => context.pop()),
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionLabel('Tipo de hecho', key: _tipoKey, error: errorTipo),
                GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 7,
                  crossAxisSpacing: 7,
                  childAspectRatio: 90 / 58,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final t in TipoHecho.values)
                      TypeTile(
                        tipo: t,
                        selected: _tipo == t,
                        hasError: errorTipo,
                        onTap: () => setState(() {
                          _tipo = t;
                          _mostrarErrorTipo = false;
                        }),
                      ),
                  ],
                ),
                if (errorTipo)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.red),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Selecciona el tipo de hecho para continuar',
                            style: AppTextStyles.caption.copyWith(color: AppColors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SectionLabel('Ubicación'),
                AppTextField(
                  label: 'Dónde ocurrió',
                  hint: 'Dirección o punto de referencia',
                  prefixIcon: Icons.place_outlined,
                  controller: _ubicacion,
                  action: TextInputAction.next,
                  validator: requerido('Indica dónde ocurrió'),
                  suffix: TextButton(
                    onPressed: _miUbicacion,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Mi ubicación',
                      style: AppTextStyles.inter(size: 10.5, weight: FontWeight.w600, color: AppColors.primary)
                          .copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.primary),
                    ),
                  ),
                ),
                const SectionLabel('Descripción'),
                AppTextField(
                  label: '',
                  hint: 'Qué está pasando, cuántas personas, si hay tráfico detenido…',
                  controller: _descripcion,
                  minLines: 3,
                  maxLines: 5,
                  validator: requerido('Describe lo que está pasando'),
                ),
                const SizedBox(height: 10),
                PhotoPicker(foto: _foto, onCambiar: (f) => setState(() => _foto = f)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.visibility_off_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Publicar como anónimo',
                        style: AppTextStyles.inter(size: 12.5, weight: FontWeight.w600, color: AppColors.ink),
                      ),
                    ),
                    Switch(value: _anonimo, onChanged: (v) => setState(() => _anonimo = v)),
                  ],
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Publicar reporte', icon: Icons.send_outlined, onPressed: _publicar),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
