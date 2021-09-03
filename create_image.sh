#!/bin/bash -e

echo "Building Dell Waggle Ubuntu [$VERSION]"

#unpack iso
mkdir /mnt/iso
mount -o loop /${UBUNTU_IMG} /mnt/iso/

#copy contents to rw access
mkdir /iso
cp -rT /mnt/iso/ /iso/
umount /mnt/iso/

#grab neccessary build files
cp /iso_tools/preseed.seed /iso/preseed/
cp /iso_tools/grub.cfg /iso/boot/grub/grub.cfg
cp /iso_tools/txt.cfg /iso/isolinux/txt.cfg

# copy required debs
mkdir -p /iso/pool/extras
cp -r /isodebs/* /iso/pool/extras/

mkdir -p /ROOTFS/etc
echo $VERSION > /ROOTFS/etc/waggle_version_os

mkdir -p /ROOTFS/usr/local/bin/
wget https://github.com/rancher/k3s/releases/download/v1.20.0+k3s2/k3s
chmod +x k3s
cp k3s /ROOTFS/usr/local/bin/

# copy all the Waggle specifics for the end file-system to the ISO
cp -r /ROOTFS /iso/

ouputfile="$OUTPUT_NAME_$VERSION.iso"
pushd /iso
mkisofs -D -r -V "AUTOINSTALL" -cache-inodes -J -l -b isolinux/isolinux.bin \
    -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o \
    /tmp/${ouputfile} .
popd
mv /tmp/${ouputfile} /output
echo "ISO [${ouputfile}] created successfully."
