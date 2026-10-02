import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.Commons
import "Spotify.js" as Spotify

// Desktop widgets on the main screen: a full-height column on the left
// (calendar, pull requests, GitHub Actions, events, weather) and Spotify
// top-right. Both sit on
// the Bottom layer (above the wallpaper, below windows) and fade out while a
// window on the visible workspace overlaps them.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // Hyprland monitor name; empty picks the first screen.
  readonly property string monitor: ""
  // Hyprland's gaps_out, so the sidebar lines up with tiled windows.
  readonly property int margin: Style.gapsOut * 2
  readonly property int sidebarWidth: 380
  readonly property int rightWidth: 340
  // Island background opacity (0 = clear glass, 1 = solid).
  readonly property real glass: 0.35

  // Date picked in the calendar; null shows upcoming events.
  property var selectedDate: null

  readonly property var player: Spotify.findPlayer(Mpris.players ? Mpris.players.values : [])
  readonly property var targetScreen: {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++)
      if (screens[i].name === monitor) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }

  // Coalesces bursts of Hyprland events into one check.
  Timer {
    id: recheck
    interval: 80
    onTriggered: { leftCover.check(); rightCover.check() }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event && event.name ? String(event.name) : ""
      if (/^(openwindow|closewindow|movewindow|workspace|focusedmon|changefloatingmode|fullscreen|activespecial|moveworkspace|resizewindow|movewindowv2|workspacev2|activespecialv2)/.test(name))
        recheck.restart()
    }
  }

  Component.onCompleted: recheck.restart()

  EventsModel { id: events }
  GithubModel { id: github }

  CoverWatcher {
    id: leftCover
    screen: root.targetScreen
    rectX: root.margin
    rectWidth: root.sidebarWidth
    rectHeight: root.targetScreen ? root.targetScreen.height : 0
  }

  // Top-right corner down to the Spotify islands' bottom edge (bar + gap + islands).
  CoverWatcher {
    id: rightCover
    screen: root.targetScreen
    rectX: root.targetScreen ? root.targetScreen.width - root.margin - root.rightWidth : 0
    rectWidth: root.rightWidth
    rectHeight: 40 + root.margin + rightColumn.implicitHeight
  }

  // Left: calendar, pull requests, GitHub Actions, events, weather.
  PanelWindow {
    screen: root.targetScreen
    visible: root.targetScreen !== null && (!leftCover.covered || leftColumn.opacity > 0)
    color: "transparent"
    anchors { top: true; bottom: true; left: true }
    margins { top: root.margin; bottom: root.margin; left: root.margin }
    implicitWidth: root.sidebarWidth

    WlrLayershell.namespace: "kpedroc-desk"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    ColumnLayout {
      id: leftColumn
      anchors.fill: parent
      spacing: root.margin
      opacity: leftCover.covered ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Island {
        glass: root.glass
        Layout.fillWidth: true
        CalendarSection {
          width: parent.width
          model: events
          selectedDate: root.selectedDate
          onDateClicked: function(date) {
            root.selectedDate = root.selectedDate && events.sameDay(root.selectedDate, date) ? null : date
          }
        }
      }

      Island {
        glass: root.glass
        Layout.fillWidth: true
        PullsSection { width: parent.width; model: github; maxMine: 3 }
      }

      Island {
        glass: root.glass
        Layout.fillWidth: true
        ActionsSection { width: parent.width; model: github; maxRuns: 2 }
      }

      Island {
        glass: root.glass
        Layout.fillWidth: true
        Layout.fillHeight: true
        EventsSection {
          width: parent.width
          height: parent.height
          model: events
          selectedDate: root.selectedDate
          onCleared: root.selectedDate = null
        }
      }

      Island {
        glass: root.glass
        Layout.fillWidth: true
        WeatherSection { width: parent.width }
      }
    }
  }

  // Right: Spotify, top corner.
  PanelWindow {
    id: rightWindow
    screen: root.targetScreen
    visible: root.targetScreen !== null && (!rightCover.covered || rightColumn.opacity > 0)
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: root.margin; right: root.margin }
    implicitWidth: root.rightWidth
    implicitHeight: rightColumn.implicitHeight

    WlrLayershell.namespace: "kpedroc-desk"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    ColumnLayout {
      id: rightColumn
      anchors.fill: parent
      spacing: root.margin
      opacity: rightCover.covered ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

      Island {
        id: artIsland
        glass: root.glass
        padding: 0
        Layout.fillWidth: true
        PlayerArt { width: parent.width; radius: artIsland.radius; player: root.player }
      }

      Island {
        glass: root.glass
        Layout.fillWidth: true
        PlayerControls { width: parent.width; player: root.player }
      }
    }
  }
}
