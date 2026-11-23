#!/bin/bash
set -e
set -o pipefail

cd /home/rymos-dev/rymos-build

# Identificativo della build: data e ora di avvio (nome della ISO e BUILD_ID in os-release)
BUILD_ID=$(date +%Y%m%d-%H%M)
ISO_NAME="RymOS-1.0-Aurora-amd64-${BUILD_ID}.iso"
OS_RELEASE=config/includes.chroot/etc/os-release
sed -i '/^BUILD_ID=/d' "$OS_RELEASE"
echo "BUILD_ID=\"${BUILD_ID}\"" >> "$OS_RELEASE"
echo "Pulizia ambiente di build..."
lb clean --purge

echo "Configurazione live-build..."
lb config \
  --distribution trixie \
  --archive-areas "main contrib non-free non-free-firmware" \
  --binary-images iso-hybrid \
  --bootloaders "grub-pc grub-efi" \
  --debian-installer none \
  --iso-application "RymOS" \
  --iso-publisher "RymStudio" \
  --iso-volume "RymOS 1.0 Aurora" \
  --memtest none \
  --win32-loader false

echo "Build in corso..."
lb build 2>&1 | tee build.log
mv live-image-amd64.hybrid.iso "$ISO_NAME"
echo "ISO pronta: $ISO_NAME"
