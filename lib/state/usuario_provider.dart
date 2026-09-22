import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/mock_reportes.dart';
import '../models/usuario.dart';

class UsuarioNotifier extends Notifier<Usuario> {
  ApiClient get _api => ref.read(apiClientProvider);

  @override
  Usuario build() {
    if (usaApi) _restaurar();
    return const Usuario.invitado();
  }

  /// Con token guardado, recupera la sesión al arrancar.
  Future<void> _restaurar() async {
    await _api.restaurarToken();
    if (_api.token == null) return;
    try {
      state = _desdeJson(await _api.get('/me/'));
    } on ApiException catch (e) {
      if (e.status == 401) await _api.guardarToken(null);
    } catch (_) {
      // sin red: se queda como invitado hasta que vuelva a entrar
    }
  }

  Usuario _desdeJson(dynamic j) => Usuario(nombre: j['nombre'] as String, correo: j['correo'] as String, tieneCuenta: true);

  Future<void> _sesion(dynamic r) async {
    await _api.guardarToken(r['token'] as String);
    state = _desdeJson(r['usuario']);
  }

  Future<void> iniciarSesion(String correo, String password) async {
    if (!usaApi) {
      state = Usuario(nombre: usuarioMockNombre, correo: correo, tieneCuenta: true);
      return;
    }
    await _sesion(await _api.send('POST', '/auth/login/', body: {'correo': correo, 'password': password}));
  }

  Future<void> crearCuenta(String nombre, String correo, String password) async {
    if (!usaApi) {
      state = Usuario(nombre: nombre, correo: correo, tieneCuenta: true);
      return;
    }
    await _sesion(await _api.send('POST', '/auth/registro/', body: {'nombre': nombre, 'correo': correo, 'password': password}));
  }

  void continuarSinCuenta() => state = const Usuario.invitado();

  Future<void> cerrarSesion() async {
    state = const Usuario.invitado();
    if (!usaApi) return;
    try {
      await _api.send('POST', '/auth/logout/');
    } catch (_) {}
    await _api.guardarToken(null);
  }

  Future<void> actualizar(String nombre, String correo) async {
    if (usaApi) {
      state = _desdeJson(await _api.send('PATCH', '/me/', body: {'nombre': nombre, 'correo': correo}));
      return;
    }
    state = state.copyWith(nombre: nombre, correo: correo);
  }
}

final usuarioProvider =
    NotifierProvider<UsuarioNotifier, Usuario>(UsuarioNotifier.new);

/// Tarjetas del perfil: `{reportes, confirmaciones, fiabilidad}` (fiabilidad 0..1).
final estadisticasProvider = FutureProvider<({int reportes, int confirmaciones, double fiabilidad})>((ref) async {
  ref.watch(usuarioProvider);
  if (!usaApi) return (reportes: 12, confirmaciones: 34, fiabilidad: 0.92);
  final j = await ref.read(apiClientProvider).get('/me/estadisticas/');
  return (
    reportes: (j['reportes'] as num).toInt(),
    confirmaciones: (j['confirmaciones'] as num).toInt(),
    fiabilidad: (j['fiabilidad'] as num).toDouble(),
  );
});
