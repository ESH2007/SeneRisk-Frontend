import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum TipoHecho { bloqueo, protesta, incendio, agresion, vandalismo, desaparecida }

extension TipoHechoX on TipoHecho {
  String get etiqueta => switch (this) {
        TipoHecho.bloqueo => 'Bloqueo',
        TipoHecho.protesta => 'Protesta',
        TipoHecho.incendio => 'Incendio',
        TipoHecho.agresion => 'Agresión',
        TipoHecho.vandalismo => 'Vandalismo',
        TipoHecho.desaparecida => 'Persona desaparecida',
      };

  IconData get icono => switch (this) {
        TipoHecho.bloqueo => Icons.construction,
        TipoHecho.protesta => Icons.campaign_outlined,
        TipoHecho.incendio => Icons.local_fire_department_outlined,
        TipoHecho.agresion => Icons.back_hand_outlined,
        TipoHecho.vandalismo => Icons.format_paint_outlined,
        TipoHecho.desaparecida => Icons.person_search_outlined,
      };

  /// Rojo = riesgo a personas, ámbar = movilidad, azul = resto.
  Color get color => switch (this) {
        TipoHecho.agresion ||
        TipoHecho.incendio ||
        TipoHecho.desaparecida =>
          AppColors.red,
        TipoHecho.bloqueo => AppColors.amber,
        _ => AppColors.primary,
      };

  Color get colorSuave => switch (this) {
        TipoHecho.agresion ||
        TipoHecho.incendio ||
        TipoHecho.desaparecida =>
          AppColors.redSoft,
        TipoHecho.bloqueo => AppColors.amberSoft,
        _ => AppColors.blueSoft,
      };

  Color get colorCalor => switch (this) {
        TipoHecho.agresion ||
        TipoHecho.incendio ||
        TipoHecho.desaparecida =>
          AppColors.red,
        TipoHecho.bloqueo => AppColors.heatMid,
        _ => AppColors.heatLow,
      };
}
