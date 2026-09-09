#!/usr/bin/env bash
#
# Dependency installer for this dotfiles set — Arch Linux.
#
# Installs everything the configuration in this repository expects to find.
# It does NOT copy any config: see README.md for that.
#
# AUR packages go through paru, which is bootstrapped if it is missing.
# Safe to re-run: every step is idempotent.

set -euo pipefail

say() { printf '\n\033[1;35m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as your normal user; it will call sudo where it needs to." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. paru
# ---------------------------------------------------------------------------
say "Making sure the base toolchain and paru are present"
sudo pacman -S --needed --noconfirm base-devel git

if ! have paru; then
    tmp="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
    (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
else
    echo "  paru already present"
fi

# ---------------------------------------------------------------------------
# 2. Repository packages
# ---------------------------------------------------------------------------
say "Installing the Hyprland desktop"
sudo pacman -S --needed --noconfirm \
    hyprland hyprlock hypridle hyprpaper hyprsunset hyprpicker \
    xdg-desktop-portal-hyprland xdg-desktop-portal xdg-desktop-portal-gtk \
    waybar

say "Installing the shell and notification centre"
sudo pacman -S --needed --noconfirm \
    swaync rofi-wayland

say "Installing Wayland utilities"
sudo pacman -S --needed --noconfirm \
    wl-clipboard cliphist grim slurp brightnessctl playerctl \
    pavucontrol blueman flameshot polkit-gnome \
    networkmanager network-manager-applet

say "Installing audio and Bluetooth"
sudo pacman -S --needed --noconfirm \
    pipewire pipewire-pulse pipewire-audio wireplumber \
    bluez bluez-utils

say "Installing the terminal and CLI tools"
sudo pacman -S --needed --noconfirm \
    kitty zsh eza zoxide fzf yazi btop fastfetch neovim lazygit \
    ripgrep fd bat git wget curl unzip jq imagemagick \
    ffmpegthumbnailer poppler

say "Installing theming and toolkit support"
sudo pacman -S --needed --noconfirm \
    qt6ct nwg-look gnome-themes-extra \
    gtk3 gtk4 libadwaita python-gobject \
    qt6-declarative qt6-5compat qt6-multimedia

say "Installing fonts"
sudo pacman -S --needed --noconfirm \
    ttf-firacode-nerd ttf-font-awesome noto-fonts-emoji

# ---------------------------------------------------------------------------
# 3. AUR packages
# ---------------------------------------------------------------------------
say "Installing AUR packages"
# quickshell        — draws the bar and every panel (0.3.x or newer: the bar
#                     uses Hyprland.toplevels, rawEvent and IconImage)
# awww              — the wallpaper daemon the Hyprland autostart launches
# nwg-*             — dock and display tools the ML4W sidebar calls
# waypaper/wlogout  — alternative wallpaper and logout front-ends ML4W ships
# matugen           — generates the wallpaper colour scheme
# oh-my-posh-bin    — the zsh prompt
# kora / bibata     — icon and cursor themes named in gtk-3.0/settings.ini,
#                     and the source of the app icons the workspace module shows
paru -S --needed --noconfirm \
    quickshell \
    nwg-dock-hyprland nwg-displays \
    waypaper wlogout \
    matugen-bin \
    oh-my-posh-bin \
    kora-icon-theme \
    bibata-cursor-theme-bin \
    ttf-0xproto-nerd \
    || echo "  (one or more AUR packages failed — see the notes at the end)"

# awww is a swww fork and may not be in the AUR. swww is a drop-in for what the
# autostart uses it for, so fall back to it and say so.
if ! have awww-daemon; then
    say "awww not available — falling back to swww"
    paru -S --needed --noconfirm awww 2>/dev/null || sudo pacman -S --needed --noconfirm swww
    if ! have awww-daemon && have swww-daemon; then
        cat <<'NOTE'
  swww installed instead of awww. Edit hypr/conf/autostart.lua and change
      hl.exec_cmd("awww-daemon")
  to
      hl.exec_cmd("swww-daemon")
NOTE
    fi
fi

# ---------------------------------------------------------------------------
# 4. Things no package provides
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say "Installing the unpackaged fonts shipped with this repo"
# Fira Sans is the UI font every Quickshell panel names, and Material Icons is
# used by the waybar themes. Neither is packaged the way this setup expects.
sudo mkdir -p /usr/share/fonts
sudo cp -r "$REPO_ROOT/extras/fonts/Fira_Sans" /usr/share/fonts/
sudo cp -r "$REPO_ROOT/extras/fonts/Material-Icons" /usr/share/fonts/
sudo fc-cache -f

say "Installing hyprmod (Hyprland settings GUI, optional)"
if ! have hyprmod; then
    sudo pacman -S --needed --noconfirm python-pipx
    pipx install hyprmod || echo "  (hyprmod unavailable — the sidebar button will stay hidden)"
fi

say "Enabling services"
sudo systemctl enable --now bluetooth.service || true
sudo systemctl enable --now NetworkManager.service || true

say "Setting zsh as the login shell"
if [ "$SHELL" != "$(command -v zsh)" ]; then
    chsh -s "$(command -v zsh)"
    echo "  Log out and back in for this to take effect."
fi

cat <<'DONE'

==> Dependencies installed.

Next:
  1. Put the configuration in place  (see README.md — copy or stow).
  2. Log out and pick "Hyprland" at the login screen.

Not installed automatically, by design:
  * zinit and the zsh plugins  — .zshrc clones them on first shell start.
  * Neovim plugins            — your plugin manager fetches them on first run.
  * tty-clock                 — aliased in .zshrc; `paru -S tty-clock` if you
                                want the `clock` alias.
  * solaar                    — referenced by the Hyprland autostart for
                                Logitech devices; harmless if absent.

If an AUR package failed above, the usual causes are a renamed package or a
build dependency. Search with `paru -Ss <name>` and install the current name.
DONE
