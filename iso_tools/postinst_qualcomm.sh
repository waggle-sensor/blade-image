#!/bin/sh -x

# Operations to perform at the very end of ISO installation running in the installer context

POSTINST_TARGET_PATH=/target/postinst
SPECIAL_DEB_CD_PATH=/cdrom/pool/special/
SPECIAL_DEB_TARGET_PATH=${POSTINST_TARGET_PATH}/debs
PYTHON_CD_PATH=/cdrom/waggle/pip/
PYTHON_TARGET_PATH=${POSTINST_TARGET_PATH}/pip/

QUALCOMM_DRIVER_CD_PATH=/cdrom/qualcomm/
QUALCOMM_DRIVER_TARGET_PATH=${postinst_target_path}/qualcomm


POST_INST_FILE=/etc/waggle/postinst/postinst.sh

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

echo "Copy python package(s) to ${PYTHON_TARGET_PATH}"
mkdir -p ${PYTHON_TARGET_PATH}
for pip in ${PYTHON_CD_PATH}/*; do
    echo "Copying python package [$pip] -> ${PYTHON_TARGET_PATH}"
    cp $pip ${PYTHON_TARGET_PATH}
done


echo "Copy qualcomm drivers to ${QUALCOMM_DRIVER_TARGET_PATH}"
mkdir -p ${QUALCOM_DRIVER_TARGET_PATH}
cp -a ${QUALCOMM_DRIVER_CD_PATH}/. ${QUALCOMM_DRIVER_TARGET_PATH}


echo "Add installation step to the post installer"
echo "${QUALCOMM_DRIVER_TARGET_PATH}/qaic-platform-sdk-1.9.0.159/x86_64/deb/install.sh">>${POST_INST_FILE}
echo "${QUALCOMM_DRIVER_TARGET_PATH}/qaic-apps-1.9.0.159/install.sh">>${POST_INST_FILE}
