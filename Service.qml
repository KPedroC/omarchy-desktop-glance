import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.Commons
import "Spotify.js" as Spotify

// Desktop widgets on the main screen: a full-height column on the left
// (calendar, events, weather) and a Spotify island top-right. Both sit on
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
  readonly property int playerWidth: 340
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

  CoverWatcher {
    id: leftCover
    screen: root.targetScreen
    rectX: root.margin
    rectWidth: root.sidebarWidth
    rectHeight: root.targetScreen ? root.targetScreen.height : 0
  }

  // Top-right corner down to the island's bottom edge (bar + gap + card).
  CoverWatcher {
    id: rightCover
    screen: root.targetScreen
    rectX: root.targetScreen ? root.targetScreen.width - root.margin - root.playerWidth : 0
    rectWidth: root.playerWidth
    rectHeight: 40 + root.margin + playerIsland.implicitHeight
  }

  // Left: calendar, events, weather.
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
    visible: root.targetScreen !== null && (!rightCover.covered || playerIsland.opacity > 0)
    color: "transparent"
    anchors { top: true; right: true }
    margins { top: root.margin; right: root.margin }
    implicitWidth: root.playerWidth
    implicitHeight: playerIsland.implicitHeight

    WlrLayershell.namespace: "kpedroc-desk"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    Island {
      id: playerIsland
      glass: root.glass
      width: parent.width
      height: parent.height
      opacity: rightCover.covered ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      PlayerSection { width: parent.width; player: root.player }
    }
  }
}
