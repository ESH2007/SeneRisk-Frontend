import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_reportes.dart';

class BusquedasRecientesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => List.of(busquedasRecientesIniciales);

  void agregar(String texto) =>
      state = [texto, ...state.where((s) => s != texto)];

  void quitar(int i) => state = [...state]..removeAt(i);

  void limpiar() => state = [];
}

final busquedasRecientesProvider =
    NotifierProvider<BusquedasRecientesNotifier, List<String>>(
        BusquedasRecientesNotifier.new);
