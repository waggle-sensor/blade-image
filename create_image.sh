#!/bin/bash -e

echo "Building Dell Waggle Ubuntu [$PROJ_VERSION]"

#grab neccessary build files
cp /iso_tools/preseed.seed /iso/preseed/
cp /iso_tools/grub.cfg /iso/boot/grub/grub.cfg
cp /iso_tools/txt.cfg /iso/isolinux/txt.cfg

# count the added debs
echo "Count list of additional debs"
ls -lah /iso/pool/contrib/*
echo "Additional Debs: $(ls -la /iso/pool/contrib/* | wc -l) [$(du -hs /iso/pool/contrib/)]"

mkdir -p /ROOTFS/etc
echo $PROJ_VERSION > /ROOTFS/etc/waggle_version_os

# copy all the Waggle specifics for the end file-system to the ISO
echo "Copy SAGE rootfs to ISO"
cp -r /ROOTFS /iso/

echo "Make the ISO"
ouputfile="${OUTPUT_NAME}_${PROJ_VERSION}.iso"
pushd /iso
mkisofs -D -r -V "AUTOINSTALL" -cache-inodes -J -l -b isolinux/isolinux.bin \
    -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o \
    /tmp/${ouputfile} .
popd
mv /tmp/${ouputfile} /output
echo "ISO [${ouputfile}] created successfully."
