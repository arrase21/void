#!/usr/bin/env bash
MOUNT_POINT="$HOME/Android/phone"
ACTION="$1"  # "mount" o "umount"

# Variables necesarias para notify-send en udev
export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"

if [ "$ACTION" = "mount" ]; then
    /home/arrase/.local/bin/mtp-auto-mount.sh mount
elif [ "$ACTION" = "umount" ]; then
    /home/arrase/.local/bin/mtp-auto-mount.sh umount
fi
