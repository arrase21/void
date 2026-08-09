#!/bin/bash

set +e
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=mango
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    sleep 0.5
fi
# wallpaper=====================================================================================
awww-daemon &
# top bar=======================================================================================
# "$HOME/.config/mango/waybar/launch.sh"
quickshell &
# services
pipewire &
pipewire-pulse &
wireplumber &
devmon &
sleep 0.5
# clipboard content manager=====================================================================
wl-clip-persist --clipboard regular --reconnect-tries 0 >/dev/null 2>&1 &
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
# Permission authentication
/usr/libexec/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &
