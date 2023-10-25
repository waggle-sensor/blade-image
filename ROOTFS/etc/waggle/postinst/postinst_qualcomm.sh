POSTINST_QUALCOMM_PATH=/postinst/qualcomm
QUALCOMM_DEB_PATH=${POSTINST_QUALCOMM_PATH}/debs
QUALCOMM_PYTHON_PATH=${POSTINST_QUALCOMM_PATH}/pip
QUALCOMM_APP_SDK_PATH=${POSTINST_QUALCOMM_PATH}/sdks/qaic-apps-*
QUALCOMM_PLATFORM_SDK_PATH=${POSTINST_QUALCOMM_PATH}/sdks/qaic-platform-*
QUALCOMM_EV_PATH=/postinst/qualcomm_ev.sh

#set up enviornmental variables.
export LD_LIBRARY_PATH=“$LD_LIBRARY_PATH:/opt/qti-aic/dev/lib/x86_64” 
export PATH="/usr/local/bin:$PATH"
export PATH="$PATH:/opt/qti-aic/tools:/opt/qti-aic/exec:/opt/qti-aic/scripts"
export QRAN_EXAMPLES="/opt/qti-aic/examples"
export PYTHONPATH="$PYTHONPATH:/opt/qti-aic/dev/lib/x86_64"
export QAIC_APPS="/opt/qti-aic/examples/apps"
export QAIC_LIB="/opt/qti-aic/dev/lib/x86_64/libQAic.so"
export QAIC_COMPILER_LIB="/opt/qti-aic/dev/lib/x86_64/libQAicCompiler.so"

cat ${QUALCOMM_EV_PATH} | tee -a  /home/waggle/.bashrc


# loop over the debs and install them
for deb in ${QUALCOMM_DEB_PATH}/*.deb; do
    debpath=${QUALCOMM_DEB_PATH}/$(basename $deb)
    echo "Installing special deb [${debpath}]"
    dpkg -i ${debpath}
    echo "Remove the cached special deb [${debpath}]"
    rm -rf ${debpath}
done


# install the required python packags
echo "Install python packages [${QUALCOMM_PYTHON_PATH}]"
python3 -m pip install -r ${QUALCOMM_PYTHON_PATH}/required_pip_qualcomm_packages.txt --no-index --find-links=file://${QUALCOMM_PYTHON_PATH}

# install platform SDK

${QUALCOMM_PLATFORM_SDK_PATH}/x86_64/deb/install.sh
# install apps SDK
${QUALCOMM_APP_SDK_PATH}/install.sh


#remove all SDKs

rm -rf ${POSTINST_QUALCOMM_PATH}
# delete the cache directory
