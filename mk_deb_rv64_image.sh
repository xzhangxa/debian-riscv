#!/bin/bash

set -e

# create image file
dd if=/dev/zero of=debian-sid-riscv-unmatched.img bs=1M count=4096

# Partition image with correct disk IDs
sudo sgdisk -g --clear --set-alignment=1 \
       --new=1:34:+1M:    --change-name=1:'u-boot-spl'    --typecode=1:5b193300-fc78-40cd-8002-e86c45580b47 \
       --new=2:2082:+4M:  --change-name=2:'opensbi-uboot' --typecode=2:2e54b353-1271-4842-806f-e436d6af6985 \
       --new=3:16384:+400M:   --change-name=3:'boot'      --typecode=3:0x0700  --attributes=3:set:2  \
       --new=4:835584:-0   --change-name=4:'rootfs'       --typecode=4:0x8300 \
       debian-sid-riscv-unmatched.img

# Mount image in loop device
sudo losetup --partscan --find --show debian-sid-riscv-unmatched.img

# format partitions
sudo mkfs.vfat /dev/loop0p3
sudo mkfs.ext4 /dev/loop0p4
sudo fatlabel /dev/loop0p3 boot
sudo e2label /dev/loop0p4 rootfs

# mount root partition
mkdir -p /tmp/deb_rv64/boot
sudo mount /dev/loop0p4 /tmp/deb_rv64

# install base files
sudo apt-get install debootstrap binfmt-support debian-ports-archive-keyring
sudo -E debootstrap --arch=riscv64 --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg --include=debian-ports-archive-keyring unstable /tmp/deb_rv64 http://deb.debian.org/debian-ports

# mount boot partition
sudo mount /dev/loop0p3 /tmp/deb_rv64/boot

# chroot into base filesystem and made basic configuration
sudo cp setup_rootfs.sh /tmp/deb_rv64
sudo chroot /tmp/deb_rv64 ./setup_rootfs.sh $http_proxy
sudo rm /tmp/deb_rv64/setup_rootfs.sh

sudo dd if=/tmp/deb_rv64/usr/lib/u-boot/sifive_unmatched/u-boot-spl.bin of=/dev/loop0p1 bs=4k iflag=fullblock oflag=direct conv=fsync status=progress
sudo dd if=/tmp/deb_rv64/usr/lib/u-boot/sifive_unmatched/u-boot.itb of=/dev/loop0p2 bs=4k iflag=fullblock oflag=direct conv=fsync status=progress

sudo umount /tmp/deb_rv64/boot
sudo umount /tmp/deb_rv64
rm -r /tmp/deb_rv64

sudo losetup -d /dev/loop0
