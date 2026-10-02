import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons

Item {
  id: root

  property var player: null

  readonly property bool hasTrack: player !== null && (player.trackTitle || "") !== ""
  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.6)
  readonly property string fontFamily: Style.font.family
  readonly property string togglePath: decodeURIComponent(Qt.resolvedUrl("bin/spotify-toggle").toString().replace("file://", ""))

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
    spacing: 4

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      width: Math.min(parent.width, 280)
      height: width
      radius: 10
      color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
      clip: true

      Image {
        anchors.fill: parent
        source: root.hasTrack ? (root.player.trackArtUrl || "") : ""
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onDoubleClicked: Quickshell.execDetached([root.togglePath])
      }

      Text {
        anchors.centerIn: parent
        visible: !root.hasTrack || (root.player.trackArtUrl || "") === ""
        text: "󰓇"
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: 96
      }
    }

    Item { width: 1; height: 8 }

    Text {
      width: parent.width
      text: root.hasTrack ? root.player.trackTitle : (root.player ? "Nothing playing" : "Spotify isn't running")
      color: root.fg
      font.family: root.fontFamily
      font.pixelSize: Style.font.heading
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      text: root.hasTrack ? (root.player.trackArtist || "") : (root.player ? "" : "Click to open")
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.subtitle
      elide: Text.ElideRight
    }

    Item { width: 1; height: 8 }

    Rectangle {
      visible: root.hasTrack
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
      visible: root.hasTrack
      width: parent.width
      height: elapsed.implicitHeight

      Text {
        id: elapsed
        text: root.player ? root.formatTime(root.player.position) : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        anchors.right: parent.right
        text: root.player ? root.formatTime(root.player.length) : ""
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Row {
      visible: root.player !== null
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 16

      ControlButton {
        anchors.verticalCenter: parent.verticalCenter
        glyph: "󰒮"
        enabled: root.player !== null && root.player.canGoPrevious
        onClicked: root.player.previous()
      }
      ControlButton {
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
        size: 48
        enabled: root.player !== null && root.player.canTogglePlaying
        onClicked: root.player.togglePlaying()
      }
      ControlButton {
        anchors.verticalCenter: parent.verticalCenter
        glyph: "󰒭"
        enabled: root.player !== null && root.player.canGoNext
        onClicked: root.player.next()
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    visible: root.player === null
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached([root.togglePath])
  }

  component ControlButton: Rectangle {
    id: button

    property string glyph: ""
    property int size: 36
    signal clicked()

    width: size
    height: size
    radius: size / 2
    color: mouse.containsMouse && enabled ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : "transparent"
    opacity: enabled ? 1 : 0.35

    Text {
      anchors.centerIn: parent
      text: button.glyph
      color: root.fg
      font.family: root.fontFamily
      font.pixelSize: button.size * 0.6
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (button.enabled) button.clicked()
    }
  }
}
