/** @file CellBootLauncher.c — CellBoot's main EFI application.

  The host EFI chain is entirely AcreetionOS-owned; Windows runs as a KVM
  guest, so it can never overwrite \EFI\cellboot\ or reset NVRAM to steal
  the boot. CellBootLauncher's job: launch the CellBoot KVM-host payload
  (Linux microkernel+initramfs, or any staged PE32+ host stage) via
  LoadImage + StartImage, honestly.

  M0.2 semantics (milestone/M0.2-payload-launch.md):
    - payload location is HARDCODED by design (prove the hop first);
    - any failure (not found, load error, invalid signature) is an honest
      FAIL with the status printed to console/serial — the launcher NEVER
      silently continues into a boot we did not verify;
    - StartImage not returning is the normal case; if it returns we
      report the return pass-through from the payload itself.

  SPDX-License-Identifier: BSD-3-Clause
  Copyright (c) 2026 Natalie Cole-Clift Spiva / AcreetionOS.
**/
#include <Uefi.h>
#include <Library/UefiApplicationEntryPoint.h>
#include <Library/UefiLib.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Library/DevicePathLib.h>
#include <Library/MemoryAllocationLib.h>
#include <Protocol/LoadedImage.h>

//
// M0.2: hardcoded by design (prove the hop). M0.3+ graduate this constant
// into manifest-driven resolution — see milestone/M0.3-guest-bringup.md.
//
STATIC CONST CHAR16 mPayloadFilePath[] = L"\\EFI\\cellboot\\CellBootStub.efi";

EFI_STATUS
EFIAPI
CellBootLauncherEntry (
  IN EFI_HANDLE        ImageHandle,
  IN EFI_SYSTEM_TABLE  *SystemTable
  )
{
  EFI_STATUS                Status;
  EFI_LOADED_IMAGE_PROTOCOL *LoadedImage;
  EFI_DEVICE_PATH_PROTOCOL  *PayloadDevPath;
  EFI_HANDLE                PayloadImage;
  UINTN                     ExitDataSize;
  CHAR16                    *ExitData;

  Print (L"CellBoot launcher: host chain is AcreetionOS-owned "
         L"(\\EFI\\cellboot\\); Windows boots as a KVM guest\n");

  //
  // Get our own device (loaded image protocol) so the payload path resolves
  // on the volume CellBoot was loaded from, not some firmware-default disk.
  //
  Status = gBS->OpenProtocol (
                  ImageHandle,
                  &gEfiLoadedImageProtocolGuid,
                  (VOID **)&LoadedImage,
                  ImageHandle,
                  NULL,
                  EFI_OPEN_PROTOCOL_GET_PROTOCOL
                  );
  if (EFI_ERROR (Status)) {
    Print (L"cellboot: FATAL: OpenProtocol(LoadedImage) failed: %r\n", Status);
    return Status;
  }

  //
  // Build the payload device path (media path on the launcher ESP) and
  // dispatch it: LoadImage + StartImage. No interpreter, no fake continue.
  //
  PayloadDevPath = FileDevicePath (LoadedImage->DeviceHandle, mPayloadFilePath);
  if (PayloadDevPath == NULL) {
    Print (L"cellboot: FATAL: could not build payload device path\n");
    return EFI_INVALID_PARAMETER;
  }

  PayloadImage = NULL;
  Status = gBS->LoadImage (
                  FALSE,
                  ImageHandle,
                  PayloadDevPath,
                  NULL,
                  0,
                  &PayloadImage
                  );
  FreePool (PayloadDevPath);
  if (EFI_ERROR (Status)) {
    Print (L"cellboot: FATAL: LoadImage of %s failed: %r\n",
           mPayloadFilePath, Status);
    return Status;
  }

  ExitDataSize = 0;
  ExitData     = NULL;
  Status = gBS->StartImage (PayloadImage, &ExitDataSize, &ExitData);
  //
  // StartImage normally never returns (the payload boots the guest lane).
  // If we are here, the payload returned: report it honestly — success only
  // means "payload chose to return", not "host boot succeeded".
  //
  if (EFI_ERROR (Status)) {
    Print (L"cellboot: FATAL: StartImage failed: %r\n", Status);
    return Status;
  }
  Print (L"cellboot: payload returned ExitData (size %u)\n", ExitDataSize);
  return EFI_SUCCESS;
}
