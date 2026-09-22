#!/usr/bin/env bash
# Extrae los PMTiles de Colombia (base) y de cada región desde el build diario de Protomaps.
# Uso: ./build_tiles.sh [--national-detail]
# Requiere: pmtiles (go-pmtiles), jq, sha256sum. Variables: MAPS_BASE_URL (plantilla de URL del bucket).
set -euo pipefail
cd "$(dirname "$0")"

for t in pmtiles jq sha256sum; do command -v "$t" >/dev/null || { echo "falta $t" >&2; exit 1; }; done

NATIONAL=0; [[ "${1:-}" == "--national-detail" ]] && NATIONAL=1
MAPS_BASE_URL="${MAPS_BASE_URL:-https://maps.example.com/tiles}"
CFG=regions.json; OUT=out
BUILD=$(jq -r .build $CFG); SCHEMA=$(jq -r .schema $CFG)
SRC="https://build.protomaps.com/$BUILD.pmtiles"
DMIN=$(jq -r .detail_zoom.min $CFG); DMAX=$(jq -r .detail_zoom.max $CFG)
mkdir -p $OUT
entries=()

# extract <id> <name> <bbox-json> <minzoom> <maxzoom> [--region=file | --bbox=a,b,c,d]
extract() {
  local id=$1 name=$2 bbox=$3 minz=$4 maxz=$5 sel=$6; local f="$OUT/$id.pmtiles"
  if [[ -f "$f" ]]; then echo ">> $id ya existe, se omite (borra $f para regenerar)"; else
    echo ">> $id z$minz-$maxz"; pmtiles extract "$SRC" "$f" "$sel" --minzoom="$minz" --maxzoom="$maxz" -q
  fi
  pmtiles show "$f" >/dev/null   # falla si el archivo está corrupto
  local bytes sha; bytes=$(stat -c %s "$f"); sha=$(sha256sum "$f" | cut -d' ' -f1)
  entries+=("$(jq -nc --arg id "$id" --arg name "$name" --argjson bbox "$bbox" --argjson minz "$minz" --argjson maxz "$maxz" \
    --argjson bytes "$bytes" --arg sha "$sha" --arg build "$BUILD" --arg schema "$SCHEMA" --arg url "$MAPS_BASE_URL/$BUILD/$id.pmtiles" \
    '{id:$id,name:$name,bbox:$bbox,minzoom:$minz,maxzoom:$maxz,bytes:$bytes,sha256:$sha,build:$build,schema:$schema,url:$url}')")
}

b=$(jq -c .base $CFG)
extract "$(jq -r .id <<<"$b")" "$(jq -r .name <<<"$b")" "$(jq -c .bbox <<<"$b")" "$(jq -r .minzoom <<<"$b")" "$(jq -r .maxzoom <<<"$b")" \
  "--region=$(jq -r .region <<<"$b")"
base_entry=${entries[0]}; entries=()

# Partes extra de la base (p. ej. z12 aparte para no superar 50 MB por archivo en Supabase).
base_parts="[]"
if [[ $(jq 'has("base_extra")' $CFG) == true ]]; then
  b=$(jq -c .base_extra $CFG)
  extract "$(jq -r .id <<<"$b")" "$(jq -r .name <<<"$b")" "$(jq -c .bbox <<<"$b")" "$(jq -r .minzoom <<<"$b")" "$(jq -r .maxzoom <<<"$b")" \
    "--region=$(jq -r .region <<<"$b")"
  base_parts=$(printf '%s\n' "${entries[@]}" | jq -s .); entries=()
fi

while IFS= read -r r; do
  extract "$(jq -r .id <<<"$r")" "$(jq -r .name <<<"$r")" "$(jq -c .bbox <<<"$r")" "$DMIN" "$DMAX" "--bbox=$(jq -r '.bbox|join(",")' <<<"$r")"
done < <(jq -c '.regions[]' $CFG)

national="null"
if (( NATIONAL )); then
  extract colombia_detail "Colombia (detalle remoto)" "$(jq -c .base.bbox $CFG)" "$DMIN" "$DMAX" "--region=$(jq -r .base.region $CFG)"
  national=${entries[-1]}; unset 'entries[-1]'
fi

jq -nS --arg build "$BUILD" --arg schema "$SCHEMA" --argjson base "$base_entry" --argjson base_parts "$base_parts" --argjson national "$national" \
  --argjson regions "$(printf '%s\n' "${entries[@]}" | jq -s .)" \
  '{build:$build,schema:$schema,base:$base,base_parts:$base_parts,regions:$regions,national_detail:$national}' > $OUT/manifest.json

echo; printf "%-18s %-8s %10s\n" archivo zooms tamaño
jq -r '[.base] + .base_parts + .regions + ([.national_detail]|map(select(.!=null))) | .[] | "\(.id)\t\(.minzoom)-\(.maxzoom)\t\(.bytes)"' $OUT/manifest.json \
  | awk -F'\t' '{printf "%-18s %-8s %8.1f MB\n", $1, $2, $3/1048576}'
