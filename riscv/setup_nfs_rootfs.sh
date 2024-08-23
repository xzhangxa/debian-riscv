#!/bin/bash

set -e

if [ $# -eq 1 ]; then
    export http_proxy="$1"
    export https_proxy="$1"
fi

# Update package information
apt-get update
apt-get install -y dropbear
apt-get clean

echo debian > /etc/hostname
echo -e "127.0.1.1\tdebian" > /etc/hosts

echo "root:debian" | chpasswd

systemctl disable networking.service
systemctl disable e2scrub_reap.service

exit
