#!/bin/bash

qemu-system-x86_64 \
-drive if=pflash,format=raw,unit=0,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
-drive if=pflash,format=raw,unit=1,readonly=on,file=/usr/share/OVMF/OVMF_VARS.fd \
-nographic -m 2048 -smp 4 \
-device virtio-net-pci,netdev=eth0 \
-netdev user,id=eth0,hostfwd=:127.0.0.1:22222-:22 \
-drive file=debian-stable-amd64.img,format=raw,if=virtio
