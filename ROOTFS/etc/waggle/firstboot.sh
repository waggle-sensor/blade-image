#!/bin/bash -e

# Helper logging functions to log to rsyslog
# 1: message to log
SYSLOGTAG="waggle-init"
log () {
    echo "$1" | logger -t ${SYSLOGTAG}
}
log_error() {
    echo "$1" | logger -t ${SYSLOGTAG} -p "err"
}
log_warn() {
    echo "$1" | logger -t ${SYSLOGTAG} -p "warning"
}
# forward all stdout/stderr output to our rsyslog
exec 1> >(logger -s -t "$SYSLOGTAG") 2>&1

log "Removing efi and media/sys-data from /etc/fstab"
sed -i '/efi/d' /etc/fstab
sed -i '/\/media\/sys-data/d' /etc/fstab

log "Remake GRUB to enable serial console output"
grub-mkconfig -o /boot/grub/grub.cfg

# configure docker plugin-data partition
log "Move Docker storage to external media"
systemctl stop docker
rm -rf /var/lib/docker
mkdir -p /media/plugin-data/docker
ln -s /media/plugin-data/docker /var/lib/docker

#configure k3s plugin-data partition
log "Move k3s storage to external media"
mkdir -p /media/plugin-data/k3s/kubelet
mkdir -p /media/plugin-data/k3s/rancher
ln -s /media/plugin-data/k3s/kubelet/ /var/lib/kubelet
ln -s /media/plugin-data/k3s/rancher/ /var/lib/rancher
INSTALL_K3S_SKIP_DOWNLOAD=true /etc/waggle/k3s_install.sh

# update ssh conf
log "Configure SSHD Config"
echo "ListenAddress 127.0.0.1" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# configure root overlay
log "Enable overlayroot"
sed -i 's|overlayroot=""|overlayroot="device:dev=/dev/sda4,timeout=180,recurse=0,swap=1"|' /etc/overlayroot.conf

log "Disable first boot script"
mv /etc/waggle/firstboot.sh /etc/waggle/firstboot.sh.$(date '+%Y%m%d-%H%M%S').bck

wall -n "Waggle first boot: configuration complete (reboot needed to finish setup)"
log "First boot configuration complete, Schedule reboot"
shutdown -r +1
