#!/bin/bash

# If we are not connected to the internet, exit this updater
is_connected() {
    ping -q -c3 1.1.1.1 >/dev/null 2>&1
    return $?
}

[ is_connected ] || exit 0

# This script is used to update the packages in the repo
opkg update
[ $? -eq 0 ] && {
    opkg install tgwireguard
    opkg install tgdocker
}