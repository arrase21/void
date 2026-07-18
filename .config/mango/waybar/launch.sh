#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

killall waybar 2>/dev/null

waybar -c "$DIR/config" -s "$DIR/style.css" &

# waybar -c ~/.config/mango/waybar/config -s ~/.config/mango/way bar/style.css >/dev/null 2>&1 &
