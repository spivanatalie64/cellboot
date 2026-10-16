#!/usr/bin/env bash
# CellBoot — test orchestrator (v0.1 scaffold)
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 Natalie Cole-Clift Spiva / AcreetionOS.
#
# v0.1: no runnable harnesses yet. This runs static checks honestly and
# exits green ONLY on substance. The OVMF e2e lands in M0.2
# (test/test_ovmf_boot.sh, CELL-PAYLOAD-OK marker).
set -euo pipefail
ROOT="${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fails=$((fails+1)); }

# 1. CellBootPkg C/INF pairs must both exist (launcher INF is CellLauncher.inf;
#    BASE_NAME inside it produces CellBootLauncher.efi).
for pair in "CellLauncher:CellBootLauncher.c:CellLauncher.inf" \
            "CellBootStub:CellBootStub.c:CellBootStub.inf" ; do
  IFS=: read -r dir cfile infile <<< "$pair"
  [ -f "$ROOT/efi/edk2/CellBootPkg/$dir/$cfile" ] \
    && [ -f "$ROOT/efi/edk2/CellBootPkg/$dir/$infile" ] \
    && pass "CellBootPkg/$dir pair present ($cfile + $infile)" \
    || fail "CellBootPkg/$dir pair missing"
done

# 2. DSC must name both components.
grep -q 'CellLauncher/CellLauncher.inf' "$ROOT/efi/edk2/CellBootPkg/CellBootPkg.dsc" \
  && grep -q 'CellBootStub/CellBootStub.inf' "$ROOT/efi/edk2/CellBootPkg/CellBootPkg.dsc" \
  && pass "CellBootPkg.dsc names both components" \
  || fail "CellBootPkg.dsc does not name both components"

# 3. Stub must carry the M0.2 serial marker text (the harness future-leg).
grep -q 'CELL-PAYLOAD-OK' "$ROOT/efi/edk2/CellBootPkg/CellBootStub/CellBootStub.c" \
  && pass "CELL-PAYLOAD-OK marker present in stub" \
  || fail "CELL-PAYLOAD-OK marker missing from stub"

# 4. initramfs/init must refuse to run as real init (stub discipline).
chmod +x "$ROOT/initramfs/init" 2>/dev/null || true
if ! "$ROOT/initramfs/init" >/dev/null 2>&1; then
  pass "initramfs/init stub refuses real environment (as designed)"
else
  fail "initramfs/init failed to refuse real environment"
fi

# 5. Launcher banner must be honest about what isn't real yet.
grep -q 'M0.2 TODO' "$ROOT/efi/edk2/CellBootPkg/CellLauncher/CellBootLauncher.c" \
  && pass "launcher banner carries its honest TODO" \
  || fail "launcher banner lost its honest TODO guard"

# 6. No Microsoft boot path dependence in tracked sources (README documents
#    why Windows runs as a guest; no tracked file may point at the
#    \EFI\Microsoft\Boot chainload lane).
if grep -rn '\\EFI\\Microsoft\\Boot' "$ROOT/efi/edk2/CellBootPkg" >/dev/null 2>&1; then
  fail "Microsoft EFI path leaked into CellBootPkg sources"
else
  pass "no Microsoft EFI path in CellBootPkg sources"
fi

if [ "$fails" -gt 0 ]; then
  echo "TESTS: $fails FAILED" >&2
  exit 1
fi
echo "TESTS: all green"
