#!/bin/bash

# This script is used to update the packages in the repo
opkg update
[ $? -eq 0 ] && {
    opkg install tgwireguard
    opkg install tgdocker
}