# dotfilesLaptop

My Hyprland rice, built on [ML4W OS](https://github.com/mylinuxforwork/dotfiles)
by Stephan Raabe. All credit for the base goes to him. ML4W installs the
dependencies.

**Baseline: ML4W 2.14.1**, the stable release that was current when I installed
on 2026-07-22. The version is kept in `ML4W_BASELINE`.

## Layout

This is a traditional stow layout: each package mirrors `~`, so
`hypr/.config/hypr` becomes `~/.config/hypr`.

| Package                            | Becomes                                          | What I changed compared with ML4W                                                                                                                                                                                                                                                 |
| ---------------------------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `hypr`                             | `~/.config/hypr`                                 | own keybindings (`conf/keybindings/gabriel.lua`), autostart, window rules (Matlab, Flameshot, swaync, settings app), `fluidDrop` animation curve, gb/br keyboard, hypridle without screen-off, nvidia environment, HyprMod monitors/borders/gaps (`hyprland-gui.lua`, `hyprmod/`) |
| `quickshell`                       | `~/.config/quickshell`                           | the whole bar and its panels: notifications with Wi-Fi/Bluetooth, media, calendar, clipboard, power, wallpaper, sidebar, system monitor                                                                                                                                           |
| `kitty`                            | `~/.config/kitty`                                | 0xProto font, full-size window, remote control on, no cursor trail                                                                                                                                                                                                                |
| `fastfetch`                        | `~/.config/fastfetch`                            | Ulster University x Fedora config and logo                                                                                                                                                                                                                                        |
| `btop`                             | `~/.config/btop`                                 | process sorting, disks shown                                                                                                                                                                                                                                                      |
| `ml4w`                             | `~/.config/ml4w`                                 | `settings/`: Quickshell bar and its module layout, Vivaldi, dock and waybar off, no wallpaper transition; three extra wallpapers. 43 MB, mostly ML4W's wallpapers                                                                                                                 |
| `gtk-3.0`, `gtk-4.0`, `xsettingsd` | `~/.config/…`                                    | ArcStarry cursor, kora icons                                                                                                                                                                                                                                                      |
| `zsh`                              | `~/.zshrc`                                       | my own zshrc, not ML4W's loader                                                                                                                                                                                                                                                   |
| `ohmyposh`                         | `~/Documents/mytheme_v2.toml`                    | the prompt `.zshrc` loads                                                                                                                                                                                                                                                         |
| `systemd`                          | `~/.config/systemd/user/hyprland-session.target` | needed by `autostart.lua`                                                                                                                                                                                                                                                         |
| `xdg-desktop-portal`               | `~/.config/xdg-desktop-portal/portals.conf`      | hyprland portal first, gtk second                                                                                                                                                                                                                                                 |

Each `~/.config/<app>` package holds the **whole** folder (ML4W's files plus my
edits), not just the files I changed. ML4W makes `~/.config/hypr` a link to its
own copy in `~/.mydotfiles/com.ml4w.dotfiles.stable/`, and stow can't put files
inside a link it doesn't own. So the package replaces ML4W's link outright.

`./upstream-diff.sh --mine` lists every file I changed compared with the
baseline.

## Installing on a new machine

1. Install ML4W (stable) the normal way and log into Hyprland once.
2. `sudo dnf install stow`
3. Clone this repo to `~/.dotfilesLaptop`.
4. Stow what you want. Plain stow works once ML4W's link is out of the way:

```bash
cd ~/.dotfilesLaptop
unlink ~/.config/hypr     # removes only ML4W's link, never its files
stow hypr
```

Or let the helper move whatever is in the way into
`~/.dotfilesLaptop-backup/<date>/` and stow for you:

```bash
./install.sh --dry-run hypr   # see what would happen
./install.sh hypr kitty       # some packages
./install.sh                  # everything
```

1. Reload Hyprland (SUPER+SHIFT+R) or log out and back in, and open a new
   terminal.

Plain-stow notes:

- **Never** `rm -r ~/.config/hypr/` with a trailing slash. That deletes ML4W's
  files through the link. `unlink` refuses to touch anything but a link.
- `zsh`: ML4W links `~/.zshrc` to its own loader, so `unlink ~/.zshrc` first.
- Stow `systemd`, `xdg-desktop-portal` and `ohmyposh` with `--no-folding`.
  Otherwise, on a machine where `~/.config/systemd` doesn't exist yet, stow
  links the whole folder to the repo, and every unit you enable later lands in
  git. `install.sh` does this for you.

## Living with it

- Stowed folders are links into the repo, so anything that writes there
  (HyprMod, the ML4W settings app, you) changes the repo directly.
- matugen rewrites the colour files on every wallpaper change:
  `hypr/colors.*`, `kitty/colors-matugen.conf`, `btop/themes/matugen.theme`,
  `ml4w/colors/`, `gtk-*/colors.css`,
  `quickshell/overview/common/Appearance.colors.qml`. They're kept in the repo
  so a fresh machine starts with valid colours. After your first commit, hide
  the churn with `git update-index --skip-worktree <file>`.
- ML4W updates don't reach a stowed package any more. ML4W keeps updating its
  copy in `~/.mydotfiles/`, but nothing links to it. `./upstream-diff.sh` shows
  what you'd be missing.
- `./install.sh --delete hypr` unstows. To hand the folder back to ML4W, move
  its old link back from the backup folder.

## Upstream changes since the baseline

`./upstream-diff.sh` clones ML4W into `~/.cache/dotfilesLaptop/` and diffs
`ML4W_BASELINE` against the current stable tag, limited to the folders this
repo takes over. Pass a tag to compare against something else, `-p` for full
diffs.

As of 2.15.1, these are the upstream changes to files I had also changed:

| File                                                            | What upstream changed                                                                                             | 3-way merge onto 2.15.1                                                                                           |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `hypr/conf/environment.lua`                                     | Sets `QS_ICON_THEME` from the GTK icon theme, so Quickshell uses the same icons                                   | 1 conflict (small)                                                                                                |
| `hypr/conf/ml4w.lua`                                            | pavucontrol and waypaper rules changed from `*name*` to regex `.*name.*`                                          | 2 conflicts, mostly whitespace (mine uses tabs)                                                                   |
| `hypr/conf/keybindings/gabriel.lua` (forked from `default.lua`) | Calculator on SUPER+C; new status bar and dock toggles; scratchpad workspace renamed from `magic` to `scratchpad` | 2 conflicts                                                                                                       |
| `quickshell/`                                                   | New dock (`DockApp`, loaded from `shell.qml`), status bar autohide, restyled power-profile menu, sidebar changes  | `shell.qml` merges cleanly; `StatusbarWindow.qml` has 3 conflicts, `PowerProfileModule.qml` 2, `statusbar.json` 1 |
| `ml4w/settings/statusbar*`                                      | Upstream now defaults to the Quickshell bar too                                                                   | mine still sets the module layout                                                                                 |
| `fastfetch/config.jsonc`                                        | Minor edits                                                                                                       | mine replaces it entirely                                                                                         |

Upstream also changed files I never touched in those folders. Examples are the
order of the monitor includes in `hyprland.lua`, `WelcomeWindow.qml`, and
several ML4W scripts; `./upstream-diff.sh` lists them. The repo as it stands
is exactly what runs on this laptop today. One thing won't work: the 2.15.1
dock toggles (SUPER+CTRL+D, `ml4w-toggle-dock`), because my Quickshell has no
`DockApp`. I have the dock disabled anyway.

## Deliberately left out

- swaync and rofi: unchanged from ML4W. waybar: disabled in favour of
  Quickshell. ML4W's copies keep working.
- `*.bak`, `fastfetch/config.jsonc.bkp` (the stock config) and
  `quickshell/StatusbarApp.backup-*`.
- Not part of the rice: `~/.config/autostart` (Dropbox, MATLAB), voxtype,
  nvim, yazi.

## Things ML4W may not install

The configs use these; check they're present:

- **0xProto Nerd Font**: kitty.
- **kora** icon theme and **ArcStarry** cursors: gtk and xsettingsd. The
  Quickshell workspace module resolves app icons through kora.
- **solaar**, **flameshot**: autostart and window rules.
- **eza**, **zoxide**, **fzf**, **yazi**, **neovim**, **oh-my-posh**: `.zshrc`.
  zinit and its plugins clone themselves on the first shell start.
- `.zshrc` hard-codes `/home/gabriel/…` paths for TeX Live and MATLAB, and runs
  `fastfetch` on start.
- `hyprland-gui.lua` holds this laptop's monitor layout (eDP-1 plus DP-5 on the
  left), and `environment.lua` selects the nvidia variant.
