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
