import QtQuick
import qs.Commons
import "Icons.js" as Icons

IconButton {
  property var player: null
  readonly property bool active: player !== null && player.shuffle

  path: Icons.shuffle
  foreground: active ? Color.accent : Color.popups.text
  idleOpacity: active ? 1 : 0.6
  enabled: player !== null && player.canControl && player.shuffleSupported
  onClicked: player.shuffle = !player.shuffle
}
