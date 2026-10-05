import QtQuick
import Quickshell.Services.Mpris
import qs.Commons
import "Icons.js" as Icons

// Cycles off → playlist → track, like Spotify's own button.
IconButton {
  property var player: null
  readonly property int loopState: player ? player.loopState : MprisLoopState.None
  readonly property bool active: loopState !== MprisLoopState.None

  path: loopState === MprisLoopState.Track ? Icons.repeatOnce : Icons.repeat
  foreground: active ? Color.accent : Color.popups.text
  idleOpacity: active ? 1 : 0.6
  enabled: player !== null && player.canControl && player.loopSupported
  onClicked: player.loopState = loopState === MprisLoopState.None ? MprisLoopState.Playlist
    : loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
}
