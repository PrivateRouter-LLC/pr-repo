#!/bin/bash

# Get the name of the script without the path
SCRIPT_NAME=$(basename "$0")

# Count the number of running instances of the script (excluding the current one)
NUM_INSTANCES=$(pgrep -f "${SCRIPT_NAME}" | grep -v "$$" | wc -l)

# If more than one instance is found, exit
if [ "$NUM_INSTANCES" -gt 1 ]; then
    log_say "${SCRIPT_NAME} is already running, exiting."
    exit 1
fi

# Log to the system log and echo if needed
log_say()
{
    SCRIPT_NAME=$(basename "$0")
    echo "${SCRIPT_NAME}: ${1}"
    logger "${SCRIPT_NAME}: ${1}"
    echo "${SCRIPT_NAME}: ${1}" >> "/tmp/${SCRIPT_NAME}.log"
}

# Command to wait for Internet connection
wait_for_internet() {
    while ! ping -q -c3 1.1.1.1 >/dev/null 2>&1; do
        log_say "Waiting for Internet connection..."
        sleep 1
    done
    log_say "Internet connection established"
}

# Wait for Internet connection
wait_for_internet

# Command to wait for opkg to finish
wait_for_opkg() {
  while pgrep -x opkg >/dev/null; do
    log_say "Waiting for opkg to finish..."
    sleep 1
  done
  log_say "opkg is released, our turn!"
}

# Wait for opkg to finish
wait_for_opkg

# Always install our repo's public key to the router
log_say "Installing PrivateRouter repo public key"
wget -qO /tmp/public.key https://repo.privaterouter.com/public.key
opkg-key add /tmp/public.key
rm /tmp/public.key 

# Always update the repo
log_say "Add PrivateRouter repo"
sed -i '/privaterouter_repo/d' /etc/opkg/customfeeds.conf 
echo "src/gz privaterouter_repo https://repo.privaterouter.com" >> /etc/opkg/customfeeds.conf

# Temp fix to remove v2raya repo until we can find a backup
sed -i '/v2raya/d' /etc/opkg/customfeeds.conf

# Make sure we have ran opkg update at least once
log_say "Waiting for opkg update to succesfully run..."
while ! opkg update >/tmp/opkg_update.log 2>&1; do
    log_say "... Waiting for opkg update to succesfully run ..."
    sleep 1
done

# This script is used to update the packages in the repo

# not everyone gets these packages
# opkg install tgopenvpn tgsstp tganyconnect

# If we are on a "mini" or "mesh" device, we don't need the docker package
# We check for the existence of the /etc/pr-mini /etc/pr-mesh file to determine

if [ -f /etc/pr-mesh ]; then
    ## INSTALL MESH LEAN PROFILE ##
    log_say "Installing Mesh Packages..."
    opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard
    opkg remove wpad wpad-basic wpad-basic-openssl wpad-basic-wolfssl wpad-wolfssl
    opkg install wpad-mesh-openssl kmod-batman-adv batctl avahi-autoipd mesh11sd batctl-full luci-app-dawn
    opkg install /etc/luci-app-easymesh_2.1_all.ipk
    exit 0 
fi

if [ -f /etc/pr-mini ]; then
    ## INSTALL ROUTER APP STORE ##
    log_say "Installing Router App Store..."
    opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard tgwireguard tgopenvpn
    
    ## REMOVE PACKAGES INSTALLED BY ERROR ##
    opkg remove luci-lib-taskd taskd tgappstore luci-lib-xterm luci-lib-fs luci-app-filetransfer luci-app-docker-backup luci-app-nextcloud
    opkg remove luci-app-jellyfin luci-app-homeassistant tgdocker kmod-veth uxc procd-ujail procd-ujail-console
    opkg remove luci-app-simplex luci-app-photoprism luci-app-libreddit luci-app-nodered luci-app-diskman
    opkg remove luci-app-syncthing luci-app-qbittorrentdocker luci-app-megamedia luci-app-whoogle luci-app-nfs luci-app-webtop luci-app-alltube
    opkg remove luci-app-emby luci-app-joplin luci-app-bookstack luci-app-filebrowser luci-app-heimdall luci-app-seafile
    exit 0 
else
    log_say "Installing PrivateRouter Cloud Packages"
	opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard
    opkg remove wpad wpad-basic wpad-basic-openssl wpad-basic-wolfssl wpad-wolfssl
    opkg install wpad-mesh-openssl kmod-batman-adv batctl avahi-autoipd
    opkg install luci-lib-taskd taskd tgappstore luci-lib-xterm luci-lib-fs luci-app-docker-backup luci-app-shortcutmenu tgwireguard luci-app-nextcloud
    opkg install luci-app-poweroff tgdocker kmod-veth uxc procd-ujail procd-ujail-console
    opkg install tgappstore luci-app-wizard luci-app-diskman
    opkg install luci-app-syncthing luci-app-qbittorrentdocker
    opkg install luci-app-filebrowser kmod-igc tgopenvpn tgsstp tganyconnect
fi
