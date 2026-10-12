import QtQuick
import QtQuick.Shapes
import qs.Commons

// Round icon button: brightens and grows slightly on hover.
Rectangle {
  id: root

  property string glyph: ""
  // SVG path on a 24x24 grid (see Icons.js); drawn instead of `glyph`.
  property string path: ""
  property int size: 28
  property real glyphScale: 0.55
  property color foreground: Color.popups.text
  // Resting background; hover tints it towards the foreground.
  property color fill: "transparent"
  // Resting opacity; hover shows the button fully.
  property real idleOpacity: 1
  signal clicked()

  readonly property bool hovered: mouse.containsMouse && enabled

  width: size
  height: size
  radius: size / 2
  color: hovered ? Qt.tint(fill, Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)) : fill
  opacity: !enabled ? 0.35 : hovered ? 1 : idleOpacity
  scale: mouse.pressed && enabled ? 0.94 : hovered ? 1.08 : 1

  Behavior on color { ColorAnimation { duration: 120 } }
  Behavior on opacity { NumberAnimation { duration: 120 } }
  Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

  // Centers the glyph's ink rather than its line box; icon-font glyphs often
  // sit off-center within their advance and ascent.
  TextMetrics { id: ink; font: label.font; text: root.glyph }

  Text {
    id: label
    visible: root.path === ""
    anchors.centerIn: parent
    anchors.horizontalCenterOffset: width / 2 - (ink.tightBoundingRect.x + ink.tightBoundingRect.width / 2)
    anchors.verticalCenterOffset: height / 2 - (baselineOffset + ink.tightBoundingRect.y + ink.tightBoundingRect.height / 2)
    text: root.glyph
    color: root.foreground
    font.family: Style.font.family
    font.pixelSize: Math.round(root.size * root.glyphScale)
  }

  Shape {
    visible: root.path !== ""
    anchors.centerIn: parent
    width: 24
    height: 24
    scale: label.font.pixelSize / 24
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: root.foreground
      strokeColor: "transparent"
      PathSvg { path: root.path }
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (root.enabled) root.clicked()
  }
}
