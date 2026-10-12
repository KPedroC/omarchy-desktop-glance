# Desktop Glance

Two parts, enabled separately:

- **Desktop widgets** (`Desktop.qml`): glass panels on the desktop, above the wallpaper and below windows
- **Bar widget** (`SpotifyBar.qml`): Spotify icon and track title in the top bar

The desktop widgets are a full-height column on the left (weather, calendar, upcoming, pull requests, GitHub Actions) and Spotify top-right (cover and player islands). Each fades out while a window on the visible workspace overlaps it.

- **Spotify**: large cover art (double-click to show the Spotify window), title, artist, progress, previous / play-pause / next
- **Calendar**: month grid (Monday first, ISO week numbers) with a dot per calendar on days with events, month stepping; click a day to list its events, click the month title to jump back to today
- **Upcoming**: upcoming meetings from your calendars (or the picked day's), grouped by day, with a Join button for Meet/Zoom/Teams links from 10 minutes before start
- **Pull requests**: your open PRs, what needs you first: unread reviews/comments (dot), ready to merge, changes requested; each with checks (✓ / ✗ / running) and who did what last. Bots are ignored. Click to open
- **Actions**: tracked GitHub Actions runs; running ones first with progress against the workflow's typical duration, then results from the last 24 hours. Click a run to open it
- **Weather**: current conditions and a 3-day forecast from wttr.in, using Omarchy's weather location (or IP auto-detect)
- **Spotify bar widget**: icon plus track title while playing
  - Left click: show/hide the Spotify window
  - Middle click: play/pause
  - Scroll: next/previous

Spotify's window lives on the hidden `special:spotify` workspace. Hide it with the bar icon rather than closing it; closing quits the app.

## Requirements

- Omarchy (shell plugins, Hyprland)
- `jq`, `curl`
- Calendars: `python-recurring-ical-events` (`sudo pacman -S python-recurring-ical-events`)
- Pull requests and Actions: the `gh` CLI, logged in (`gh auth login`)
- Spotify parts: the Spotify desktop app

## Install

```bash
omarchy plugin add https://github.com/KPedroC/omarchy-desktop-glance.git
omarchy-shell shell enablePlugin kpedroc.desktop-glance '{}'   # desktop widgets
omarchy plugin enable kpedroc.desktop-glance                   # bar widget
```

Private repo: needs GitHub access and git credentials (e.g. `gh auth setup-git`). Update with `omarchy plugin update kpedroc.desktop-glance`.

## Calendars

List feeds in `~/.config/omarchy/desktop-glance/calendars` (keep it private, never commit it), one per line:

```
work     #4f9d69  https://calendar.google.com/calendar/ical/.../basic.ics
private  #7aa2f7  https://...
```

`calendar/calendar-sync` runs every 5 minutes (Google API calendars at most every 15, reusing the access token for its hour; the ↻ button forces a full sync) and writes this month's grid through two months ahead to `~/.cache/omarchy/desktop-glance/events.json`. It never prints or logs feed URLs.

### Google Calendar API (optional)

For Google calendars that block secret iCal links (e.g. Workspace accounts):

1. Google Cloud Console (signed in with that account): create a project, enable the Google Calendar API
2. OAuth consent screen: user type **Internal** (Workspace), so the login never expires
3. Credentials → Create OAuth client ID → **Desktop app** → download JSON to `~/.config/omarchy/desktop-glance/google-client.json`
4. `calendar/calendar-sync --login` (opens the browser once), then `calendar/calendar-sync --list` for calendar ids
5. Add lines like `work  #4f9d69  google:primary` to `calendars`

The refresh token lives in `~/.local/state/omarchy/desktop-glance/google-token.json`; declined meetings, out-of-office and working-location entries are skipped.

## GitHub

Pull requests need only the `gh` login. To also track Actions runs, list workflows in `~/.config/omarchy/desktop-glance/github`:

```
# <owner/repo>  <notify: mine|all|none>  <workflow name regex>
acme/api  mine  ^CI$
acme/api  all   ^Deploy (Staging|Production)
```

`github/github-sync` polls every minute while a run is in progress (5 minutes otherwise) and sends desktop notifications when a run finishes (`mine` for your own runs, `all` for every run), and when someone reviews, approves, requests changes on or comments on your PR.

## Features

Turn parts of the desktop widgets off on the plugin's entry in `~/.config/omarchy/shell.json` (applies live; missing = on):

```json
{ "id": "kpedroc.desktop-glance", "github": false, "calendar.events": false }
```

| Flag | Turns off |
| --- | --- |
| `spotify` | cover and player (top-right) and the focus view |
| `weather` | weather |
| `calendar` | month grid and upcoming events |
| `calendar.month` | month grid |
| `calendar.events` | upcoming events |
| `github` | pull requests and Actions |
| `github.pulls` | pull requests |
| `github.actions` | Actions |

Turned-off features stop syncing too. The Spotify bar widget is separate: `omarchy plugin disable` / `enable`.

## Optional

Hyprland tweaks that go with the plugin.

### Start Spotify hidden at login (optional)

`~/.config/hypr/autostart.lua`:

```lua
o.exec_on_start(os.getenv("HOME") .. "/.config/omarchy/plugins/kpedroc.desktop-glance/spotify/spotify-toggle --start")
```

### Esc hides Spotify (optional)

While the Spotify window has focus (`~/.config/hypr/bindings.lua`):

```lua
local spotify_escape = nil
hl.on("window.active", function(window)
  local shown = window ~= nil and window.workspace ~= nil and window.workspace.name == "special:spotify"
  if shown and not spotify_escape then
    spotify_escape = hl.bind("ESCAPE", hl.dsp.workspace.toggle_special("spotify"), { description = "Hide Spotify" })
  elseif not shown and spotify_escape then
    spotify_escape:unbind()
    spotify_escape = nil
  end
end)
```

### Glass blur (optional)

Each section is a translucent island. Omarchy ships with blur off; to blur behind the desktop widgets only (`~/.config/hypr/looknfeel.lua`):

```lua
hl.config({ decoration = { blur = { enabled = true, size = 8, passes = 3 } } })
o.window({ class = ".*" }, { no_blur = true })  -- keep windows unblurred
hl.layer_rule({ match = { namespace = "^kpedroc-desktop-glance$" }, blur = true, ignore_alpha = 0.1 })
```

## Reference

### Files

Kept outside the plugin folder, so updating or removing the plugin never touches them:

| What | Where |
| --- | --- |
| Config you edit: `calendars`, `github`, `google-client.json` | `~/.config/omarchy/desktop-glance/` |
| Google login, notification state | `~/.local/state/omarchy/desktop-glance/` |
| Synced events and GitHub data (safe to delete) | `~/.cache/omarchy/desktop-glance/` |

### Layout

- `Desktop.qml`, `SpotifyBar.qml`: entry points
- `spotify/`, `calendar/`, `github/`, `weather/`: one folder per feature, with its QML, JS and helper script
- `common/`: shared pieces (islands, icon buttons, icons, cover detection)

### Config

- `Desktop.qml`: `monitor` (empty = first screen), `margin`, `sidebarWidth`, `rightWidth`; row limits on `PullsSection` (`maxMine`) and `ActionsSection` (`maxRuns`), `glass` (island opacity)
- Bar widget entry in `shell.json`: `maxChars` (title length, default 30)
- Desktop widget changes need `omarchy-restart-shell`; the bar widget reloads on save
