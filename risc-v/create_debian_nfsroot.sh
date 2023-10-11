#!/bin/bash

set -e

if [[ $# < 1 ]]; then
    echo "nfs path not given..."
    echo "example: ./create_debian_nfsroot.sh /opt/nfs_debian"
    exit
fi

NFS_PATH=${1}

while true; do
    read -p "path \"${NFS_PATH}\" will be cleaned up, you have been warned. Yes? (y/n) " yn
    case $yn in
        [Yy]* ) sudo rm -rf ${NFS_PATH}; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
sudo mkdir -p ${NFS_PATH}

sudo apt-get install -y debootstrap binfmt-support debian-archive-keyring gdisk dosfstools

# Workaround for Ubuntu 20.04, which debian-archive-keyring package is out of date.
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$NAME" = "Ubuntu" ] && [ "$VERSION_ID" = "20.04" ]; then
        wget -c -P /tmp http://http.us.debian.org/debian/pool/main/d/debian-archive-keyring/debian-archive-keyring_2023.3+deb12u1_all.deb
        sudo dpkg -i /tmp/debian-archive-keyring_2023.3+deb12u1_all.deb
    fi
fi

# install base files
sudo -E debootstrap \
            --arch=riscv64 \
            --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
            --include=debian-archive-keyring \
            --components=main,contrib,non-free,non-free-firmware \
            unstable \
            ${NFS_PATH} \
            http://deb.debian.org/debian

# chroot in and set up
cd `dirname $0`
SETUP_SCRIPT=setup_nfs_rootfs.sh
sudo cp ${SETUP_SCRIPT} ${NFS_PATH}
sudo chroot ${NFS_PATH} ./${SETUP_SCRIPT} $http_proxy
sudo rm ${NFS_PATH}/${SETUP_SCRIPT}
