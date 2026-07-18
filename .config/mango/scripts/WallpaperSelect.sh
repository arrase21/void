#!/usr/bin/env bash

wall_dir="$HOME/Pictures/wallpapers"
cacheDir="$HOME/.cache/wallcache"
scriptsDir="$HOME/.config/mango/scripts/"
iDIR="$HOME/.config/swaync/images"

S -d "$cacheDir" ] || mkdir -p "$cacheDir"

# -------------------------------------------------
# Detectar monitor enfocado
# -------------------------------------------------

get_focused_monitor() {
    local output=$(wlr-randr --json 2>/dev/null |
        jq -r '.[] | select(.enabled==true) | .name' | head -n1)

    [ -z "$output" ] &&
        output=$(wlr-randr 2>/dev/null |
        grep -E "^[A-Z]" | head -n1 | awk '{print $1}')

    [ -z "$output" ] && output="eDP-1"

    echo "$output"
}

focused_monitor=$(get_focused_monitor)

# -------------------------------------------------
# Obtener info del monitor
# -------------------------------------------------

get_monitor_info() {
    local monitor="$1"

    if wlr-randr --json &>/dev/null; then
        wlr-randr --json |
        jq -r --arg mon "$monitor" '
            .[] | select(.name==$mon) |
            (.modes[] | select(.current==true) | .width),
            (.scale // 1.0)
        ' | xargs
    else
        echo "1920 1.0"
    fi
}

read monitor_width scale_factor < <(get_monitor_info "$focused_monitor")

monitor_width=${monitor_width:-1920}
scale_factor=${scale_factor:-1.0}

icon_size=$(echo "scale=2; ($monitor_width * 14) / ($scale_factor * 96)" | bc)
rofi_override="element-icon{size:${icon_size}px;}"
rofi_command="rofi -i -show -dmenu \
    -theme $HOME/.config/mango/rofi/themes/wallselect.rasi \
    -theme-str $rofi_override"

# -------------------------------------------------
# Paralelismo inteligente
# -------------------------------------------------

get_optimal_jobs() {
    local cores=$(nproc)
    (( cores <= 2 )) && echo 2 || echo $(( cores > 4 ? 4 : cores-1 ))
}

PARALLEL_JOBS=$(get_optimal_jobs)

# -------------------------------------------------
# Procesar imágenes (NO procesa GIF)
# -------------------------------------------------

process_image() {
    local imagen="$1"
    local nombre_archivo=$(basename "$imagen")
    local cache_file="${cacheDir}/${nombre_archivo}"
    local lock_file="${cacheDir}/.lock_${nombre_archivo}"

    # 👉 Si es GIF no lo convertimos
    [[ "$imagen" =~ \.gif$ ]] && return 0

    (
        flock -x 200
        [ ! -f "$cache_file" ] &&
            magick "$imagen" \
                -resize 500x500^ \
                -gravity center \
                -extent 500x500 \
                "$cache_file"
        rm -f "$lock_file"
    ) 200>"$lock_file"
}

export -f process_image
export cacheDir

rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

# -------------------------------------------------
# Generar cache paralelo
# -------------------------------------------------

find "$wall_dir" -type f \
\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
-print0 |
xargs -0 -P "$PARALLEL_JOBS" -I {} bash -c 'process_image "{}"'

# -------------------------------------------------
# Limpiar cache huérfano
# -------------------------------------------------

for cached in "$cacheDir"/*; do
    [ -f "$cached" ] || continue
    original="${wall_dir}/$(basename "$cached")"
    [ ! -f "$original" ] && rm -f "$cached"
done

rm -f "${cacheDir}"/.lock_* 2>/dev/null || true

# -------------------------------------------------
# Reiniciar rofi si está abierto
# -------------------------------------------------

pidof rofi >/dev/null && pkill rofi

# -------------------------------------------------
# Selector con preview correcto
# -------------------------------------------------

wall_selection=$(find "$wall_dir" -type f \
\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
   -o -iname "*.webp" -o -iname "*.gif" \) -print0 |
    xargs -0 basename -a |
    LC_ALL=C sort -V |
    while IFS= read -r A; do
        if [[ "$A" =~ \.gif$ ]]; then
            # 👉 GIF usa archivo original
            printf '%s\x00icon\x1f%s/%s\n' "$A" "$wall_dir" "$A"
        else
            # 👉 otras imágenes usan cache
            printf '%s\x00icon\x1f%s/%s\n' "$A" "$cacheDir" "$A"
        fi
    done | $rofi_command)

# -------------------------------------------------
# Configuración SWWW
# -------------------------------------------------

FPS=60
TYPE="any"
DURATION=2
SWWW_PARAMS="--transition-fps $FPS --transition-type $TYPE --transition-duration $DURATION"

awww query || awww-daemon --format xrgb

# -------------------------------------------------
# Aplicar wallpaper
# -------------------------------------------------

if [[ -n "$wall_selection" ]]; then

    selected="${wall_dir}/${wall_selection}"

    cp "$selected" ~/.config/wall.png
    magick "$selected" -gravity center -crop 1:1 +repage "$HOME/.config/wall_square.png" 2>&1
    awww img -o "$focused_monitor" "$selected" $SWWW_PARAMS

    # 👉 colores
    "$scriptsDir/WallustSwww" --dark
    matugen image "$selected" -m dark --source-color-index 0

    # 👉 recargar waybar
    killall waybar
    if pgrep -x waybar >/dev/null; then
        pkill -SIGUSR2 waybar
    else
        waybar -c ~/.config/mango/waybar/config -s ~/.config/mango/waybar/style.css &
    fi

    # 👉 recargar swaync
    pkill -USR2 swaync-client 2>/dev/null || swaync-client -rs &

    "$scriptsDir/mako.sh" 2>/dev/null || true

    notify-send "Wallpaper cambiado" "$wall_selection" -i "$selected"
    mpv /usr/share/sounds/freedesktop/stereo/message.oga &
fi
