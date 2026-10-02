import QtQuick
import Quickshell
import Quickshell.Io

// GitHub data shared by the Actions and pull request sections. Runs
// bin/github-sync every minute while a run is in progress, otherwise every
// 5 minutes, and reloads when its output changes.
Item {
  id: root
  visible: false

  readonly property string syncPath: decodeURIComponent(Qt.resolvedUrl("bin/github-sync").toString().replace("file://", ""))

  property var feed: null
  property var now: new Date()

  readonly property var runs: feed && feed.runs ? feed.runs : []
  readonly property var errors: feed && feed.errors ? feed.errors : []
  readonly property var reviewPulls: feed && feed.pulls ? feed.pulls.review : []
  readonly property var myPulls: feed && feed.pulls ? feed.pulls.mine : []
  readonly property bool anyRunning: feed !== null && feed.anyRunning === true
  readonly property bool syncing: syncProc.running

  function sync() {
    if (!syncProc.running) syncProc.running = true
  }

  function ago(iso) {
    var mins = Math.max(0, Math.round((now - new Date(iso)) / 60000))
    if (mins < 1) return "just now"
    if (mins < 60) return mins + "m ago"
    var hours = Math.floor(mins / 60)
    return hours < 24 ? hours + "h ago" : Math.floor(hours / 24) + "d ago"
  }

  FileView {
    path: Quickshell.env("HOME") + "/.cache/omarchy-desk/github.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.feed = JSON.parse(text()) } catch (e) { root.feed = null }
    }
  }

  Process {
    id: syncProc
    command: [root.syncPath]
  }

  Timer {
    interval: root.anyRunning ? 60000 : 5 * 60000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.sync()
  }

  Timer {
    interval: root.anyRunning ? 1000 : 30000
    repeat: true
    running: true
    onTriggered: root.now = new Date()
  }
}
