#!/bin/bash -x

# Operations to perform at the very end of ISO installation on the target system

MEDIA_PARTITION=/dev/sda6
MEDIA_PATH=/media/plugin-data
RPI_PARTITION=/dev/sda5
RPI_PATH=/media/rpi
SPECIAL_DEB_PATH="/tmp/"

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
mkdir -p ${MEDIA_PATH}
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

# enable the docker registry mirror services
echo "Enable the docker registry mirror services"
mkdir -p ${MEDIA_PATH}/docker_registry/mirrors/docker
systemctl enable waggle-registry-mirror-docker.service
mkdir -p ${MEDIA_PATH}/docker_registry/mirrors/sage
systemctl enable waggle-registry-mirror-sage.service
mkdir -p ${MEDIA_PATH}/docker_registry/local
systemctl enable waggle-registry-local.service

# sync the disk and unmount the media partition
echo "Un-mount ${MEDIA_PARTITION}"
sync
umount ${MEDIA_PARTITION}

# mount the RPi partition and install the "special" debs
echo "Mount ${RPI_PARTITION} -> ${RPI_PATH}"
mkdir -p ${RPI_PATH}
mount ${RPI_PARTITION} ${RPI_PATH}

# loop over the debs and install them
for deb in ${SPECIAL_DEB_PATH}/*.deb; do
    debpath=${SPECIAL_DEB_PATH}/$(basename $deb)
    echo "Installing special deb [${debpath}]"
    dpkg -i ${debpath}
    echo "Remove the cached special deb [${debpath}]"
    rm -rf ${debpath}
done

# sync the disk and unmount the RPi partition
echo "Un-mount ${RPI_PARTITION}"
sync
umount ${RPI_PARTITION}

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
echo "Enable the graceful k3s shutdown service"
systemctl enable waggle-k3s-shutdown

# set proper permissions for files
echo "Set file permissions"
chmod 700 /root/.ssh
chmod 600 /root/.ssh/*
chmod 600 /home/waggle/.ssh/*
chmod 644 /etc/ssh/ssh_known_hosts
chmod 600 /etc/waggle/id_rsa_waggle_registration.enc
chmod 600 /etc/waggle/sage_registration.enc
chmod 600 /etc/waggle/sage_registration-cert.pub
chmod 644 /etc/waggle/sage_registration.pub
chmod 600 /etc/NetworkManager/system-connections/*
chmod 644 /etc/waggle/docker/certs/domain.crt
chmod 600 /etc/waggle/docker/certs/domain.key
chmod 440 /etc/sudoers.d/waggle

## Configure the docker local registry certification
echo "Configure the docker local registry certs"
mkdir -p /etc/docker/certs.d/10.31.81.1\:5000/
cp /etc/waggle/docker/certs/domain.crt /etc/docker/certs.d/10.31.81.1\:5000/
mkdir -p /usr/local/share/ca-certificates
cp /etc/waggle/docker/certs/domain.crt /usr/local/share/ca-certificates/docker.crt
update-ca-certificates

# Add docker registry mirror to Docker deamon (original file )
echo "Configure Docker to use the local registry mirror (for docker.io)"
jq '. += {"registry-mirrors": [ "http://10.31.81.1:5001" ]}' /etc/docker/daemon.json > /tmp/daemon.json
mv /tmp/daemon.json /etc/docker/daemon.json

# disable ipv6
echo "Disable IPv6"
echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf

# add the 'waggle' development user
echo "Add the 'waggle' user"
useradd -m waggle -s /bin/bash
chown -R waggle:waggle /home/waggle
chmod -R +w /home/waggle
