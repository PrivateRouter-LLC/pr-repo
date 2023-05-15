#!/bin/bash

# If we are not connected to the internet, exit this updater
is_connected() {
    ping -q -c3 1.1.1.1 >/dev/null 2>&1
    return $?
}

# Log to the system log and echo if needed
log_say()
{
    echo "${1}"
    logger "${1}"
}

#[ is_connected ] || { log_say "update-repo-packages - Not Connected!"; exit 0; }

# Check and wait for Internet connection
while ! is_connected; do
    log_say "Waiting for Internet connection..."
    sleep 1
done
log_say "Internet connection established"

# Command to wait for opkg to finish
wait_for_opkg() {
  while pgrep -x opkg >/dev/null; do
    sleep 1
  done
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

# Always install our repo's public key to the router
log_say "Installing v2raya repo public key"
wget -qO /tmp/v2raya.pub https://osdn.net/projects/v2raya/storage/openwrt/v2raya.pub
opkg-key add /tmp/v2raya.pub
rm /tmp/v2raya.pub

# Always update the repo
log_say "Add v2raya repo"
sed -i '/v2raya/d' /etc/opkg/customfeeds.conf 
echo "src/gz v2raya https://osdn.net/projects/v2raya/storage/openwrt/$(. /etc/openwrt_release && echo "$DISTRIB_ARCH")" >> /etc/opkg/customfeeds.conf

# This script is used to update the packages in the repo
opkg update
[ $? -eq 0 ] && {
    opkg install tgwireguard
    # If we are on a "mini" device, we don't need the docker package
    # We check for the existance of the /etc/pr-mini file to determine
    [ -f /etc/pr-mini ] || {
        log_say "Installing PrivateRouter Packages"
        opkg install luci-lib-taskd taskd tgappstore luci-lib-xterm luci-lib-fs luci-app-filetransfer luci-app-docker-backup luci-app-shortcutmenu tgwireguard luci-app-nextcloud
        opkg install luci-app-jellyfin luci-app-homeassistant luci-app-poweroff tgdocker kmod-veth uxc procd-ujail procd-ujail-console
        opkg install tgappstore luci-app-wizard luci-app-simplex luci-app-photoprism luci-app-libreddit luci-app-nodered luci-app-diskman
        opkg install luci-app-syncthing luci-app-qbittorrentdocker luci-app-megamedia luci-app-whoogle luci-app-nfs luci-app-webtop luci-app-alltube
        opkg install luci-app-emby luci-app-joplin luci-app-bookstack luci-app-filebrowser luci-app-heimdall luci-app-seafile

        log_say "Installing v2raya and luci-app-v2raya"
        opkg install v2raya iptables-mod-conntrack-extra iptables-mod-extra iptables-mod-filter iptables-mod-tproxy kmod-ipt-nat6 kmod-ipt-tproxy xray-core luci-app-v2raya
    }
}