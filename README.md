# CellBoot

[![license](https://img.shields.io/badge/license-BSD--3-green)]()

CellBoot is the **Windows bootloader replacement** for the AcreetBoot boot
chain (AcreetionOS). It boots Windows without fighting Windows Update:
instead of chainloading `\EFI\Microsoft\Boot\bootmgfw.efi` — which every
Windows feature update overwrites, along with resetting UEFI NVRAM
`BootOrder`/`BootNext` — CellBoot lives at `\EFI\cellboot\`, boots a minimal
Linux environment, brings up KVM, and launches the **official, unmodified
Windows boot files as a guest**. Windows validates its own Secure Boot chain
inside the VM; the host EFI chain is entirely AcreetionOS-owned and Windows
can never overwrite it.

CellBoot is the standalone successor to AcreetBoot's WanBoot lane
([acreetboot](https://github.com/spivanatalie64/acreetboot)), built as its
own project so the Windows path can be developed and shipped independently.

## VaultBoot — bring your own Windows

CellBoot ships **no copy of Windows, no Windows boot files, and no Windows
installer**. VaultBoot, the guest-boot lane of CellBoot, boots only the
*user's own* Windows installation — you must provide your own OS.

> **VaultBoot disclaimer:** you must provide your own copy of Windows.
> CellBoot does not ship, install, activate, or license Windows on your
> behalf. Download your own copy directly from Microsoft and review the
> Microsoft Software License Terms before installing:
>
> - Windows 11: <https://www.microsoft.com/software-download/windows11>
> - Windows 10: <https://www.microsoft.com/software-download/windows10>
>
> Windows is provided by and licensed by Microsoft, not by the
> AcreetionOS project. Your use of Windows and compliance with Microsoft's
> license terms are entirely your responsibility.

## License

- All first-party CellBoot code: BSD-3 (see `LICENSE`).
- CellBoot does not ship macOS or OpenCore, and the user is responsible
  for their own macOS installation and EULA compliance.
- Windows itself is Microsoft's: CellBoot boots the official boot files
  the user already owns; we never redistribute or modify Microsoft's
  binaries.

## Status

v0 scaffold. Proposed structure and milestones tracked in issue #1.

## Source & tracking

- GitHub: <https://github.com/spivanatalie64/cellboot> — current work lane:
  `feature/cellboot`
- Scaffold proposal + milestones: <https://github.com/spivanatalie64/cellboot/issues/1>
- Per-milestone plan files: [`milestone/00-INDEX.md`](milestone/00-INDEX.md)
- Long-form plan: [`docs/plan/00-PLAN.md`](docs/plan/00-PLAN.md)
Owner/Co-Lead: Natalie (AcreetionOS). License: BSD-3.
