#!/usr/bin/env bash
# set -e

# Variables de entorno
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# PATH ampliado
export PATH="$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

THEME_DIR="$HOME/.config/themes"
CURRENT_THEME_DIR="$HOME/.config/current/theme"
NVIM_THEME_FILE="$HOME/.config/nvim/plugin/40_plugins.lua"
SCR="$HOME/.config/mango/scripts"

USAGE="
Usage: $0 [OPTION] [ARGUMENT]
Options:
  -l, --list             List available themes
  -c, --change THEME     Change to specified THEME
  -p, --prompt           Change theme with interactive prompt
  -h, --help             Show this help message
"

list_themes() {
  find "$THEME_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
}

change_theme() {
  local chosen="$1"

  THEME_PATH="$THEME_DIR/$chosen"
  THEME_NAME="$chosen"
  THEME_FILE="$THEME_PATH/${THEME_NAME}.ini"

  if [[ ! -d "$THEME_PATH" ]]; then
    echo "Error: no existe el tema '$chosen'"
    echo -e "Temas disponibles:\n$(list_themes)"
    exit 1
  fi

  mkdir -p "$HOME/.config/foot" "$(dirname "$CURRENT_THEME_DIR")"
  ln -nsf "$THEME_PATH" "$CURRENT_THEME_DIR"

  # Ejecutar wallpaper.sh
  if [[ -x "$SCR/wallpaper.sh" ]]; then
    export THEME_CHANGE_MODE=1
    "$SCR/wallpaper.sh"
    unset THEME_CHANGE_MODE
  else
    echo "ERROR: $SCR/wallpaper.sh no existe o no es ejecutable"
    ls -la "$SCR/wallpaper.sh" 2>/dev/null
  fi

  "$SCR/chrome.sh"

  # Copiar foot.ini
  if [[ -f "$THEME_FILE" ]]; then
    cp "$THEME_FILE" "$HOME/.config/foot/foot.ini"

    if pgrep foot >/dev/null; then
      killall -SIGUSR1 foot 2>/dev/null
      pkill -SIGUSR1 -f "foot --server" 2>/dev/null
      for pid in $(pgrep foot); do
        kill -SIGUSR1 "$pid" 2>/dev/null
      done
      sleep 0.3
    fi
  else
    echo "Advertencia: $THEME_FILE no existe"
  fi

  paplay /usr/share/sounds/freedesktop/stereo/message.oga &
  sleep 1
  echo "Tema cambiado a '$chosen'"
}

case "$1" in
  --list|-l)
    echo -e "Temas disponibles:\n$(list_themes)"
    ;;
  --change|-c)
    chosen="$2"
    [[ -z "$chosen" ]] && { echo "No se especificó tema."; exit 1; }
    change_theme "$chosen"
    ;;
  --prompt|-p)
    mapfile -t THEMES < <(list_themes)
    [[ ${#THEMES[@]} -eq 0 ]] && { echo "No hay temas en $THEME_DIR"; exit 1; }

    echo "Selecciona un tema:"
    PS3="Opción: "
    select chosen in "${THEMES[@]}" "Cancelar"; do
      [[ "$chosen" == "Cancelar" ]] && exit 0
      [[ -n "$chosen" ]] && { change_theme "$chosen"; break; }
      echo "Opción inválida."
    done
    ;;
  --help|-h|"")
    echo "$USAGE"
    ;;
  *)
    echo -e "Error: bandera desconocida '$1'\n$USAGE"
    exit 1
    ;;
esac

