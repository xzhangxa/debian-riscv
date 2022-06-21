## Build Debian RISC-V Port Image

These scripts could be used to build a Debian RISC-V port image, that could be used on both SiFive HiFive Unmatched board and QEMU.

Run this command to create the image:

```
# ./create_debian_image.sh
```

The image `debian-sid-riscv.img` will be created. Please note currently for Debian RISC-V is not an official architecture, so the image is based on Debian Unstable release.

One additional script `run_qemu.sh` is provided to run the image in QEMU. This image could also be flashed in a SD card and boot on SiFive HiFive Unmatched board.
