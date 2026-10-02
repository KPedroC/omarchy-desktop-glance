import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons

// Square cover art filling its island, corners masked to the island radius.
// Click opens Spotify when it isn't running; double-click shows its window.
Item {
  id: root

  property var player: null
  property real radius: 16

  readonly property bool hasArt: player !== null && (player.trackArtUrl || "") !== "" && (player.trackTitle || "") !== ""
  readonly property string togglePath: decodeURIComponent(Qt.resolvedUrl("bin/spotify-toggle").toString().replace("file://", ""))

  implicitHeight: width

  Image {
    id: art
    anchors.fill: parent
    source: root.hasArt ? root.player.trackArtUrl : ""
    sourceSize.width: width * 2
    sourceSize.height: height * 2
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }

  Rectangle {
    id: mask
    anchors.fill: parent
    radius: root.radius
    visible: false
    layer.enabled: true
  }

  MultiEffect {
    anchors.fill: parent
    source: art
    maskEnabled: true
    maskSource: mask
    visible: art.status === Image.Ready
  }

  Text {
    anchors.centerIn: parent
    visible: art.status !== Image.Ready
    text: "󰓇"
    color: Qt.darker(Color.popups.text, 1.6)
    font.family: Style.font.family
    font.pixelSize: 96
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: if (!root.player) Quickshell.execDetached([root.togglePath])
    onDoubleClicked: Quickshell.execDetached([root.togglePath])
  }
}
