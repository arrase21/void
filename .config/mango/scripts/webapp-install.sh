#!/usr/bin/env bash
set -e

clear

# === Encabezado con ASCII art ===
TERM_WIDTH=100
# Banner ASCII
ASCII_ART="
▗▖  ▗▖ ▗▄▖ ▗▖ ▗▖▗▄▄▄▖    ▗▖ ▗▖▗▄▄▄▖▗▄▄▖  ▗▄▖ ▗▄▄▖ ▗▄▄▖ 
▐▛▚▞▜▌▐▌ ▐▌▐▌▗▞▘▐▌       ▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌▐▌ ▐▌
▐▌  ▐▌▐▛▀▜▌▐▛▚▖ ▐▛▀▀▘    ▐▌ ▐▌▐▛▀▀▘▐▛▀▚▖▐▛▀▜▌▐▛▀▘ ▐▛▀▘ 
▐▌  ▐▌▐▌ ▐▌▐▌ ▐▌▐▙▄▄▖    ▐▙█▟▌▐▙▄▄▖▐▙▄▞▘▐▌ ▐▌▐▌   ▐▌   
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

gum style --foreground 110 --align center "WebApp Maker for launcher 💻"
echo

# === Interacción ===
if [ "$#" -lt 3 ]; then

  gum style --foreground 45 "Let's create a new web app you can start with the app launcher."
  echo

  APP_NAME=$(gum input --prompt "📦 Name> " --placeholder "Mi favorite app name")
  APP_URL=$(gum input --prompt "🌐 URL> " --placeholder "https://example.com")
  ICON_REF=$(gum input --prompt "🖼️ Icon (URL or name png)> " --placeholder "https://dashboardicons.com/icon.png")
  CUSTOM_EXEC=""
  MIME_TYPES=""
  INTERACTIVE_MODE=true
else
  APP_NAME="$1"
  APP_URL="$2"
  ICON_REF="$3"
  CUSTOM_EXEC="$4"
  MIME_TYPES="$5"
  INTERACTIVE_MODE=false
fi

# === Validación ===
if [[ -z "$APP_NAME" || -z "$APP_URL" || -z "$ICON_REF" ]]; then
  gum style --foreground 196 "❌ You must set app name, app URL, and icon URL!."
  exit 1
fi

# === Directorios ===
ICON_DIR="$HOME/.local/share/applications/icons"
mkdir -p "$ICON_DIR"

# === Icono ===
if [[ $ICON_REF =~ ^https?:// ]]; then
  ICON_PATH="$ICON_DIR/$APP_NAME.png"
  gum spin --spinner line --title "Descargando icono..." -- sleep 1
  if curl -sL -o "$ICON_PATH" "$ICON_REF"; then
    gum style --foreground 82 "✅ Icono descargado correctamente."
  else
    gum style --foreground 196 "Error failed to download icon."
    exit 1
  fi
else
  ICON_PATH="$ICON_DIR/$ICON_REF"
fi

# === Comando de ejecución ===
if [[ -n $CUSTOM_EXEC ]]; then
  EXEC_COMMAND="$CUSTOM_EXEC"
else
  EXEC_COMMAND="launch-webapp $APP_URL"
fi

# === Crear archivo .desktop ===
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"

cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=$APP_NAME
Comment=$APP_NAME
Exec=$EXEC_COMMAND
Terminal=false
Type=Application
Icon=$ICON_PATH
StartupNotify=true
EOF

if [[ -n $MIME_TYPES ]]; then
  echo "MimeType=$MIME_TYPES" >>"$DESKTOP_FILE"
fi

chmod +x "$DESKTOP_FILE"

# === Mensaje final ===
if [[ $INTERACTIVE_MODE == true ]]; then
  gum style --foreground 214 --bold \
    "🎉 $APP_NAME ha sido creada con éxito.
  You can now find using the app launcher (SUPER + SPACE)"

gum confirm "Press Enter." > /dev/null
fi

