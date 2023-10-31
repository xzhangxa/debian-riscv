#!/bin/bash

IMG_NAME=debian-stable-amd64.img
LOOP_DEVICE=/dev/loop0
ROOTFS_DIR=/tmp/deb_amd64
SETUP_SCRIPT=setup_rootfs_uefi.sh

cleanup() {
    sudo umount ${ROOTFS_DIR}/boot/efi
    sudo umount ${ROOTFS_DIR}
    sudo rm -rf ${ROOTFS_DIR}
    sudo fsck ${LOOP_DEVICE}p1
    sudo fsck ${LOOP_DEVICE}p2
    sudo losetup -d $LOOP_DEVICE
    if [ $1 -ne 0 ]; then
        rm $IMG_NAME
    fi
    exit
}

if [ -f $IMG_NAME ]; then
    rm $IMG_NAME
fi

sudo apt-get install -y debootstrap debian-archive-keyring gdisk

# Workaround for Ubuntu 20.04, which debian-ports-archive-keyring package is out of date.
# https://bugs.launchpad.net/ubuntu/+source/debian-ports-archive-keyring/+bug/1969202
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$NAME" = "Ubuntu" ] && [ "$VERSION_ID" = "20.04" ]; then
        wget -c -P /tmp http://http.us.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2023.3_all.deb
        sudo dpkg -i /tmp/debian-archive-keyring_2023.3_all.deb
    fi
fi

# create image file
dd if=/dev/zero of=$IMG_NAME bs=1M count=4096

# Partition image
sudo sgdisk -g --clear --set-alignment=1 \
       --new=1::+512MiB --typecode=1:0xef00 \
       --new=2::-0 --change-name=2:'rootfs' --typecode=2:0x8300 \
       $IMG_NAME

# Mount image in loop device
LOOP_DEVICE=$(sudo losetup --partscan --find --show $IMG_NAME)

# format partitions
sudo mkfs.fat -F 32 ${LOOP_DEVICE}p1
sudo mkfs.ext4 ${LOOP_DEVICE}p2
sudo e2label ${LOOP_DEVICE}p2 rootfs

# mount root partition
sudo mkdir ${ROOTFS_DIR}
sudo mount ${LOOP_DEVICE}p2 ${ROOTFS_DIR}
sudo mkdir -p ${ROOTFS_DIR}/boot/efi
sudo mount ${LOOP_DEVICE}p1 ${ROOTFS_DIR}/boot/efi

# install base files
sudo -E debootstrap \
            --arch=amd64 \
            --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
            --include=debian-archive-keyring,linux-image-amd64,openssh-server,sudo,locales,dbus \
            --components=main,contrib,non-free,non-free-firmware \
            stable \
            ${ROOTFS_DIR} \
            http://deb.debian.org/debian

if [ $? -ne 0 ]; then
    cleanup 1
fi

for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i ${ROOTFS_DIR}$i; done

# chroot in and set up
sudo cp ${SETUP_SCRIPT} ${ROOTFS_DIR}
sudo chroot ${ROOTFS_DIR} ./${SETUP_SCRIPT} $http_proxy || cleanup 1
sudo rm ${ROOTFS_DIR}/${SETUP_SCRIPT}

for i in /dev/pts /dev /proc /sys /run; do sudo umount ${ROOTFS_DIR}$i; done

cleanup 0
