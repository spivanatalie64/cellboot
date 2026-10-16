## CellBootPkg — EDK II package definition (milestone 0.1 scaffold)
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 Natalie Cole-Clift Spiva / AcreetionOS.
#
# CellBoot lives at \EFI\cellboot\ — a path Windows Update never learns
# about. This package builds CellBootLauncher.efi (the main EFI app that
# will locate the guest boot files and set up the guest VM) and
# CellBootStub.efi (the OVMF payload stand-in for the M0.2 end-to-end
# proof).
##
[Defines]
  PLATFORM_NAME                  = CellBootPkg
  PLATFORM_GUID                  = 185DA790-3BBD-4371-80AE-7BF83BA38332
  PLATFORM_VERSION               = 0.1
  DSC_DESCRIPTION                = CellBoot: Windows boots as a KVM guest; host chain is AcreetionOS-owned
  DSC_SPECIFICATION              = 0x00010005
  OUTPUT_DIRECTORY               = Build/CellBootPkg
  SUPPORTED_ARCHITECTURES        = X64
  BUILD_TARGETS                  = DEBUG|RELEASE

[LibraryClasses]
  BaseLib|MdePkg/Library/BaseLib/BaseLib.inf
  BaseMemoryLib|MdePkg/Library/BaseMemoryLib/BaseMemoryLib.inf
  PrintLib|MdePkg/Library/BasePrintLib/BasePrintLib.inf
  UefiLib|MdePkg/Library/UefiLib/UefiLib.inf
  UefiApplicationEntryPoint|MdePkg/Library/UefiApplicationEntryPoint/UefiApplicationEntryPoint.inf
  UefiBootServicesTableLib|MdePkg/Library/UefiBootServicesTableLib/UefiBootServicesTableLib.inf
  UefiRuntimeServicesTableLib|MdePkg/Library/UefiRuntimeServicesTableLib/UefiRuntimeServicesTableLib.inf
  DevicePathLib|MdePkg/Library/UefiDevicePathLib/UefiDevicePathLib.inf
  MemoryAllocationLib|MdePkg/Library/UefiMemoryAllocationLib/UefiMemoryAllocationLib.inf
  DebugLib|MdePkg/Library/BaseDebugLibNull/BaseDebugLibNull.inf
  DebugPrintErrorLevelLib|MdePkg/Library/BaseDebugPrintErrorLevelLib/BaseDebugPrintErrorLevelLib.inf
  PcdLib|MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
  RegisterFilterLib|MdePkg/Library/RegisterFilterLibNull/RegisterFilterLibNull.inf
  StackCheckLib|MdePkg/Library/StackCheckLibNull/StackCheckLibNull.inf

[LibraryClasses.X64]
  IoLib|MdePkg/Library/BaseIoLibIntrinsic/BaseIoLibIntrinsic.inf
  CpuLib|MdePkg/Library/BaseCpuLib/BaseCpuLib.inf

[Components]
  CellBootPkg/CellLauncher/CellLauncher.inf
  CellBootPkg/CellBootStub/CellBootStub.inf
