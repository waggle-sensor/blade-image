#!/bin/bash -x

# Operations to perform at the very end of ISO installation on the target system

MEDIA_PARTITION=/dev/sda5
MEDIA_PATH=/media/plugin-data

# Remove undesired packages
echo "Remove undesired packages"
apt-get purge -y \
    rsyslog \
    logrotate \
    snapd \
    unattended-upgrades
apt-get autoremove -y

# Remove partitions from fstab that we don't want to automount
echo "Removing efi and media/system-data from /etc/fstab"
sed -i '/efi/d' /etc/fstab
sed -i '/\/media\/system-data/d' /etc/fstab

# configure root overlay
echo "Enable overlayroot file system"
sed -i 's|overlayroot=""|overlayroot="device:dev=/dev/sda4,timeout=180,recurse=0,swap=1"|' /etc/overlayroot.conf

# update ssh conf
echo "Configure SSHD Config"
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config
echo "ListenAddress 127.0.0.1" >> /etc/ssh/sshd_config

echo "Mount ${MEDIA_PARTITION} -> ${MEDIA_PATH}"
mount ${MEDIA_PARTITION} ${MEDIA_PATH}

# configure docker plugin-data partition
echo "Move Docker storage to external media"
systemctl stop docker
rm -rf /var/lib/docker
mkdir -p ${MEDIA_PATH}/docker
ln -s ${MEDIA_PATH}/docker /var/lib/docker

#configure k3s plugin-data partition
echo "Move k3s storage to external media"
mkdir -p ${MEDIA_PATH}/k3s/etc/rancher
mkdir -p ${MEDIA_PATH}/k3s/kubelet
mkdir -p ${MEDIA_PATH}/k3s/rancher
ln -s ${MEDIA_PATH}/k3s/etc/rancher/ /etc/rancher
ln -s ${MEDIA_PATH}/k3s/kubelet/ /var/lib/kubelet
ln -s ${MEDIA_PATH}/k3s/rancher/ /var/lib/rancher
INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_SKIP_START=true /etc/waggle/k3s_config/k3s_install.sh

echo "Remake GRUB to enable serial console output"
grub-mkconfig -o /boot/grub/grub.cfg
