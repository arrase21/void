#!/usr/bin/env bash
set -euo pipefail

# Config
MOUNT_BASE="$HOME/Android"            # base para los montajes
MOUNT_POINT="$MOUNT_BASE/phone"       # punto final (puedes cambiar)
NOTIFY_TITLE="Android MTP"
YAZI_CMD="$(command -v yazi || true)"

mkdir -p "$MOUNT_POINT"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$NOTIFY_TITLE" "$1"
  else
    echo "[notify] $1"
  fi
}

try_jmtpfs() {
  if command -v jmtpfs >/dev/null 2>&1; then
    if mountpoint -q "$MOUNT_POINT"; then
      notify "Ya está montado en $MOUNT_POINT"
      return 0
    fi
    jmtpfs "$MOUNT_POINT" && return 0 || return 1
  fi
  return 1
}

try_simple_mtpfs() {
  if command -v simple-mtpfs >/dev/null 2>&1; then
    if mountpoint -q "$MOUNT_POINT"; then
      notify "Ya está montado en $MOUNT_POINT"
      return 0
    fi
    simple-mtpfs --device 1 "$MOUNT_POINT" && return 0 || return 1
  fi
  return 1
}

try_gio_gvfs() {
  if command -v gio >/dev/null 2>&1; then
    local list
    list="$(gio mount -l 2>/dev/null || true)"
    if echo "$list" | grep -qi mtp; then
      while IFS= read -r line; do
        if echo "$line" | grep -qi mtp; then
          uri="$(echo "$line" | grep -oP 'mtp://[^ ]+' || true)"
          if [ -n "$uri" ]; then
            gio mount "$uri" || true
          fi
        fi
      done <<< "$list"
      return 0
    fi
  fi
  return 1
}

unmount() {
  if mountpoint -q "$MOUNT_POINT"; then
    if command -v fusermount >/dev/null 2>&1; then
      fusermount -u "$MOUNT_POINT" || umount "$MOUNT_POINT" || true
    else
      umount "$MOUNT_POINT" || true
    fi
    notify "Desmontado."
  else
    notify "Nada montado en $MOUNT_POINT."
  fi
}

status() {
  if mountpoint -q "$MOUNT_POINT"; then
    echo "mounted"
  else
    echo "not-mounted"
  fi
}

case "${1:-status}" in
  mount)
    if [ "$(status)" = "mounted" ]; then
      notify "Ya montado en $MOUNT_POINT"
      exit 0
    fi

    # Orden de preferencia: jmtpfs -> simple-mtpfs -> gvfs (gio)
    if try_jmtpfs; then
      notify "Teléfono montado en $MOUNT_POINT (jmtpfs)."
    elif try_simple_mtpfs; then
      notify "Teléfono montado en $MOUNT_POINT (simple-mtpfs)."
    elif try_gio_gvfs; then
      notify-send "Android MTP" "Click in the icon to mount"
    else
      echo "Instala jmtpfs / simple-mtpfs o asegúrate de que GVFS detecte el dispositivo."
      exit 1
    fi

    echo "Montado en $MOUNT_POINT"
    ;;

  umount|unmount)
    unmount
    ;;

  toggle)
    if [ "$(status)" = "mounted" ]; then
      unmount
    else
      "$0" mount
    fi
    ;;

  status)
    if [ "$(status)" = "mounted" ]; then
      echo "mounted: $MOUNT_POINT"
    else
      echo "not-mounted"
    fi
    ;;

  *)
    echo "Uso: $0 {mount|unmount|toggle|status}"
    exit 2
    ;;
esac
