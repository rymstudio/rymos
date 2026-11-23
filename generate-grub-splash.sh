#!/bin/bash
#
# generate-grub-splash.sh
# RymStudio / RymOS - generatore automatico dello splash.svg per GRUB (live-build)
#
# Replica il procedimento manuale: prende un'immagine di sfondo e un logo,
# li ridimensiona/converte, li incorpora in base64 e compone l'SVG finale
# con i placeholder live-build (@LB_ISO_APPLICATION@, @VERSION@, @ARCHITECTURE@, ecc.)
#
# Requisiti: ImageMagick (convert/identify), base64 (coreutils)
#
# Uso:
#   ./generate-grub-splash.sh --background sfondo.png --logo logo.png [opzioni]
#
# Opzioni:
#   --background <file>   Immagine di sfondo (obbligatorio). Qualsiasi formato letto da ImageMagick.
#   --logo <file>          Logo con canale alpha, PNG consigliato (obbligatorio).
#   --output <file>        Percorso file SVG di output (default: config/bootloaders/splash.svg)
#   --codename <testo>     Codename da mostrare al posto di @DISTRIBUTION@ (default: Aurora)
#   --accent-color <hex>   Colore titolo/accento (default: #fdf188)
#   --panel-color <hex>    Colore pannello semitrasparente dietro il menu (default: #2c3e50)
#   -h, --help              Mostra questo aiuto
#
set -e

# ---------- Default ----------
OUTPUT="config/bootloaders/splash.svg"
CODENAME="Aurora"
ACCENT_COLOR="#fdf188"
PANEL_COLOR="#2c3e50"
BACKGROUND=""
LOGO=""

# ---------- Parsing argomenti ----------
while [ $# -gt 0 ]; do
	case "$1" in
		--background) BACKGROUND="$2"; shift 2 ;;
		--logo) LOGO="$2"; shift 2 ;;
		--output) OUTPUT="$2"; shift 2 ;;
		--codename) CODENAME="$2"; shift 2 ;;
		--accent-color) ACCENT_COLOR="$2"; shift 2 ;;
		--panel-color) PANEL_COLOR="$2"; shift 2 ;;
		-h|--help)
			sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		*)
			echo "Argomento sconosciuto: $1" >&2
			exit 1
			;;
	esac
done

# ---------- Verifica dipendenze ----------
for _CMD in convert identify base64; do
	if ! command -v "$_CMD" >/dev/null 2>&1; then
		echo "Errore: '$_CMD' non trovato. Installa imagemagick (e coreutils)." >&2
		exit 1
	fi
done

# ---------- Verifica argomenti obbligatori ----------
if [ -z "$BACKGROUND" ] || [ -z "$LOGO" ]; then
	echo "Errore: --background e --logo sono obbligatori." >&2
	echo "Uso: $0 --background sfondo.png --logo logo.png [opzioni]" >&2
	exit 1
fi

if [ ! -f "$BACKGROUND" ]; then
	echo "Errore: file di sfondo non trovato: $BACKGROUND" >&2
	exit 1
fi

if [ ! -f "$LOGO" ]; then
	echo "Errore: file logo non trovato: $LOGO" >&2
	exit 1
fi

# ---------- Verifica canale alpha nel logo (avviso, non blocca) ----------
_LOGO_ALPHA="$(identify -format '%A' "$LOGO" 2>/dev/null || echo 'Unknown')"
if [ "$_LOGO_ALPHA" != "True" ] && [ "$_LOGO_ALPHA" != "Blend" ]; then
	echo "Attenzione: il logo '$LOGO' non sembra avere un canale alpha (trasparenza)." >&2
	echo "Il risultato potrebbe mostrare un riquadro pieno intorno al logo." >&2
fi

# ---------- Working directory temporanea ----------
_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$_TMPDIR"' EXIT

echo "==> Ridimensiono lo sfondo a 800x600 (crop centrato, riempimento)..."
convert "$BACKGROUND" -resize 800x600^ -gravity center -extent 800x600 \
	-quality 88 "$_TMPDIR/bg.jpg"

echo "==> Ridimensiono il logo a 220x220 (mantenendo trasparenza)..."
convert "$LOGO" -resize 220x220 -background none -gravity center -extent 220x220 \
	"$_TMPDIR/logo.png"

echo "==> Codifico le immagini in base64..."
BG_B64="$(base64 -w0 "$_TMPDIR/bg.jpg")"
LOGO_B64="$(base64 -w0 "$_TMPDIR/logo.png")"

echo "==> Compongo l'SVG finale..."
mkdir -p "$(dirname "$OUTPUT")"

cat > "$OUTPUT" << SVGEOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   version="1.1"
   width="800"
   height="600"
   viewBox="0 0 800 600"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="topFade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="${PANEL_COLOR}" stop-opacity="0.85"/>
      <stop offset="1" stop-color="${PANEL_COLOR}" stop-opacity="0"/>
    </linearGradient>
  </defs>

  <!-- Livello 1: sfondo -->
  <image x="0" y="0" width="800" height="600"
         xlink:href="data:image/jpeg;base64,${BG_B64}" />

  <!-- Livello 2: fascia scura superiore per leggibilita' logo/titolo -->
  <rect x="0" y="0" width="800" height="220" fill="url(#topFade)" />

  <!-- Livello 3: logo -->
  <image x="290" y="18" width="220" height="220"
         xlink:href="data:image/png;base64,${LOGO_B64}" />

  <!-- Livello 4: titolo brand + versione -->
  <text x="400" y="270" text-anchor="middle"
        font-family="Inter, DejaVu Sans" font-weight="bold" font-size="30"
        fill="${ACCENT_COLOR}">@LB_ISO_APPLICATION@ @VERSION@ (${CODENAME})</text>
  <text x="400" y="296" text-anchor="middle"
        font-family="Inter, DejaVu Sans" font-weight="bold" font-size="16"
        fill="#ffffff">@ARCHITECTURE@</text>

  <!-- Livello 5: pannello semitrasparente dietro l'area menu di GRUB
       (coerente con boot_menu in theme.txt: top=52% height=48%-80 -> y=312..520) -->
  <rect x="80" y="312" width="640" height="208" rx="10"
        fill="${PANEL_COLOR}" fill-opacity="0.72" />

  <!-- Livello 6: dati tecnici di build, SOTTO l'area riservata al boot_menu -->
  <rect x="200" y="528" width="400" height="26" rx="6"
        fill="${PANEL_COLOR}" fill-opacity="0.6" />
  <text x="400" y="545" text-anchor="middle"
        font-family="JetBrains Mono, DejaVu Sans" font-size="11"
        fill="#dddddd">Built: @YEAR@-@MONTH@-@DAY@ @HOUR@:@MINUTE@:@SECOND@ @TIMEZONE@</text>
</svg>
SVGEOF

echo "==> Fatto. File scritto in: $OUTPUT"
echo "==> Dimensione file: $(du -h "$OUTPUT" | cut -f1)"
echo ""
echo "Ricorda: i placeholder (@LB_ISO_APPLICATION@, @VERSION@, @ARCHITECTURE@, ecc.)"
echo "vengono sostituiti automaticamente da live-build durante 'lb build', non prima."
