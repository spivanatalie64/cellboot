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

# edksetup.sh reads PYTHON_COMMAND unguarded; provide ours (edk2 toolcheck
# runs its own python discovery otherwise, unbound under set -u).
export PYTHON_COMMAND="${PYTHON_COMMAND:-python3}"
mkdir -p "$BUILD/edk2-conf"   # CONF_PATH dir must exist for BaseTools/BuildEnv to write BuildEnv.sh

echo "==> building CellBootPkg (X64)"
(
  cd "$EDK2"
  export WORKSPACE="$EDK2"
  export CONF_PATH="$BUILD/edk2-conf"
  # Our package lives in this repo (out of the EDK2 tree) — PACKAGES_PATH
  # adds both roots; EDK2 first so MdePkg library classes resolve, ours
  # second so CellBootPkg modules resolve.
  export PACKAGES_PATH="$EDK2:$ROOT/efi/edk2"
  # Upstream edksetup.sh is not -u-clean (EDK_TOOLS_PATH etc.) — relax -u for
  # the sourcing only; -e stays on so any real build failure stops the lane.
  set +u
  . ./edksetup.sh BaseTools
  build -a X64 -b RELEASE -t GCC -p CellBootPkg/CellBootPkg.dsc
)
OUT="$EDK2/Build/CellBootPkg/RELEASE_GCC/X64"
[ -d "$OUT" ] || { echo "FATAL: EDK2 produced no output at $OUT" >&2; exit 1; }

mkdir -p "$BUILD/efi-output"
find "$OUT" -maxdepth 1 -name '*.efi' -exec cp -v {} "$BUILD/efi-output/" \;
ls "$BUILD/efi-output" | grep -q '.efi' || { echo "FATAL: no .efi staged" >&2; exit 1; }

echo "==> receipt for each staged EFI"
( cd "$BUILD/efi-output" && sha256sum *.efi > "$BUILD/efi-output.sha256" )
echo "efi-build: OK → $BUILD/efi-output (receipt: $BUILD/efi-output.sha256)"
