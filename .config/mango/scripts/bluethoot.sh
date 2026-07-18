#!/usr/bin/env bash
set -e

# ASCII banner
ascii_art="
▗▄▄▖ ▗▖   ▗▖ ▗▖▗▄▄▄▖
▐▌ ▐▌▐▌   ▐▌ ▐▌▐▌   
▐▛▀▚▖▐▌   ▐▌ ▐▌▐▛▀▀▘
▐▙▄▞▘▐▙▄▄▖▝▚▄▞▘▐▙▄▄▖
"
if command -v gum >/dev/null 2>&1; then
  gum style --foreground 212 --border none --margin "1 2" --padding "1 3" --align center "$ascii_art"
else
  echo -e "\n\e[1;35m$ascii_art\e[0m\n"
fi

# Verificar bluetoothctl
if ! command -v bluetoothctl &>/dev/null; then
  echo -e "${RED}❌ bluetoothctl no está instalado.${NC}"
  echo "   Instálalo con: sudo zypper install bluez bluez-tools"
  exit 1
fi

# Verificar gum (opcional, pero recomendado)
if ! command -v gum &>/dev/null; then
  echo -e "${YELLOW}⚠️ gum no está instalado. Usando selección básica.${NC}"
  USE_GUM=false
else
  USE_GUM=true
fi

# Activar Bluetooth
echo -e "${CYAN}🔋 Iniciando servicio Bluetooth...${NC}"
sudo systemctl start bluetooth.service &>/dev/null || true
bluetoothctl power on &>/dev/null || {
  echo -e "${RED}❌ No se pudo activar el adaptador Bluetooth.${NC}"
  exit 1
}

# Función: Escanear dispositivos
# Función: Escanear dispositivos (captura en tiempo real)
scan_devices() {
  echo -e "${CYAN}🔍 Escaneando dispositivos (15 segundos)...${NC}"

  # Iniciar bluetoothctl en modo no interactivo y capturar salida
  local temp_file=$(mktemp)
  local discovered=()

  # Ejecutar bluetoothctl con scan on y capturar líneas
  {
    echo "scan on"
    sleep 16  # más que el timeout para que no se corte
    echo "exit"
  } | bluetoothctl > "$temp_file" 2>&1 &

  local pid=$!
  sleep 16
  kill $pid 2>/dev/null || true
  wait $pid 2>/dev/null || true

  # Extraer dispositivos [NEW] Device
  while IFS= read -r line; do
    if [[ $line =~ \[NEW\]\ Device\ ([0-9A-F:]{17})\ (.*) ]]; then
      local mac="${BASH_REMATCH[1]}"
      local name="${BASH_REMATCH[2]}"
      [[ "$name" == "$mac" ]] && name="(sin nombre)"
      discovered+=("$mac $name")
    fi
  done < "$temp_file"

  rm -f "$temp_file"

  # También incluir dispositivos ya emparejados (por si no se descubren)
  local paired
  paired=$(bluetoothctl devices | awk '{print $2 " " substr($0, index($0,$3))}' | sort -u)

  # Combinar y eliminar duplicados
  {
    printf "%s\n" "${discovered[@]}"
    printf "%s\n" "$paired"
  } | sort -u
}
# Función: Menú principal
main_menu() {
  local devices mac name
  devices=$(scan_devices)

  if [ -z "$devices" ]; then
    echo -e "${YELLOW}⚠️ No se detectaron dispositivos.${NC}"
    read -p "Presiona Enter para reintentar..." || return 1
    return 1
  fi

  if $USE_GUM; then
    selected=$(echo "$devices" | gum choose --height 15 --cursor "👉 " --header "Selecciona un dispositivo:")
  else
    echo "Dispositivos encontrados:"
    echo "$devices" | nl
    read -p "Ingresa el número del dispositivo: " choice
    selected=$(echo "$devices" | sed -n "${choice}p")
  fi

  [ -z "$selected" ] && return 1

  MAC=$(echo "$selected" | awk '{print $1}')
  NAME=$(echo "$selected" | cut -d' ' -f2-)

  echo -e "${GREEN}📱 Dispositivo seleccionado: '$NAME' ($MAC)${NC}"

  device_menu "$MAC" "$NAME"
}

