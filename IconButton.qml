import QtQuick
import qs.Commons

// Round icon button with a soft hover fill.
Rectangle {
  id: root

  property string glyph: ""
  property int size: 28
  property real glyphScale: 0.55
  property color foreground: Color.popups.text
  signal clicked()

  width: size
  height: size
  radius: size / 2
  color: mouse.containsMouse && enabled ? Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12) : "transparent"
  opacity: enabled ? 1 : 0.35

  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: root.foreground
    font.family: Style.font.family
    font.pixelSize: Math.round(root.size * root.glyphScale)
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (root.enabled) root.clicked()
  }
}
