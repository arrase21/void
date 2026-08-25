#!/usr/bin/env bash
set -Eeuo pipefail

LOG="$HOME/mangowc-install.log"
exec > >(tee -a "$LOG") 2>&1

trap 'echo "❌ Error in $LINENO: $BASH_COMMAND"; exit 1' ERR

### ---------- UI helpers ----------
title() {
    echo -e "\n\033[1;35m==> $1\033[0m\n"
}
step() {
    echo -e "\033[1;36m[•] $1...\033[0m"
}
ok() {
    echo -e "\033[1;32m✔ $1\033[0m"
}
warn() {
    echo -e "\033[1;33m⚠ $1\033[0m"
}

### ---------------------------------
# DEPENDENCIAS MODULARIZADAS
### ---------------------------------

core_pkgs="
bc curl wget unzip 7zip git jq inxi xdg-user-dirs
playerctl wiremix libspa-bluetooth pamixer bluetui
bluez dbus turnstile seatd zzzy xdg-portal-wlr
linux-firmware-intel mesa-dri rsync
intel-video-accel zramen pipewire wireplumber
iwd udevil chrony
"

wayland_pkgs="
mangowc grim slurp swappy cliphist wlsunset
mpv rust cargo awww sox ImageMagick matugen
sound-theme-freedesktop brightnessctl
"

desktop_apps_pkgs="
foot Thunar telegram-desktop rofi quickshell
yazi fd bat fzf eza fish-shell tmux btop
go tree-sitter-cli lazygit
"

build_deps="
meson ninja gcc make
"

### ---------------------------------
# REPOSITORIES
### ---------------------------------

add_repositories() {
    title "Adding repositories"
    echo "repository=https://repo.voiders.dev" |
        sudo tee /etc/xbps.d/10-voiders-community.conf > /dev/null
    sudo xbps-install -S
    ok "Repositories added"
}

### ---------------------------------
# DEPENDENCIAS (fault-tolerant per package)
### ---------------------------------

install_dependencies() {
    title "Installing dependencies"

    local all_pkgs="$core_pkgs $wayland_pkgs $desktop_apps_pkgs $build_deps"
    local failed_pkgs=()

    if sudo xbps-install -S -y $all_pkgs; then
        ok "Dependencies installed"
        return 0
    fi

    warn "Bulk install failed, retrying package by package to isolate failures"

    for pkg in $all_pkgs; do
        step "Installing $pkg"
        if ! sudo xbps-install -S -y "$pkg"; then
            warn "Failed to install: $pkg"
            failed_pkgs+=("$pkg")
        fi
    done

    if [ "${#failed_pkgs[@]}" -gt 0 ]; then
        warn "The following packages failed to install:"
        printf '    - %s\n' "${failed_pkgs[@]}"
        warn "Continuing installation. Review the log at $LOG"
    else
        ok "Dependencies installed"
    fi
}

### ---------------------------------
# DOTFILES
### ---------------------------------

clone_dotfiles() {
    title "Dotfiles"

    mkdir -p "$HOME/repos"

    if [ ! -d "$HOME/repos/void/.git" ]; then
        step "Cloning repository"

        rm -rf "$HOME/repos/void"

        git clone \
            https://github.com/arrase21/void.git \
            "$HOME/repos/void"
    else
        step "Updating existing repository"

        git -C "$HOME/repos/void" pull --rebase
    fi

    ok "Dotfiles ready in $HOME/repos/void"
}

### ---------------------------------
# CONFIGURACIONES
### ---------------------------------

copy_configs() {
    title "Install configs"

    local BASE="$HOME/repos/void"

    mkdir -p \
        "$HOME/.config" \
        "$HOME/.local" \
        "$HOME/Pictures"

    if [ ! -d "$BASE" ]; then
        echo "❌ Error: $BASE does not exist."
        echo "❌ Dotfiles clone failed."
        exit 1
    fi

    step "Copying .config"

    rsync -av \
        --no-perms \
        "$BASE/.config/" \
        "$HOME/.config/"

    step "Copying .local"

    rsync -av \
        --no-perms \
        "$BASE/.local/" \
        "$HOME/.local/"

    if [ -d "$BASE/.themes" ]; then
        step "Copying themes"

        rsync -av \
            --no-perms \
            "$BASE/.themes/" \
            "$HOME/.themes/"
    fi

    if [ -d "$BASE/.icons" ]; then
        step "Copying icons"

        rsync -av \
            --no-perms \
            "$BASE/.icons/" \
            "$HOME/.icons/"
    fi

    if [ -d "$BASE/wallpapers" ]; then
        step "Copying wallpapers"

        mkdir -p "$HOME/Pictures/wallpapers"

        rsync -a \
            --no-perms \
            "$BASE/wallpapers/" \
            "$HOME/Pictures/wallpapers/"
    fi

    ok "Configs installed"
}

### ---------------------------------
# FONTS
### ---------------------------------

install_fonts() {
    title "Nerd Fonts"

    mkdir -p "$HOME/.local/share/fonts"

    (
        cd "$HOME/.local/share/fonts"

        for font in JetBrainsMono VictorMono; do

            step "Installing $font"

            wget -q \
                -O "$font.zip" \
                "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.zip"

            unzip -o \
                "$font.zip" \
                -d "$font"

            rm -f "$font.zip"
        done

        step "Installing PlemolJP NF"

        curl -fLo \
            /tmp/plemol.zip \
            "https://github.com/yuru7/PlemolJP/releases/download/v3.0.0/PlemolJP_NF_v3.0.0.zip"

        unzip -o \
            /tmp/plemol.zip \
            -d "$HOME/.local/share/fonts/"

        rm -f /tmp/plemol.zip
    )

    fc-cache -fv

    ok "Fonts installed"
}