# Función: Menú de acciones por dispositivo
device_menu() {
  local mac="$1" name="$2"
  while true; do
    clear
    echo -e "$BLUE"
    center_text "$ASCII_ART"
    echo -e "$NC"
    echo -e "${GREEN}📱 Dispositivo: $name ($mac)${NC}"
    echo

    local options=(
      "🔗 Emparejar"
      "🔌 Conectar"
      "🔓 Desconectar"
      "🤝 Confiar"
      "🙅 Desconfiar"
      "ℹ️  Información"
      "🗑️  Eliminar"
      "🔄 Volver a escanear"
      "🚪 Salir"
    )

    if $USE_GUM; then
      choice=$(printf "%s\n" "${options[@]}" | gum choose --cursor "➤ " --header "Acciones")
    else
      printf "%s\n" "${options[@]}" | nl
      read -p "Elige una opción: " num
      choice=$(printf "%s\n" "${options[@]}" | sed -n "${num}p")
    fi

    case "$choice" in
      "🔗 Emparejar")
        echo -e "${CYAN}🔗 Emparejando $mac...${NC}"
        if bluetoothctl pair "$mac" | grep -q "successful"; then
          echo -e "${GREEN}✅ Emparejado.${NC}"
        else
          echo -e "${YELLOW}⚠️ Falló (puede requerir PIN/confirmación).${NC}"
        fi
        ;;
      "🔌 Conectar")
        echo -e "${CYAN}🔌 Conectando $mac...${NC}"
        if bluetoothctl connect "$mac" | grep -q "successful"; then
          echo -e "${GREEN}✅ Conectado.${NC}"
        else
          echo -e "${YELLOW}⚠️ Falló la conexión.${NC}"
        fi
        ;;
      "🔓 Desconectar")
        echo -e "${CYAN}🔓 Desconectando $mac...${NC}"
        if bluetoothctl disconnect "$mac" | grep -q "Successful"; then
          echo -e "${GREEN}✅ Desconectado.${NC}"
        else
          echo -e "${YELLOW}⚠️ No estaba conectado o falló.${NC}"
        fi
        ;;
      "🤝 Confiar")
        echo -e "${CYAN}🤝 Marcando como confiable...${NC}"
        bluetoothctl trust "$mac" &>/dev/null && echo -e "${GREEN}✅ Confiable.${NC}"
        ;;
      "🙅 Desconfiar")
        echo -e "${CYAN}🙅 Quitando confianza...${NC}"
        bluetoothctl untrust "$mac" &>/dev/null && echo -e "${GREEN}✅ Desconfiado.${NC}"
        ;;
      "ℹ️  Información")
        echo -e "${CYAN}ℹ️ Información del dispositivo:${NC}"
        bluetoothctl info "$mac" | sed 's/^/  /'
        ;;
      "🗑️  Eliminar")
        echo -e "${RED}🗑️ Eliminando $mac...${NC}"
        bluetoothctl remove "$mac" &>/dev/null && echo -e "${GREEN}✅ Dispositivo eliminado.${NC}"
        sleep 2
        return
        ;;
      "🔄 Volver a escanear")
        return
        ;;
      "🚪 Salir"|"")
        echo -e "${BLUE}👋 ¡Hasta luego!${NC}"
        exit 0
        ;;
    esac
    echo
    read -p "Presiona Enter para continuar..." || true
  done
}

# Bucle principal
while true; do
  main_menu || continue
done
# #!/usr/bin/env bash
# set -e
#
#
# TERM_WIDTH=110
#
# # ASCII banner
# ASCII_ART="
# ██████╗ ██╗     ██╗   ██╗███████╗████████╗████████╗██╗  ██╗███████╗████████╗
# ██╔══██╗██║     ██║   ██║██╔════╝╚══██╔══╝╚══██╔══╝██║  ██║██╔════╝╚══██╔══╝
# ██████╔╝██║     ██║   ██║███████╗   ██║      ██║   ███████║█████╗     ██║   
# ██╔═══╝ ██║     ██║   ██║╚════██║   ██║      ██║   ██╔══██║██╔══╝     ██║   
# ██║     ███████╗╚██████╔╝███████║   ██║      ██║   ██║  ██║███████╗   ██║   
# ╚═╝     ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚══════╝   ╚═╝   
# "
#
# center_text() {
#   local text="$1"
#   local term_width=$TERM_WIDTH
#   local max_width=0
#   while IFS= read -r line; do
#     (( ${#line} > max_width )) && max_width=${#line}
#   done <<< "$text"
#   local padding=$(( (term_width - max_width) / 2 ))
#   (( padding < 0 )) && padding=0
#   while IFS= read -r line; do
#     printf "%${padding}s%s\n" "" "$line"
#   done <<< "$text"
# }
#
# echo -e "\033[1;34m"
# center_text "$ASCII_ART"
# echo -e "\033[0m"
#
# # Comprobar bluetoothctl
# if ! command -v bluetoothctl &>/dev/null; then
#   echo "❌ bluetoothctl no está instalado. Instálalo con:"
#   echo "   sudo zypper install bluez bluez-tools"
#   exit 1
# fi
#
# # Activar Bluetooth si está apagado (sin habilitar)
# echo "🔋 Activando adaptador Bluetooth..."
# sudo systemctl start bluetooth.service
# bluetoothctl power on &>/dev/null || {
#   echo "❌ No se pudo activar el adaptador Bluetooth."
#   exit 1
# }
#
# # Escanear dispositivos
# echo "🔍 Escaneando dispositivos cercanos durante 15s..."
# output=$(timeout 15s bluetoothctl scan on 2>/dev/null || true)
#
# devices=$(bluetoothctl devices | awk '{print $2 " " substr($0, index($0,$3))}' | sort -u)
#
# if [ -z "$devices" ]; then
#   echo "⚠️ No se detectaron dispositivos."
#   exit 1
# fi
#
# # Menú con gum
# selected=$(echo "$devices" | gum choose --height 15 --cursor "👉" --header "Selecciona un dispositivo Bluetooth:")
# if [ -z "$selected" ]; then
#   echo "❌ No seleccionaste ningún dispositivo."
#   exit 1
# fi
#
# MAC=$(echo "$selected" | awk '{print $1}')
# NAME=$(echo "$selected" | cut -d' ' -f2-)
#
# echo "📱 Dispositivo seleccionado: '$NAME' ($MAC)"
#
# # Intentar emparejar
# echo "🔗 Intentando emparejar..."
# if ! bluetoothctl pair "$MAC" | grep -q "Pairing successful"; then
#   echo "⚠️ No se pudo emparejar (puede requerir confirmación manual)."
# else
#   echo "✅ Emparejamiento exitoso."
# fi
#
# # Intentar conectar
# echo "🔌 Intentando conectar..."
# if ! bluetoothctl connect "$MAC" | grep -q "Connection successful"; then
#   echo "⚠️ No se pudo conectar automáticamente (puede requerir confirmación manual)."
# else
#   echo "✅ Conexión exitosa."
# fi
#
# # Marcar como confiable
# bluetoothctl trust "$MAC" &>/dev/null
# echo "🤝 Dispositivo marcado como confiable."
#
# echo "✨ Finalizado. Puedes verificar con:"
# echo "   bluetoothctl info $MAC"
