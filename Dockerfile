# ANL:waggle-license
#  This file is part of the Waggle Platform.  Please see the file
#  LICENSE.waggle.txt for the legal details of the copyright and software
#  license.  For more details on the Waggle project, visit:
#           http://www.wa8.gl
# ANL:waggle-license

FROM amd64/ubuntu:bionic-20200921

RUN apt-get update && apt-get install -y \
    curl \
    mkisofs \
    wget \
    bsdtar \
    dpkg-dev \
    apt-utils \
    vim

# Download the base Ubuntu ISO (don't use var in curl to use docker cache)
ARG UBUNTU_IMG
RUN curl -L https://old-releases.ubuntu.com/releases/bionic/${UBUNTU_IMG} > /${UBUNTU_IMG} \
    && mkdir -p /iso && bsdtar -C iso/ -xf /${UBUNTU_IMG} && chmod -R +w /iso

ARG REQ_PACKAGES
RUN mkdir -p /iso/pool/contrib
RUN cd /iso/pool/contrib; apt-get update && apt-get download -y $REQ_PACKAGES

COPY iso_tools /iso_tools

# update the apt archives in ISO
RUN mkdir -p /iso/dists/bionic/contrib/binary-amd64
RUN apt-ftparchive generate /iso_tools/config-deb
# generate new checksums for new apt repository files
RUN sed -i '/SHA256:/,$d' /iso/dists/bionic/Release
RUN apt-ftparchive release /iso/dists/bionic >> /iso/dists/bionic/Release
# remove the signature check as we have created a new Release
RUN rm /iso/dists/bionic/Release.gpg

# create new iso md5 checksum file
RUN cd /iso; md5sum `find ! -name "md5sum.txt" ! -path "./isolinux/*" -follow -type f` > md5sum.txt;

# Copy final system root file system files
COPY ROOTFS/ /ROOTFS

COPY create_image.sh .
