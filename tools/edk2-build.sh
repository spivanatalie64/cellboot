#!/usr/bin/env bash
# CellBoot — EDK2 build (milestone 0.1 scaffold; real compile gate is M0.2)
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 Natalie Cole-Clift Spiva / AcreetionOS.
#
# Assumes build.sh already ran tools/edk2-bootstrap.sh (pinned EDK2 tree +
# BaseTools at build/edk2/edk2/). Builds CellBootPkg for X64 and stages the
# produced .efi files into build/efi-output/.
#
# HONEST STATUS: this script is scaffolding — it wires the flow, but the
# DSC/INF set only becomes a *validated* build target in milestone 0.2
# (see milestone/M0.2-payload-launch.md). Until then a failing EDK2 build
# is a true signal, not a bug in this file.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/build"
EDK2="$BUILD/edk2/edk2-edk2-stable202608"
PKG="$ROOT/efi/edk2/CellBootPkg"

[ -d "$EDK2" ] || { echo "FATAL: pinned EDK2 tree missing — run tools/edk2-bootstrap.sh first" >&2; exit 1; }
[ -d "$PKG" ] || { echo "FATAL: CellBootPkg missing from $PKG" >&2; exit 1; }

echo "==> building CellBootPkg (X64)"
(
  cd "$EDK2"
  export WORKSPACE="$EDK2"
  export CONF_PATH="$BUILD/edk2-conf"
  . ./edksetup.sh BaseTools
  build -a X64 -b GCC5 -t GCC5 -p CellBootPkg/CellBootPkg.dsc
)
OUT="$EDK2/Build/CellBootPkg/DEBUG_GCC5/X64"
if [ "${CELLBOOT_CONFIG:-release}" = "release" ]; then
  OUT="$EDK2/Build/CellBootPkg/RELEASE_GCC5/X64"
fi
[ -d "$OUT" ] || { echo "FATAL: EDK2 produced no output at $OUT" >&2; exit 1; }

mkdir -p "$BUILD/efi-output"
find "$OUT" -maxdepth 1 -name '*.efi' -exec cp -v {} "$BUILD/efi-output/" \;
ls "$BUILD/efi-output" | grep -q '.efi' || { echo "FATAL: no .efi staged" >&2; exit 1; }

echo "==> receipt for each staged EFI"
( cd "$BUILD/efi-output" && sha256sum *.efi > "$BUILD/efi-output.sha256" )
echo "efi-build: OK → $BUILD/efi-output (receipt: $BUILD/efi-output.sha256)"
