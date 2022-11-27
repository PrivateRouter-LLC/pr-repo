#!/bin/bash

# If we are not connected to the internet, exit this updater
is_connected() {
    ping -q -c3 1.1.1.1 >/dev/null 2>&1
    return $?
}

[ is_connected ] || exit 0

# Always install our repo's public key to the router
wget -qO /tmp/public.key https://repo.privaterouter.com/public.key
opkg-key add /tmp/public.key
rm /tmp/public.key 

# Always update the repo
sed -i '/privaterouter_repo/d' /etc/opkg/customfeeds.conf 
echo "src/gz privaterouter_repo https://repo.privaterouter.com" >> /etc/opkg/customfeeds.conf

# This script is used to update the packages in the repo
opkg update
[ $? -eq 0 ] && {
    opkg install tgwireguard
    opkg install tgdocker
}