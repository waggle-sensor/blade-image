#!/bin/bash

#pull image we'll be working on
wget http://cdimage.ubuntu.com/releases/18.04/release/ubuntu-18.04.5-server-amd64.iso

#unpack iso
mkdir /mnt/iso  
mount -o loop ubuntu-18.04.5-server-amd64.iso /mnt/iso/  

#move contents to rw access
mkdir iso
cp -rT /mnt/iso/ iso/

#grab neccessary build files eventually we'll just edit them
cp preseed.seed iso/preseed/

cp grub.cfg iso/boot/grub/grub.cfg
cp txt.cfg iso/isolinux/txt.cfg

mkdir -p iso/wscripts
cp -r wscripts/* iso/wscripts

cd iso/
mkisofs -D -r -V "AUTOINSTALL" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o /output/dockerauto.iso .
