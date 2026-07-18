#!/usr/bin/env bash
# set -e

# Variables de entorno
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# PATH ampliado
export PATH="$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

THEME_LINK="$HOME/.config/current/theme"
THEME="$(readlink -f "$THEME_LINK" 2>/dev/null || echo "$THEME_LINK")"
WALLPAPERS_DIR="$THEME/wallpapers"
SCRIPTSDIR="$HOME/.config/mango/scripts"
WAYBAR_CSS_DEST="$HOME/.config/mango/waybar/style.css"
WAYBAR_CSS_SRC="$THEME/waybar.css"
WAYBAR_CONFIG="$HOME/.config/mango/waybar/config"

# Verificar tema
[[ ! -d "$THEME" ]] && exit 1

# Wallpaper aleatorio
if [[ -d "$WALLPAPERS_DIR" && -n "$(ls -A "$WALLPAPERS_DIR" 2>/dev/null)" ]]; then
  mapfile -t WALLPAPERS < <(
    find "$WALLPAPERS_DIR" -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort
  )

  if [[ ${#WALLPAPERS[@]} -gt 0 ]]; then
    WALLPAPER="${WALLPAPERS[$(( RANDOM % ${#WALLPAPERS[@]} ))]}"

    cp "$WALLPAPER" ~/.config/wall.png 2>/dev/null

    if command -v awww >/dev/null 2>&1; then
      awww img "$WALLPAPER" \
        --transition-type wipe \
        --transition-fps 60 \
        --transition-duration 2
    fi

    if command -v matugen >/dev/null 2>&1; then
      matugen image "$WALLPAPER" --mode dark --source-color-index 0
    fi

    sleep 1
  fi
fi

# CSS Waybar
[[ -f "$WAYBAR_CSS_SRC" ]] && cp -f "$WAYBAR_CSS_SRC" "$WAYBAR_CSS_DEST"

# Reload Waybar
if pgrep -x waybar >/dev/null; then
  pkill -SIGUSR2 waybar
else
  waybar -c "$WAYBAR_CONFIG" -s "$WAYBAR_CSS_DEST" &
fi

# Notificación
if [[ -n "$WALLPAPER" ]] && command -v notify-send >/dev/null 2>&1; then
  notify-send "Tema completo" "$(basename "$THEME")\n$(basename "$WALLPAPER")" -i "$WALLPAPER"
fi

# Mako
[[ -f "$SCRIPTSDIR/mako.sh" ]] && "$SCRIPTSDIR/mako.sh" 2>/dev/null || true

