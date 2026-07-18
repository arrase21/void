#!/bin/bash
set -e

clear

# === Encabezado con ASCII art ===
TERM_WIDTH=100
# Banner ASCII
ASCII_ART="
▗▄▄▖ ▗▄▄▄▖▗▖  ▗▖ ▗▄▖ ▗▖  ▗▖▗▄▄▄▖    ▗▖ ▗▖▗▄▄▄▖▗▄▄▖  ▗▄▖ ▗▄▄▖ ▗▄▄▖ 
▐▌ ▐▌▐▌   ▐▛▚▞▜▌▐▌ ▐▌▐▌  ▐▌▐▌       ▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌
▐▛▀▚▖▐▛▀▀▘▐▌  ▐▌▐▌ ▐▌▐▌  ▐▌▐▛▀▀▘    ▐▌ ▐▌▐▛▀▀▘▐▛▀▚▖▐▛▀▜▌▐▛▀▘ ▐▛▀▘ 
▐▌ ▐▌▐▙▄▄▖▐▌  ▐▌▝▚▄▞▘ ▝▚▞▘ ▐▙▄▄▖    ▐▙█▟▌▐▙▄▄▖▐▙▄▞▘▐▌ ▐▌▐▌   ▐▌   
"

# Función para centrar el texto
center_text() {
  local text="$1"
  local term_width=$TERM_WIDTH
  # Calcular el ancho de la línea más larga del arte ASCII
  local max_width=0
  while IFS= read -r line; do
    line_width=${#line}
    if [ $line_width -gt $max_width ]; then
      max_width=$line_width
    fi
  done <<< "$text"
  
  # Calcular el padding necesario para centrar
  local padding=$(( (term_width - max_width) / 2 ))
  if [ $padding -lt 0 ]; then padding=0; fi
  
  # Imprimir cada línea con el padding
  while IFS= read -r line; do
    printf "%${padding}s%s\n" "" "$line"
  done <<< "$text"
}

# Imprimir el banner centrado con color
echo -e "\033[1;36m"
center_text "$ASCII_ART"
echo -e "\033[0m"



ICON_DIR="$HOME/.local/share/applications/icons"
DESKTOP_DIR="$HOME/.local/share/applications/"

if [ "$#" -eq 0 ]; then
  # Find all web apps
  while IFS= read -r -d '' file; do
    if grep -q '^Exec=.*launch-webapp.*' "$file"; then
      WEB_APPS+=("$(basename "${file%.desktop}")")
    fi
  done < <(find "$DESKTOP_DIR" -name '*.desktop' -print0)

  if ((${#WEB_APPS[@]})); then
    IFS=$'\n' SORTED_WEB_APPS=($(sort <<<"${WEB_APPS[*]}"))
    unset IFS
    APP_NAMES_STRING=$(gum choose --no-limit --header "Select web app to remove..." --selected-prefix="✗ " "${SORTED_WEB_APPS[@]}")
    # Convert newline-separated string to array
    APP_NAMES=()
    while IFS= read -r line; do
      [[ -n "$line" ]] && APP_NAMES+=("$line")
    done <<< "$APP_NAMES_STRING"
  else
    echo "No web apps to remove."
    exit 1
  fi
else
  # Use array to preserve spaces in app names
  APP_NAMES=("$@")
fi

if [[ ${#APP_NAMES[@]} -eq 0 ]]; then
  echo "You must provide web app names."
  exit 1
fi

for APP_NAME in "${APP_NAMES[@]}"; do
  rm -f "$DESKTOP_DIR/$APP_NAME.desktop"
  rm -f "$ICON_DIR/$APP_NAME.png"
  echo "Removed $APP_NAME"
done
