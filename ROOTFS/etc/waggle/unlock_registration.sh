#!/bin/bash

#check if waggle registartion is in the right place, if so, change permissions.
touch /etc/waggle/id_rsa_waggle_registration
if [ "$(shasum /etc/waggle/id_rsa_waggle_registration | cut -d ' ' -f 1)" == "5fd9b3233c94e6b17f67120222c1e765530cb149" ]; then
 echo "Registration Key in-place, continuing..."
else
 echo "Please unlock the registration key to continue..."
 openssl aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -d -in /etc/waggle/id_rsa_waggle_registration.enc -out /etc/waggle/id_rsa_waggle_registration
 chmod 600 /etc/waggle/id_rsa_waggle_registration
fi
