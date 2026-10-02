import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons
import "Spotify.js" as Spotify

// Full-height sidebar on the left of the main screen. Sits on the Bottom
// layer: above the wallpaper, below windows. Fades out while a window on
// the visible workspace overlaps it.
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

  readonly property string coveredPath: decodeURIComponent(Qt.resolvedUrl("bin/sidebar-covered").toString().replace("file://", ""))
  property bool covered: false

  function checkCovered() {
    if (!root.targetScreen) return
    coveredProc.command = [root.coveredPath, root.targetScreen.name, String(root.margin), "0",
      String(root.sidebarWidth), String(root.targetScreen.height)]
    if (coveredProc.running) recheck.restart()
    else coveredProc.running = true
  }

  Process {
    id: coveredProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.covered = text.trim() === "1"
    }
  }

  // Coalesces bursts of Hyprland events into one check.
  Timer {
    id: recheck
    interval: 80
    onTriggered: root.checkCovered()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event && event.name ? String(event.name) : ""
      if (/^(openwindow|closewindow|movewindow|workspace|focusedmon|changefloatingmode|fullscreen|activespecial|moveworkspace|resizewindow|movewindowv2|workspacev2|activespecialv2)/.test(name))
        recheck.restart()
    }
  }

  Component.onCompleted: checkCovered()

  PanelWindow {
    screen: root.targetScreen
    visible: root.targetScreen !== null && (!root.covered || frame.opacity > 0)
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
      id: frame
      anchors.fill: parent
      opacity: root.covered ? 0 : 1
      Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
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
