#!/usr/bin/env bash
#
# Dependency installer for this dotfiles set — Fedora.
#
# Installs everything the configuration in this repository expects to find.
# It does NOT copy any config: run install/link.sh (or copy by hand) for that.
#
# Safe to re-run: every step is idempotent.

set -euo pipefail

FEDORA_VERSION="$(rpm -E %fedora)"
say() { printf '\n\033[1;35m==>\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

if [ "$(id -u)" -eq 0 ]; then
    echo "Run this as your normal user; it will call sudo where it needs to." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. Third-party repositories
# ---------------------------------------------------------------------------
say "Enabling RPM Fusion (free and nonfree)"
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm"

say "Enabling COPR repositories"
sudo dnf install -y dnf-plugins-core
# mineiro/hyprland     — Hyprland itself and its ecosystem (hyprlock, hypridle,
#                        hyprpaper, hyprsunset, hyprpicker, waybar, cliphist,
#                        awww, xdg-desktop-portal-hyprland)
# errornointernet/...  — quickshell, which draws the bar and every panel
# erikreider/...       — SwayNotificationCenter
# tofik/nwg-shell      — nwg-look and friends
# lihaohong/yazi       — yazi file manager
# dejan/lazygit        — lazygit
# che/nerd-fonts       — the patched fonts the bar and terminal use
for copr in \
    mineiro/hyprland \
    errornointernet/quickshell \
    erikreider/SwayNotificationCenter \
    tofik/nwg-shell \
    lihaohong/yazi \
    dejan/lazygit \
    che/nerd-fonts
do
    sudo dnf copr enable -y "$copr" || echo "  (already enabled or unavailable: $copr)"
done

# ---------------------------------------------------------------------------
# 2. Packages
# ---------------------------------------------------------------------------
say "Installing the Hyprland desktop"
sudo dnf install -y \
    hyprland hyprlock hypridle hyprpaper hyprsunset hyprpicker \
    xdg-desktop-portal-hyprland xdg-desktop-portal xdg-desktop-portal-gtk \
    awww cliphist waybar

say "Installing the shell (Quickshell bar and panels)"
# Quickshell 0.3.x or newer is required: the bar uses Hyprland.toplevels,
# rawEvent, IconImage and DesktopEntries.heuristicLookup.
sudo dnf install -y \
    quickshell SwayNotificationCenter rofi wlogout || \
    sudo dnf install -y quickshell SwayNotificationCenter rofi

say "Installing Wayland utilities"
sudo dnf install -y \
    wl-clipboard grim slurp brightnessctl playerctl pavucontrol blueman \
    flameshot polkit-gnome NetworkManager-tui network-manager-applet

say "Installing audio and Bluetooth"
sudo dnf install -y \
    pipewire pipewire-pulseaudio wireplumber pipewire-utils \
    bluez bluez-tools

say "Installing the terminal and CLI tools"
# The shell prompt, aliases and functions in extras/home/.zshrc need all of
# these; the Quickshell panels shell out to wpctl, brightnessctl and nmcli.
sudo dnf install -y \
    kitty zsh eza zoxide fzf yazi btop fastfetch neovim lazygit \
    ripgrep fd-find bat git wget curl unzip jq ImageMagick \
    ffmpegthumbnailer poppler-utils

say "Installing theming and toolkit support"
sudo dnf install -y \
    qt6ct nwg-look gnome-themes-extra \
    gtk3 gtk4 libadwaita python3-gobject \
    qt6-qtdeclarative qt6-qt5compat qt6-qtmultimedia

say "Installing fonts"
# Fira Sans (the UI font every panel names) and Material Icons are shipped in
# extras/fonts because they are not packaged; they are installed in step 3.
sudo dnf install -y \
    0xproto-nerd-font firacode-nerd-font \
    fontawesome-fonts fontawesome-6-free-fonts \
    google-noto-color-emoji-fonts google-noto-emoji-fonts || true

# ---------------------------------------------------------------------------
# 3. Things Fedora does not package
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

say "Installing the unpackaged fonts shipped with this repo"
sudo mkdir -p /usr/share/fonts
sudo cp -r "$REPO_ROOT/extras/fonts/Fira_Sans" /usr/share/fonts/
sudo cp -r "$REPO_ROOT/extras/fonts/Material-Icons" /usr/share/fonts/
sudo fc-cache -f

say "Installing the kora icon theme"
# The workspace module resolves app icons through the icon theme; kora is what
# supplies the vim, git and terminal-tool icons the bar shows.
if [ ! -d "$HOME/.local/share/icons/kora" ]; then
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/bikass/kora.git "$tmp/kora"
    mkdir -p "$HOME/.local/share/icons"
    cp -r "$tmp/kora/kora" "$tmp/kora/kora-pgrey" "$HOME/.local/share/icons/"
    rm -rf "$tmp"
    gtk-update-icon-cache -f "$HOME/.local/share/icons/kora" 2>/dev/null || true
else
    echo "  kora already present"
fi

say "Installing the Bibata cursor theme"
if [ ! -d "$HOME/.local/share/icons/Bibata-Modern-Ice" ]; then
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/bibata.tar.xz" \
        https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata.tar.xz
    mkdir -p "$HOME/.local/share/icons"
    tar -xf "$tmp/bibata.tar.xz" -C "$HOME/.local/share/icons"
    rm -rf "$tmp"
else
    echo "  Bibata already present"
fi

say "Installing oh-my-posh"
# .zshrc runs it with the theme in extras/home/Documents/mytheme_v2.toml.
if ! have oh-my-posh; then
    mkdir -p "$HOME/.local/bin"
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
else
    echo "  oh-my-posh already present"
fi

say "Installing matugen"
# Generates the wallpaper colour scheme every theme file is derived from.
if ! have matugen; then
    sudo dnf install -y cargo
    cargo install matugen
    echo "  matugen installed to ~/.cargo/bin (already on PATH via .zshrc)"
else
    echo "  matugen already present"
fi

say "Installing hyprmod (Hyprland settings GUI, optional)"
if ! have hyprmod; then
    sudo dnf install -y pipx
    pipx install hyprmod || echo "  (hyprmod unavailable — the sidebar button will stay hidden)"
fi

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
  * tty-clock                 — aliased in .zshrc but not in the Fedora repos;
                                build it yourself if you want the `clock` alias.
  * solaar                    — referenced by the Hyprland autostart for
                                Logitech devices. `sudo dnf install solaar` if
                                you use one; harmless if absent.
DONE
