# dotfilesLaptop

My Hyprland rice as GNU Stow packages. It no longer needs ML4W installed.

It started as [ML4W OS](https://github.com/mylinuxforwork/dotfiles) 2.14.1 by
Stephan Raabe, and a lot of it is still his work. Since ML4W is licensed under
the GNU General Public License v3.0, so is this repo (see `LICENSE`). The
changes made to ML4W's files are listed under "Changes from ML4W" below.

## Packages

Each folder is a stow package that mirrors `~`, so `hypr/.config/hypr` becomes
`~/.config/hypr`.

| Package | Becomes | What it is |
| --- | --- | --- |
| `hypr` | `~/.config/hypr` | Hyprland config (Lua), keybindings in `conf/keybindings/gabriel.lua`, hyprlock, hypridle |
| `quickshell` | `~/.config/quickshell` | the bar and its panels, including Settings |
| `ml4w` | `~/.config/ml4w` | ML4W's scripts the rice still uses (wallpaper, cliphist, updates, toggles), settings files, wallpapers |
| `matugen` | `~/.config/matugen` | colours generated from the wallpaper |
| `rofi`, `swaync`, `kitty`, `fastfetch`, `btop`, `qt6ct` | `~/.config/…` | app configs |
| `gtk-2.0`, `gtk-3.0`, `gtk-4.0`, `xsettingsd`, `xresources` | `~/.gtkrc-2.0`, `~/.config/…`, `~/.Xresources` | GTK theme, ArcStarry cursor, kora icons |
| `fonts` | `~/.local/share/fonts/Fira_Sans` | Fira Sans, which the bar, rofi and hyprlock use |
| `cursors` | `~/.local/share/icons/ArcStarry-cursors` | the cursor theme |
| `zsh` | `~/.zshrc` | shell config |
| `ohmyposh` | `~/Documents/mytheme_v2.toml` | prompt theme `.zshrc` loads |
| `systemd` | `~/.config/systemd/user/hyprland-session.target` | started by `autostart.lua` |
| `xdg-desktop-portal` | `~/.config/xdg-desktop-portal/portals.conf` | Hyprland portal first |

Stow `systemd`, `xdg-desktop-portal` and `ohmyposh` with `--no-folding`, so
stow doesn't turn `~/.config/systemd` or `~/Documents` into a link to the
repo.

## Installing on a new machine

1. **Packages.** On Fedora, enable the COPRs listed at the top of
   `packages-fedora.txt`, then:

   ```bash
   sudo dnf install $(grep -v '^#' packages-fedora.txt)
   ```

   On Arch:

   ```bash
   paru -S --needed $(grep -v '^#' packages-arch.txt)
   ```

2. **Things no package manager ships.** Both packages files list them at the
   top: matugen, oh-my-posh, nwg-displays, the kora icons, grimblast on
   Fedora, and the calculator and emoji-picker flatpaks.

3. **Stow everything:**

   ```bash
   cd ~/.dotfilesLaptop
   stow hypr quickshell ml4w matugen rofi swaync kitty fastfetch btop qt6ct \
        gtk-2.0 gtk-3.0 gtk-4.0 xsettingsd xresources fonts cursors zsh
   stow --no-folding systemd xdg-desktop-portal ohmyposh
   fc-cache -f
   ```

4. **Log in.** Pick Hyprland at the login screen.

## Moving this laptop off ML4W

ML4W's links are still in place here: `~/.config/hypr` and the others point
into `~/.mydotfiles/com.ml4w.dotfiles.stable/`. Stow won't write through a
link it doesn't own. To switch an app over, remove ML4W's link and stow:

```bash
unlink ~/.config/hypr && stow hypr
```

`unlink` only ever removes the link, never ML4W's files. Once every package is
stowed and the desktop has run fine for a while, `~/.mydotfiles/` can go.
`~/.zshrc` is a plain file here, so move it aside before `stow zsh`.

## Settings

The separate ML4W settings app is replaced by a panel that drops out of the
bar, like the notification centre. Open it three ways:
- the **Settings** button or the theme icon in the sidebar
- `qs ipc call settings toggle`
- the `settings` alias

It has three tabs:
- **Appearance:** rofi border and font, wallpaper blur, and the animation,
  decoration, window, layout and workspace variants.
- **Default apps:** terminal, browser, email, file manager, network and
  Bluetooth managers, software manager, calculator, screenshot editor and
  system monitor. There's also an AUR helper row, which only appears on
  Arch-based systems (detected from `/etc/os-release`).
- **System:** keybinding, monitor, environment and window-rule variants.

The panel lists whatever `quickshell/.config/quickshell/SettingsApp/settings.json`
says, so adding a setting means adding an entry there. Changing a Hyprland
variant runs `hyprctl reload`.

## Power menu

The power panel follows the
[Hyprland wiki](https://wiki.hypr.land/Hypr-Ecosystem/hyprshutdown/): logout,
reboot and power off go through `hyprshutdown`, which asks every app to close
before Hyprland exits instead of killing them. Lock goes through
`loginctl lock-session`, so hypridle starts hyprlock; when hypridle is stopped
(caffeine mode), it runs hyprlock directly. SUPER+CTRL+L does the same.

This laptop uses SDDM with NVIDIA. If logging out ever leaves a black screen,
the wiki's fix is adding `--vt <n>` to the `hyprshutdown` calls in
`quickshell/.config/quickshell/PowerApp/PowerPanel.qml`, where `n` is the VT
SDDM runs on.

## Notifications

swaync still handles notifications. `NOTIFICATIONS.md` compares the ways to
show the list inside the bar's own panel instead: Quickshell's built-in
notification server, mako, and dunst.

## Changes from ML4W

**Removed:**
- waybar and its themes
- the ML4W dock (nwg-dock-hyprland)
- walker, waypaper and wlogout configs
- the welcome app and ML4W's separate settings app
- the theme switcher (`ml4w/themes`), which only switched waybar, dock and
  walker themes
- ML4W's own install and update scripts
- about 20 scripts nothing calls
- matugen outputs for the removed apps

**Replaced:**
- the settings app, with the Settings panel
- `ml4w-power`, with the `hyprshutdown` calls above
- the launcher script, with rofi only
- the status bar toggle and reload scripts, with Quickshell only

**Edited:**
- **Sidebar:** Welcome button, waybar engine switch, waybar menu items and dock
  switches removed.
- **SUPER+Q:** closes an open Settings panel too.
- **Wallpaper script and GTK theme listener:** no longer restart waybar or the
  dock.
- **Autostart log:** now written to `~/.cache/ml4w-autostart.log` instead of
  `~/.mydotfiles/`.
- **Kept on purpose:** paths under `~/.config/ml4w`, and ML4W's wallpaper
  script (`ml4w-wallpaper`), so nothing that already worked had to change.

**Your own work on top:**
- the Quickshell bar and its panels
- your keybindings and the fluidDrop animation
- the window rules, hypridle, kitty and fastfetch configs

`ML4W_BASELINE` and `./upstream-diff.sh` are still here if you want to see
what ML4W changed upstream and pick fixes by hand. `--mine` will now also list
everything removed.

## Known gaps

- **Polkit agent:** `autostart.lua` starts polkit-gnome from
  `/usr/lib/polkit-gnome/`, which is where Arch installs it. Fedora doesn't
  package polkit-gnome, so this laptop has been running without a polkit agent;
  `mate-polkit` is Fedora's closest equivalent. This comes from ML4W and is
  unchanged here.
- **grimblast:** not in Fedora's repos or the COPRs above. `screenshot.sh` uses
  it for some modes.
- **Arch list:** `packages-arch.txt` comes from ML4W's Arch lists and couldn't be
  checked from this machine.

## Licences

- **Everything derived from ML4W:** GPL-3.0 (`LICENSE`).
- **Fira Sans:** SIL Open Font License (`fonts/.local/share/fonts/Fira_Sans/OFL.txt`).
- **ArcStarry cursors:** they came with ML4W's setup files; check the cursor
  project's own licence before publishing this repo.
- **`quickshell/overview`:** a separate project, with its own README.
