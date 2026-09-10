#!/usr/bin/env bash
# Stow packages from this repo over an ML4W install.
#
# Plain `stow hypr` works once ML4W's link at ~/.config/hypr is out of the
# way. This script moves such links (and any other file in the way) into a
# backup folder, then runs stow for you.
#
#   ./install.sh                  every package
#   ./install.sh hypr kitty       only these
#   ./install.sh --dry-run hypr   show what would happen
#   ./install.sh --delete hypr    unstow (ML4W's old link stays in the backup)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW="${STOW:-stow}"
BACKUP="$HOME/.dotfilesLaptop-backup/$(date +%Y%m%d-%H%M%S)"

# Never fold these: stow would turn ~/.config/systemd or ~/Documents into a
# link to the repo, and everything written there later would land in the repo.
NO_FOLDING=(systemd xdg-desktop-portal ohmyposh)

flags_for() {
    local n
    for n in "${NO_FOLDING[@]}"; do
        if [[ $1 == "$n" ]]; then echo --no-folding; fi
    done
}

owned() { [[ "$(realpath -m -- "$1")" == "$REPO"/* ]]; }

move_aside() { # <path relative to $HOME>
    if [[ $mode == dry ]]; then
        echo "  would move ~/$1 to the backup"
    else
        mkdir -p "$BACKUP/$(dirname "$1")"
        mv -- "$HOME/$1" "$BACKUP/$1"
        echo "  moved ~/$1 to $BACKUP"
    fi
    moved=1
}

# Walk the package top-down. A link or file in the way (ML4W's link to its own
# folder, or its ~/.zshrc) is moved aside; a real directory is descended into.
clear_way() { # <package>
    local rel t skip=
    while IFS= read -r rel; do
        if [[ -n $skip && $rel == "$skip"/* ]]; then continue; fi
        t=$HOME/$rel
        if [[ -L $t ]]; then
            skip=$rel
            if ! owned "$t"; then move_aside "$rel"; fi
        elif [[ -d $t && -d $REPO/$1/$rel ]]; then
            continue
        elif [[ -e $t ]]; then
            skip=$rel
            move_aside "$rel"
        fi
    done < <(cd "$REPO/$1" && find . -mindepth 1 -printf '%P\n')
}

mode=link
packages=()
for arg in "$@"; do
    case $arg in
        -n|--dry-run) mode=dry ;;
        -D|--delete)  mode=delete ;;
        -h|--help)    sed -n '2,11p' "$0"; exit 0 ;;
        -*)           echo "Unknown option: $arg" >&2; exit 1 ;;
        *)            packages+=("${arg%/}") ;;
    esac
done
if (( ${#packages[@]} == 0 )); then
    for d in "$REPO"/*/; do d=${d%/}; packages+=("${d##*/}"); done
fi

if ! command -v "$STOW" >/dev/null; then
    echo "GNU Stow is not installed (sudo dnf install stow)." >&2
    exit 1
fi

for pkg in "${packages[@]}"; do
    if [[ ! -d $REPO/$pkg ]]; then echo "No package called $pkg" >&2; exit 1; fi
    echo "$pkg"
    case $mode in
        delete)
            "$STOW" -D -d "$REPO" -t "$HOME" "$pkg" ;;
        dry)
            moved=0
            clear_way "$pkg"
            # With something still in the way, stow would only report a conflict.
            if (( ! moved )); then
                "$STOW" -n -v -R $(flags_for "$pkg") -d "$REPO" -t "$HOME" "$pkg"
            fi ;;
        link)
            moved=0
            clear_way "$pkg"
            "$STOW" -R $(flags_for "$pkg") -d "$REPO" -t "$HOME" "$pkg" ;;
    esac
done

case $mode in
    link)
        echo
        if [[ -d $BACKUP ]]; then echo "Whatever was in the way is in $BACKUP"; fi
        echo "Reload Hyprland (SUPER+SHIFT+R) or log out, and open a new terminal." ;;
    delete)
        echo
        echo "Unstowed. To hand a folder back to ML4W, move its old link back from"
        echo "~/.dotfilesLaptop-backup/, e.g.  mv ~/.dotfilesLaptop-backup/<date>/.config/hypr ~/.config/" ;;
esac
