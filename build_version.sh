#!/bin/bash

BASE_VERSION="$(cat 'version' | xargs).${BUILD_NUMBER:-local}"
GIT_SHA=$(git rev-parse --short HEAD)
DIRTY=$([[ -z $(git status -s) ]] || echo '-dirty')
PROJ_VERSION=${BASE_VERSION}-${GIT_SHA}${DIRTY}

echo $PROJ_VERSION > blade-image-build/ROOTFS/opt/sage/blade/image/wscripts/version
