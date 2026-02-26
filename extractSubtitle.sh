#!/usr/bin/env bash

set -euo pipefail

LIST_ONLY=false
LANG_FILTER="${1:-}"

check_dependencies() {
  local missing=0
  local deps=("ffmpeg" "ffprobe" "jq" "find" "xargs")

  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "[-] Error: '$cmd' no está instalado o no está en el PATH."
      missing=1
    fi
  done

  if [[ "$missing" -eq 1 ]]; then
    echo
    echo "Instala las dependencias faltantes antes de continuar."
    exit 1
  fi
}

check_dependencies

usage() {
  echo "Uso:"
  echo "  $0 [idiomas]"
  echo "  $0 -l"
  echo
  echo "Ejemplos:"
  echo "  $0 eng,spa"
  echo "  $0"
  echo "  $0 -l"
  exit 1
}

while getopts ":lh" opt; do
  case $opt in
    l) LIST_ONLY=true ;;
    h) usage ;;
    *) usage ;;
  esac
done

shift $((OPTIND -1))

LANG_FILTER="${1:-}"
LANG_FILTER=$(echo "$LANG_FILTER" | tr 'A-Z' 'a-z')

VIDEO_EXTENSIONS="mkv mp4 mov avi webm"

find_videos() {
  for ext in $VIDEO_EXTENSIONS; do
    find . -maxdepth 1 -type f -iname "*.${ext}"
  done
}

process_file() {
  INPUT="$1"
  BASENAME="$(basename "$INPUT")"
  NAME="${BASENAME%.*}"
  OUTDIR="${NAME}_subs"

  TMP_JSON="$(mktemp)"

  ffprobe -v error -select_streams s -show_streams -of json "$INPUT" > "$TMP_JSON"

  SUB_COUNT=$(jq '.streams | length' "$TMP_JSON")

  if [[ "$SUB_COUNT" -eq 0 ]]; then
    rm -f "$TMP_JSON"
    return
  fi

  echo
  echo "[+] Archivo: $INPUT"

  if $LIST_ONLY || [[ -z "$LANG_FILTER" ]]; then
    echo "Subtítulos disponibles:"
    jq -r '.streams[] | "Index: \(.index)\tCodec: \(.codec_name)\tLang: \(.tags.language // "unknown")\tTitle: \(.tags.title // "subtitle")"' "$TMP_JSON"
    rm -f "$TMP_JSON"
    return
  fi

  mkdir -p "$OUTDIR"

  export INPUT NAME OUTDIR LANG_FILTER TMP_JSON

  jq -r '.streams[].index' "$TMP_JSON" |
  xargs -P 4 -n 1 bash -c '
    idx="$1"
    [[ -z "$idx" ]] && exit 0

    stream=$(jq -c ".streams[] | select(.index == ($idx|tonumber))" "$TMP_JSON") || exit 0

    codec=$(jq -r ".codec_name" <<<"$stream")
    lang=$(jq -r ".tags.language // \"\"" <<<"$stream" | tr "A-Z" "a-z")
    title=$(jq -r ".tags.title // \"subtitle\"" <<<"$stream")

    if [[ -n "$LANG_FILTER" ]]; then
      [[ -z "$lang" ]] && exit 0
      echo ",$LANG_FILTER," | grep -q ",$lang," || exit 0
    fi

    safe=$(echo "$title" | tr " /()" "____")

    case "$codec" in
      hdmv_pgs_subtitle) ext="sup" ;;
      subrip) ext="srt" ;;
      ass|ssa) ext="ass" ;;
      *) exit 0 ;;
    esac

    out="$OUTDIR/${NAME}_s${idx}_${lang}_${safe}.${ext}"

    echo "[+] Extrayendo #$idx [$lang] $title"

    ffmpeg -nostdin -loglevel error -y -i "$INPUT" -map 0:${idx} -c copy "$out"
  ' _

  rm -f "$TMP_JSON"
}

echo "[+] Buscando archivos de video..."

VIDEOS=$(find_videos)

if [[ -z "$VIDEOS" ]]; then
  echo "[-] No se encontraron videos en el directorio actual."
  exit 0
fi

for vid in $VIDEOS; do
  process_file "$vid"
done

echo
echo "[+] Proceso finalizado."
