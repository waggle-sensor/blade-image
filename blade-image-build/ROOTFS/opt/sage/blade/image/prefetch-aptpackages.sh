#!/bin/bash
apt-get update
apt-get -y --download-only install ssh ansible git htop iotop iftop bwm-ng screen nmap sshfs autossh network-manager apt-transport-https ca-certificates curl gnupg-agent software-properties-common
