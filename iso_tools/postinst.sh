#!/bin/sh -x

# Operations to perform at the very end of ISO installation running in the installer context

POSTINST_TARGET_PATH=/target/postinst
SPECIAL_DEB_CD_PATH=/cdrom/pool/special/
SPECIAL_DEB_TARGET_PATH=${POSTINST_TARGET_PATH}/debs

echo "Copy the ROOTFS to the target system"
cp -r /cdrom/ROOTFS/* /target/

echo "Add write permissions to all copied ROOTFS files"
(cd /cdrom/ROOTFS/ && /usr/bin/find . -type f -exec /bin/chmod +w "/target/{}" \;)

echo "Copy special debian package(s) to ${SPECIAL_DEB_TARGET_PATH}"
mkdir -p ${SPECIAL_DEB_TARGET_PATH}
for deb in ${SPECIAL_DEB_CD_PATH}/*.deb; do
    echo "Copying special deb [${SPECIAL_DEB_TARGET_PATH}/$(basename $deb)] -> ${SPECIAL_DEB_TARGET_PATH}"
    cp $deb ${SPECIAL_DEB_TARGET_PATH}
done
