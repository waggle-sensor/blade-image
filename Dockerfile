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
    ca-certificates=20211016ubuntu0.18.04.1 \
    curl=7.58.0-2ubuntu3.22 \
    gnupg-agent=2.2.4-1ubuntu1.6 \
    software-properties-common=0.96.24.32.20
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Base OS additional packages
ARG REQ_PACKAGES
RUN mkdir -p /iso/pool/contrib
RUN cd /iso/pool/contrib; apt-get update && apt-get download -y $REQ_PACKAGES

# NVidia additional packages
ARG REQ_PACKAGES_NVIDIA
RUN cd /tmp \
    && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-keyring_1.0-1_all.deb \
    && dpkg -i cuda-keyring_1.0-1_all.deb
COPY ROOTFS/etc/apt/trusted.gpg.d/*.asc /etc/apt/trusted.gpg.d/
COPY ROOTFS/etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/
RUN mkdir -p /iso/pool/contrib
RUN cd /iso/pool/contrib; apt-get update && apt-get download -y $REQ_PACKAGES_NVIDIA

# Download the Waggle RPI package that needs to be installed to a separate partition
RUN mkdir -p /iso/pool/special
RUN cd /iso/pool/special ; \
    wget https://github.com/waggle-sensor/waggle-rpi-pxeboot/releases/download/v2.3.0/sage-rpi-pxeboot_2.3.0_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-rpi-pxeboot/releases/download/v2.3.0/sage-rpi-pxeboot-boot_2.3.0_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-rpi-pxeboot/releases/download/v2.3.0/sage-rpi-pxeboot-os-usrlibfw_2.3.0_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-rpi-pxeboot/releases/download/v2.3.0/sage-rpi-pxeboot-os-usrlib_2.3.0_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-rpi-pxeboot/releases/download/v2.3.0/sage-rpi-pxeboot-os-other_2.3.0_all.deb

# Waggle packages
RUN cd /iso/pool/contrib; \
    wget https://github.com/waggle-sensor/waggle-common-tools/releases/download/v1.0.0/waggle-common-tools_1.0.0_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-nodeid/releases/download/v1.0.7/waggle-nodeid_1.0.7_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-node-hostname/releases/download/v1.2.1/waggle-node-hostname_1.2.1_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-bk-registration/releases/download/v2.2.2/waggle-bk-registration_2.2.2_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-bk-reverse-tunnel/releases/download/v2.3.2/waggle-bk-reverse-tunnel_2.3.2_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-wan-tunnel/releases/download/v1.0.0/waggle-wan-tunnel_1.0.0_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-internet-share/releases/download/v1.4.1/waggle-internet-share_1.4.1_all.deb ; \
    wget https://github.com/waggle-sensor/waggle-firewall/releases/download/v1.1.3/waggle-firewall_1.1.3_all.deb
ARG REQ_PACKAGES_WAGGLE="waggle-common-tools waggle-nodeid waggle-node-hostname waggle-bk-registration waggle-bk-reverse-tunnel waggle-wan-tunnel waggle-internet-share waggle-firewall"

# Download the Waggle python packages to be installed to the end-system
#  - python versions match end-system verions
RUN apt-get update && apt-get install -y \
    python3.6=3.6.9-1~18.04ubuntu1.9 \
    python3-pip=9.0.1-2.3~ubuntu1.18.04.6
RUN mkdir -p /iso/waggle/pip
COPY required_pip_packages.txt /iso/waggle/pip/
# - this will download all packages and dependencies
RUN python3 -m pip download -r /iso/waggle/pip/required_pip_packages.txt -d /iso/waggle/pip

COPY iso_tools /iso_tools
# Add additional packages to install list in pressed
ARG PARTITION_LAYOUT
RUN cd /iso_tools; sed "s|{{REQ_PACKAGES}}|${REQ_PACKAGES}|" preseed.seed.base \
    | sed "s|{{REQ_PACKAGES_NVIDIA}}|${REQ_PACKAGES_NVIDIA}|" \
    | sed "s|{{REQ_PACKAGES_WAGGLE}}|${REQ_PACKAGES_WAGGLE}|" \
    | sed "s|{{PARTITION_LAYOUT}}|${PARTITION_LAYOUT}|" > preseed.seed

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

# Add k3s binary and install script for a later install
RUN mkdir -p /ROOTFS/etc/waggle/k3s_config; \
    cd /ROOTFS/etc/waggle/k3s_config; \
    curl -sfL https://get.k3s.io > k3s_install.sh ; \
    chmod +x k3s_install.sh
RUN mkdir -p /ROOTFS/usr/local/bin/ ; \
    cd /ROOTFS/usr/local/bin/ ; \
    wget https://github.com/rancher/k3s/releases/download/v1.20.15+k3s1/k3s ; \
    chmod +x k3s

# Make custom file system changes for VM mode
ARG VM_MODE
RUN if [ -n "$VM_MODE" ]; then \
    mv /ROOTFS/etc/waggle/config-vm.ini /ROOTFS/etc/waggle/config.ini ; \
    else \
    rm /ROOTFS/etc/waggle/config-vm.ini ; \
    fi

COPY create_image.sh .
