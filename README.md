Alpine Linux real-time kernel build root for NanoPi NEO
=======================================================

This repository contains the build root for building an unofficial port
of [Alpine Linux][1] for the [FriendlyARM NanoPi NEO][2] board patched with the
[CONFIG_PREEMPT_RT][3] real-time Linux patch.

- U-Boot v2024.04
- Kernel v5.4.84 (rt47)
- Alpine 3.19

Use the provided docker files to build the sdcard image.

[1]: https://alpinelinux.org/
[2]: https://linux-sunxi.org/FriendlyARM_NanoPi_NEO
[3]: https://rt.wiki.kernel.org/index.php/Main_Page
