import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.Commons
import "spotify"
import "calendar"
import "github"
import "weather"
import "common"
import "common/Icons.js" as Icons
import "spotify/Spotify.js" as Spotify

// Desktop widgets on every screen: a full-height column on the left
// (weather, calendar, events, pull requests, GitHub Actions) and Spotify
// top-right. Both sit on the Bottom layer (above the wallpaper, below
// windows) and fade out while a window on the visible workspace overlaps
// them, or while the bar is hidden. The cover's expand button switches
// Spotify to a focus view filling the space right of the sidebar.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // Hyprland's gaps_out, so the sidebar lines up with tiled windows.
  readonly property int margin: Style.gapsOut * 2
  readonly property int sidebarWidth: 380
  readonly property int rightWidth: 340
  // Island background opacity (0 = clear glass, 1 = solid).
  readonly property real glass: 0.35

  // Hidden together with the bar (SUPER + SHIFT + SPACE).
  readonly property bool barHidden: shell && shell.bar ? shell.bar.barHidden === true : false
  signal checkCovers()

  readonly property var player: Spotify.findPlayer(Mpris.players ? Mpris.players.values : [])
  // Coalesces bursts of Hyprland events into one check.
  Timer {
    id: recheck
    interval: 80
    onTriggered: root.checkCovers()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = event && event.name ? String(event.name) : ""
      if (/^(openwindow|closewindow|movewindow|workspace|focusedmon|changefloatingmode|fullscreen|activespecial|moveworkspace|resizewindow|movewindowv2|workspacev2|activespecialv2|monitoradded|monitorremoved)/.test(name))
        recheck.restart()
    }
  }

  Component.onCompleted: recheck.restart()

  EventsModel { id: events }
  GithubModel { id: github }

  // One set of widgets per screen; follows hot-plugged monitors.
  Variants {
    model: Quickshell.screens

    Item {
      id: desk

      required property var modelData

      // Spotify fills the space right of the sidebar; drops back to the
      // corner while a window covers that space.
      property bool focusMode: false
      readonly property bool leftShown: !root.barHidden && !leftCover.covered
      readonly property bool focusShown: !root.barHidden && focusMode && !focusCover.covered
      readonly property bool rightShown: !root.barHidden && !focusShown && !rightCover.covered

      // Date picked in the calendar; null shows upcoming events.
      property var selectedDate: null

      Connections {
        target: root
        function onCheckCovers() { leftCover.check(); rightCover.check(); focusCover.check() }
      }

      Component.onCompleted: { leftCover.check(); rightCover.check(); focusCover.check() }

      CoverWatcher {
        id: leftCover
        screen: desk.modelData
        rectX: root.margin
        rectWidth: root.sidebarWidth
        rectHeight: desk.modelData.height
      }

      // Top-right corner down to the Spotify islands' bottom edge (bar + gap + islands).
      CoverWatcher {
        id: rightCover
        screen: desk.modelData
        rectX: desk.modelData.width - root.margin - root.rightWidth
        rectWidth: root.rightWidth
        rectHeight: 40 + root.margin + rightColumn.implicitHeight
      }

      // Everything right of the sidebar.
      CoverWatcher {
        id: focusCover
        screen: desk.modelData
        rectX: root.margin + root.sidebarWidth
        rectWidth: desk.modelData.width - rectX
        rectHeight: desk.modelData.height
      }

      // Left: weather, calendar, events, pull requests, GitHub Actions.
      PanelWindow {
        screen: desk.modelData
        visible: desk.leftShown || leftColumn.opacity > 0
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
          opacity: desk.leftShown ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          Island {
            glass: root.glass
            Layout.fillWidth: true
            WeatherSection { width: parent.width }
          }

          Island {
            glass: root.glass
            Layout.fillWidth: true
            CalendarSection {
              width: parent.width
              model: events
              selectedDate: desk.selectedDate
              onDateClicked: function(date) {
                desk.selectedDate = desk.selectedDate && events.sameDay(desk.selectedDate, date) ? null : date
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
              selectedDate: desk.selectedDate
              onCleared: desk.selectedDate = null
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
        }
      }

      // Right: Spotify, top corner.
      PanelWindow {
        id: rightWindow
        screen: desk.modelData
        visible: desk.rightShown || rightColumn.opacity > 0
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
          opacity: desk.rightShown ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          Island {
            id: artIsland
            glass: root.glass
            padding: 0
            Layout.fillWidth: true
            PlayerArt { width: parent.width; radius: artIsland.radius; player: root.player }

            IconButton {
              anchors { top: parent.top; right: parent.right; margins: Style.spacing.lg }
              path: Icons.expand
              size: 30
              idleOpacity: 0.7
              fill: Qt.rgba(Color.popups.background.r, Color.popups.background.g, Color.popups.background.b, 0.25)
              onClicked: desk.focusMode = true
            }
          }

          Island {
            glass: root.glass
            Layout.fillWidth: true
            PlayerControls { width: parent.width; player: root.player }
          }
        }
      }

      // Focus: Spotify across the space right of the sidebar.
      PanelWindow {
        screen: desk.modelData
        visible: desk.focusShown || focusView.opacity > 0
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        margins {
          top: root.margin
          bottom: root.margin
          right: root.margin
          left: root.margin * 2 + root.sidebarWidth
        }

        WlrLayershell.namespace: "kpedroc-desk"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0

        SpotifyFocus {
          id: focusView
          anchors.fill: parent
          player: root.player
          glass: root.glass
          opacity: desk.focusShown ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          onCollapse: desk.focusMode = false
        }
      }
    }
  }
}
