#!/bin/bash

set -e

if [ $# -eq 1 ]; then
    export http_proxy="$1"
    export https_proxy="$1"
fi

# Update package information
apt-get update
apt-get install -y linux-image-riscv64 u-boot-menu u-boot-sifive openssh-server sudo locales
apt-get clean

sed -i s'/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Set up basic networking
cat >>/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Change hostname
echo debian > /etc/hostname

# Set up fstab
cat > /etc/fstab <<EOF
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

LABEL=rootfs /               ext4    errors=remount-ro 0       1
LABEL=boot /boot           vfat    defaults   0       2
EOF

# add needed modules in initrd
echo mmc_spi >>/etc/initramfs-tools/modules
rm /boot/initrd*
update-initramfs -c -k all

# console=ttySIF0,115200 for Unmatched?
dtb_dirs=(/usr/lib/linux-image-*-riscv64)
cat >>/etc/default/u-boot <<EOF
U_BOOT_PARAMETERS="rw noquite root=LABEL=rootfs earlycon"
U_BOOT_FDT_DIR="${dtb_dirs[0]}"
EOF
u-boot-update

useradd -m -s /bin/bash -G sudo debian
echo "root:debian" | chpasswd
echo "debian:debian" | chpasswd

# exit chroot
exit
