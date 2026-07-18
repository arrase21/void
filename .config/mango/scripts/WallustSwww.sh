#!/usr/bin/env bash
exec 1>/dev/null 2>&1
cache_dir="$HOME/.cache/awww/"
current_monitor=$(wlr-randr | grep -m1 -o '^[^ ]*')
cache_file="${cache_dir}${current_monitor}"

[[ -f "$cache_file" ]] || exit 1
wallpaper_path=$(grep -m1 -v lanczos3 "$cache_file")
[[ -f "$wallpaper_path" ]] || exit 1
# Waybar recarga (USR2 es más suave que USR1)

if pgrep -x waybar >/dev/null; then
    pkill -SIGUSR2 waybar
else
    waybar -c "$WAYBAR_CONFIG" -s "$WAYBAR_CSS_DEST" &
fi
# Otros daemons que usan wallust
pkill -USR2 swaync-client 2>/dev/null || swaync-client -rs &
"$HOME/.config/mango/scripts/mako.sh" 2>/dev/null || true
exit 0
