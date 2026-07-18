
#!/usr/bin/env bash
set -e

clear

# === Header with ASCII art ===
ASCII_ART="
          ▗▄▄▖  ▗▄▖ ▗▖ ▗▖▗▄▄▄▖▗▄▄▖ 
          ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌   ▐▌ ▐▌
          ▐▛▀▘ ▐▌ ▐▌▐▌ ▐▌▐▛▀▀▘▐▛▀▚▖
          ▐▌   ▝▚▄▞▘▐▙█▟▌▐▙▄▄▖▐▌ ▐▌
"

center_text() {
  local text="$1"
  local max_width=0
  while IFS= read -r line; do
    (( ${#line} > max_width )) && max_width=${#line}
  done <<< "$text"

  local padding=$(( (term_width - max_width) / 2 ))
  (( padding < 0 )) && padding=0

  while IFS= read -r line; do
    printf "%${padding}s%s\n" "" "$line"
  done <<< "$text"
}

# === Dependency check (openSUSE only) ===
check_and_install() {
  local pkg="$1"
  if ! rpm -q "$pkg" >/dev/null 2>&1; then
    gum style --foreground 214 "📦 Installing missing package: $pkg"
    sudo zypper --non-interactive in -y "$pkg"
  fi
}

# Ensure required packages
check_and_install "gum"
check_and_install "libnotify-tools"
check_and_install "power-profiles-daemon"

# Start daemon if needed
if ! systemctl is-active --quiet power-profiles-daemon; then
  sudo systemctl enable --now power-profiles-daemon
fi

# === Get current and previous profile ===
STATE_FILE="$HOME/.cache/power_profile_state"
mkdir -p "$(dirname "$STATE_FILE")"
CURRENT_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "unknown")

# Load previous profile from cache (if any)
PREVIOUS_PROFILE="none"
if [[ -f "$STATE_FILE" ]]; then
  PREVIOUS_PROFILE=$(cat "$STATE_FILE")
fi

# Save current as previous for next run
echo "$CURRENT_PROFILE" > "$STATE_FILE"

# === Icon for current profile ===
case "$CURRENT_PROFILE" in
  performance) PROFILE_ICON="⚡" ;;
  balanced) PROFILE_ICON="⚙️" ;;
  power-saver) PROFILE_ICON="🌿" ;;
  *) PROFILE_ICON="❓" ;;
esac

# === Show title ===
echo -e "\033[1;36m"
center_text "$ASCII_ART"
echo -e "\033[0m"
gum style --foreground 110 --align center "Power Profile Switcher ⚡"
gum style --foreground 244 --align center "Current profile: $CURRENT_PROFILE $PROFILE_ICON"
echo

# === Interactive menu ===
gum style --foreground 45 "Select a power profile:"
echo
OPTIONS=("performance ⚡ (High Energy Consumption)" "balanced ⚙️ (Balanced)" "power-saver 🌿 (Power Saving Mode)")
if [[ "$PREVIOUS_PROFILE" != "none" && "$PREVIOUS_PROFILE" != "$CURRENT_PROFILE" ]]; then
  OPTIONS+=("restore ↩️ (Return to previous: $PREVIOUS_PROFILE)")
fi

PROFILE=$(gum choose --header "Available Profiles" "${OPTIONS[@]}")

case "$PROFILE" in
  performance*) NEW_PROFILE="performance" ;;
  balanced*) NEW_PROFILE="balanced" ;;
  power-saver*) NEW_PROFILE="power-saver" ;;
  restore*) NEW_PROFILE="$PREVIOUS_PROFILE" ;;
  *) echo "❌ Invalid choice."; exit 1 ;;
esac

# === Change profile ===
if [ "$CURRENT_PROFILE" = "$NEW_PROFILE" ]; then
  gum style --foreground 214 "⚙️  You’re already using '$NEW_PROFILE'."
else
  gum spin --spinner line --title "Switching power profile..." -- \
    powerprofilesctl set "$NEW_PROFILE"
  notify-send "⚡ Power profile changed to: $NEW_PROFILE"
  gum style --foreground 82 "✅  Successfully switched to '$NEW_PROFILE'."
fi

# === Summary ===
echo
gum style --foreground 110 "📊  Active power profiles:"
powerprofilesctl list | grep -E "^\*|performance|balanced|power-saver" | sed "s/^/* /"

echo
gum confirm "Press Enter to exit." > /dev/null

