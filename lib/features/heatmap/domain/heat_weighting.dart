import 'dart:math';

import '../data/risk_report.dart';

/// `peso = severidad × decaimiento(edad) × (1 + ln(1 + validaciones))`,
/// con decaimiento exponencial de vida media [halfLife].
class HeatWeighting {
  const HeatWeighting({this.halfLife = const Duration(days: 30)});

  final Duration halfLife;

  double weight(RiskReport r, DateTime now) {
    final age = now.difference(r.createdAt).inSeconds.clamp(0, 1 << 40);
    final decay = pow(0.5, age / halfLife.inSeconds).toDouble();
    return r.severity * decay * (1 + log(1 + r.validations));
  }
}
