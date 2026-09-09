# myDotfilesLaptop

Everything needed to rebuild this Hyprland desktop on a fresh Fedora or Arch
install. Taken from a working ML4W-based system.

This is my own modified version of ML4W OS by Raabe [found on github](https://github.com/mylinuxforwork/dotfiles).
All credits to him, I just modified to suit my liking.

## Layout

Everything at the top level is a `~/.config` entry, so the root of this repo
maps one-to-one onto `~/.config`. That makes both `cp -r * ~/.config/` and GNU
stow work without rearranging anything.

```
.                       -> ~/.config/
├── btop/ fastfetch/ hypr/ kitty/ quickshell/ rofi/ swaync/ waybar/ ...
├── ml4w/               ML4W scripts, settings, themes and wallpapers
├── nvim/ yazi/ lazygit/ git/ flameshot/ nwg-look/ systemd/
├── gtk-3.0/ gtk-4.0/ qt6ct/ xsettingsd/   toolkit theming
│
├── extras/             everything that does NOT live in ~/.config
│   ├── home/           mirrors $HOME
│   │   ├── .zshrc                          my own, not ML4W's
│   │   ├── .gtkrc-2.0  .Xresources
│   │   ├── Documents/mytheme_v2.toml       oh-my-posh prompt theme
│   │   └── .local/
│   │       ├── bin/                        ML4W and nwg launchers
│   │       └── share/ml4w-dotfiles-settings/
│   └── fonts/          Fira Sans and Material Icons (not packaged anywhere)
│
└── install/
    ├── fedora.sh       dependencies, RPM Fusion and the COPRs
    ├── arch.sh         dependencies, AUR through paru
    └── link.sh         puts the configuration in place
```

Deliberately **not** included: ML4W's `bashrc`, `fish` and `zshrc` (I use my
own zsh config), browser profiles, and application state.

## Restoring

```bash
git clone <this repo> ~/Projects/myDotfilesLaptop
cd ~/Projects/myDotfilesLaptop

./install/fedora.sh          # or ./install/arch.sh

./install/link.sh            # copy into place
# or
./install/link.sh --stow     # symlink with GNU stow
./install/link.sh --dry-run  # see what it would do first
```

`link.sh` moves anything it would overwrite into
`~/.dotfiles-backup-<timestamp>`, so a bad restore is always reversible.

Then log out and choose **Hyprland** at the login screen.

## Check these after restoring

These are the files that carry something specific to _this_ laptop. None of
them will stop the desktop from starting, but they are worth a look before you
wonder why something is off:

| File                             | Why                                                                                                                                                                |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `hypr/monitors.lua`              | Display layout. Currently generic (`output = ""`, preferred mode), so it adapts on its own — but `nwg-displays` overwrites this file, so it may not stay that way. |
| `hypr/conf/autostart.lua`        | Launches `awww-daemon`, `solaar`, `polkit-gnome`. Missing programs fail silently.                                                                                  |
| `ml4w/settings/wallpaper-folder` | Absolute path to the wallpaper directory.                                                                                                                          |
| `ml4w/settings/*.sh`             | Which terminal, browser, file manager and editor to use.                                                                                                           |
| `ml4w/settings/statusbar.json`   | Which Quickshell bar modules are shown, and in what order.                                                                                                         |
| `extras/home/.zshrc`             | Hard-codes `/home/gabriel/...` in a few places (MATLAB, TeX Live, the `yc` alias).                                                                                 |

## The status bar

`quickshell/` holds a customised ML4W bar. Beyond the stock ML4W setup it has:

- app icons on inactive workspaces, resolved through the icon theme, with the
  running program in a terminal identified from the process tree;
- panels that drop out of the bar as a fluid, drawn with the bar's own
  silhouette (`shared/BarShape.qml`, `shared/BarPanel.qml`,
  `shared/FluidReveal.qml`);
- a notification panel with quick toggles, Wi-Fi and Bluetooth pickers,
  volume / microphone / brightness sliders, and weather from Open-Meteo;
- media controls, and calendar, clipboard, power, sidebar and wallpaper panels.

It needs **Quickshell 0.3.x or newer** (`Hyprland.toplevels`, `rawEvent`,
`IconImage`, `DesktopEntries.heuristicLookup`) and **Qt 6.6+** for
`Shape.CurveRenderer`. Both install scripts pull in a new enough version.

The weather location lives in `ml4w/settings/statusbar.json`:

```json
"weather": { "location": "Belfast, UK" }
```

Anything after the comma is a hint used to pick between same-named places.

## Fonts

`extras/fonts/` carries **Fira Sans** and **Material Icons** because neither is
packaged the way this setup expects, and every Quickshell panel names
`Fira Sans Semibold` explicitly. The install scripts copy them to
`/usr/share/fonts` and refresh the font cache. Nerd Fonts (0xProto for the
terminal, FiraCode) come from the package manager.

## Icon and cursor themes

`gtk-3.0/settings.ini` names the **kora** icon theme and an **ArcStarry**
cursor; Hyprland sets **Bibata-Modern-Ice** at startup. The install scripts
fetch kora and Bibata into `~/.local/share/icons` rather than shipping ~120 MB
of PNGs here. kora is what supplies the app icons the workspace module shows,
so it is not optional.

## Not handled automatically

- **zinit** and the zsh plugins — `.zshrc` clones them on first shell start.
- **Neovim plugins** — fetched by the plugin manager on first run.
- **TeX Live, MATLAB, Dropbox** — referenced in `.zshrc` and `autostart/`;
  install them yourself if you want them.
