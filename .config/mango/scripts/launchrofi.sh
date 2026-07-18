#!/usr/bin/env bash

cd ~

CONFIG="$HOME/.config/mango/rofi/launcher/sysmenu.rasi"

# -------------------------------------------------
# UTIL
# -------------------------------------------------

run_menu() {
    echo -e "$1" | rofi -config "$CONFIG" -dmenu
}

get_action() {
    echo "$1" | awk -F'|' '{print $2}'
}

# -------------------------------------------------
# LAUNCHERS
# -------------------------------------------------

drun_launcher() {
    rofi -config ~/.config/mango/rofi/config.rasi -show drun
}

# -------------------------------------------------
# SESSION MENU
# -------------------------------------------------

session_options() {
    options="  Shutdown|shutdown
  Reboot|reboot
  Lock|lock
󰍃  Logout|logout
󰌍  Back|back"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    case "$action" in
        shutdown) systemctl poweroff ;;
        reboot) systemctl reboot ;;
        lock) hyprlock & disown ;;
        logout) hyprctl dispatch exit ;;
        back) system_menu ;;
    esac
}

# -------------------------------------------------
# CONNECTIONS
# -------------------------------------------------

connections_func() {
    options="󰤨  WiFi|wifi
  Bluetooth|bluetooth
󰌍  Back|back"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    case "$action" in
        wifi) bash ~/scripts/rofi-wifi ;;
        bluetooth) bash ~/scripts/rofi-bluetooth ;;
        back) system_menu ;;
    esac
}

# -------------------------------------------------
# SCREENSHOT
# -------------------------------------------------

screenshot_func() {
    options="  Screenshots|folder
  Fullscreen|fullscreen
  Selection|region
  Now|instant
󰌍  Back|back"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    case "$action" in
        folder) foot -e yazi ~/Pictures/Screenshots/ ;;
        fullscreen) bash $HOME/.config/mango/scripts/screenshot.sh fullscreen ;;
        region) bash $HOME/.config/mango/scripts/screenshot.sh region ;;
        instant) bash $HOME/.config/mango/scripts/screenshot.sh instant ;;
        back) system_menu ;;
    esac
}

# -------------------------------------------------
# MISC
# -------------------------------------------------

misc_func() {
    options="  Toggle DND|dnd
  Toggle Cafein|cafein
󰈈  Toggle Eye Saver|eye
󰌍  Back|back"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    case "$action" in
        dnd) makoctl mode -t dnd ;;
        cafein) bash $HOME/scripts/cafein toggle -n ;;
        eye) bash $HOME/.config/mango/scripts/Sunset.sh ;;
        back) system_menu ;;
    esac
}

# -------------------------------------------------
# MAINTAIN
# -------------------------------------------------

maintain_menu() {
    options="󰃢  Clear Cache|cache
󱘡  Clear Clipboard|clipboard
󰌍  Back|back"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    case "$action" in
        cache)
            find ~/.cache -mindepth 1 -maxdepth 1 \
                ! -name "spotify" \
                ! -name "cliphist" \
                ! -name "paru" \
                -exec rm -rf {} + ;;
        clipboard)
            rm -rf ~/.cache/cliphist ;;
        back) system_menu ;;
    esac
}

# -------------------------------------------------
# SETTINGS
# -------------------------------------------------

settings_func() {
    options="  Reload Shell|reload
  Set Default Apps|apps
󰌁  Customize Rice|custom
󰚰  Update Config|update
󰌍  Back|back"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    case "$action" in
        reload)
            pkill waybar
            waybar >/dev/null 2>&1 & ;;
        apps)
            bash ~/.config/mango/scripts/set-default-browser ;;
        custom)
            customize_func ;;
        update)
            foot -e bash ~/Dotfiles/bin/update_binarydots ;;
        back) system_menu ;;
    esac
}

# -------------------------------------------------
# CUSTOMIZE
# -------------------------------------------------

customize_func() {
    options="  Set Style Locks|locks
  Wallpapers|walls
󰌁  Themes|themes
󰌍  Back|back"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    case "$action" in
        locks) lock_menu ;;
        walls) set_wallpaper ;;
        themes) theme_menu ;;
        back) settings_func ;;
    esac
}

# -------------------------------------------------
# WALLPAPER
# -------------------------------------------------

set_wallpaper() {
    "$HOME/.config/mango/scripts/WallpaperSelect.sh"
}

# -------------------------------------------------
# THEMES
# -------------------------------------------------

theme_menu() {
    THEME_DIR="$HOME/.config/themes"
    THEMES=$(find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f|theme_%f\n')

    options="󰌍  Back|back
$THEMES"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    if [[ "$action" == back ]]; then
        system_menu
    elif [[ "$action" == theme_* ]]; then
        theme_name=${action#theme_}
        "$HOME/.config/mango/scripts/themes.sh" -c "$theme_name"
    fi
}

# -------------------------------------------------
# SYSTEM MENU (MAIN)
# -------------------------------------------------

system_menu() {
    options="  Apps|apps
  Connections|connections
󰃢  Maintaining|maintain
󰄀  Screenshot|screenshot
󰐱  Miscellaneous|misc
󰌁  Customize|customize
  Session Options|session
  Settings|settings
  Wallpapers|wallpapers"

    chosen=$(run_menu "$options")
    action=$(get_action "$chosen")

    case "$action" in
        apps) drun_launcher ;;
        connections) connections_func ;;
        maintain) maintain_menu ;;
        screenshot) screenshot_func ;;
        misc) misc_func ;;
        customize) customize_func;;
        session) session_options ;;
        settings) settings_func ;;
        wallpapers) set_wallpaper ;;
    esac
}
# -------------------------------------------------
# FLAGS
# -------------------------------------------------

case "$1" in
    --drun|-d) drun_launcher ;;
    --system_menu|--sys_menu|-sm) system_menu ;;
    --screenshot_menu|--ss_menu|-ss) screenshot_func ;;
    --power-menu|-pm) session_options ;;
    *) system_menu ;;
esac
