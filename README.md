# desk

Desktop sidebar for Omarchy: full height on the left, above the wallpaper, below windows.

- **Spotify**: large cover art, title, artist, progress, previous / play-pause / next
- **Calendar**: today's date, month grid (Monday first, ISO week numbers), month stepping; click the month title to jump back to today
- **Weather**: current conditions and a 3-day forecast from wttr.in, using Omarchy's weather location (or IP auto-detect)
- **Spotify bar widget**: icon plus track title while playing
  - Left click: show/hide the Spotify window
  - Middle click: play/pause
  - Scroll: next/previous

Spotify's window lives on the hidden `special:spotify` workspace. Hide it with the bar icon rather than closing it; closing quits the app.

## Install

```bash
ln -s "$PWD" ~/.config/omarchy/plugins/kpedroc.desk
omarchy-shell shell rescanPlugins
omarchy-shell shell enablePlugin kpedroc.desk '{}'   # sidebar
omarchy plugin enable kpedroc.desk                   # bar widget
```

Start Spotify hidden at login (`~/.config/hypr/autostart.lua`):

```lua
o.exec_on_start(os.getenv("HOME") .. "/.config/omarchy/plugins/kpedroc.desk/bin/spotify-toggle --start")
```

## Config

- `Service.qml`: `monitor` (empty = first screen), `margin`, `sidebarWidth`
- Bar widget entry in `shell.json`: `maxChars` (title length, default 30)
- Sidebar changes need `omarchy-restart-shell`; the bar widget reloads on save
