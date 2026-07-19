#!/usr/bin/env bash
set -Eeuo pipefail

LOG="$HOME/mangowc-install.log"
exec > >(tee -a "$LOG") 2>&1

trap 'echo "❌ Error en línea $LINENO"; exit 1' ERR

### ---------- UI helpers ----------
title(){ echo -e "\n\033[1;35m==> $1\033[0m\n"; }
step(){ echo -e "\033[1;36m[•] $1...\033[0m"; }
ok(){ echo -e "\033[1;32m✔ $1\033[0m"; }

##################################
# DEPENDENCIAS MODULARIZADAS
##################################

core_pkgs="
bc curl wget unzip 7zip git jq inxi xdg-user-dirs playerctl wiremix
pamixer bluetui bluez dbus elogind linux-firmware-intel mesa-dri
intel-video-accel zramen pipewire pipewire-pulseaudio wireplumber NetworkManager
"

wayland_pkgs="
mangowc grim slurp swappy cliphist Waybar mako
mpv rust cargo awww sox ImageMagick matugen
sound-theme-freedesktop brightnessctl
"

desktop_apps_pkgs="
ghostty foot thunar telegram-desktop rofi
yazi fd bat fzf eza fish-shell tmux btop
go tree-sitter-cli
"

build_deps="
meson ninja gcc make
"

##################################
# FUNCIONES INSTALL
##################################

add_repositories() {
  title "Adding repositories"
  echo "repository=https://repo.voiders.dev" | sudo tee /etc/xbps.d/10-voiders-community.conf
  sudo xbps-install -S
  ok "Repositories added"
}

install_dependencies() {
  title "Installing dependencies"
  sudo xbps-install -S \
    $core_pkgs \
    $wayland_pkgs \
    $desktop_apps_pkgs \
    $build_deps || echo "⚠️ Some packages failed"
  ok "Dependencies installed"
}

clone_dotfiles() {
  title "Dotfiles"
  mkdir -p "$HOME/repos"
  if [ ! -d "$HOME/repos/opensuseTumbleweed/.git" ]; then
    step "Clon Repo"
    rm -rf "$HOME/repos/opensuseTumbleweed"
    git clone https://github.com/arrase21/opensuseTumbleweed.git "$HOME/repos/opensuseTumbleweed"
  else
    step "Update exist repo"
    git -C "$HOME/repos/opensuseTumbleweed" pull --rebase
  fi
  ok "Dotfiles ready in $HOME/repos/opensuseTumbleweed"
}

copy_configs() {
  title "Install configs"
  BASE="$HOME/repos/opensuseTumbleweed"
  mkdir -p "$HOME/.config" "$HOME/.local" "$HOME/Pictures"

  if [ ! -d "$BASE" ]; then
    echo "❌ Error: The file $BASE dont exists. Clone fail."
    exit 1
  fi
  step "Copy .config"
  rsync -av --no-perms "$BASE/.config/" "$HOME/.config/"
  step "Copy .local"
  rsync -av --no-perms "$BASE/.local/" "$HOME/.local/"
  [ -d "$BASE/.themes" ] && rsync -av --no-perms "$BASE/.themes/" "$HOME/.themes/"
  [ -d "$BASE/.icons" ] && rsync -av --no-perms "$BASE/.icons/" "$HOME/.icons/"
  [ -d "$BASE/wallpapers" ] && rsync -a --no-perms "$BASE/wallpapers/" "$HOME/Pictures/wallpapers/"
  ok "Already config"
}

setup() {
  title "Configurando servicios y XDG"
  xdg-user-dirs-update

  if [ -f "$HOME/repos/opensuseTumbleweed/.config/user-dirs.dirs" ]; then
    cp "$HOME/repos/opensuseTumbleweed/.config/user-dirs.dirs" "$HOME/.config/"
    xdg-user-dirs-update
  fi

  sudo ln -sf /etc/sv/dbus /var/service/
  echo "dbus active"
  sudo ln -sf /etc/sv/elogind /var/service/
  echo "elogind active"
  step "Configurando zramen"
  sudo sed -i 's/^#export ZRAM_COMP_ALGORITHM=.*/export ZRAM_COMP_ALGORITHM=lz4/' /etc/sv/zramen/conf
  sudo sed -i 's/^#export ZRAM_SIZE=.*/export ZRAM_SIZE=100/' /etc/sv/zramen/conf
  sudo ln -sf /etc/sv/zramen /var/service/
  echo "zram active"

  step "Configurando swappiness"
  sudo tee /etc/sysctl.d/99-custom.conf > /dev/null << 'EOF'
vm.swappiness=180
vm.watermark_boost_factor=0
vm.watermark_scale_factor=125
vm.page-cluster=0
EOF
  sudo sysctl --system

  sudo ln -sf /etc/sv/bluetoothd /var/service/
  echo "bluetoothd active"
  sudo rm -f /var/service/dhcpcd
  echo "delete dhcpcd"
  sudo ln -sf /etc/sv/NetworkManager /var/service/
  echo "active network"

  ok "updated"
}

install_fonts() {
  title "Nerd Fonts"
  mkdir -p "$HOME/.local/share/fonts"
  (
    cd "$HOME/.local/share/fonts"
    for font in JetBrainsMono VictorMono; do
      wget -q -O "$font.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip"
      unzip -o "$font.zip" -d "$font"
      rm "$font.zip"
    done

    step "Installing PlemolJP NF"
    curl -fLo /tmp/plemol.zip "https://github.com/yuru7/PlemolJP/releases/download/v3.0.0/PlemolJP_NF_v3.0.0.zip"
    unzip -o /tmp/plemol.zip -d "$HOME/.local/share/fonts/"
    rm -f /tmp/plemol.zip
  )

  fc-cache -fv
  ok "Fonts installed"
}

##################################
# MAIN
##################################

main() {
  clear
  title "Mangowc Installer"
  add_repositories
  install_dependencies
  clone_dotfiles
  copy_configs
  setup
  install_rust_tools
  install_fonts
  title "INSTALL COMPLETE"
  echo "👉 Restart session recommended"
  echo "📄 Log saved at: $LOG"
}

main "$@"

