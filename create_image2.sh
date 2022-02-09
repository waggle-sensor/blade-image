#!/bin/bash -e

echo "Building Dell Waggle Ubuntu [$VERSION]"

#grab neccessary build files
cp /iso_tools/preseed.seed /iso/preseed/
cp /iso_tools/grub.cfg /iso/boot/grub/grub.cfg
cp /iso_tools/txt.cfg /iso/isolinux/txt.cfg

# count the added debs
ls -lah /iso/pool/contrib/*
echo "Additional Debs: $(ls -la /iso/pool/contrib/* | wc -l) [$(du -hs /iso/pool/contrib/)]"
# mkdir -p /iso/pool/contrib
# cp -r /isodebs/* /iso/pool/contrib/

mkdir -p /ROOTFS/etc
echo $VERSION > /ROOTFS/etc/waggle_version_os

echo "Downloading & Installing K3S"
mkdir -p /ROOTFS/usr/local/bin/
wget https://github.com/rancher/k3s/releases/download/v1.20.0+k3s2/k3s
chmod +x k3s
cp k3s /ROOTFS/usr/local/bin/

# copy all the Waggle specifics for the end file-system to the ISO
echo "Copy SAGE rootfs to ISO"
cp -r /ROOTFS /iso/

echo "Make the ISO"
ouputfile="${OUTPUT_NAME}_${VERSION}.iso"
pushd /iso
mkisofs -D -r -V "AUTOINSTALL" -cache-inodes -J -l -b isolinux/isolinux.bin \
    -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o \
    /tmp/${ouputfile} .
popd
mv /tmp/${ouputfile} /output
echo "ISO [${ouputfile}] created successfully."
