#!/bin/bash

set -e

if [ $# -eq 1 ]; then
    export http_proxy="$1"
    export https_proxy="$1"
fi

sed -i s'/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Update package information
apt-get update
apt-get install -y grub-efi-amd64
apt-get clean

# Set up basic networking
cat >>/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Change hostname
echo debian > /etc/hostname
echo -e "127.0.1.1\tdebian" >> /etc/hosts

# Set up fstab
cat > /etc/fstab <<EOF
# <file system> <mount point>   <type>  <options>       <dump>  <pass>

LABEL=rootfs /               ext4    errors=remount-ro 0       1
EOF

# Write /etc/default/grub
cat <<EOF > /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="root=/dev/vda2 console=ttyS0 net.ifnames=0 splash"
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL=console
EOF

grub-install --target=x86_64-efi
update-grub
cp -r /boot/efi/EFI/debian /boot/efi/EFI/BOOT
mv /boot/efi/EFI/BOOT/grubx64.efi /boot/efi/EFI/BOOT/bootx64.efi

useradd -m -s /bin/bash -G sudo debian
echo "root:debian" | chpasswd
echo "debian:debian" | chpasswd

# exit chroot
exit
