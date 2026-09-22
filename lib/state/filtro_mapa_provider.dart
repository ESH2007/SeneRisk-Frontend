import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "todos" | "bloqueo" | "protesta" | "incendio" | "agresion".
class FiltroMapaNotifier extends Notifier<String> {
  @override
  String build() => 'todos';

  void set(String filtro) => state = filtro;
}

final filtroMapaProvider =
    NotifierProvider<FiltroMapaNotifier, String>(FiltroMapaNotifier.new);
