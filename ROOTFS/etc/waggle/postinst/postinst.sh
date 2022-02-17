#!/bin/bash -x

# Operations to perform at the very end of ISO installation on the target system

# Remove undesired packages
echo "Remove undesired packages"
apt-get purge -y \
    rsyslog \
    logrotate \
    snapd \
    unattended-upgrades
apt-get autoremove -y

# update ssh conf
echo "Configure SSHD Config"
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config
echo "ListenAddress 127.0.0.1" >> /etc/ssh/sshd_config

# configure docker plugin-data partition
echo "Move Docker storage to external media"
systemctl stop docker
rm -rf /var/lib/docker
mkdir -p /media/plugin-data/docker
ln -s /media/plugin-data/docker /var/lib/docker

#configure k3s plugin-data partition
echo "Move k3s storage to external media"
mkdir -p /media/plugin-data/k3s/etc/rancher
mkdir -p /media/plugin-data/k3s/kubelet
mkdir -p /media/plugin-data/k3s/rancher
ln -s /media/plugin-data/k3s/etc/rancher/ /etc/rancher
ln -s /media/plugin-data/k3s/kubelet/ /var/lib/kubelet
ln -s /media/plugin-data/k3s/rancher/ /var/lib/rancher
INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_SKIP_START=true /etc/waggle/k3s_config/k3s_install.sh