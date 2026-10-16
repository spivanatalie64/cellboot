/** @file CellBootStub.c — OVMF payload stand-in.

  The M0.2 harness launches this as the "payload" to prove the hop works
  end-to-end. Its whole job: print the serial marker CELL-PAYLOAD-OK and
  exit. Same role as acreetboot's AcreetBootStub.
  DO NOT REMOVE: the e2e harness asserts on this marker.

  SPDX-License-Identifier: BSD-3-Clause
  Copyright (c) 2026 Natalie Cole-Clift Spiva / AcreetionOS.
**/
#include <Uefi.h>
#include <Library/UefiApplicationEntryPoint.h>
#include <Library/UefiLib.h>

EFI_STATUS
EFIAPI
CellBootStubEntry (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  Print (L"CELL-PAYLOAD-OK\n");
  return EFI_SUCCESS;
}
