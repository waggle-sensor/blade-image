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