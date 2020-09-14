#!/bin/bash

sed -i '/efi/d' /etc/fstab
sed -i '/\/media\/sys-data/d' /etc/fstab
umount /boot/efi
umount /media/sys-data

mkdir -p /root/.ssh/
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEScCdR3mr+QgCnuvGSwsjw1lmatwrHvVvUtEoc7du5vCMTXT25L3rqhaG8Ngy4OTAfVEtSR0qfgJ6UrH1oyacPMBYAETOfnHqKqoi1Dcej9f3+QuBNA7pOIjLK2jqbK+VGPHEM9NVKXb8XbcL9mpn+sKy4f2J1kRMD79+5R+8EbV2jVcwwOa/1+bsbF/jtGlmoHD4RbNHrO65Y2BuLpQMYSv4Q0lwwe/pwYSYgCkeD0ve9XfwZktnluYyOQjaTw+qyMpNjfYCfWDHZtKHeUCRcNgpXydcJ6Obc/h9kQQC1ZWU1GDc+BFWwo/ZLrHeedilggUwRTqpM9j3lYPi1NfX /home/rajesh/.ssh/id_rsa_waggle_user" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsYPMSrC6k33vqzulXSx8141ThfNKXiyFxwNxnudLCa0NuE1SZTMad2ottHIgA9ZawcSWOVkAlwkvufh4gjA8LVZYAVGYHHfU/+MyxhK0InI8+FHOPKAnpno1wsTRxU92xYAYIwAz0tFmhhIgnraBfkJAVKrdezE/9P6EmtKCiJs9At8FjpQPUamuXOy9/yyFOxb8DuDfYepr1M0u1vn8nTGjXUrj7BZ45VJq33nNIVu8ScEdCN1b6PlCzLVylRWnt8+A99VHwtVwt2vHmCZhMJa3XE7GqoFocpp8TxbxsnzSuEGMs3QzwR9vHZT9ICq6O8C1YOG6JSxuXupUUrHgd /home/rajesh/.ssh/id_rsa_waggle_aot" >> /root/.ssh/authorized_keys


mkdir -p /etc/waggle/

#console com2 config
cat << EOF | tee /etc/default/grub
GRUB_DEFAULT=0
GRUB_TIMEOUT=1
GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo Debian\`
GRUB_CMDLINE_LINUX_DEFAULT=""
GRUB_CMDLINE_LINUX="console=tty1 console=ttyS0,115200"
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"
EOF

grub-mkconfig -o /boot/grub/grub.cfg

mv /root/version /etc/sage_version_os
rm /etc/rc.local
reboot
