#!/bin/bash

CHROMIUM_THEME=~/.config/current/theme/chromium.theme

if cmd-present chromium || cmd-present helium-browser || cmd-present brave-browser; then
  if [[ -f $CHROMIUM_THEME ]]; then
    THEME_RGB_COLOR=$(<$CHROMIUM_THEME)
    THEME_HEX_COLOR=$(printf '#%02x%02x%02x' ${THEME_RGB_COLOR//,/ })
  else
    # Use a default, neutral grey if theme doesn't have a color
    THEME_RGB_COLOR="28,32,39"
    THEME_HEX_COLOR="#1c2027"
  fi
  
  # Chromium
  if cmd-present -v chromium >/dev/null 2>&1; then
     mkdir -p /etc/chromium/policies/managed/
    echo "{\"BrowserThemeColor\": \"$THEME_HEX_COLOR\"}" | \
      sudo tee /etc/chromium/policies/managed/color.json >/dev/null
    chromium --no-startup-window &
  fi

  if cmd-present helium-browser; then
    echo "{\"BrowserThemeColor\": \"$THEME_HEX_COLOR\"}" | tee "/etc/chromium/policies/managed/color.json" >/dev/null
    helium-browser --no-startup-window --refresh-platform-policy
  fi

  if cmd-present brave-browser; then
    echo "{\"BrowserThemeColor\": \"$THEME_HEX_COLOR\"}" | sudo tee "/etc/brave/policies/managed/color.json" >/dev/null
    brave-browser --refresh-platform-policy --no-startup-window 
  fi
fi
