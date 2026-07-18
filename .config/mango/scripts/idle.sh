#!/usr/bin/bash

#swayidle -w \
#	timeout 1800 'swaylock -f -c 000000' \
#	timeout 1800 'hyprctl dispatch dpms off' \
#		resume 'hyprctl dispatch dpms on && ~/.config/hypr/scripts/restart_wlsunset.sh' \
#	timeout 300 'bash $HOME/.config/hypr/scripts/lightresume.sh dark' \
#		resume 'bash $HOME/.config/hypr/scripts/lightresume.sh resume' \
#	timeout 3600 'systemctl suspend'


# swayidle -w \
#   timeout 60 'swaylock -f -c 000000 && sleep 10 && wlr-dpms off' \
#   resume 'wlr-dpms on && ~/.config/mango/scripts/restart_wlsunset.sh' \
#   # timeout 60 'dimland -a 0.3' \
#   resume '~/.config/mango/scripts/exitdim.sh'

swayidle -w \
  timeout 30 'hyprlock' \
  resume 'wlr-dpms on && ~/.config/mango/scripts/restart_wlsunset.sh' \
  timeout 60 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
  before-sleep 'hyprlock -f -c 000000'

