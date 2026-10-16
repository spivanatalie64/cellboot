/** @file CellBootLauncher.c — CellBoot's main EFI application.

  Milestone 0.1 scaffold: prints its identity banner over serial/console and
  installs a loaded-image handle so the app is inspectable. The real work —
  locate the KVM-host payload, LoadImage + StartImage it, hand the machine
  to the guest lane — is milestone 0.2's deliverable
  (milestone/M0.2-payload-launch.md, serial marker CELL-PAYLOAD-OK).

  CellBoot boots Windows WITHOUT fighting Windows Update: the host EFI chain
  is entirely AcreetionOS-owned; the official, unmodified Windows boot files
  run as a KVM guest. Windows updates can never overwrite \EFI\cellboot\ —
  Windows Update does not know this path exists.

  SPDX-License-Identifier: BSD-3-Clause
  Copyright (c) 2026 Natalie Cole-Clift Spiva / AcreetionOS.
**/
#include <Uefi.h>
#include <Library/UefiApplicationEntryPoint.h>
#include <Library/UefiLib.h>

/** Application entry point — milestone 0.1 scaffold.

  Deliberately minimal: banner + sentinel. Returning EFI_SUCCESS from here
  lets the firmware continue its normal boot path in scaffold mode; M0.2
  replaces this with payload dispatch, where a FAIL is an honest FAIL.
**/
EFI_STATUS
EFIAPI
CellBootLauncherEntry (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  Print (L"CellBoot launcher v0.1 scaffold — host chain is AcreetionOS-owned\n");
  Print (L"(M0.2 TODO: payload dispatch, CELL-PAYLOAD-OK e2e)\n");
  return EFI_SUCCESS;
}