### ---------------------------------
# SERVICES
### ---------------------------------

enable_service() {
    local service="$1"

    if [ -d "/etc/sv/$service" ]; then
        sudo ln -sfn \
            "/etc/sv/$service" \
            "/var/service/$service"

        echo "  ✔ $service enabled"
    else
        warn "Service $service not found in /etc/sv"
    fi
}

disable_service() {
    local service="$1"

    if [ -L "/var/service/$service" ]; then
        sudo rm -f "/var/service/$service"
        echo "  ✔ $service disabled"
    fi
}

### ---------------------------------
# USER D-BUS (turnstile)
### ---------------------------------

install_user_dbus() {
    title "User D-Bus (turnstile)"

    local BASE="$HOME/repos/void"
    local SHARE=/usr/share/examples/turnstile
    local DEST="$HOME/.config/service"

    mkdir -p "$DEST/dbus" "$DEST/turnstile-ready"

    if [ -f "$SHARE/dbus.run" ] && [ -f "$SHARE/dbus.check" ]; then
        step "Installing dbus.run / dbus.check"

        cp "$SHARE/dbus.run" "$DEST/dbus/run"
        cp "$SHARE/dbus.check" "$DEST/dbus/check"
        chmod +x "$DEST/dbus/run" "$DEST/dbus/check"
    else
        warn "turnstile examples not found in $SHARE"
    fi

    cat > "$DEST/turnstile-ready/conf" << 'EOF'
core_services="dbus"
EOF

    if [ -d "$BASE" ]; then
        step "Mirroring to dotfiles repo"

        mkdir -p \
            "$BASE/.config/service/dbus" \
            "$BASE/.config/service/turnstile-ready"

        cp -a \
            "$DEST/dbus/." \
            "$BASE/.config/service/dbus/"

        cp \
            "$DEST/turnstile-ready/conf" \
            "$BASE/.config/service/turnstile-ready/conf"

        ok "User D-Bus saved in $BASE/.config/service"
    else
        warn "Dotfiles repo not found, skipping mirror"
    fi

    ok "User D-Bus configured"
}

### ---------------------------------
# SETUP
### ---------------------------------

setup() {
    title "Configuring services and XDG"

    step "Updating XDG user directories"

    xdg-user-dirs-update

    if [ -f "$HOME/repos/void/.config/user-dirs.dirs" ]; then

        cp \
            "$HOME/repos/void/.config/user-dirs.dirs" \
            "$HOME/.config/user-dirs.dirs"

        xdg-user-dirs-update
    fi

    ### -----------------------------
    # CORE SERVICES
    ### -----------------------------
    step "Adding &USER to group"
    sudo usermod -aG _seatd,wheel,video,input,kvm "$USER"
    ok "Groups added (requires logout or reboot)"
    step "Enabling core services"

    enable_service dbus
    enable_service seatd
    enable_service turnstiled

    ### -----------------------------
    # ZRAM
    ### -----------------------------

    step "Configuring zramen"

    if [ -f /etc/sv/zramen/conf ]; then
        sudo sed -i \
            's/^#export ZRAM_COMP_ALGORITHM=.*/export ZRAM_COMP_ALGORITHM=lz4/' \
            /etc/sv/zramen/conf
        sudo sed -i \
            's/^#export ZRAM_SIZE=.*/export ZRAM_SIZE=100/' \
            /etc/sv/zramen/conf
    else
        warn "/etc/sv/zramen/conf not found"
    fi
    enable_service zramen

    ### -----------------------------
    # SWAPPINESS
    ### -----------------------------

    step "Configuring swappiness"
    sudo mkdir -p /etc/sysctl.d
    sudo tee /etc/sysctl.d/99-custom.conf > /dev/null << 'EOF'
vm.swappiness=180
vm.watermark_boost_factor=0
vm.watermark_scale_factor=125
vm.page-cluster=0
EOF

    sudo sysctl --system

    ### -----------------------------
    # NETWORK
    ### -----------------------------

    step "Configuring network"

    disable_service dhcpcd
    disable_service wpa_supplicant

    enable_service iwd

    ### -----------------------------
    # BLUETOOTH
    ### -----------------------------
    step "Configuring Bluetooth"
    enable_service bluetoothd
    ### -----------------------------
    # CHRONY
    ### -----------------------------
    step "Configuring chrony"
    enable_service chronyd

    ### -----------------------------
    # VERIFY
    ### -----------------------------
    sleep 2
    title "Checking services"

    local services=(
        dbus
        seatd
        turnstiled
        zramen
        bluetoothd
        iwd
        chronyd
    )

    local failed=0

    for service in "${services[@]}"; do
        if sv status "$service" >/dev/null 2>&1; then
            echo "  ✔ $service"
        else
            echo "  ❌ $service"
            failed=1
        fi
    done

    if [ "$failed" -ne 0 ]; then
        warn "Some services are not running yet."
        warn "This can be normal immediately after enabling them."
    else
        ok "All services are running"
    fi
    ok "System configuration completed"
}

### ---------------------------------
# MAIN
### ---------------------------------

main() {

    clear
    title "Mangowc Installer"
    add_repositories
    install_dependencies
    clone_dotfiles
    copy_configs
    install_user_dbus
    install_fonts
    setup

    title "INSTALL COMPLETE"

    echo
    echo "👉 Restart your session or reboot the system."
    echo
    echo "📄 Log saved at:"
    echo "$LOG"
    echo
}

main "$@"
