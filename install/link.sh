#!/usr/bin/env bash
#
# Puts the configuration in this repository into place.
#
#   install/link.sh            copy into ~/.config and ~ (default)
#   install/link.sh --stow     symlink with GNU stow instead
#   install/link.sh --dry-run  show what would happen and change nothing
#
# Anything it would overwrite is moved to ~/.dotfiles-backup-<timestamp> first,
# so a botched restore is always reversible.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
MODE="copy"
DRY=0

for arg in "$@"; do
    case "$arg" in
        --stow)    MODE="stow" ;;
        --dry-run) DRY=1 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

say() { printf '\n\033[1;35m==>\033[0m %s\n' "$*"; }
run() { if [ "$DRY" -eq 1 ]; then echo "  would: $*"; else "$@"; fi; }

# Everything at the repo root is a ~/.config entry, except these.
is_meta() {
    case "$1" in
        install|extras|README.md|.git|.gitignore) return 0 ;;
        *) return 1 ;;
    esac
}

back_up() {
    local target="$1" rel="$2"
    [ -e "$target" ] || [ -L "$target" ] || return 0
    run mkdir -p "$BACKUP/$(dirname "$rel")"
    run mv "$target" "$BACKUP/$rel"
}

# ---------------------------------------------------------------------------
# ~/.config
# ---------------------------------------------------------------------------
say "Installing into ~/.config  (mode: $MODE)"
run mkdir -p "$HOME/.config"

if [ "$MODE" = "stow" ]; then
    command -v stow >/dev/null || { echo "stow is not installed." >&2; exit 1; }
    for entry in "$REPO_ROOT"/*; do
        name="$(basename "$entry")"
        is_meta "$name" && continue
        [ -d "$entry" ] || continue   # stow only handles directories
        back_up "$HOME/.config/$name" ".config/$name"
        run stow --dir="$REPO_ROOT" --target="$HOME/.config" "$name"
        echo "  stowed $name"
    done
    echo "  Loose files are copied even in stow mode:"
    for entry in "$REPO_ROOT"/*; do
        name="$(basename "$entry")"
        is_meta "$name" && continue
        [ -f "$entry" ] || continue
        back_up "$HOME/.config/$name" ".config/$name"
        run cp "$entry" "$HOME/.config/$name"
        echo "    $name"
    done
else
    for entry in "$REPO_ROOT"/*; do
        name="$(basename "$entry")"
        is_meta "$name" && continue
        back_up "$HOME/.config/$name" ".config/$name"
        run cp -r "$entry" "$HOME/.config/$name"
        echo "  $name"
    done
fi

# ---------------------------------------------------------------------------
# $HOME  (everything outside ~/.config)
# ---------------------------------------------------------------------------
say "Installing into \$HOME"
# extras/home mirrors $HOME, so walk it and place each file at the same path.
if [ -d "$REPO_ROOT/extras/home" ]; then
    while IFS= read -r -d '' src; do
        rel="${src#$REPO_ROOT/extras/home/}"
        dest="$HOME/$rel"
        back_up "$dest" "$rel"
        run mkdir -p "$(dirname "$dest")"
        run cp "$src" "$dest"
        echo "  ~/$rel"
    done < <(find "$REPO_ROOT/extras/home" -type f -print0)
fi

# The ML4W launchers and nwg wrappers have to stay executable.
if [ -d "$HOME/.local/bin" ] && [ "$DRY" -eq 0 ]; then
    chmod +x "$HOME/.local/bin"/* 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
if [ "$DRY" -eq 1 ]; then
    say "Dry run only — nothing was changed."
    exit 0
fi

if [ -d "$BACKUP" ]; then
    say "Replaced files were moved to $BACKUP"
fi

cat <<'DONE'

==> Configuration in place.

Before logging in to Hyprland, check the machine-specific bits:

  hypr/monitors.lua                 display layout (nwg-displays rewrites it)
  hypr/conf/autostart.lua           autostarted programs
  ml4w/settings/wallpaper-folder    absolute path to your wallpapers
  ml4w/settings/*.sh                terminal, browser, file manager choices

Then log out and pick "Hyprland" at the login screen.
DONE
