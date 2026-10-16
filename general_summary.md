# CellBoot — General Summary

*Repo: <https://github.com/spivanatalie64/cellboot> · BSD-3 · Owner/Co-Lead: Natalie (AcreetionOS)*

## What CellBoot is

CellBoot is the **Windows bootloader replacement** for the AcreetBoot boot chain
of AcreetionOS. Its job: boot Windows without ever letting Windows Update fight
back.

The classic dual-boot approach — chainloading
`\EFI\Microsoft\Boot\bootmgfw.efi` — loses every time a Windows feature update
ships, because Windows overwrites the bootloader files **and** resets the UEFI
NVRAM (`BootOrder` / `BootNext`), stealing the machine back.

CellBoot's answer is structural, not defensive:

1. The EFI application lives at `\EFI\cellboot\` — a path Windows Update never
   learns about and therefore never overwrites.
2. It boots a **minimal Linux environment** (KVM-capable microkernel +
   initramfs) as the host.
3. That host brings up **KVM** and launches the *official, unmodified Windows
   boot files as a guest VM*.
4. Windows validates its own Secure Boot chain inside the VM; the host EFI
   chain stays entirely AcreetionOS-owned. Windows physically cannot overwrite
   it.

Lineage: standalone successor to AcreetBoot's **WanBoot** lane
([acreetboot #3](https://github.com/spivanatalie64/acreetboot/issues/3)),
split out into its own repo so the Windows path can be developed and shipped
independently of the broader AcreetBoot chain.

## VaultBoot — bring-your-own-Windows lane

VaultBoot is the guest-OS lane of CellBoot. It ships **no copy of Windows, no
Windows boot files, and no Windows installer** — it boots only the *user's own*
Windows installation. Users download Windows directly from Microsoft and their
use of it, plus EULA/license compliance, is entirely their responsibility.
Same stance for macOS/OpenCore: never shipped, user's own responsibility.

## Technical approach

- `CellLauncher.efi` — EDK II application (from `\EFI\cellboot\`): locates the
  guest boot files on the user's Windows ESP and sets up the guest VM
  (initial approach: hardcoded PE32+ payload via `LoadImage` + `StartImage`
  to prove the mechanism end-to-end).
- Guest bring-up: KVM-capable microkernel + initramfs boots the guest OVMF
  from the user's Windows ESP; the Windows disk is passed through to the VM.
- End-state: `winload`/kernel boots inside KVM, verified by serial
  (`Windows-Boot-Manager`) assertions in the OVMF test harness; `CELL-PAYLOAD-OK`
  marks the earlier payload-launch proof.
- `cellbootctl` — `bootctl`-style installer/status/uninstall tool.

## Hardening model (mirrors acreetboot)

- Host kernel: `lockdown=confidentiality`, `module.sig_enforce=1`, ESP mounted
  read-only.
- The **Windows ESP is mounted read-only by the host at all times**; the guest
  sees only its own virtual ESP.
- No interpreter in the boot chain; VaultBoot boots only manifest-verified
  payloads.
- USB/disk passthrough is explicit per-entry opt-in config — never default.
- M0.5 adds an **NVRAM guard**: refuses/restores any Windows-side
  `BootOrder`/`BootNext` reset attempt, making even the abandoned
  `\EFI\Microsoft\Boot\` entry unnecessary.

## Proposed repository structure (issue #1)

```
cellboot/
├── build.sh             # syntax-check + build + test entrypoint (mirrors acreetboot)
├── efi/edk2/CellBootPkg # EDK II package: CellBootLauncher.efi (DSC/INF)
│   ├── CellLauncher/    # main EFI app: guest boot-file location + VM setup
│   └── CellBootStub/    # OVMF payload stub for end-to-end proof
├── initramfs/           # KVM-host minimal initramfs source (busybox-ish)
├── c/                   # userspace C helpers (device-path resolver, NVRAM guards)
├── test/                # run_all.sh + OVMF e2e harness (serial assertions)
├── docs/
│   ├── plan/00-PLAN.md  # lifecycle, milestones, hardening model
│   └── sprint/          # per-day logs
└── man/                 # cellboot(1)
```

## Milestones (proposed, issue #1)

Per-milestone files live in [`milestone/`](milestone/00-INDEX.md) — index,
deliverables, acceptance gates, dependencies, status per M0.1–M0.6.

| M   | Scope | Proof |
|-----|-------|-------|
| 0.1 | Scaffold: dirs, plan doc, sha256-pinned `edk2-stable` bootstrap script (same pattern as acreetboot's `tools/edk2-bootstrap.sh`) | — |
| 0.2 | `CellLauncher.efi` boots a hardcoded PE32+ payload via LoadImage+StartImage | `CELL-PAYLOAD-OK` serial marker in QEMU/OVMF |
| 0.3 | Guest bring-up: microkernel + initramfs boots guest OVMF from user's Windows ESP (host read-only), Windows disk passthrough | — |
| 0.4 | Windows guest boots to winload/kernel inside KVM; host never mounts Windows ESP read-write | `Windows-Boot-Manager` serial assertion |
| 0.5 | NVRAM guard: refuses/restores Windows-side `BootOrder`/`BootNext` resets | tamper test |
| 0.6 | `cellbootctl`: install (`bootctl`-style), status, uninstall | tool e2e |

## Current status

**v0 scaffold.** As of 2026-10-15 the repo contains exactly:

- `README.md` — project description + VaultBoot BYO-Windows disclaimer
  + licensing note
- `LICENSE` — BSD-3 (matches acreetboot)
- `.gitignore` — `build/`, `*.efi`, `*.o`, `*.iso`

Single commit `9cd4644` ("v0 scaffold"), branch `main`. Everything beyond this
point — the directory tree, milestones 0.1–0.6, and the hardening model — is
**proposed** in
[issue #1](https://github.com/spivanatalie64/cellboot/issues/1) and not yet
implemented. No source code exists yet.

## Licensing

- All first-party CellBoot code: **BSD-3**.
- CellBoot never redistributes or modifies Microsoft's binaries; it boots the
  official boot files the user already owns.
- macOS/OpenCore are never shipped; user is responsible for their own install
  and EULA compliance.

## Coordination

Chain-glue work (how CellBoot slots into the wider AcreetBoot boot chain) is
coordinated in [acreetboot issue #3](https://github.com/spivanatalie64/acreetboot/issues/3);
development and shipping happen here.
