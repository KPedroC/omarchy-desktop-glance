import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Ui
import "spotify/Spotify.js" as Spotify

BarWidget {
  id: root
  moduleName: "kpedroc.desktop-glance"

  readonly property var player: Spotify.findPlayer(Mpris.players ? Mpris.players.values : [])
  readonly property bool playing: player !== null && player.isPlaying
  readonly property string title: player ? (player.trackTitle || "") : ""
  readonly property string artist: player ? (player.trackArtist || "") : ""
  readonly property int maxChars: Number(setting("maxChars", 30))
  readonly property string togglePath: decodeURIComponent(Qt.resolvedUrl("spotify/spotify-toggle").toString().replace("file://", ""))

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function label() {
    if (root.vertical || !root.playing || !root.title) return "󰓇"
    var text = root.title.length > root.maxChars ? root.title.slice(0, root.maxChars - 1) + "…" : root.title
    return "󰓇 " + text
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label()
    useActiveColor: false
    tooltipText: (root.title ? root.title + (root.artist ? " — " + root.artist : "") + "\n" : "")
      + "Left: show/hide Spotify · Middle: play/pause · Scroll: next/previous"
    onPressed: function(b) {
      if (b === Qt.MiddleButton) {
        if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
      } else {
        Quickshell.execDetached([root.togglePath])
      }
    }
    onWheelMoved: function(delta) {
      if (!root.player) return
      if (delta < 0 && root.player.canGoNext) root.player.next()
      else if (delta > 0 && root.player.canGoPrevious) root.player.previous()
    }
  }
}
