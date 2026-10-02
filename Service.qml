import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import qs.Commons
import "Spotify.js" as Spotify

// Full-height sidebar on the left of the main screen. Sits on the Bottom
// layer: above the wallpaper, below windows.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // Hyprland monitor name; empty picks the first screen.
  readonly property string monitor: ""
  readonly property int margin: 16
  readonly property int sidebarWidth: 320

  readonly property var player: Spotify.findPlayer(Mpris.players ? Mpris.players.values : [])
  readonly property var targetScreen: {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++)
      if (screens[i].name === monitor) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }

  PanelWindow {
    screen: root.targetScreen
    visible: root.targetScreen !== null
    color: "transparent"
    anchors { top: true; bottom: true; left: true }
    margins { top: root.margin; bottom: root.margin; left: root.margin }
    implicitWidth: root.sidebarWidth

    WlrLayershell.namespace: "kpedroc-desk"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0

    Rectangle {
      anchors.fill: parent
      radius: 14
      color: Qt.rgba(Color.popups.background.r, Color.popups.background.g, Color.popups.background.b, 0.85)
      border.width: 1
      border.color: Qt.rgba(Color.popups.border.r, Color.popups.border.g, Color.popups.border.b, 0.5)

      Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 20

        PlayerSection { width: parent.width; player: root.player }
        Divider {}
        CalendarSection { width: parent.width }
        Divider {}
        WeatherSection { width: parent.width }
      }
    }
  }

  component Divider: Rectangle {
    width: parent.width
    height: 1
    color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.1)
  }
}
