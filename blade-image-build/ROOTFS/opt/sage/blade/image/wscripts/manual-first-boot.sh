#!/bin/bash

#check if waggle registartion is in the right place, if so, change permissions.
touch /etc/waggle/id_rsa_waggle_registration
if [ "$(shasum /etc/waggle/id_rsa_waggle_registration | cut -d ' ' -f 1)" == "5fd9b3233c94e6b17f67120222c1e765530cb149" ]; then
 echo "Registration Key in-place, continuing..."
else
 echo "Please unlock the registration key to continue..."
 openssl aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in /root/id_rsa_waggle_registration.enc -out /etc/waggle/id_rsa_waggle_registration
 chmod 600 /etc/waggle/id_rsa_waggle_registration
fi



#check if network is good, if so, execute the rest
echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Online, proceeding with installations."
    echo "140.221.47.67 beehive" >> /etc/hosts
    ln -s /media/plugin-data /var/lib/docker

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    apt-get -y update
    apt-get -y install $(cat /root/base_packages)
    apt-get -y install docker-ce docker-ce-cli containerd.io

    curl -L https://github.com/waggle-sensor/beekeeper-registration/releases/download/v1.1.0/waggle-registration_1.1.0.local-47ccaae_all.deb > waggle-registration.deb
    curl -L https://github.com/waggle-sensor/beekeeper-registration/releases/download/v1.1.0/waggle-reverse-tunnel_1.1.0.local-47ccaae_all.deb > waggle-reverse-tunnel.deb

    echo "ListenAddress 127.0.0.1" >> /etc/ssh/sshd_config
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

    systemctl restart ssh

    rm /etc/netplan/*.yaml
    mv /root/01-network-manager-all.yaml /etc/netplan/01-network-manager-all.yaml
    netplan generate
    netplan apply
    systemctl restart network-manager

    dpkg -i waggle-registration.deb
    dpkg -i waggle-reverse-tunnel.deb

    sed -i 's|overlayroot=""|overlayroot="device:dev=/dev/sda4,timeout=180,recurse=0"|' /etc/overlayroot.conf
    echo "Set up finished, please reboot now..."
    #rm -rf /usr/bin/manual-first-boot.sh
    #reboot
else
    echo "Offline, no network connectivity, so trying offline install"
    cp -r /root/apt/* /var/cache/apt/
    sync /var/cache/apt/
    apt-get -y install $(cat /root/base_packages)
    rm /etc/netplan/*.yaml
    cp /root/01-network-manager-all.yaml /etc/netplan/01-network-manager-all.yaml
    netplan generate
    netplan apply
    systemctl restart network-manager
    echo "Offline install completed. Reboot and try the script again on next reboot."
fi
