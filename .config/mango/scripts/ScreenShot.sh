#!/usr/bin/env bash
# Screenshot script for dwl + Wayland

time=$(date "+%d-%b_%H-%M-%S")
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
file="Screenshot_${time}_${RANDOM}.png"

iDIR="$HOME/.config/swaync/icons"
iDoR="$HOME/.config/swaync/images"
sDIR="$HOME/.config/mango/scripts"

notify_cmd_base="notify-send -t 10000 -A action1=Open -A action2=Delete -h string:x-canonical-private-synchronous:shot-notify"
notify_cmd_shot="${notify_cmd_base} -i ${iDIR}/picture.png"
notify_cmd_NOT="notify-send -u low -i ${iDoR}/note.png"

mkdir -p "$dir"

notify_view() {
    local check_file="$1"
    if [[ -e "$check_file" ]]; then
        "${sDIR}/Sounds.sh" --screenshot
        resp=$(timeout 5 ${notify_cmd_shot} "Screenshot saved" "$check_file")
        case "$resp" in
            action1) xdg-open "$check_file" & ;;
            action2) rm "$check_file" & ;;
        esac
    else
        ${notify_cmd_NOT} "Screenshot" "NOT Saved"
        "${sDIR}/Sounds.sh" --error
    fi
}

countdown() {
    for sec in $(seq "$1" -1 1); do
        notify-send -h string:x-canonical-private-synchronous:shot-notify -t 1000 -i "$iDIR"/timer.png "Taking shot" "in: $sec secs"
        sleep 1
    done
}

shotnow() {
    cd "$dir" && grim - | tee "$file" | wl-copy
    notify_view "$dir/$file"
}

shot5() {
    countdown 5
    cd "$dir" && grim - | tee "$file" | wl-copy
    notify_view "$dir/$file"
}

shot10() {
    countdown 10
    cd "$dir" && grim - | tee "$file" | wl-copy
    notify_view "$dir/$file"
}

shotarea() {
    tmpfile=$(mktemp)
    grim -g "$(slurp)" - >"$tmpfile"
    if [[ -s "$tmpfile" ]]; then
        wl-copy <"$tmpfile"
        mv "$tmpfile" "$dir/$file"
    fi
    notify_view "$dir/$file"
}

shotswappy() {
    tmpfile=$(mktemp)
    grim -g "$(slurp)" - >"$tmpfile"
    if [[ -s "$tmpfile" ]]; then
        wl-copy <"$tmpfile"
        swappy -f "$tmpfile"
    fi
    rm -f "$tmpfile"
}

case "$1" in
    --now) shotnow ;;
    --in5) shot5 ;;
    --in10) shot10 ;;
    --area) shotarea ;;
    --swappy) shotswappy ;;
    *)
        echo "Available Options: --now --in5 --in10 --area --swappy"
        ;;
esac

exit 0

