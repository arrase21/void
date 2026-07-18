#!/bin/bash

export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

PGADMIN="/home/arrase/pgadmin4/bin/pgadmin4"
URL="http://127.0.0.1:5050"

"$PGADMIN" >/tmp/pgadmin.log 2>&1 &

i=0
while [ $i -lt 20 ]; do
  curl -sf "$URL" >/dev/null && break
  sleep 1
  i=$((i + 1))
done

launch-webapp "$URL" >/dev/null 2>&1 &

