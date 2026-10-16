#!/usr/bin/env bash
# CellBoot — build orchestrator (v0 scaffold entry point)
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 Natalie Cole-Clift Spiva / AcreetionOS.
#
# What this does today (v0.1 scaffold):
#   1. syntax-check every shell script + presence-check the package skeleton
#   2. run the test suite (test/run_all.sh)
# EDK2 EFI modules are opt-in (CELLBOOT_BUILD_EFI=1): the fast host lane
# never downloads/builds the firmware toolchain unless asked —
# tools/edk2-bootstrap.sh (pinned fetch) + tools/edk2-build.sh.
#
# M0.1 scope note: there are no host C tools yet (the device-path resolver
# and NVRAM guard helpers land in M0.3/M0.5). build.sh grows with them.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$ROOT/build"
mkdir -p "$BUILD/bin"

echo "==> cellboot build (host: $(uname -srm))"

# --- package skeleton presence gates --------------------------------------
for f in \
  efi/edk2/CellBootPkg/CellBootPkg.dsc \
  efi/edk2/CellBootPkg/CellLauncher/CellLauncher.inf \
  efi/edk2/CellBootPkg/CellLauncher/CellBootLauncher.c \
  efi/edk2/CellBootPkg/CellBootStub/CellBootStub.inf \
  efi/edk2/CellBootPkg/CellBootStub/CellBootStub.c \
  ; do
  [ -f "$ROOT/$f" ] || { echo "MISSING: $f" >&2; exit 1; }
done
echo "ok: CellBootPkg skeleton present"

# --- syntax checks ----------------------------------------------------------
for s in build.sh tools/edk2-bootstrap.sh tools/edk2-build.sh initramfs/init test/run_all.sh; do
  bash -n "$ROOT/$s" && echo "ok: bash -n $s"
done

# --- EFI lane (opt-in) -------------------------------------------------------
if [ "${CELLBOOT_BUILD_EFI:-0}" = "1" ]; then
  "$ROOT/tools/edk2-bootstrap.sh"
  "$ROOT/tools/edk2-build.sh"
  echo "ok: build/efi-output staged"
fi

# --- host C lane (empty for now — honest) ------------------------------------
if command -v gcc >/dev/null; then
  echo "no host C sources yet (M0.3+/M0.5); gcc present, lane empty"
else
  echo "no gcc on host AND no host C sources yet; nothing lost (lane empty)"
fi

# --- tests --------------------------------------------------------------------
test/run_all.sh "$ROOT" && echo "ALL TESTS GREEN"
