#!/bin/bash

IMG_NAME=debian-sid-riscv.img
LOOP_DEVICE=/dev/loop0

cleanup() {
    sudo umount /tmp/deb_rv64/boot
    sudo umount /tmp/deb_rv64
    sudo rm -rf /tmp/deb_rv64
    sudo losetup -d $LOOP_DEVICE
    if [ $1 -ne 0 ]; then
        rm $IMG_NAME
    fi
    exit
}

if [ -f $IMG_NAME ]; then
    rm $IMG_NAME
fi

sudo apt-get install -y debootstrap qemu-user-static binfmt-support debian-ports-archive-keyring gdisk dosfstools

# Workaround for Ubuntu 20.04, which debian-ports-archive-keyring package is out of date.
# https://bugs.launchpad.net/ubuntu/+source/debian-ports-archive-keyring/+bug/1969202
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$NAME" = "Ubuntu" ] && [ "$VERSION_ID" = "20.04" ]; then
        wget -c -P /tmp http://http.us.debian.org/debian/pool/main/d/debian-ports-archive-keyring/debian-ports-archive-keyring_2022.02.15_all.deb
        sudo dpkg -i /tmp/debian-ports-archive-keyring_2022.02.15_all.deb
    fi
fi

# create image file
dd if=/dev/zero of=$IMG_NAME bs=1M count=4096

# Partition image with correct disk IDs
sudo sgdisk -g --clear --set-alignment=1 \
       --new=3:34:+1M:    --change-name=3:'u-boot-spl'    --typecode=3:5b193300-fc78-40cd-8002-e86c45580b47 \
       --new=4:2082:+4M:  --change-name=4:'opensbi-uboot' --typecode=4:2e54b353-1271-4842-806f-e436d6af6985 \
       --new=2:16384:+400M:   --change-name=2:'boot'      --typecode=2:0x0700  --attributes=2:set:2  \
       --new=1:835584:-0   --change-name=1:'rootfs'       --typecode=1:0x8300 \
       $IMG_NAME

# Mount image in loop device
LOOP_DEVICE=$(sudo losetup --partscan --find --show $IMG_NAME)

# format partitions
sudo mkfs.vfat ${LOOP_DEVICE}p2
sudo mkfs.ext4 ${LOOP_DEVICE}p1
sudo fatlabel ${LOOP_DEVICE}p2 boot
sudo e2label ${LOOP_DEVICE}p1 rootfs

# mount root partition
mkdir -p /tmp/deb_rv64/boot
sudo mount ${LOOP_DEVICE}p1 /tmp/deb_rv64

# install base files
sudo -E debootstrap \
            --arch=riscv64 \
            --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg \
            --include=debian-ports-archive-keyring \
            unstable \
            /tmp/deb_rv64 \
            http://deb.debian.org/debian-ports

if [ $? -ne 0 ]; then
    cleanup 1
fi

# mount boot partition
sudo mount ${LOOP_DEVICE}p2 /tmp/deb_rv64/boot

# chroot in and set up
sudo cp setup_rootfs.sh /tmp/deb_rv64
sudo chroot /tmp/deb_rv64 ./setup_rootfs.sh $http_proxy || cleanup 1
sudo rm /tmp/deb_rv64/setup_rootfs.sh

sudo dd if=/tmp/deb_rv64/usr/lib/u-boot/sifive_unmatched/u-boot-spl.bin of=${LOOP_DEVICE}p3 bs=4k iflag=fullblock oflag=direct conv=fsync status=progress
sudo dd if=/tmp/deb_rv64/usr/lib/u-boot/sifive_unmatched/u-boot.itb of=${LOOP_DEVICE}p4 bs=4k iflag=fullblock oflag=direct conv=fsync status=progress

cleanup 0
