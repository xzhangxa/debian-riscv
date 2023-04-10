## Build Debian RISC-V Port Image

These scripts could be used to build a Debian RISC-V port image, that could be used on both SiFive HiFive Unmatched board and QEMU, and maybe other compatible platforms.

Run this command to create the image:

```
# ./create_debian_image.sh
```

The image `debian-sid-riscv.img` will be created. Please note currently for Debian RISC-V is not an official architecture, so the image is based on Debian Unstable release (sid).

As the nature of sid, it's rolling release so the created images at different times will be different. In case the created image cannot boot, it may be the latest sid introduces some breaking changes or bugs, please use an previously created image for the time being or wait for sid to fixing the issue and try again.

One additional script `run_qemu.sh` is provided to run the image in QEMU. This image could also be flashed in a SD card and boot on SiFive HiFive Unmatched board.
