#!/bin/bash

set +e
# notify===========================================================================================
mako &
# wallpaper=====================================================================================
awww-daemon &
# top bar=======================================================================================
"$HOME/.config/mango/waybar/launch.sh"
# clipboard content manager=====================================================================
wl-clip-persist --clipboard regular --reconnect-tries 0 >/dev/null 2>&1 &
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
# Permission authentication
/usr/libexec/polkit-gnome-authentication-agent-1 >/dev/null 2>&1 &
