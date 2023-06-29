#!/bin/bash

qemu-system-x86_64 \
-machine q35 -nographic -m 2048 -smp 4 \
-drive file=debian-stable-amd64.img,format=raw,if=virtio
