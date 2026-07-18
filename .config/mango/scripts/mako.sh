#!/usr/bin/env bash
set -e

MATUGEN_COLORS="$HOME/.config/mango/waybar/matugen/matugen-waybar.css"
MAKO_CONFIG="$HOME/.config/mako/config"

# Verificar que existen los colores de matugen
if [[ ! -f "$MATUGEN_COLORS" ]]; then
  echo "❌ No se encontraron colores de matugen en: $MATUGEN_COLORS"
  exit 1
fi

extract_color() {
  grep -Po "(?<=@define-color $1 )#[0-9A-Fa-f]{6}" "$MATUGEN_COLORS" | head -n1
}

extract_rgba_to_hex() {
  rgba=$(grep -Po "(?<=@define-color $1 )rgba\([^)]+\)" "$MATUGEN_COLORS" | head -n1)
  if [[ -n "$rgba" ]]; then
    r=$(echo "$rgba" | grep -Po '\d+' | sed -n '1p')
    g=$(echo "$rgba" | grep -Po '\d+' | sed -n '2p')
    b=$(echo "$rgba" | grep -Po '\d+' | sed -n '3p')
    printf "#%02x%02x%02x" "$r" "$g" "$b"
  fi
}

primary=$(extract_color primary)                    # #bbc3ff
surface=$(extract_color surface)                    # #131318
on_surface=$(extract_color on_surface)              # #e4e1e9
error=$(extract_color error)                        # #ffb4ab

# Si surface está en rgba(), convertirlo
if [[ -z "$surface" ]]; then
  surface=$(extract_rgba_to_hex surface)
fi

# Usamos surface_container para fondos con más contraste
on_primary="$surface"

for var in primary surface on_surface error; do
  if [ -z "${!var}" ]; then
    echo "❌ Falta color: $var (no encontrado en $MATUGEN_COLORS)"
    exit 1
  fi
done

cat > "$MAKO_CONFIG" <<EOF
# 🦊 Config de Mako generado automáticamente por Matugen
# $(date)

font=JetBrainsMono Nerd Font 10
max-visible=10
ignore-timeout=1

background-color=${surface}ee
text-color=${on_surface}
border-color=${primary}
progress-color=${primary}

margin=1
padding=1
border-size=4
border-radius=8

[urgency=high]
border-color=${error}
EOF

if pgrep -x mako >/dev/null; then
  makoctl reload || { pkill mako && mako & }
else
  mako &
fi

echo "✅ Mako actualizado con colores de Matugen"
