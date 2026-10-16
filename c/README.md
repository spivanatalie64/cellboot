# CellBoot — userspace C helpers

Real sources land per milestone:

- M0.3: `devicepath-resolver.c` — locates `\EFI\Microsoft\Boot\bootmgfw.efi`
  on the user's *read-only* ESP to compute the pass-through sector mapping;
  pure read.
- M0.5: `nvram-guard.c` — snapshot/detect/restore of `BootOrder`/`BootNext`;
  restore-first, refuse-second; honest poweroff with serial trace when
  firmware refuses.

Nothing builds here yet. `build.sh` reports the empty lane honestly.
