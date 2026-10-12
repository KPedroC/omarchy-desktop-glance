import QtQuick
import qs.Commons

// Rounded translucent card; Hyprland blurs what's behind it (see README).
Rectangle {
  id: root

  property int padding: 16
  // Background opacity; lower is more see-through.
  property real glass: 0.55
  default property alias content: inner.data

  implicitHeight: inner.childrenRect.height + padding * 2
  radius: 16
  color: Qt.rgba(Color.popups.background.r, Color.popups.background.g, Color.popups.background.b, root.glass)
  border.width: 1
  border.color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.1)

  Item {
    id: inner
    anchors.fill: parent
    anchors.margins: root.padding
  }
}
