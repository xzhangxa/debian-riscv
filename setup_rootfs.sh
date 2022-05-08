#!/bin/bash

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
echo unmatched > /etc/hostname

# Set up fstab
cat > /etc/fstab <<EOF
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

/dev/mmcblk0p4 /               ext4    errors=remount-ro 0       1
/dev/mmcblk0p3 /boot           vfat    defaults   0       2
EOF

# add needed modules in initrd
echo mmc_spi >>/etc/initramfs-tools/modules
rm /boot/initrd*
update-initramfs -c -k all

# Set up u-boot (TODO: better integration for kernel updates)
# Should cp your latest dtb file,e.g, cp /usr/lib/linux-image-xx-riscv64
cp /usr/lib/linux-image-*-riscv64/sifive/hifive-unmatched-a00.dtb /boot/
echo U_BOOT_FDT=\"hifive-unmatched-a00.dtb\" >> /etc/default/u-boot
echo U_BOOT_PARAMETERS=\"rw rootwait console=ttySIF0,115200 earlycon\" >> /etc/default/u-boot
u-boot-update

useradd -m -s /bin/bash -G sudo debian
echo "root:debian" | chpasswd
echo "debian:debian" | chpasswd

# exit chroot
exit
