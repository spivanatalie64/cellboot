#!/usr/bin/env bash
# CellBoot M0.2 end-to-end proof — OVMF/QEMU, serial-asserted.
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 Natalie Cole-Clift Spiva / AcreetionOS.
#
# Flow: system firmware (OVMF, TCG) → fallback boot \EFI\BOOT\BOOTX64.EFI
# (a copy of CellBootLauncher.efi; its real home \EFI\cellboot\ is also
# staged) → launcher resolves \EFI\cellboot\CellBootStub.efi on the volume
# it itself was loaded from → LoadImage + StartImage → stub prints the
# marker → serial asserts CELL-PAYLOAD-OK → (payload returns; Bds moves on
# to the BootManagerMenu — normal, and we kill QEMU right after proving).
#
# Requires: build/efi-output/ staged by `CELLBOOT_BUILD_EFI=1 ./build.sh`,
# qemu, an OVMF firmware pair, mkfs.vfat, mtools. Fails loudly otherwise.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
B="$(mktemp -d /tmp/cellboot-ovmf-boot.XXXXXX)"
TRANSIENT=1   # cleared when we copied the serial transcript into build/
cleanup() {
  local qrc=0; [ -n "${QPID:-}" ] && kill "$QPID" 2>/dev/null || true
  if [ "$TRANSIENT" = 0 ] && [ -f "$B/serial.log" ]; then
    cp -f "$B/serial.log" "$ROOT/build/ovmf-serial-last.log" 2>/dev/null || true
  fi
  [ "${KEEP_DEBUG:-0}" = 1 ] || rm -rf "$B"
  exit "${1:-1}"
}
trap 'cleanup 130' INT; trap 'cleanup 1' ERR; trap 'cleanup $?' EXIT

MARKER="CELL-PAYLOAD-OK"
TIMEOUT="${CELLBOOT_OVMF_TIMEOUT:-180}"

msg() { echo "ovmf-boot: $*"; }
die() { echo "ovmf-boot: FATAL: $*" >&2; exit 1; }

# --- prerequisites ----------------------------------------------------------
[ -d "$ROOT/build/efi-output" ] ||
  die "no build/efi-output — run: CELLBOOT_BUILD_EFI=1 ./build.sh"
for f in CellBootLauncher.efi CellBootStub.efi; do
  [ -f "$ROOT/build/efi-output/$f" ] || die "missing build/efi-output/$f"
done
command -v qemu-system-x86_64 >/dev/null || die "qemu-system-x86_64 not found"
command -v mkfs.vfat >/dev/null || die "mkfs.vfat not found"
command -v mmd >/dev/null || die "mtools (mmd/mcopy) not found"

OVMF_CODE="/usr/share/ovmf/x64/OVMF_CODE.4m.fd"
OVMF_VARS="/usr/share/ovmf/x64/OVMF_VARS.4m.fd"
[ -f "$OVMF_CODE" ] && [ -f "$OVMF_VARS" ] ||
  die "OVMF firmware not found at /usr/share/ovmf/x64/ (edk2-ovmf)"

# --- stage the ESP image (FAT16 — OVMF's minimum cluster rule bites FAT32
#     on small images) ---------------------------------------------------------
msg "staging ESP image (launcher as fallback BOOTX64.EFI + real home)"
dd if=/dev/zero of="$B/esp.img" bs=1M count=16 status=none
mkfs.vfat -F 16 -n "CELLBOOT" "$B/esp.img" >/dev/null
mmd -i "$B/esp.img" ::/EFI ::/EFI/BOOT ::/EFI/cellboot
mcopy -i "$B/esp.img" "$ROOT/build/efi-output/CellBootLauncher.efi" ::/EFI/BOOT/BOOTX64.EFI
mcopy -i "$B/esp.img" "$ROOT/build/efi-output/CellBootLauncher.efi" ::/EFI/cellboot/CellBootLauncher.efi
mcopy -i "$B/esp.img" "$ROOT/build/efi-output/CellBootStub.efi" ::/EFI/cellboot/CellBootStub.efi

# --- boot OVMF, capture serial to FILE, poll for the marker ------------------
cp "$OVMF_VARS" "$B/OVMF_VARS.fd"
msg "booting QEMU/OVMF headless (TCG; proof marker poll, cap ${TIMEOUT}s)"
qemu-system-x86_64 \
  -m 256 \
  -display none \
  -serial file:"$B/serial.log" \
  -no-reboot \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$B/OVMF_VARS.fd" \
  -drive file="$B/esp.img",format=raw,media=disk \
  >/dev/null 2>&1 &
QPID=$!

prv=0
for i in $(seq 1 "$((TIMEOUT*2))"); do
  sleep 0.5
  kill -0 "$QPID" 2>/dev/null || break
  if grep -aq "$MARKER" "$B/serial.log" 2>/dev/null; then
    prv=1
    break
  fi
done
kill "$QPID" 2>/dev/null || true
wait "$QPID" 2>/dev/null || true
sleep 1   # let the serial file catch the trailing honest-return line

# --- verdict (always keep the transcript — build/, not the void) --------------
[ -f "$B/serial.log" ] || die "no serial transcript produced"
TRANSIENT=0
cp -f "$B/serial.log" "$ROOT/build/ovmf-serial-last.log"
echo "ovmf-boot: serial transcript: build/ovmf-serial-last.log"

if [ "$prv" = 1 ]; then
  msg "PASS: $MARKER asserted on serial"
  # positive assertions beyond the marker: the launcher banner must have
  # stated the host chain identity (structure proof, not just text).
  if grep -aq "host chain is AcreetionOS-owned" "$ROOT/build/ovmf-serial-last.log" &&
     grep -aq "payload returned" "$ROOT/build/ovmf-serial-last.log"; then
    msg "PASS: launcher banner + honest payload-return line asserted"
  else
    die "marker seen but identity banner / honest-return line missing — transcript corrupted?"
  fi
  exit 0
fi

echo "ovmf-boot: FATAL: marker '$MARKER' NOT found within ${TIMEOUT}s." >&2
echo "--- last serial lines ---"
tr -d '\000' < "$B/serial.log" | strings | tail -12 >&2
exit 1
