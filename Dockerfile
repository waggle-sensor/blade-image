# ANL:waggle-license
#  This file is part of the Waggle Platform.  Please see the file
#  LICENSE.waggle.txt for the legal details of the copyright and software
#  license.  For more details on the Waggle project, visit:
#           http://www.wa8.gl
# ANL:waggle-license

FROM amd64/ubuntu:bionic-20200921

RUN apt-get update && apt-get install -y \
    apt-utils \
    bsdtar \
    curl \
    dpkg-dev \
    mkisofs \
    wget \
    vim

# Download the base Ubuntu ISO (don't use var in curl to use docker cache)
ARG UBUNTU_IMG
RUN curl -L https://old-releases.ubuntu.com/releases/bionic/${UBUNTU_IMG} > /${UBUNTU_IMG} \
    && mkdir -p /iso && bsdtar -C iso/ -xf /${UBUNTU_IMG} && chmod -R +w /iso

# Get the docker apt source as docker is a required package to be downloaded below
RUN apt-get update && apt-get install --no-install-recommends -y \
    apt-transport-https=1.6.12ubuntu0.2 \
    ca-certificates=20210119~18.04.2 \
    curl=7.58.0-2ubuntu3.16 \
    gnupg-agent=2.2.4-1ubuntu1.3 \
    software-properties-common=0.96.24.32.18
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Base OS additional packages
ARG REQ_PACKAGES
RUN mkdir -p /iso/pool/contrib
RUN cd /iso/pool/contrib; apt-get update && apt-get download -y $REQ_PACKAGES

# NVidia additional packages
ARG REQ_PACKAGES_NVIDIA
COPY ROOTFS/etc/apt/trusted.gpg.d/*.asc /etc/apt/trusted.gpg.d/
COPY ROOTFS/etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/
RUN mkdir -p /iso/pool/contrib
RUN cd /iso/pool/contrib; apt-get update && apt-get download -y $REQ_PACKAGES_NVIDIA

# Waggle packages
RUN cd /iso/pool/contrib; \
    wget https://github.com/waggle-sensor/waggle-common-tools/releases/download/v0.4.0/waggle-common-tools_0.4.0_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-nodeid/releases/download/v1.0.6/waggle-nodeid_1.0.6_all.deb ; \
    wget https://github.com/waggle-sensor/node-hostname-service/releases/download/v1.2.0/waggle-node-hostname_1.2.0_all.deb ; \
    wget https://github.com/waggle-sensor/node-registration-service/releases/download/v1.2.3/waggle-registration_1.2.2.local-0575b18_all.deb ; \
    wget https://github.com/waggle-sensor/node-registration-service/releases/download/v1.2.3/waggle-reverse-tunnel_1.2.2.local-0575b18_all.deb ; \
    wget https://github.com/waggle-sensor/node-registration-service/releases/download/v2.2.1/waggle-bk-registration_2.2.1_all.deb ; \
    wget https://github.com/waggle-sensor/node-reverse-tunnel-service/releases/download/v2.3.1/waggle-bk-reverse-tunnel_2.3.1_all.deb
ARG REQ_PACKAGES_WAGGLE="waggle-common-tools waggle-nodeid waggle-node-hostname waggle-registration waggle-reverse-tunnel waggle-bk-registration waggle-bk-reverse-tunnel"

COPY iso_tools /iso_tools
# Add additional packages to install list in pressed
RUN cd /iso_tools; sed "s/{{REQ_PACKAGES}}/${REQ_PACKAGES}/" preseed.seed.base \
    | sed "s/{{REQ_PACKAGES_NVIDIA}}/${REQ_PACKAGES_NVIDIA}/" \
    | sed "s/{{REQ_PACKAGES_WAGGLE}}/${REQ_PACKAGES_WAGGLE}/" > preseed.seed

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
