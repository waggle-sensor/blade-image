#!/bin/bash -e

print_help() {
  echo """
usage: build.sh [-d] [-f] [-o] [-v]

Create a modified Ubuntu ISO from a base Ubuntu ISO that contains all
neccessary packages and Waggle software tools for installation on a Dell blade.

  -o : (optional) output filename (i.e. custom_name) (default: dell)
  -d : don't build the image and enter debug mode within the Docker build environment.
  -f : force the build to proceed (debugging only) without checking for tagged commit
  -v : build the image for a test virtual machine
  -? : print this help menu
"""
}

CMD="./create_image.sh"
OUTPUT_NAME="waggle-ubuntu"
BUILDNAME="dell"
UBUNTU_IMG="ubuntu-18.04.5-server-amd64.iso"
FORCE=
TTY=
PARTITION_LAYOUT=$(cat ./iso_tools/partition_layout_dell)
VM_MODE=
while getopts "o:fdv?" opt; do
  case $opt in
    o) OUTPUT_NAME=$OPTARG
      ;;
    d) # enable debug mode
      echo "** DEBUG MODE **"
      set +x
      TTY="-it"
      CMD="/bin/bash"
      ;;
    f) # force build
      echo "** Force build: ignore tag depth check **"
      FORCE=1
      ;;
    v) # vm mode
      echo "** VM mode: build for virtual machine **"
      PARTITION_LAYOUT=$(cat ./iso_tools/partition_layout_vm)
      VM_MODE=1
      ;;
    ?|*)
      print_help
      exit 1
      ;;
  esac
done

# create version string
PROJ_VERSION="${BUILDNAME}-$(git describe --tags --long --dirty | cut -c2-)"

TAG_DEPTH=$(echo ${PROJ_VERSION} | cut -d '-' -f 3)
if [[ -z "${FORCE}" && "${TAG_DEPTH}_" != "0_" ]]; then
  echo "Error:"
  echo "  The current git commit has not been tagged. Please create a new tag first to ensure a proper unique version number."
  echo "  Use -f to ignore error (for debugging only)."
  exit 1
fi

echo "Build Parameters:"
echo -e " Ubuntu image:\t${UBUNTU_IMG}"
echo -e " Output name:\t${OUTPUT_NAME}"
echo -e " Version:\t${PROJ_VERSION}"
echo -e " VM Mode\t${VM_MODE}"

PWD=`pwd`

# get the list of all required debian packages to install in final image
REQ_PACKAGES=$(sed -e '/^#/d' required_deb_packages.txt | tr '\n' ' ')
REQ_PACKAGES_NVIDIA=$(sed -e '/^#/d' required_deb_nvidia_packages.txt | tr '\n' ' ')

# create and run the Docker build environment
docker build -f Dockerfile -t blade_image_build \
    --build-arg UBUNTU_IMG="${UBUNTU_IMG}" \
    --build-arg REQ_PACKAGES="${REQ_PACKAGES}" \
    --build-arg REQ_PACKAGES_NVIDIA="${REQ_PACKAGES_NVIDIA}" \
    --build-arg PARTITION_LAYOUT="${PARTITION_LAYOUT}" \
    --build-arg VM_MODE="${VM_MODE}" .
docker run $TTY --rm --privileged \
    -v ${PWD}:/output \
    --env UBUNTU_IMG=${UBUNTU_IMG} \
    --env OUTPUT_NAME=${OUTPUT_NAME} \
    --env PROJ_VERSION=${PROJ_VERSION} \
    blade_image_build $CMD
