import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_reportes.dart';

/// Ubicación real si hay permiso; si no, la simulada. Se evalúa una sola vez.
final ubicacionUsuarioProvider = FutureProvider<LatLng>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return ubicacionSimulada;
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return ubicacionSimulada;
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 8));
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return ubicacionSimulada;
  }
});

/// Verdadero solo cuando la ubicación proviene del GPS.
final tienePermisoUbicacionProvider = Provider<bool>((ref) {
  final ubic = ref.watch(ubicacionUsuarioProvider).value;
  return ubic != null && ubic != ubicacionSimulada;
});
