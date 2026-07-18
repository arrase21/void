#!/usr/bin/env bash
MOUNT_POINT="$HOME/Android/phone"

DEVICES=$(simple-mtpfs -l 2>/dev/null || true)

if [ -n "$DEVICES" ]; then
    if mountpoint -q "$MOUNT_POINT"; then
      echo " "  # conectado pero no montado
    else
        echo ""  # conectado pero no montado
    fi
else
    exit 1
fi

