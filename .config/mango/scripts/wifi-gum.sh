#!/bin/bash

IFACE="wlp3s0"

# Ancho fijo de la terminal (120 columnas para una ventana de 1200 píxeles)
TERM_WIDTH=110

# Banner ASCII
ASCII_ART="
    ██     ██ ██ ███████ ██      ██████  ██████  ███    ██ ███    ██ ███████  ██████ ████████ 
    ██     ██ ██ ██      ██     ██      ██    ██ ████   ██ ████   ██ ██      ██         ██    
    ██  █  ██ ██ █████   ██     ██      ██    ██ ██ ██  ██ ██ ██  ██ █████   ██         ██    
    ██ ███ ██ ██ ██      ██     ██      ██    ██ ██  ██ ██ ██  ██ ██ ██      ██         ██    
     ███ ███  ██ ██      ██      ██████  ██████  ██   ████ ██   ████ ███████  ██████    ██    
"
center_text() {
  local text="$1"
  local max_width=0
  while IFS= read -r line; do
    (( ${#line} > max_width )) && max_width=${#line}
  done <<< "$text"
  local padding=$(( (TERM_WIDTH - max_width) / 2 ))
  (( padding < 0 )) && padding=0
  while IFS= read -r line; do
    printf "%${padding}s%s\n" "" "$line"
  done <<< "$text"
}

# ====================== CURRENT NETWORK FUNCTION ======================
show_current_connection() {
  CURRENT=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes:' | head -n1)
  if [ -z "$CURRENT" ]; then
    gum style --foreground 240 --italic "  ❌Not connected to any network"
  else
    SSID=$(echo "$CURRENT" | cut -d: -f2)
    SIGNAL=$(echo "$CURRENT" | cut -d: -f3)
    if [ "$SIGNAL" -ge 80 ]; then COLOR=82;   EMOJI="✅"
    elif [ "$SIGNAL" -ge 60 ]; then COLOR=118; EMOJI="👍"
    elif [ "$SIGNAL" -ge 40 ]; then COLOR=226; EMOJI="👌"
    elif [ "$SIGNAL" -ge 20 ]; then COLOR=208; EMOJI="⚠️"
    else COLOR=196; EMOJI="Weak"; fi
    gum style --foreground $COLOR --bold " 🔗 Connected to: $SSID  |  Signal: ${SIGNAL}% ($EMOJI)"
  fi
}

# ====================== START ======================
clear
echo -e "\033[1;36m"
center_text "$ASCII_ART"
echo -e "\033[0m"

command -v nmcli &>/dev/null || { echo "nmcli is not installed."; exit 1; }
command -v gum &>/dev/null   || { echo "gum is not installed. Run: sudo zypper in gum"; exit 1; }

echo
echo -e "📡 \033[1;33mScanning for nearby WiFi networks... (may take 5-10 seconds)\033[0m"

# Background spinner
spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
i=0
(
  stdbuf -oL nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>/dev/null
) | awk -F: '
  $1 != "" {
    gsub(/--/, "Open", $3)
    gsub(/WPA3/, "WPA3", $3)
    gsub(/WPA2/, "WPA2", $3)
    gsub(/WPA/, "WPA", $3)
    printf "%s (%s%%) %s\n", $1, $2, $3
  }
' | sort -k2 -nr > /tmp/wifi_list_tmp.$$

printf "\033[2K\r"

if [ ! -s /tmp/wifi_list_tmp.$$ ]; then
  echo "No networks found."
  gum confirm "Retry scan?" && exec "$0"
  rm -f /tmp/wifi_list_tmp.$$
  exit 1
fi

# ===============================================
# AHORA SÍ: MOSTRAR A QUÉ RED ESTÁS CONECTADO
# ===============================================
clear
echo -e "\033[1;36m"
center_text "$ASCII_ART"
echo -e "\033[0m"
echo

show_current_connection
echo
gum style --foreground 82 "✅ Scan complete! Found $(wc -l < /tmp/wifi_list_tmp.$$) networks"
echo

# ===============================================
# Select network
# ===============================================
SSID=$(cat /tmp/wifi_list_tmp.$$ | gum filter \
  --height 18 \
  --placeholder "Type to search..." \
  --header "👉 Available WiFi networks (sorted by signal)" \
  --header.foreground 27 | awk '{print $1}')

rm -f /tmp/wifi_list_tmp.$$
[ -z "$SSID" ] && { clear; echo; gum style --foreground 208 "No network selected. Exiting."; exit 1; }

clear
echo -e "\033[1;36m"
center_text "$ASCII_ART"
echo -e "\033[0m"
echo

gum style --foreground 45 --bold "Selected network: $SSID"
echo

# ===============================================
# Connect
# ===============================================
if nmcli connection show --active | grep -q " $SSID$"; then
  gum style --foreground 82 "You're already connected to: $SSID"
  exit 0
fi

if nmcli connection show | grep -q "^$SSID "; then
  gum style --foreground 220 "Saved connection found. Activating..."
  if pkexec nmcli connection up "$SSID" >/dev/null 2>&1; then
    gum style --foreground 82 "Successfully switched to $SSID"
    exit 0
  else
    gum style --foreground 208 "Auto-connect failed. Requesting new password..."
  fi
fi

WIFI_PASS=$(gum input --password --placeholder "Password for '$SSID'" --header "WiFi Password")
[ -z "$WIFI_PASS" ] && { gum style --foreground 196 "Password required!"; exit 1; }

nmcli connection delete "$SSID" &>/dev/null

echo
gum style --foreground 220 "Connecting to '$SSID'..."
if pkexec nmcli dev wifi connect "$SSID" password "$WIFI_PASS" ifname "$IFACE" >/dev/null 2>&1; then
  gum style --foreground 82 "Successfully connected to $SSID!"
else
  gum style --foreground 220 "Creating manual profile..."
  pkexec nmcli connection add type wifi ifname "$IFACE" con-name "$SSID" ssid "$SSID" \
    wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$WIFI_PASS" autoconnect yes >/dev/null
  if pkexec nmcli connection up "$SSID" >/dev/null 2>&1; then
    gum style --foreground 82 "Connected using manual profile!"
  else
    gum style --foreground 196 "Connection failed. Check password or signal."
    exit 1
  fi
fi

echo
gum style --foreground 82 --bold "All done! Enjoy your internet on $SSID"
