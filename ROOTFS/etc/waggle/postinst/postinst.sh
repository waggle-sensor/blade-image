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
INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_SKIP_START=true K3S_CLUSTER_SECRET=4tX0DUZ0uQknRtVUAKjt /etc/waggle/k3s_config/k3s_install.sh

# sync the disk and unmount the media partition
echo "Un-mount ${MEDIA_PARTITION}"
sync
umount ${MEDIA_PARTITION}

echo "Remake GRUB to enable serial console output"
grub-mkconfig -o /boot/grub/grub.cfg

# disable all other MOTD and enable the WaggleOS MOTD
echo "Enable the WaggleOS MOTD"
chmod -x /etc/update-motd.d/*
sed -i 's/^ENABLED=1/ENABLED=0/' /etc/default/motd-news
systemctl disable motd-news.service
systemctl disable motd-news.timer
chmod +x /etc/update-motd.d/*waggle*

# disable apt-update timers
echo "Disable apt-update timers"
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer

# enable the graceful k3s shutdown service
systemctl enable waggle-k3s-shutdown
