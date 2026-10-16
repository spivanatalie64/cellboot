# CellBoot — Milestones Index

Status: **proposed, none started** (v0 scaffold, 2026-10-15).
Source of truth: [issue #1](https://github.com/spivanatalie64/cellboot/issues/1)
("Proposed scaffold (v0)"). Birthright: standalone successor of the WanBoot
lane ([acreetboot #3](https://github.com/spivanatalie64/acreetboot/issues/3)).
License: BSD-3.

## Milestone table

| M    | One-liner                                                                    | Status | File |
|------|------------------------------------------------------------------------------|--------|------|
| 0.1  | Repo scaffold + sha256-pinned EDK2 bootstrap                                  | ⬜ planned | [M0.1-scaffold.md](M0.1-scaffold.md) |
| 0.2  | `CellBootLauncher.efi` boots a hardcoded PE32+ payload (LoadImage+StartImage) | ⬜ planned | [M0.2-payload-launch.md](M0.2-payload-launch.md) |
| 0.3  | Guest bring-up: KVM host boots guest OVMF from the user's Windows ESP         | ⬜ planned | [M0.3-guest-bringup.md](M0.3-guest-bringup.md) |
| 0.4  | Windows guest boots to winload/kernel inside KVM                              | ⬜ planned | [M0.4-windows-guest.md](M0.4-windows-guest.md) |
| 0.5  | NVRAM guard: refuse/restore Windows-side `BootOrder`/`BootNext` resets        | ⬜ planned | [M0.5-nvram-guard.md](M0.5-nvram-guard.md) |
| 0.6  | `cellbootctl`: install / status / uninstall                                   | ⬜ planned | [M0.6-cellbootctl.md](M0.6-cellbootctl.md) |

Status legend: ⬜ planned · 🔨 in progress (say where, honestly, like acreetboot
0.3 PARTIAL) · ✅ done (with the serial-assertion receipt that proves it).

## Hardening model (carries across every milestone)

- Host kernel: `lockdown=confidentiality`, `module.sig_enforce=1`,
  read-only ESP mount.
- The Windows ESP is mounted **read-only by the host at all times**; the
  guest sees only its own virtual ESP.
- No interpreter in the boot chain; VaultBoot boots only manifest-verified
  payloads.
- USB/disk passthrough is explicit per-entry opt-in config — never default.

## End-to-end proof discipline

Every milestone that touches a boot stage is proven in QEMU/OVMF with a
**serial assertion marker**, same pattern as acreetboot (`ACREET-PAYLOAD-OK`
et al.). CellBoot's markers:

- `CELL-PAYLOAD-OK` — M0.2: the EFI app launched its payload.
- `CELLOVF-GUEST-START` (proposed, M0.3): guest OVMF has come up inside KVM.
- `Windows-Boot-Manager` — M0.4: the Windows BCD path is executing in-kernel.
- NVRAM tamper test (M0.5) and `cellbootctl` e2e (M0.6) assert exit codes +
  restored NVRAM state, not vibes.

Zero fake success: a milestone is ✅ only when its marker is green in the
committed test harness.

## Non-goals (see also acreetboot 00-PLAN)

- CellBoot ships **no OS at all**: no Windows binaries, no macOS/OpenCore.
  VaultBoot boots only the user's own, official boot files.
- Not an ISO builder; does not replace pacman/Freeman; it sits below them.
- No Apple Secure Boot enrolment for v0 (documented future, matches acreetboot).
