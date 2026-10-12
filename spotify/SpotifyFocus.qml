import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import "../common"
import "../common/Icons.js" as Icons

// Spotify focus view: blurred cover backdrop, large centered cover art and a
// bottom bar with track info, playback controls and a seekable progress bar.
Item {
  id: root

  property var player: null
  property real glass: 0.35
  signal collapse()

  readonly property bool hasTrack: player !== null && (player.trackTitle || "") !== ""
  readonly property bool hasArt: hasTrack && (player.trackArtUrl || "") !== ""
  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property color bg: Color.popups.background
  readonly property string fontFamily: Style.font.family
  readonly property int pad: 32
  readonly property int radius: 16

  function formatTime(seconds) {
    if (!isFinite(seconds) || seconds < 0) seconds = 0
    var s = Math.floor(seconds)
    var sec = s % 60
    return Math.floor(s / 60) + ":" + (sec < 10 ? "0" : "") + sec
  }

  // MPRIS doesn't push position updates; poll while playing.
  Timer {
    interval: 1000
    repeat: true
    running: root.visible && root.player !== null && root.player.isPlaying
    onTriggered: root.player.positionChanged()
  }

  // Backdrop, corners masked to the card radius.
  Item {
    id: card
    anchors.fill: parent
    layer.enabled: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: cardMask
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1.0
    }

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, root.glass)
    }

    Image {
      id: backdrop
      anchors.fill: parent
      source: root.hasArt ? root.player.trackArtUrl : ""
      sourceSize.width: 256
      sourceSize.height: 256
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      visible: false
    }

    MultiEffect {
      anchors.fill: parent
      source: backdrop
      visible: backdrop.status === Image.Ready
      blurEnabled: true
      blur: 1.0
      blurMax: 64
      saturation: 0.15
      brightness: -0.35
    }
  }

  Item {
    id: cardMask
    anchors.fill: parent
    layer.enabled: true
    visible: false
    Rectangle { anchors.fill: parent; radius: root.radius }
  }

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: "transparent"
    border.width: 1
    border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)
  }

  // Large cover, centered above the bar.
  Item {
    id: artArea
    anchors { top: parent.top; left: parent.left; right: parent.right; bottom: bar.top }
    anchors.margins: root.pad

    Item {
      readonly property real size: Math.max(0, Math.min(artArea.width, artArea.height))
      width: size
      height: size
      anchors.centerIn: parent

      PlayerArt {
        width: parent.width
        aspect: 1
        radius: root.radius
        player: root.player
      }
    }
  }

  IconButton {
    anchors { top: parent.top; right: parent.right; margins: Style.spacing.xl }
    path: Icons.collapse
    size: 32
    onClicked: root.collapse()
  }

  // Bottom bar: track info, controls, elapsed / length, progress.
  Rectangle {
    id: bar
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: root.pad }
    height: barContent.implicitHeight + Style.spacing.huge * 2
    radius: root.radius
    color: Qt.rgba(root.bg.r, root.bg.g, root.bg.b, 0.45)
    border.width: 1
    border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)

    Column {
      id: barContent
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
      anchors.leftMargin: Style.spacing.huge * 1.5
      anchors.rightMargin: Style.spacing.huge * 1.5
      spacing: Style.spacing.xl

      Item {
        width: parent.width
        height: Math.max(info.implicitHeight, controls.height)

        Column {
          id: info
          anchors { left: parent.left; verticalCenter: parent.verticalCenter }
          width: (parent.width - controls.width) / 2 - Style.spacing.huge
          spacing: Style.spacing.xs

          Text {
            textFormat: Text.PlainText
            width: parent.width
            text: root.hasTrack ? root.player.trackTitle : (root.player ? "Nothing playing" : "Spotify isn't running")
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            width: parent.width
            visible: text !== ""
            text: root.hasTrack ? [root.player.trackArtist, root.player.trackAlbum].filter(Boolean).join("  ·  ") : ""
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            elide: Text.ElideRight
          }
        }

        Row {
          id: controls
          anchors.centerIn: parent
          visible: root.player !== null
          spacing: Style.spacing.huge

          ShuffleButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 34
            player: root.player
          }
          IconButton {
            anchors.verticalCenter: parent.verticalCenter
            path: Icons.previous
            size: 44
            enabled: root.player !== null && root.player.canGoPrevious
            onClicked: root.player.previous()
          }
          IconButton {
            anchors.verticalCenter: parent.verticalCenter
            path: root.player && root.player.isPlaying ? Icons.pause : Icons.play
            size: 60
            glyphScale: 0.6
            enabled: root.player !== null && root.player.canTogglePlaying
            fill: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
            onClicked: root.player.togglePlaying()
          }
          IconButton {
            anchors.verticalCenter: parent.verticalCenter
            path: Icons.next
            size: 44
            enabled: root.player !== null && root.player.canGoNext
            onClicked: root.player.next()
          }
          RepeatButton {
            anchors.verticalCenter: parent.verticalCenter
            size: 34
            player: root.player
          }
        }

        Row {
          anchors { right: parent.right; verticalCenter: parent.verticalCenter }
          spacing: Style.spacing.huge

          Row {
            id: volumeControl
            anchors.verticalCenter: parent.verticalCenter
            visible: root.player !== null && root.player.volumeSupported
            spacing: Style.spacing.md

            property real unmutedVolume: 0.5

            IconButton {
              anchors.verticalCenter: parent.verticalCenter
              path: root.player && root.player.volume > 0 ? Icons.volume : Icons.volumeOff
              size: 30
              idleOpacity: 0.6
              enabled: root.player !== null && root.player.canControl
              onClicked: {
                if (root.player.volume > 0) {
                  volumeControl.unmutedVolume = root.player.volume
                  root.player.volume = 0
                } else {
                  root.player.volume = volumeControl.unmutedVolume
                }
              }
            }

            // Click, drag or scroll to set the volume.
            Item {
              anchors.verticalCenter: parent.verticalCenter
              width: 110
              height: 14

              Rectangle {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: volumeArea.containsMouse || volumeArea.pressed ? 6 : 4
                radius: height / 2
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.15)

                Rectangle {
                  width: root.player ? parent.width * Math.max(0, Math.min(1, root.player.volume)) : 0
                  height: parent.height
                  radius: parent.radius
                  color: root.fg
                }
              }

              MouseArea {
                id: volumeArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: root.player !== null && root.player.canControl
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                function setTo(x) {
                  root.player.volume = Math.max(0, Math.min(1, x / width))
                }
                onPressed: function(mouse) { setTo(mouse.x) }
                onPositionChanged: function(mouse) { if (pressed) setTo(mouse.x) }
                onWheel: function(wheel) {
                  root.player.volume = Math.max(0, Math.min(1, root.player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hasTrack
            text: root.player ? root.formatTime(root.player.position) + " / " + root.formatTime(root.player.length) : ""
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
          }
        }
      }

      // Click or drag to seek.
      Item {
        width: parent.width
        height: 14
        visible: root.hasTrack

        Rectangle {
          id: track
          anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
          height: seek.containsMouse || seek.pressed ? 6 : 4
          radius: height / 2
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.15)

          Rectangle {
            width: root.player && root.player.length > 0
              ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
            height: parent.height
            radius: parent.radius
            color: Color.accent
          }
        }

        MouseArea {
          id: seek
          anchors.fill: parent
          hoverEnabled: true
          enabled: root.player !== null && root.player.canSeek && root.player.length > 0
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          function seekTo(x) {
            root.player.position = Math.max(0, Math.min(1, x / width)) * root.player.length
          }
          onPressed: function(mouse) { seekTo(mouse.x) }
          onPositionChanged: function(mouse) { if (pressed) seekTo(mouse.x) }
        }
      }
    }
  }
}
