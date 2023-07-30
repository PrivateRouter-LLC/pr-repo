#!/bin/bash

# Log to the system log and echo if needed
log_say()
{
    SCRIPT_NAME=$(basename "$0")
    echo "${SCRIPT_NAME}: ${1}"
    logger "${SCRIPT_NAME}: ${1}"
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

# This script is used to update the packages in the repo
opkg update
[ $? -eq 0 ] && {

    # Everyone gets these packages
    opkg install tgopenvpn tgsstp tganyconnect

    # If we are on a "mini" device, we don't need the docker package
    # We check for the existance of the /etc/pr-mini file to determine
    if [ -f /etc/pr-mini ]; then
        ## INSTALL ROUTER APP STORE ##
        log_say "Installing Router App Store..."
        opkg install tgrouterappstore luci-app-shortcutmenu luci-app-poweroff luci-app-wizard tgwireguard

        ## REMOVE PACKAGES INSTALLED BY ERROR ##
        opkg remove luci-lib-taskd taskd tgappstore luci-lib-xterm luci-lib-fs luci-app-filetransfer luci-app-docker-backup luci-app-nextcloud
        opkg remove luci-app-jellyfin luci-app-homeassistant tgdocker kmod-veth uxc procd-ujail procd-ujail-console
        opkg remove luci-app-simplex luci-app-photoprism luci-app-libreddit luci-app-nodered luci-app-diskman
        opkg remove luci-app-syncthing luci-app-qbittorrentdocker luci-app-megamedia luci-app-whoogle luci-app-nfs luci-app-webtop luci-app-alltube
        opkg remove luci-app-emby luci-app-joplin luci-app-bookstack luci-app-filebrowser luci-app-heimdall luci-app-seafile
    else
        log_say "Installing PrivateRouter Packages"
        opkg install luci-lib-taskd taskd tgappstore luci-lib-xterm luci-lib-fs luci-app-filetransfer luci-app-docker-backup luci-app-shortcutmenu tgwireguard luci-app-nextcloud
        opkg install luci-app-jellyfin luci-app-homeassistant luci-app-poweroff tgdocker kmod-veth uxc procd-ujail procd-ujail-console
        opkg install tgappstore luci-app-wizard luci-app-simplex luci-app-photoprism luci-app-libreddit luci-app-nodered luci-app-diskman
        opkg install luci-app-syncthing luci-app-qbittorrentdocker luci-app-megamedia luci-app-whoogle luci-app-nfs luci-app-webtop luci-app-alltube
        opkg install luci-app-emby luci-app-joplin luci-app-bookstack luci-app-filebrowser luci-app-heimdall luci-app-seafile
    fi
}