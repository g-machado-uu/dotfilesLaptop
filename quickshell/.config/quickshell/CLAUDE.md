# Desktop time & weather widget — working notes

Untracked scratch notes for picking this up again. Everything below was built and
verified on 2026-09-11/12. The widget itself is **uncommitted** on top of the
last push.

## What it is

A time/weather widget that lives on an **empty workspace only**. Open a window
or switch to a workspace that has one, and it is sucked up into the status bar,
which takes the clock back over at the same moment. Step onto an empty
workspace and it pours back out.

Three sections, no dividing lines, no background:
1. Time (92px), day + date below.
2. Current weather: icon + temperature centred, detail block to the right
   (min/max, humidity, feels like, wind, QNH).
3. Three-day forecast.

## Files

| File | Role |
|---|---|
| `DesktopWidget/DesktopWidgetWindow.qml` | The widget: layout, show/hide logic, animation, contrast |
| `DesktopWidget/WeatherSource.qml` | Open-Meteo fetch + METAR formatting |
| `shell.qml` | Mounts the widget **before** the bar (stacking order matters, see below) |
| `StatusbarApp/ClockModule.qml` | Gained `hidden` / `fold` so the bar clock folds away |
| `StatusbarApp/StatusbarWindow.qml` | `hideClock` property; centre modules carry half-gap margins |
| `shared/WeatherIcon.qml` | Moon is now a masked crescent (was a bite painted in the bg colour) |

## Decisions worth not re-litigating

- **Contrast is measured, not themed.** matugen derives the palette from the
  wallpaper, but light/dark is a user choice, so a white wallpaper can arrive
  with a dark palette whose "on background" is near-white. The widget samples
  the brightness of the wallpaper region behind it (`magick`, top-centre crop)
  and picks white or near-black ink. Re-samples on wallpaper change via a
  `FileView` watch on `~/.cache/ml4w/hyprland-dotfiles/current_wallpaper`.
  Weather glyphs are monochrome for the same reason.
- **The surface is never unmapped.** Hyprland slide-animates layer surfaces on
  map (`layersIn`), which fought the widget's own animation; and the widget is
  declared before the bar in `shell.qml` so the **bar stacks above it** and
  sections vanish *underneath* the bar. Transparent + `mask: Region {}`
  (click-through) when hidden.
- **Centre-module margins.** The bar's centre `RowLayout` uses `spacing: 0` plus
  7px margins per module, because layout spacing would survive the clock's fold
  and leave a hole. Negative `Layout` margins do **not** work — tested, RowLayout
  clamps them to 0.
- **Animation** = each section scales about the bar's clock position, so it
  shrinks and travels up at once; x collapses faster than y for the funnel look.
  Staggered nearest-the-bar-first.

## Performance (the stutter fix)

Measured: the shell burned **~18% of a core continuously** while the widget was
on screen, so transitions had no headroom. Tested and **ruled out**: the blurred
shadow layers, and the full-width surface — neither mattered. The whole cost was
the **weather glyphs' continuous motion** (drifting clouds etc.): any endless
animation keeps the scene graph redrawing at refresh rate.

Now: glyphs animate ~12s on arrival then park, and are frozen while any section
is in flight. **18.4% → 0.3%** once settled (1.4% with the widget hidden).

Tunables at the top of `DesktopWidgetWindow.qml`:
- `motionWindow.interval` (12000) — longer moment of movement.
- `glyphMotion: w.shown` — always-on motion, at the old cost.
- The clock section keeps a blurred `MultiEffect` halo (static content = cached,
  free). The other two use `InkText` (Qt's built-in text outline, no layer).

## Weather

Open-Meteo, no key. Location comes from the bar's `weather.location` setting
(default `Belfast, UK`); set it in `~/.config/ml4w/settings/statusbar.json`.
Refresh 15 min, retry every 20s until the first success (network is usually not
up at login).

Wind is **METAR format**: `18007KT` — direction rounded to nearest 10° as the
bearing the wind blows *from*, speed in knots (`wind_speed_unit=kn`). Calm =
`00000KT`, north = `360`, gust appended as `G` only when ≥10kt above the mean.
The arrow points like an aviation wind barb: **at the direction the wind comes
from** (a 177° southerly points down the screen). `QNH` is `pressure_msl` in hPa.

## Testing recipes

- **Hyprland here uses Lua dispatchers.** `hyprctl dispatch workspace 4` fails
  silently-ish. Use:
  `hyprctl dispatch "hl.dsp.focus({workspace = '4'})"`
- Quickshell **hot-reloads on save**. Check it loaded:
  `qs log | sed 's/\x1b\[[0-9;]*m//g' | tail -5` (look for `Configuration Loaded`)
- CPU measurement that is actually reliable (`top`'s first sample lies):
  read `/proc/$(pgrep -x qs)/stat` fields 14+15 before/after a fixed sleep.
- **Assert the workspace at every sample** when measuring — a capture taken
  after drifting back to a non-empty workspace looks like "motion parked" when
  really the widget was just hidden. Bit me once.
- Motion detection: two `grim` frames 400ms apart + `magick compare -metric AE`.

## Open / next time

- Gabriel has "a couple of things" to improve — not yet specified.
- Possible: wind gust display wording, whether the arrow should instead point
  the way the air travels, forecast day count, motion window length.
