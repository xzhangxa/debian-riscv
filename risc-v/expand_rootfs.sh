#!/bin/bash

set -e

if [[ $# < 1 ]]; then
    echo "disk not given..."
    echo "example: ./expand_rootfs.sh /dev/sdb"
    exit
fi

if [[ $UID != 0 ]]; then
    echo "use this script with sudo or root"
    exit
fi

apt update
apt install -y cloud-guest-utils e2fsprogs

resize_rootfs_partition()
{
    local device=$(basename ${1})
    local rootfs=$(lsblk -nlo NAME,LABEL /dev/${device} | grep -E "root|rootfs" | cut -d ' ' -f 1 | head -1)
    if [[ -n "${rootfs}" ]]; then
        echo "Resize rootfs partition /dev/${rootfs}"
        growpart "/dev/${device}" "${rootfs/$device/}"
        e2fsck -f "/dev/${rootfs}"
        resize2fs "/dev/${rootfs}"
        sync
    else
        echo "Skip rootfs partition resize: don't know which partition is root"
    fi
}

resize_rootfs_partition ${1}
