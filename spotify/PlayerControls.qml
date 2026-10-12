import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import "../common"
import "../common/Icons.js" as Icons

// Track title, artist, progress and playback controls.
Item {
  id: root

  property var player: null

  readonly property bool hasTrack: player !== null && (player.trackTitle || "") !== ""
  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property string fontFamily: Style.font.family
  readonly property string togglePath: decodeURIComponent(Qt.resolvedUrl("spotify-toggle").toString().replace("file://", ""))

  implicitHeight: content.implicitHeight

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
    running: root.player !== null && root.player.isPlaying
    onTriggered: root.player.positionChanged()
  }

  Column {
    id: content
    width: root.width
    spacing: Style.spacing.lg

    Column {
      width: parent.width
      spacing: Style.spacing.xs

      Text {
        textFormat: Text.PlainText
        width: parent.width
        text: root.hasTrack ? root.player.trackTitle : (root.player ? "Nothing playing" : "Spotify isn't running")
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.heading
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        width: parent.width
        text: root.hasTrack ? (root.player.trackArtist || "") : (root.player ? "" : "Click to open")
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        elide: Text.ElideRight
      }
    }

    Column {
      visible: root.hasTrack
      width: parent.width
      spacing: Style.spacing.sm

      Rectangle {
        width: parent.width
        height: 4
        radius: 2
        color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.15)

        Rectangle {
          width: root.player && root.player.length > 0
            ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
          height: parent.height
          radius: parent.radius
          color: Color.accent
        }
      }

      Item {
        width: parent.width
        height: elapsed.implicitHeight

        Text {
          textFormat: Text.PlainText
          id: elapsed
          text: root.player ? root.formatTime(root.player.position) : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          textFormat: Text.PlainText
          anchors.right: parent.right
          text: root.player ? root.formatTime(root.player.length) : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }

    Row {
      visible: root.player !== null
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.spacing.xl

      ShuffleButton {
        anchors.verticalCenter: parent.verticalCenter
        size: 28
        player: root.player
      }
      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        path: Icons.previous
        size: 36
        enabled: root.player !== null && root.player.canGoPrevious
        onClicked: root.player.previous()
      }
      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        path: root.player && root.player.isPlaying ? Icons.pause : Icons.play
        size: 44
        glyphScale: 0.6
        enabled: root.player !== null && root.player.canTogglePlaying
        fill: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1)
        onClicked: root.player.togglePlaying()
      }
      IconButton {
        anchors.verticalCenter: parent.verticalCenter
        path: Icons.next
        size: 36
        enabled: root.player !== null && root.player.canGoNext
        onClicked: root.player.next()
      }
      RepeatButton {
        anchors.verticalCenter: parent.verticalCenter
        size: 28
        player: root.player
      }
    }
  }

  // Covers the whole card while Spotify isn't running.
  MouseArea {
    anchors.fill: parent
    visible: root.player === null
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached([root.togglePath])
  }
}
