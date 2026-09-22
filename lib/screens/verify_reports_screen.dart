import 'package:flutter/material.dart';

import '../state/reportes_provider.dart';
import 'alerts_screen.dart';

class VerifyReportsScreen extends StatelessWidget {
  const VerifyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AlertsScreen(
      titulo: 'Verificar reportes',
      paginaActual: 'verificar',
      conChips: false,
      conVerMas: false,
      intro:
          'Estos reportes están cerca de ti y aún tienen pocas confirmaciones. Ábrelos y confirma o desmiente solo lo que hayas visto.',
      seleccionar: reportesPorVerificar,
    );
  }
}
