#!/usr/bin/env bash
# Corre o compila la app SeneRisk Atlas con la configuración de mapas y backend.
#
#   tools/app.sh run [--local] [--mock] [--profile]   # en el teléfono/emulador conectado (hot reload)
#   tools/app.sh apk [--local] [--mock]               # APK release para instalar a mano
#   tools/app.sh install [...]                        # APK release + adb install en el dispositivo
#   tools/app.sh aab                                  # Android App Bundle para Play Store
#   tools/app.sh ios                                  # iOS (solo en macOS con Xcode)
#   tools/app.sh linux | web                          # escritorio Linux / web
#
#   --local    backend Django en este PC (arranca runserver + túnel adb reverse); por defecto Render
#   --mock     sin backend: datos de prueba en memoria (mapas sí, desde el bucket)
#   --profile  compila en modo profile (log PERF de frames en logcat)
#
# Variables (opcionales, tienen valor por defecto):
#   MAPS_BASE_URL  bucket público con manifest.json y los .pmtiles
#   API_BASE_URL   URL del backend, terminando en /api
#   HEAT_MOCK_POINTS  puntos mock del mapa de calor (solo con --mock)
set -euo pipefail
SCRIPT=$(readlink -f "$0")
cd "$(dirname "$SCRIPT")/.."   # raíz del repo frontend
FRONT=$PWD
BACK=$FRONT/../backend        # repo SeneRisk-Backend, clonado al lado

MAPS_BASE_URL=${MAPS_BASE_URL:-https://npeenpccsmsodyonhxzo.supabase.co/storage/v1/object/public/mapas}
API_BASE_URL=${API_BASE_URL:-https://senerisk-backend.onrender.com/api}
PUERTO_LOCAL=8001

cmd=${1:-}; shift || true
case $cmd in run|apk|install|aab|ios|linux|web) ;; *) sed -n '2,20p' "$SCRIPT"; exit 1 ;; esac
local=0 mock=0 modo=release
for a in "$@"; do
  case $a in
    --local) local=1 ;;
    --mock) mock=1 ;;
    --profile) modo=profile ;;
    *) echo "opción desconocida: $a" >&2; exit 1 ;;
  esac
done

adb_bin() { command -v adb || echo "$HOME/Android/Sdk/platform-tools/adb"; }

backend_local() {
  # Django contra Supabase (backend/.env) y túnel USB para que el teléfono lo vea en 127.0.0.1
  if ! curl -s -m 2 -o /dev/null "http://127.0.0.1:$PUERTO_LOCAL/api/reportes/"; then
    echo ">> arrancando backend en 127.0.0.1:$PUERTO_LOCAL"
    (cd "$BACK" && set -a && source .env && set +a && setsid nohup "$(command -v ./.venv/bin/python || command -v python3)" manage.py runserver 127.0.0.1:$PUERTO_LOCAL >/tmp/senerisk_backend.log 2>&1 </dev/null &)
    sleep 4
  fi
  "$(adb_bin)" reverse tcp:$PUERTO_LOCAL tcp:$PUERTO_LOCAL >/dev/null 2>&1 || true
  API_BASE_URL="http://127.0.0.1:$PUERTO_LOCAL/api"
}

(( local )) && backend_local
D=(--dart-define=MAPS_BASE_URL="$MAPS_BASE_URL")
if (( mock )); then
  D+=(--dart-define=MOCK=true --dart-define=HEAT_MOCK_POINTS="${HEAT_MOCK_POINTS:-1000}")
else
  D+=(--dart-define=API_BASE_URL="$API_BASE_URL")
fi
cd "$FRONT"
echo ">> flutter $cmd ${D[*]}"

case $cmd in
  run)
    flutter run --$modo "${D[@]}" ;;
  apk)
    flutter build apk --$modo "${D[@]}"
    echo ">> $FRONT/build/app/outputs/flutter-apk/app-$modo.apk" ;;
  install)
    flutter build apk --$modo "${D[@]}"
    "$(adb_bin)" install -r "build/app/outputs/flutter-apk/app-$modo.apk" ;;
  aab)
    flutter build appbundle --release "${D[@]}"
    echo ">> $FRONT/build/app/outputs/bundle/release/app-release.aab" ;;
  ios)
    [[ $(uname) == Darwin ]] || { echo "iOS solo se compila en macOS con Xcode" >&2; exit 1; }
    flutter build ipa --release "${D[@]}" ;;
  linux)
    flutter build linux --release "${D[@]}"
    echo ">> $FRONT/build/linux/x64/release/bundle/" ;;
  web)
    flutter build web --release "${D[@]}"
    echo ">> $FRONT/build/web/" ;;
  *)
    sed -n '2,20p' "$0"; exit 1 ;;
esac
