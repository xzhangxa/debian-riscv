# Build Debian RISC-V Port Image

## Create image file for QEMU or save to a storage (SD card, NVMe SSD etc.)

These scripts could be used to build a Debian RISC-V port image, that could be used on both SiFive HiFive Unmatched board and QEMU, and maybe other compatible platforms.

Run this command to create the image:

```
# ./create_debian_image.sh
```

The image `debian-sid-riscv.img` will be created. Please note currently for Debian RISC-V is not an official architecture, so the image is based on Debian Unstable release (sid).

As the nature of sid, it's rolling release so the created images at different times will be different. In case the created image cannot boot, it may be the latest sid introduces some breaking changes or bugs, please use an previously created image for the time being or wait for sid to fixing the issue and try again.

One additional script `run_qemu.sh` is provided to run the image in QEMU. SSH server is pre-installed in the image and port forwarding is set in this script.

This image could also be flashed in a SD card or NVMe SSD and boot on SiFive HiFive Unmatched board. The generated image is 4 GiB and your storage is surely larger than that, use the script `expand_rootfs.sh` to extend the rootfs partition to use the full disk size.

## Set up NFS folder for Debian rootfs

Please use `create_debian_nfsroot.sh` to create a Deiban RISC-V sid rootfs on the development machine first, then use it as the remote roofs for the VPS Linux. Follow these steps:

```
# assume the the rootfs will be mount to /opt/nfs_debian
# change <VPS_IP> to the IP that VPS Linux gets from DHCP
# change <HOST_IP> to the NFS server's IP

# create Debian rootfs for NFS export
./tools/debian/create_debian_nfsroot.sh /opt/nfs_debian

sudo apt install nfs-kernel-server

# Add the path to NFS export in /etc/exports
# Add this line below
# /opt/nfs_debian         VPS_IP(rw,sync,no_root_squash,no_subtree_check)

sudo systemctl restart nfs-kernel-server

# only if ufw firewall is enabled on your system (if Ubuntu)
sudo ufw allow from VPS_IP to any port nfs

# set kernel cmdline for NFS rootfs boot
# use these kernel parameters: root=/dev/nfs rootfstype=nfs nfsroot=HOST_IP:/opt/nfs_debian,tcp,vers=4 ip=dhcp rw
# please note nfsroot vers being 4 or 3 depends on your development machine
```

## SPEC CPU 2006/2017 build scripts for RISC-V

Please see `spec_cpu/README.md`
