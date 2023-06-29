#!/bin/bash

IMG_NAME=debian-stable-amd64.img
LOOP_DEVICE=/dev/loop0
ROOTFS_DIR=/tmp/deb_amd64
SETUP_SCRIPT=setup_rootfs_bios.sh

cleanup() {
    sudo umount ${ROOTFS_DIR}
    sudo rm -rf ${ROOTFS_DIR}
    sudo fsck ${LOOP_DEVICE}p1
    sudo losetup -d $LOOP_DEVICE
    if [ $1 -ne 0 ]; then
        rm $IMG_NAME
    fi
    exit
}

if [ -f $IMG_NAME ]; then
    rm $IMG_NAME
fi

sudo apt-get install -y debootstrap debian-archive-keyring fdisk

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
# use old MBR partition table
sfdisk $IMG_NAME <<EOF
;
EOF

# Mount image in loop device
LOOP_DEVICE=$(sudo losetup --partscan --find --show $IMG_NAME)

# format partitions
sudo mkfs.ext4 ${LOOP_DEVICE}p1
sudo e2label ${LOOP_DEVICE}p1 rootfs

# mount root partition
mkdir -p ${ROOTFS_DIR}/
sudo mount ${LOOP_DEVICE}p1 ${ROOTFS_DIR}

# install base files
sudo -E debootstrap \
            --arch=amd64 \
            --keyring=/usr/share/keyrings/debian-archive-keyring.gpg \
            --include=debian-archive-keyring,linux-image-amd64,openssh-server,sudo,locales \
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
sudo chroot ${ROOTFS_DIR} ./${SETUP_SCRIPT} $http_proxy ${LOOP_DEVICE} || cleanup 1
sudo rm ${ROOTFS_DIR}/${SETUP_SCRIPT}

for i in /dev/pts /dev /proc /sys /run; do sudo umount ${ROOTFS_DIR}$i; done

cleanup 0
