# desk

Desktop widgets for Omarchy, above the wallpaper and below windows: a full-height column on the left (calendar, GitHub Actions, upcoming, weather) and Spotify top-right (a cover-art island above a player island). Each fades out while a window on the visible workspace overlaps it.

- **Spotify**: large cover art (double-click to show the Spotify window), title, artist, progress, previous / play-pause / next
- **Calendar**: month grid (Monday first, ISO week numbers) with a dot per calendar on days with events, month stepping; click a day to list its events, click the month title to jump back to today
- **Upcoming**: upcoming meetings from your calendars (or the picked day's), grouped by day, with a Join button for Meet/Zoom/Teams links from 10 minutes before start
- **Actions**: tracked GitHub Actions runs; running ones first with progress against the workflow's typical duration, then results from the last 24 hours. Click a run to open it
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

## Calendars

List feeds in `~/.config/omarchy/desk-calendars` (keep it private, never commit it), one per line:

```
work     #4f9d69  https://calendar.google.com/calendar/ical/.../basic.ics
private  #7aa2f7  https://...
```

Google calendars that block secret iCal links (e.g. Workspace accounts) can use the Calendar API instead:

1. Google Cloud Console (signed in with that account): create a project, enable the Google Calendar API
2. OAuth consent screen: user type **Internal** (Workspace), so the login never expires
3. Credentials → Create OAuth client ID → **Desktop app** → download JSON to `~/.config/omarchy/desk-google-client.json`
4. `bin/calendar-sync --login` (opens the browser once), then `bin/calendar-sync --list` for calendar ids
5. Add lines like `work  #4f9d69  google:primary` to `desk-calendars`

The refresh token lives in `~/.local/state/omarchy-desk/google-token.json`; declined meetings are skipped.

`bin/calendar-sync` runs every 5 minutes (Google API calendars at most every 15, reusing the access token for its hour; the ↻ button forces a full sync) and writes this month's grid through two months ahead to `~/.cache/omarchy-desk/events.json`. It never prints or logs feed URLs.
Requires `python-recurring-ical-events` (`sudo pacman -S python-recurring-ical-events`).

## GitHub Actions

Uses the `gh` CLI's login. List workflows to track in `~/.config/omarchy/desk-github`:

```
# <owner/repo>  <notify: mine|all|none>  <workflow name regex>
acme/api  mine  ^CI$
acme/api  all   ^Deploy (Staging|Production)
```

`bin/github-sync` polls every minute while a run is in progress (5 minutes otherwise) and sends a desktop notification when a run finishes: `mine` for your own runs, `all` for every run.

## Glass

Each section is a translucent island; Hyprland blurs what's behind them. Omarchy ships with blur off, so enable it for the sidebar only (`~/.config/hypr/looknfeel.lua`):

```lua
hl.config({ decoration = { blur = { enabled = true, size = 8, passes = 3 } } })
o.window({ class = ".*" }, { no_blur = true })  -- keep windows unblurred
hl.layer_rule({ match = { namespace = "^kpedroc-desk$" }, blur = true, ignore_alpha = 0.1 })
```

## Config

- `Service.qml`: `monitor` (empty = first screen), `margin`, `sidebarWidth`, `playerWidth`, `glass` (island opacity)
- Bar widget entry in `shell.json`: `maxChars` (title length, default 30)
- Sidebar changes need `omarchy-restart-shell`; the bar widget reloads on save
