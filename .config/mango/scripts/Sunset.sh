#!/usr/bin/env bash
set +e

if pgrep -x "wlsunset" >/dev/null; then
  pkill wlsunset >/dev/null 2>&1
else
  setsid wlsunset -T 3501 -t 3500 >/dev/null 2>&1 &
fi

exit 0
