# Guía de instalación — SeneRisk Atlas

Paso a paso para dejar la app corriendo desde cero: los dos repositorios, el backend Django,
Supabase (opcional) y los mapas, con los comandos de compilación para **Android, iOS, Web,
Windows y macOS**.

La app son dos repos separados:

| Repo | Qué es | Carpeta local sugerida |
|---|---|---|
| [SeneRisk-Frontend](https://github.com/ESH2007/SeneRisk-Frontend) | App Flutter (mapa, reportes, mapa de calor) | `SeneRisk/frontend` |
| [SeneRisk-Backend](https://github.com/ESH2007/SeneRisk-Backend) | API Django + DRF sobre Postgres/PostGIS | `SeneRisk/backend` |

La app **funciona sin backend** (modo mock, datos de prueba) y **los mapas se descargan de un
bucket público**, así que el camino corto es: instalar Flutter → clonar → `flutter run`.

---

## 1. Requisitos

### Comunes

| Herramienta | Versión | Para qué |
|---|---|---|
| [Flutter](https://docs.flutter.dev/get-started/install) | **3.29 o superior** (Dart 3.13+) | La app |
| [Git](https://git-scm.com/downloads) | cualquiera | Clonar |
| JDK **21** | solo para compilar Android | Lo instala Android Studio |
| [Python](https://www.python.org/downloads/) | **3.12+** | Solo si vas a correr el backend |

Comprueba Flutter antes de seguir:

```sh
flutter doctor
```

Cada ✗ que aparezca para la plataforma que te interesa hay que resolverlo (Flutter dice cómo).

### Por sistema operativo

**Windows**
1. Flutter: descomprime el SDK en `C:\src\flutter` y agrega `C:\src\flutter\bin` al `PATH`.
2. Android: [Android Studio](https://developer.android.com/studio) → *SDK Manager* → instala
   *Android SDK Platform-Tools* y *Android SDK Command-line Tools*; luego `flutter doctor --android-licenses`.
3. Desktop Windows: *Visual Studio 2022* con la carga de trabajo **"Desarrollo para el escritorio con C++"**.
4. Backend: Python desde python.org marcando *Add to PATH*, y **[OSGeo4W](https://trac.osgeo.org/osgeo4w/)**
   para GDAL/GEOS (Django GIS los necesita). Ver la nota de Windows en el paso 4.

**macOS**
```sh
brew install --cask flutter android-studio
brew install python@3.12 gdal geos libspatialite   # los tres últimos solo si corres el backend
sudo xcode-select --install                        # herramientas de línea de comandos
```
Para iOS además: Xcode completo desde la App Store y `sudo xcodebuild -runFirstLaunch`.

**Linux (Arch / Debian)**
```sh
# Arch
sudo pacman -S flutter jdk21-openjdk python gdal geos libspatialite
# Debian/Ubuntu (Flutter con snap)
sudo snap install flutter --classic
sudo apt install openjdk-21-jdk python3-venv gdal-bin libgdal-dev libgeos-dev libsqlite3-mod-spatialite
```

---

## 2. Descargar los dos repos (un solo comando)

**macOS / Linux / Git Bash**
```sh
mkdir SeneRisk && cd SeneRisk && git clone https://github.com/ESH2007/SeneRisk-Frontend.git frontend && git clone https://github.com/ESH2007/SeneRisk-Backend.git backend
```

**Windows (PowerShell)**
```powershell
mkdir SeneRisk; cd SeneRisk; git clone https://github.com/ESH2007/SeneRisk-Frontend.git frontend; git clone https://github.com/ESH2007/SeneRisk-Backend.git backend
```

Queda así:

```
SeneRisk/
├── frontend/   ← app Flutter + tools/ (scripts de mapas y compilación)
└── backend/    ← API Django
```

> El repo frontend incluye los mapas ya generados (`tools/maps/out/`, ~190 MB), así que el clon
> pesa. Si solo vas a compilar la app, añade `--depth 1` a los `git clone` para bajar únicamente
> la última versión.

Instala las dependencias de la app:

```sh
cd frontend && flutter pub get
```

### Primera prueba (sin backend, 2 minutos)

```sh
flutter run --dart-define=MAPS_BASE_URL=https://npeenpccsmsodyonhxzo.supabase.co/storage/v1/object/public/mapas
```

Sin `API_BASE_URL` la app entra en **modo mock**: reportes de prueba en memoria, pero mapas reales.
Si esto funciona, lo demás es opcional.

---

## 3. Configuración de la app: las tres variables

Todo se pasa con `--dart-define` al compilar (no hay archivo de configuración):

| Variable | Qué es | Por defecto |
|---|---|---|
| `MAPS_BASE_URL` | Bucket público con `manifest.json` y los `.pmtiles` | `https://maps.example.com/tiles` (inválido: **siempre pásala**) |
| `API_BASE_URL` | URL del backend, **terminada en `/api`** | vacío = modo mock |
| `HEAT_MOCK_POINTS` | Puntos falsos del mapa de calor (solo en modo mock) | `1000` |

Ejemplo completo:

```sh
flutter run \
  --dart-define=MAPS_BASE_URL=https://npeenpccsmsodyonhxzo.supabase.co/storage/v1/object/public/mapas \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

> En PowerShell usa una sola línea (sin `\`) o acento grave `` ` `` para continuar.

### El atajo: `tools/app.sh`

El repo trae un script que ya pone las variables por ti (bash: macOS, Linux o **Git Bash** en Windows):

```sh
tools/app.sh run            # correr con hot reload, backend desplegado (API_BASE_URL)
tools/app.sh run --mock     # sin backend: datos de prueba, mapas reales
tools/app.sh run --local    # arranca el Django de ../backend y hace el túnel adb solo
tools/app.sh apk --mock     # APK release
tools/app.sh install        # APK release + adb install
tools/app.sh aab            # bundle para Play Store
tools/app.sh ios | linux | web
```

Flags: `--local` (backend en este PC), `--mock` (sin backend), `--profile` (compila en profile con
log de frames). Variables opcionales: `MAPS_BASE_URL`, `API_BASE_URL`, `HEAT_MOCK_POINTS`.
`--local` espera el repo backend clonado al lado (`../backend`) con su `.venv` y su `.env`.

---

## 4. Backend (opcional)

Sin Supabase el backend corre con **SQLite + SpatiaLite** en tu equipo; es suficiente para desarrollo.

```sh
cd backend
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env             # Windows: copy .env.example .env
```

Edita `.env` y, si **no** vas a usar Supabase, deja comentadas (`#`) las líneas `DATABASE_URL`,
`SUPABASE_S3_*`. Cambia `DJANGO_SECRET_KEY`.

Carga las variables y arranca:

```sh
set -a; source .env; set +a          # Windows PowerShell: ver nota abajo
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 127.0.0.1:8000
```

Prueba: <http://127.0.0.1:8000/admin/> y <http://127.0.0.1:8000/api/reportes/>.

<details>
<summary>Windows: cargar el .env y GDAL</summary>

```powershell
Get-Content .env | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
  $k,$v = $_ -split '=',2; [Environment]::SetEnvironmentVariable($k,$v)
}
```

Django GIS necesita GDAL/GEOS. Con OSGeo4W instalado, agrega al entorno antes de `manage.py`:

```powershell
$env:GDAL_LIBRARY_PATH="C:\OSGeo4W\bin\gdal310.dll"   # ajusta el número de versión
$env:GEOS_LIBRARY_PATH="C:\OSGeo4W\bin\geos_c.dll"
$env:PATH="C:\OSGeo4W\bin;$env:PATH"
```

Para SQLite local además hace falta `mod_spatialite.dll` (viene en OSGeo4W) y
`SPATIALITE_LIBRARY_PATH=mod_spatialite.dll`. Si esto se complica, usa Supabase (paso 5):
con Postgres/PostGIS ya no necesitas SpatiaLite.
</details>

### Conectar la app al backend

| Dónde corre la app | `API_BASE_URL` | Extra |
|---|---|---|
| Emulador Android | `http://10.0.2.2:8000/api` | — |
| Teléfono Android por USB | `http://127.0.0.1:8000/api` | `adb reverse tcp:8000 tcp:8000` (repetir al reconectar) |
| Simulador iOS / escritorio / web | `http://127.0.0.1:8000/api` | — |
| Teléfono en la misma WiFi | `http://<IP-de-tu-PC>:8000/api` | `runserver 0.0.0.0:8000` y añade la IP a `DJANGO_ALLOWED_HOSTS` |

---

## 5. Supabase (opcional)

Da Postgres con PostGIS, almacenamiento de fotos y hosting de los mapas.

1. Crea un proyecto en <https://supabase.com> (plan gratis sirve).
2. **PostGIS**: *SQL Editor* → `create extension if not exists postgis;`
3. **URL de la base**: *Connect* → **Session pooler** (IPv4). Cópiala a `DATABASE_URL` en `.env`,
   codificando los caracteres raros de la contraseña (`@` → `%40`).
4. **Buckets** (*Storage* → *New bucket*, ambos **públicos**):
   - `media` → fotos de los reportes.
   - `mapas` → los archivos `.pmtiles` y el `manifest.json`.
5. **Llaves S3**: *Project Settings* → *Storage* → *S3 access keys* → crea una y llena en `.env`:
   `SUPABASE_S3_ENDPOINT` (`https://<proyecto>.supabase.co/storage/v1/s3`),
   `SUPABASE_S3_ACCESS_KEY`, `SUPABASE_S3_SECRET_KEY`.
6. Vuelve a cargar `.env` y corre `python manage.py migrate` (ahora sobre Postgres).

Las variables mandan solas: **con** `DATABASE_URL` usa Postgres, **sin** ella SQLite; **con**
`SUPABASE_S3_ACCESS_KEY` las fotos van al bucket, **sin** ella a `backend/media/`.

---

## 6. Mapas

Los mapas son vectoriales y offline: archivos **PMTiles** en un bucket público que la app descarga
al dispositivo (base de Colombia ~70 MB al primer inicio, y cada ciudad bajo demanda desde
*Configuración → Mapas sin conexión*). La app lee `MAPS_BASE_URL/manifest.json` para saber qué hay.

### Opción A — usar el bucket ya publicado (recomendado)

No configuras nada: compila con

```
--dart-define=MAPS_BASE_URL=https://npeenpccsmsodyonhxzo.supabase.co/storage/v1/object/public/mapas
```

### Opción B — servir los mapas desde tu PC (sin internet ni Supabase)

Los archivos ya vienen en el repo, en `tools/maps/out/` (`manifest.json` + carpeta `20260920/` con
los `.pmtiles`). Solo hay que apuntar el manifest a tu servidor y levantarlo:

```sh
cd tools/maps/out
sed -i 's|https://npeenpccsmsodyonhxzo.supabase.co/storage/v1/object/public/mapas|http://10.0.2.2:8000|g' manifest.json
python3 -m http.server 8000
```

Usa `http://10.0.2.2:8000` para el emulador Android, o `http://127.0.0.1:8000` con
`adb reverse tcp:8000 tcp:8000` para un teléfono por USB (y para escritorio/web). Luego compila con
`--dart-define=MAPS_BASE_URL=` a esa misma URL. No subas el `manifest.json` modificado al repo
(`git checkout tools/maps/out/manifest.json` para revertirlo).

### Opción C — publicar tus propios mapas en tu bucket

Necesitas el bucket público `mapas` (paso 5) y esta estructura:

```
<MAPS_BASE_URL>/manifest.json
<MAPS_BASE_URL>/20260920/colombia.pmtiles
<MAPS_BASE_URL>/20260920/colombia_z12.pmtiles
<MAPS_BASE_URL>/20260920/bogota_sabana.pmtiles
...
```

Con los archivos que ya están en `tools/maps/out/` basta con regenerar el manifest apuntando a tu
bucket (mismo `sed` de la opción B, con tu URL) y subirlos:

```sh
cd ../backend && set -a; source .env; set +a      # llaves S3 de Supabase
python ../frontend/tools/maps/upload_supabase.py  # sube out/ al bucket `mapas`
```

Para **regenerar los tiles** (otra fecha de datos, otra ciudad) necesitas `jq`, `sha256sum` y el CLI
[pmtiles](https://github.com/protomaps/go-pmtiles/releases). `build_tiles.sh` recorta los datos de
[build.protomaps.com](https://build.protomaps.com/) según `tools/maps/regions.json` y escribe el
`manifest.json` ya con las URLs correctas:

```sh
cd tools/maps
MAPS_BASE_URL=https://<proyecto>.supabase.co/storage/v1/object/public/mapas ./build_tiles.sh
```

- Agregar una ciudad: una entrada más en `regions.json`
  (`{ "id": "pereira", "name": "Pereira y Dosquebradas", "bbox": [-75.78, 4.75, -75.62, 4.88] }`,
  `bbox` = `[minLng, minLat, maxLng, maxLat]`) y correr el script; aparece sola en la app.
- El script omite los archivos que ya existen en `out/`: borra el que quieras rehacer.
- El estilo del mapa (`assets/maps/light_v4.json`) se regenera con
  `cd tools/maps && npm i @protomaps/basemaps && node gen_style.mjs > ../../assets/maps/light_v4.json`.

Notas:
- El plan gratis de Supabase limita cada archivo a **50 MB**: por eso la base va partida en
  `colombia` (z0–11, 30 MB) y `colombia_z12` (40 MB).
- La app **descarga los archivos completos** al dispositivo, así que cualquier servidor estático
  sirve. Solo el modo opcional "calles por internet" (archivo nacional z13–15) lee por `Range`, y
  eso sí exige un servidor que lo soporte: Supabase Storage sí, `python3 -m http.server` **no**.

### Permisos

La ubicación ya está declarada en Android (`ACCESS_FINE_LOCATION`) e iOS
(`NSLocationWhenInUseUsageDescription`). No hay que tocar nada, y no se necesita ninguna API key:
MapLibre no usa cuenta.

---

## 7. Compilar por plataforma

Define primero las variables una sola vez (ejemplos con el bucket público y el backend local):

```sh
D="--dart-define=MAPS_BASE_URL=https://npeenpccsmsodyonhxzo.supabase.co/storage/v1/object/public/mapas --dart-define=API_BASE_URL=http://10.0.2.2:8000/api"
```

(En PowerShell no uses `$D`: pega las dos `--dart-define=…` completas en cada comando.)

Cada bloque de abajo tiene su atajo con `tools/app.sh` (`run`, `apk`, `install`, `aab`, `ios`,
`linux`, `web`), que pone las variables solo.

### Android  ✅ mapa completo
```sh
flutter run $D                 # dispositivo/emulador conectado, con hot reload
flutter build apk --release $D # → build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release $D   # → .aab para Play Store
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
Requiere JDK 21 y Android 5.0 (API 21) o superior en el dispositivo.

### iOS  ✅ mapa completo *(solo desde macOS)*
```sh
cd ios && pod install && cd ..     # la primera vez
flutter run $D                     # simulador o dispositivo
flutter build ipa --release $D     # → build/ios/ipa/
```
Objetivo mínimo iOS 15. Para dispositivo físico: abre `ios/Runner.xcworkspace` en Xcode y
selecciona tu *Team* en *Signing & Capabilities*.

### Web  ✅ mapa completo
```sh
flutter build web --release $D     # → build/web/
flutter run -d chrome $D           # desarrollo
```
No hay que tocar `web/index.html`. Necesita un navegador con WebGL2 (Safari 15+, Chrome/Firefox
actuales). Sírvelo con cualquier servidor estático:
```sh
cd build/web && python3 -m http.server 8080
```
Si llamas a un backend en otro dominio, deja `DJANGO_DEBUG=1` (CORS abierto) o configura
`django-cors-headers` para producción.

### Windows (escritorio)  ⚠️ sin mapa
```powershell
flutter build windows --release $D   # → build\windows\x64\runner\Release\
flutter run -d windows $D
```

### macOS (escritorio)  ⚠️ sin mapa
```sh
flutter build macos --release $D     # → build/macos/Build/Products/Release/
```

> **Límite conocido:** el plugin `maplibre_gl` solo soporta **Android, iOS y Web**. En escritorio
> (Windows, macOS, Linux) la app compila y corre, pero la pantalla del mapa no se renderiza.
> El escritorio sirve para probar el resto de la interfaz, no para el mapa.

---

## 8. Problemas comunes

| Síntoma | Causa / arreglo |
|---|---|
| El mapa sale gris y no descarga nada | Faltó `--dart-define=MAPS_BASE_URL=…`; el valor por defecto (`maps.example.com`) no existe |
| "Descarga esta zona para ver calles sin conexión" | Normal a zoom ≥ 13: descarga la región en *Configuración → Mapas sin conexión* |
| La app no ve el backend en el emulador | Usa `10.0.2.2` en vez de `127.0.0.1` |
| La app no ve el backend en el teléfono USB | Falta `adb reverse tcp:8000 tcp:8000` (se pierde al desconectar el cable) |
| `DisallowedHost` en Django | Añade el host a `DJANGO_ALLOWED_HOSTS` en `.env` |
| `Could not find the GDAL library` | Instala GDAL/GEOS y, en Windows, define `GDAL_LIBRARY_PATH`/`GEOS_LIBRARY_PATH` |
| `UnableToLoadExtension` / SpatiaLite | Instala `libspatialite` (`mod_spatialite`) o pásate a Supabase |
| `413` al subir un `.pmtiles` | Archivo > 50 MB: el plan gratis de Supabase no lo permite, pártelo |
| `flutter build apk` falla por Java | Usa JDK 21: `flutter config --jdk-dir <ruta>` |
| El clon tarda muchísimo | El repo trae los mapas (~190 MB): usa `git clone --depth 1` |
| `tools/app.sh --local` no encuentra el backend | Espera `../backend` con `.venv` y `.env` (paso 4) |
