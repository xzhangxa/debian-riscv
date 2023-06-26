#!/bin/bash

qemu-system-riscv64 \
-machine virt -nographic -m 2048 -smp 4 \
-bios /usr/lib/riscv64-linux-gnu/opensbi/generic/fw_jump.elf \
-kernel /usr/lib/u-boot/qemu-riscv64_smode/uboot.elf \
-device virtio-net-device,netdev=eth0 \
-netdev user,id=eth0,hostfwd=:127.0.0.1:22222-:22 \
-drive file=debian-sid-riscv.img,format=raw,if=virtio
