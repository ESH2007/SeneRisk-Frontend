# senerisk_app

A new Flutter project.

# 1. servidor local (una vez por sesión)
cd tools/maps && MAPS_BASE_URL=http://127.0.0.1:8000 ./build_tiles.sh
mkdir -p out/20260920 && ln -f out/*.pmtiles out/20260920/
(cd out && python3 -m http.server 8000 &)

# 2. túnel USB (se pierde al desconectar el cable; repetir)
adb reverse tcp:8000 tcp:8000

# 3. app
cd ../../frontend
flutter run --profile --dart-define=MAPS_BASE_URL=http://127.0.0.1:8000

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
