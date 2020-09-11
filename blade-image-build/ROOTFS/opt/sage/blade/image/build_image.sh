#!/bin/bash

#pull image we'll be working on
wget http://cdimage.ubuntu.com/releases/18.04/release/ubuntu-18.04.5-server-amd64.iso

#unpack iso
#mkdir /mnt/iso  
#mount -o loop ubuntu-18.04.5-server-amd64.iso /mnt/iso/  

#move contents to rw access
#mkdir iso
#cp -rT /mnt/iso/ iso/
7z x -oiso ubuntu-18.04.5-server-amd64.iso

#grab neccessary build files eventually we'll just edit them
wget https://raw.githubusercontent.com/sagecontinuum/nodes/master/sage-blade/Blade-Image/greenhouse.seed
cp greenhouse.seed iso/preseed/

wget https://raw.githubusercontent.com/sagecontinuum/nodes/master/sage-blade/Blade-Image/grub.cfg
wget https://raw.githubusercontent.com/sagecontinuum/nodes/master/sage-blade/Blade-Image/txt.cfg

cp grub.cfg iso/isolinux/grub.cfg
cp txt.cfg iso/isolinux/txt.cfg

cd iso/
mkisofs -D -r -V "AUTOINSTALL" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../autoinstall.iso .
