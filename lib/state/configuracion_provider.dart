import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import '../models/configuracion.dart';
import 'usuario_provider.dart';

class ConfiguracionNotifier extends Notifier<Configuracion> {
  static const _kNotificaciones = 'cfg_notificaciones';
  static const _kRadioKm = 'cfg_radio_km';
  static const _kAnonimo = 'cfg_anonimo';

  @override
  Configuracion build() {
    _cargar();
    // Con cuenta y backend, la configuración vive en el servidor.
    if (usaApi) {
      ref.listen(usuarioProvider, (prev, next) {
        if (next.tieneCuenta && !(prev?.tieneCuenta ?? false)) _descargar();
      });
    }
    return const Configuracion();
  }

  Future<void> _descargar() async {
    try {
      final j = await ref.read(apiClientProvider).get('/me/configuracion/');
      state = Configuracion(
        notificaciones: j['notificaciones'] as bool,
        radioKm: (j['radioKm'] as num).toDouble(),
        anonimoPorDefecto: j['anonimoPorDefecto'] as bool,
      );
      _guardar();
    } catch (_) {}
  }

  Future<void> _subir() async {
    if (!usaApi || !ref.read(usuarioProvider).tieneCuenta) return;
    try {
      await ref.read(apiClientProvider).send('PUT', '/me/configuracion/', body: {
        'notificaciones': state.notificaciones,
        'radioKm': state.radioKm,
        'anonimoPorDefecto': state.anonimoPorDefecto,
      });
    } catch (_) {}
  }

  Future<void> _cargar() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = Configuracion(
        notificaciones: p.getBool(_kNotificaciones) ?? true,
        radioKm: p.getDouble(_kRadioKm) ?? 5,
        anonimoPorDefecto: p.getBool(_kAnonimo) ?? true,
      );
    } catch (_) {
      // Sin preferencias disponibles (tests, plataforma sin soporte): se usan los valores por defecto.
    }
  }

  Future<void> _guardar() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kNotificaciones, state.notificaciones);
      await p.setDouble(_kRadioKm, state.radioKm);
      await p.setBool(_kAnonimo, state.anonimoPorDefecto);
    } catch (_) {}
    _subir();
  }

  void setNotificaciones(bool v) {
    state = state.copyWith(notificaciones: v);
    _guardar();
  }

  void setRadioKm(double v) {
    state = state.copyWith(radioKm: v);
    _guardar();
  }

  void setAnonimoPorDefecto(bool v) {
    state = state.copyWith(anonimoPorDefecto: v);
    _guardar();
  }

  void restablecer() {
    state = const Configuracion();
    _guardar();
  }
}

final configuracionProvider =
    NotifierProvider<ConfiguracionNotifier, Configuracion>(
        ConfiguracionNotifier.new);
