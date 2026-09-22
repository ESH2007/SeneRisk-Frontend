# SeneRisk Atlas

App Flutter de reportes y mapa de riesgo para Colombia: mapa vectorial offline (PMTiles + MapLibre),
mapa de calor y reportes ciudadanos. Backend en
[SeneRisk-Backend](https://github.com/ESH2007/SeneRisk-Backend).

## Instalación

**[INSTALL.md](INSTALL.md)** — guía paso a paso: clonar los dos repos, backend Django,
Supabase (opcional), mapas y compilación para Android, iOS, Web, Windows y macOS.

Arranque rápido (sin backend, datos de prueba):

```sh
flutter pub get
flutter run --dart-define=MAPS_BASE_URL=https://npeenpccsmsodyonhxzo.supabase.co/storage/v1/object/public/mapas
```
