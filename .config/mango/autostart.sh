#!/bin/bash

set +e

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=mango

# D-Bus ===============================================================

dbus-update-activation-environment \
    WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP \
    XDG_SESSION_TYPE \
    XDG_RUNTIME_DIR

# Wallpaper============================================================
awww-daemon >/dev/null 2>&1 &

# Polkit authentication agent =========================================
/usr/libexec/polkit-gnome-authentication-agent-1 \
    >/dev/null 2>&1 &

# Quickshell ==========================================================
touch /tmp/quickshell-brightness
quickshell &

# Audio  ==============================================================
pipewire &
pipewire-pulse &
wireplumber &

# Device automount ====================================================
devmon &

# Clipboard ===========================================================
wl-clip-persist \
    --clipboard regular \
    --reconnect-tries 0 \
    >/dev/null 2>&1 &

wl-paste \
    --type text \
    --watch cliphist store \
    >/dev/null 2>&1 &
