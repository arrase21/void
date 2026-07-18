#!/bin/bash

# Expandir PATH para incluir cargo, go, y otras rutas de usuario
export PATH="$HOME/.cargo/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

sDIR="$HOME/.config/mango/scripts"

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${SCREENSHOT_DIR:-${XDG_PICTURES_DIR_SCREN:-$HOME/Pictures/Screenshots}}"

if [[ ! -d "$OUTPUT_DIR" ]]; then
  notify-send "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
  exit 1
fi

pkill slurp && exit 0

MODE="${1:-smart}"
PROCESSING="${2:-satty}"

# Modo especial: instant - captura toda la pantalla sin diálogos
if [[ "$MODE" == "instant" ]]; then
  # Obtener geometría del monitor activo
  if command -v swaymsg >/dev/null 2>&1; then
    SELECTION=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')
  elif command -v wlr-randr >/dev/null 2>&1; then
    SELECTION=$(wlr-randr --json | jq -r '.[] | select(.enabled == true) | "\(.position.x),\(.position.y) \(.modes[] | select(.current == true) | "\(.width)x\(.height)")"' | head -1)
  else
    # Fallback: capturar todo sin geometría específica
    SELECTION=""
  fi
  
  # Reproducir sonido
  if [[ -x "${sDIR}/Sounds.sh" ]]; then
    "${sDIR}/Sounds.sh" --screenshot &
  fi
  
  # Guardar directamente sin abrir satty
  FILENAME="$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
  
  if [[ -n "$SELECTION" ]]; then
    grim -g "$SELECTION" "$FILENAME"
  else
    grim "$FILENAME"
  fi
  
  # Copiar al portapapeles
  wl-copy < "$FILENAME"
  
  # Notificar
  notify-send "Screenshot saved" "$(basename "$FILENAME")" -i "$FILENAME" -t 2000
  
  exit 0
fi

get_rectangles() {
  if command -v swaymsg >/dev/null 2>&1; then
    swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"'
    swaymsg -t get_tree | jq -r '.. | select(.type? == "con" and .visible? == true) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"'
  else
    wlr-randr --json 2>/dev/null | jq -r '.[] | select(.enabled == true) | "\(.position.x),\(.position.y) \(.modes[] | select(.current == true) | "\(.width)x\(.height)")"' 2>/dev/null || {
      echo "0,0 1920x1080"
    }
  fi
}

# Select based on mode
case "$MODE" in
  region)
    if command -v wayfreeze >/dev/null 2>&1; then
      wayfreeze & PID=$!
      sleep .1
    fi
    SELECTION=$(slurp 2>/dev/null)
    [[ -n "$PID" ]] && kill $PID 2>/dev/null
    ;;
    
  windows)
    if command -v wayfreeze >/dev/null 2>&1; then
      wayfreeze & PID=$!
      sleep .1
    fi
    SELECTION=$(get_rectangles | slurp -r 2>/dev/null)
    [[ -n "$PID" ]] && kill $PID 2>/dev/null
    ;;
    
  fullscreen)
    if command -v swaymsg >/dev/null 2>&1; then
      SELECTION=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height)"')
    elif command -v wlr-randr >/dev/null 2>&1; then
      SELECTION=$(wlr-randr --json | jq -r '.[] | select(.enabled == true) | "\(.position.x),\(.position.y) \(.modes[] | select(.current == true) | "\(.width)x\(.height)")"' | head -1)
    else
      SELECTION=$(slurp -o 2>/dev/null)
    fi
    ;;
    
  smart|*)
    RECTS=$(get_rectangles)
    if command -v wayfreeze >/dev/null 2>&1; then
      wayfreeze & PID=$!
      sleep .1
    fi
    SELECTION=$(echo "$RECTS" | slurp 2>/dev/null)
    [[ -n "$PID" ]] && kill $PID 2>/dev/null
    
    if [[ "$SELECTION" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+)$ ]]; then
      if (( ${BASH_REMATCH[3]} * ${BASH_REMATCH[4]} < 20 )); then
        click_x="${BASH_REMATCH[1]}"
        click_y="${BASH_REMATCH[2]}"
        
        while IFS= read -r rect; do
          if [[ "$rect" =~ ^([0-9]+),([0-9]+)[[:space:]]([0-9]+)x([0-9]+) ]]; then
            rect_x="${BASH_REMATCH[1]}"
            rect_y="${BASH_REMATCH[2]}"
            rect_width="${BASH_REMATCH[3]}"
            rect_height="${BASH_REMATCH[4]}"
            
            if (( click_x >= rect_x && click_x < rect_x+rect_width && click_y >= rect_y && click_y < rect_y+rect_height )); then
              SELECTION="${rect_x},${rect_y} ${rect_width}x${rect_height}"
              break
            fi
          fi
        done <<< "$RECTS"
      fi
    fi
    ;;
esac

# Si no hay selección, salir sin sonido
[ -z "$SELECTION" ] && exit 0

# REPRODUCIR SONIDO DESPUÉS DE LA SELECCIÓN Y ANTES DE CAPTURAR
if [[ -x "${sDIR}/Sounds.sh" ]]; then
  "${sDIR}/Sounds.sh" &
fi

# Procesar la captura
if [[ $PROCESSING == "clipboard" ]]; then
  # Captura directa al portapapeles (sin satty)
  grim -g "$SELECTION" - | wl-copy
  notify-send "Screenshot copied to clipboard" -t 2000
else
  # Captura con satty para edición (default)
  if command -v satty >/dev/null 2>&1; then
    grim -g "$SELECTION" - |
      satty --filename - \
        --output-filename "$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" \
        --early-exit \
        --copy-command 'wl-copy'
  else
    # Fallback sin satty: guardar directamente
    FILENAME="$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
    grim -g "$SELECTION" "$FILENAME"
    wl-copy < "$FILENAME"
    notify-send "Screenshot saved" "$FILENAME" -i "$FILENAME"
  fi
fi
