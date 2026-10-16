# CellBoot — Build-Out Plan (00-PLAN)

Status: v0 scaffold (growing). Owner: Natalie (AcreetionOS Co-Lead).
License: BSD-3 (see ../../LICENSE).

Canonical long-form plan; the per-milestone breakdown lives in
[`../../milestone/00-INDEX.md`](../../milestone/00-INDEX.md) (issue #1 scope).
Companion summary: [`../../general_summary.md`](../../general_summary.md).

## Why CellBoot exists

Classic dual-boot loses to Windows Update: every Windows feature update
overwrites `\EFI\Microsoft\Boot\bootmgfw.efi` and resets UEFI NVRAM
`BootOrder`/`BootNext`, stealing the machine back from AcreetionOS.

CellBoot removes the fight structurally:

```
UEFI firmware
  └─ AcreetionOS-owned chain (sd-boot → AcreetBoot → CellBootLauncher.efi
     at \EFI\cellboot\ — a path Windows Update never learns about)
       └─ Linux microkernel + initramfs (KVM host, lockdown=confidentiality,
          module.sig_enforce=1, Windows ESP mounted READ-ONLY)
            └─ KVM guest: official, unmodified Windows boot files
               (guest OVMF reads the user's own Windows ESP read-only;
                pass-through Windows disk; guest scratch = its only ESP)
                 └─ bootmgfw.efi → winload.efi → Windows kernel
                    — Windows validates its own Secure Boot chain INSIDE
                      the guest; the host EFI chain is untouchable
```

Result: the thing Windows can overwrite (its own guest ESP) is the thing
we never depend on. The thing we depend on (`\EFI\cellboot\`, the host
chain) is a thing Windows never sees.

## Lineage

Standalone successor to the WanBoot lane of
[acreetboot](https://github.com/spivanatalie64/acreetboot) (issue #3 there).
Chain glue coordinates over there; development and shipping happen here.
VaultBoot is the guest-OS lane name: it ships NO OS — users bring their own
Windows, licensed/activated by them. macOS/OpenCore are never shipped.

## Layout (v0.1 scaffold)

| dir                      | what lives here                                                   |
|--------------------------|-------------------------------------------------------------------|
| `efi/edk2/CellBootPkg`   | our EDK II package (DSC/INF, BSD-3): CellLauncher + CellBootStub  |
| `initramfs/`             | KVM-host minimal initramfs source (busybox-ish; M0.3)             |
| `c/`                     | userspace C helpers: guest device-path resolver (M0.3), NVRAM guards (M0.5) |
| `test/`                  | `run_all.sh` + OVMF end-to-end harnesses (serial assertions)      |
| `tools/`                 | `edk2-bootstrap.sh` (sha256-pinned fetch) + `edk2-build.sh`       |
| `milestone/`             | per-milestone plan files + index (M0.1–M0.6)                      |
| `docs/plan/`             | this file; `docs/sprint/` per-day logs                            |
| `man/`                   | man pages                                                         |
| `build/`                 | build outputs — NEVER committed (in .gitignore)                   |

## Discipline (carried from acreetboot)

- **sha256-pinned EDK2**: `edk2-stable202608` + pinned brotli/mipisyst
  submodules; nothing third-party enters the build unrecorded.
- **Serial-assertion proofs**: a boot feature is done only when its marker
  is green in the committed harness — `CELL-PAYLOAD-OK` (M0.2),
  `CELLOVF-GUEST-START` (M0.3), `Windows-Boot-Manager` (M0.4).
- **Zero fake success**: scripts fail loudly with exit codes; a milestone
  is checked only with a receipt.
- **Honestness about costs**: Windows boots within a KVM guest — boot
  latency and TCG-without-KVM fallback (CI) tradeoffs are tracked, first
  class, never hidden.

## Hardening model

1. Host kernel: `lockdown=confidentiality`, `module.sig_enforce=1`,
   read-only ESP mount.
2. Microsoft-published Windows ESP mount: **read-only on the host, at all
   times**; the guest sees only its own virtual scratch ESP and the
   pass-through disk.
3. No interpreter in the boot chain; VaultBoot boots only
   manifest-verified payloads.
4. USB/disk passthrough is explicit per-entry opt-in config, never default.
5. M0.5 NVRAM guard: refuse/restore any Windows-side `BootOrder`/`BootNext`
   reset attempt — removes even the abandoned `\EFI\Microsoft\Boot\` need.

## Licensing

- All first-party CellBoot code: BSD-3 (see LICENSE).
- EDK II fetched at build time (BSD-3 + Apache-2.0 patent grant), pinned,
  never committed.
- Windows is Microsoft's; CellBoot boots the user's own official boot files
  and never redistributes or modifies Microsoft binaries.
- macOS/OpenCore: never shipped; user's own install + EULA compliance.

## Non-goals

- Not an ISO builder; does not replace pacman/Freeman; sits below them.
- Ships no OS at all (VaultBoot BYO lane).
- No Apple Secure Boot enrolment for v0 (documented future).
