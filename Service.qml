import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui
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
  // Hyprland's gaps_out, so the sidebar lines up with tiled windows.
  readonly property int margin: Style.gapsOut * 2
  readonly property int sidebarWidth: 380

  // Date picked in the calendar; null shows upcoming events.
  property var selectedDate: null

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

  EventsModel { id: events }

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
      radius: Style.cornerRadius
      color: Color.popups.background
      border.width: Math.max(1, Style.space(2))
      border.color: Color.popups.border

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        spacing: Style.spacing.panelGap

        PlayerSection { Layout.fillWidth: true; player: root.player }
        Divider {}
        CalendarSection {
          Layout.fillWidth: true
          model: events
          selectedDate: root.selectedDate
          onDateClicked: function(date) {
            root.selectedDate = root.selectedDate && events.sameDay(root.selectedDate, date) ? null : date
          }
        }
        Divider {}
        EventsSection {
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: events
          selectedDate: root.selectedDate
          onCleared: root.selectedDate = null
        }
        Divider {}
        WeatherSection { Layout.fillWidth: true }
      }
    }
  }

  component Divider: PanelSeparator {
    Layout.fillWidth: true
    foreground: Color.popups.text
  }
}
