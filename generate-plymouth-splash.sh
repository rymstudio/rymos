#!/bin/bash
#
# generate-plymouth-splash.sh
# RymStudio / RymOS - prepara un'immagine come bootscreen Plymouth (bback.png)
#
# Prende un'immagine scelta dall'utente e la converte nel formato atteso dal
# tema Plymouth 'rymos': PNG 8 bit per canale, RGB, senza canale alpha,
# 1920x1080 (dimensioni configurabili). Il tema (rymos.script) scala poi
# l'immagine a copertura dello schermo, qualunque sia la risoluzione reale.
#
# Requisiti: ImageMagick (comando 'magick' oppure 'convert' + 'identify')
#
# Uso:
#   ./generate-plymouth-splash.sh --input immagine.png [opzioni]
#
# Opzioni:
#   --input <file>      Immagine sorgente (obbligatorio). Qualsiasi formato letto da ImageMagick.
#   --output <file>     File PNG di destinazione
#                       (default: config/includes.chroot/usr/share/plymouth/themes/rymos/bback.png)
#   --mode <fill|fit>   fill = riempie tutto il fotogramma ritagliando i bordi eccedenti (default)
#                       fit  = mostra l'immagine intera, con bande di colore ai lati se serve
#   --bg <colore>       Colore delle bande in modalita' fit e dello sfondo per le trasparenze
#                       (default: #182638, lo stesso colore di fondo del tema)
#   --size <LxA>        Dimensioni di output (default: 1920x1080)
#   -h, --help          Mostra questo aiuto
#
set -e

# ---------- Default ----------
INPUT=""
OUTPUT="config/includes.chroot/usr/share/plymouth/themes/rymos/bback.png"
MODE="fill"
BG="#182638"
SIZE="1920x1080"

# ---------- Parsing argomenti ----------
while [ $# -gt 0 ]; do
	case "$1" in
		--input) INPUT="$2"; shift 2 ;;
		--output) OUTPUT="$2"; shift 2 ;;
		--mode) MODE="$2"; shift 2 ;;
		--bg) BG="$2"; shift 2 ;;
		--size) SIZE="$2"; shift 2 ;;
		-h|--help)
			sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		*)
			echo "Argomento sconosciuto: $1" >&2
			exit 1
			;;
	esac
done

# ---------- Rilevamento ImageMagick (v7 'magick' oppure v6 'convert') ----------
if command -v magick >/dev/null 2>&1; then
	IM_CONVERT="magick"
	IM_IDENTIFY="magick identify"
elif command -v convert >/dev/null 2>&1 && command -v identify >/dev/null 2>&1; then
	IM_CONVERT="convert"
	IM_IDENTIFY="identify"
else
	echo "Errore: ImageMagick non trovato (serve 'magick' oppure 'convert' + 'identify')." >&2
	exit 1
fi

# ---------- Verifica argomenti ----------
if [ -z "$INPUT" ]; then
	echo "Errore: --input e' obbligatorio." >&2
	echo "Uso: $0 --input immagine.png [opzioni]" >&2
	exit 1
fi

if [ ! -f "$INPUT" ]; then
	echo "Errore: file non trovato: $INPUT" >&2
	exit 1
fi

case "$MODE" in
	fill|fit) ;;
	*)
		echo "Errore: --mode deve essere 'fill' oppure 'fit' (ricevuto: $MODE)." >&2
		exit 1
		;;
esac

if ! echo "$SIZE" | grep -Eq '^[0-9]+x[0-9]+$'; then
	echo "Errore: --size deve avere il formato LARGHEZZAxALTEZZA, es. 1920x1080 (ricevuto: $SIZE)." >&2
	exit 1
fi

# ---------- Informazioni sull'immagine sorgente ----------
_SRC_INFO="$($IM_IDENTIFY -format '%wx%h' "${INPUT}[0]" 2>/dev/null || true)"
if [ -z "$_SRC_INFO" ]; then
	echo "Errore: ImageMagick non riesce a leggere '$INPUT'." >&2
	exit 1
fi
echo "==> Sorgente: $INPUT ($_SRC_INFO)"

# ---------- Conversione ----------
mkdir -p "$(dirname "$OUTPUT")"

if [ "$MODE" = "fill" ]; then
	echo "==> Modalita' fill: riempio ${SIZE}, ritaglio centrato dei bordi eccedenti..."
	$IM_CONVERT "${INPUT}[0]" \
		-background "$BG" -alpha remove -alpha off \
		-resize "${SIZE}^" -gravity center -extent "$SIZE" \
		-colorspace sRGB -depth 8 -strip \
		"PNG24:$OUTPUT"
else
	echo "==> Modalita' fit: immagine intera in ${SIZE}, bande colore ${BG}..."
	$IM_CONVERT "${INPUT}[0]" \
		-background "$BG" -alpha remove -alpha off \
		-resize "$SIZE" -gravity center -extent "$SIZE" \
		-colorspace sRGB -depth 8 -strip \
		"PNG24:$OUTPUT"
fi

# ---------- Verifica del risultato ----------
_OUT_INFO="$($IM_IDENTIFY -format '%wx%h, %z bit, tipo %[type], alpha: %A' "$OUTPUT")"
echo "==> Scritto: $OUTPUT"
echo "==> Risultato: $_OUT_INFO"
echo "==> Dimensione file: $(du -h "$OUTPUT" | cut -f1)"

# ---------- Controllo che il tema usi davvero questo file ----------
_THEME_DIR="$(dirname "$OUTPUT")"
if [ -f "$_THEME_DIR/rymos.script" ]; then
	if ! grep -q 'Image("bback.png")' "$_THEME_DIR/rymos.script"; then
		echo "" >&2
		echo "Attenzione: $_THEME_DIR/rymos.script non sembra caricare 'bback.png'." >&2
		echo "L'immagine e' stata creata, ma il tema potrebbe non mostrarla." >&2
	fi
fi

echo ""
echo "Prossimo passo: rilancia la build (sudo /home/rymos-dev/rymos-build/build.sh)."
