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

sudo apt-get install -y debootstrap qemu-user-static binfmt-support debian-ports-archive-keyring gdisk dosfstools

# Workaround for Ubuntu 20.04, which debian-ports-archive-keyring package is out of date.
# https://bugs.launchpad.net/ubuntu/+source/debian-ports-archive-keyring/+bug/1969202
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$NAME" = "Ubuntu" ] && [ "$VERSION_ID" = "20.04" ]; then
        wget -c -P /tmp http://http.us.debian.org/debian/pool/main/d/debian-ports-archive-keyring/debian-ports-archive-keyring_2023.02.01_all.deb
        sudo dpkg -i /tmp/debian-ports-archive-keyring_2023.02.01_all.deb
    fi
fi

# install base files
sudo -E debootstrap \
            --arch=riscv64 \
            --keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg \
            --include=debian-ports-archive-keyring \
            unstable \
            ${NFS_PATH} \
            http://deb.debian.org/debian-ports

# chroot in and set up
cd `dirname $0`
SETUP_SCRIPT=setup_nfs_rootfs.sh
sudo cp ${SETUP_SCRIPT} ${NFS_PATH}
sudo chroot ${NFS_PATH} ./${SETUP_SCRIPT} $http_proxy
sudo rm ${NFS_PATH}/${SETUP_SCRIPT}
