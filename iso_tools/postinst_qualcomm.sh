#post installation script to install qualcomm sdks


POSTINST_TARGET_QUALCOMM_PATH=/target/postinst/qualcomm
CD_QUALCOMM_APP_SDK_PATH=/cdrom/qualcomm/qaic-apps*
CD_QUALCOMM_PLATFORM_SDK_PATH=/cdrom/qualcomm/qaic-platform*
SDK_QUALCOMM_TARGET_PATH=${POSTINST_TARGET_QUALCOMM_PATH}/sdks
DEB_QUALCOMM_CD_PATH=/cdrom/pool/qualcomm
DEB_QUALCOMM_TARGET_PATH=${POSTINST_TARGET_QUALCOMM_PATH}/debs
PYTHON_CD_QUALCOMM_PATH=/cdrom/qualcomm/pip
PYTHON_QUALCOMM_TARGET_PATH=${POSTINST_TARGET_QUALCOMM_PATH}/pip


mkdir -p ${POSTINST_TARGET_QUALCOMM_PATH}

echo "Copy required debian package(s) to ${DEB_QUALCOMM_TARGET_PATH}"
mkdir -p ${DEB_QUALCOMM_TARGET_PATH}
for deb in ${DEB_QUALCOMM_CD_PATH}/*.deb; do
    echo "Copying qualcomm deb [${DEB_QUALCOMM_CD_PATH}/$(basename $deb)] -> ${DEB_QUALCOMM_TARGET_PATH}"
    cp $deb ${DEB_QUALCOMM_TARGET_PATH}
done

#copy pip files
echo "Copy python package(s) to ${PYTHON_QUALCOMM_TARGET_PATH}"
mkdir -p ${PYTHON_QUALCOMM_TARGET_PATH}
for pip in ${PYTHON_CD_QUALCOMM_PATH}/*; do
    echo "Copying python package [$pip] -> ${PYTHON_QUALCOMM_TARGET_PATH}"
    cp $pip ${PYTHON_QUALCOMM_TARGET_PATH}
done


#copy SDK files
echo "copy SDK files"
mkdir -p ${SDK_QUALCOMM_TARGET_PATH}
echo "Copying app sdk ${CD_QUALCOMM_APP_SDK_PATH}"
cp -R ${CD_QUALCOMM_APP_SDK_PATH} ${SDK_QUALCOMM_TARGET_PATH}
echo "Copying app sdk ${CD_QUALCOMM_PLATFORM_SDK_PATH}"
cp -R ${CD_QUALCOMM_PLATFORM_SDK_PATH} ${SDK_QUALCOMM_TARGET_PATH}







