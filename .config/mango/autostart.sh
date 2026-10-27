#!/bin/bash

set +e

# =====================================================================
# Session environment
# =====================================================================

export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=mango
export XDG_CURRENT_DESKTOP=mango
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland

# =====================================================================
# D-Bus
# =====================================================================

dbus-update-activation-environment \
    --systemd \
    WAYLAND_DISPLAY \
    XDG_CURRENT_DESKTOP \
    XDG_SESSION_TYPE \
    XDG_RUNTIME_DIR \
    DBUS_SESSION_BUS_ADDRESS \
    MOZ_ENABLE_WAYLAND \
    QT_QPA_PLATFORM \
    SDL_VIDEODRIVER \
    >/dev/null 2>&1

# =====================================================================
# PipeWire / WirePlumber
# =====================================================================

pipewire >/dev/null 2>&1 &
pipewire-pulse >/dev/null 2>&1 &
wireplumber >/dev/null 2>&1 &

# Wait until PipeWire is actually ready
until wpctl status >/dev/null 2>&1; do
    sleep 0.2
done

# =====================================================================
# XDG Desktop Portal
# =====================================================================

/usr/lib/xdg-desktop-portal-wlr \
    >/dev/null 2>&1 &

# Give the portal a moment to initialize
sleep 0.5

# =====================================================================
# Polkit authentication agent
# =====================================================================

/usr/libexec/polkit-gnome-authentication-agent-1 \
    >/dev/null 2>&1 &

# =====================================================================
# Noctalia Shell
# =====================================================================

noctalia >/dev/null 2>&1 &

# touch /tmp/quickshell-brightness
# quickshell >/dev/null 2>&1 &

# =====================================================================
# Device automount
# =====================================================================

devmon >/dev/null 2>&1 &

# =====================================================================
# Clipboard
# =====================================================================

wl-clip-persist \
    --clipboard regular \
    --reconnect-tries 0 \
    >/dev/null 2>&1 &

wl-paste \
    --type text \
    --watch cliphist store \
    >/dev/null 2>&1 &
# =====================================================================
# End

# #!/bin/bash
#
# set +e
#
# export XDG_SESSION_TYPE=wayland
# export XDG_CURRENT_DESKTOP=mango
#
# # D-Bus ===============================================================
#
# dbus-update-activation-environment \
#     WAYLAND_DISPLAY \
#     XDG_CURRENT_DESKTOP \
#     XDG_SESSION_TYPE \
#     XDG_RUNTIME_DIR
#
# # xdg-desktop-portal ===================================================
# /usr/lib/xdg-desktop-portal-wlr &
# sleep 1
#
# # Wallpaper============================================================
# # awww-daemon >/dev/null 2>&1 &
#
# # Polkit authentication agent =========================================
# /usr/libexec/polkit-gnome-authentication-agent-1 \
#     >/dev/null 2>&1 &
#
# # Quickshell ==========================================================
# touch /tmp/quickshell-brightness
# # quickshell &
#
# # Audio  ==============================================================
# pipewire &
# pipewire-pulse &
# wireplumber &
# sleep 2
# # until wpctl status >/dev/null 2>&1; do
# #     sleep 0.2
# # done
# noctalia &
# # Device automount ====================================================
# devmon &
#
# # Clipboard ===========================================================
# wl-clip-persist \
#     --clipboard regular \
#     --reconnect-tries 0 \
#     >/dev/null 2>&1 &
#
# wl-paste \
#     --type text \
#     --watch cliphist store \
#     >/dev/null 2>&1 &
