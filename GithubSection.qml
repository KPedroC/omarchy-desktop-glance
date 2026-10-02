import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Tracked GitHub Actions runs from bin/github-sync: running ones first with
// progress against the workflow's typical duration, then recent results.
Item {
  id: root

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property color passColor: Color.accent
  readonly property color failColor: Color.urgent
  readonly property string fontFamily: Style.font.family
  readonly property string syncPath: decodeURIComponent(Qt.resolvedUrl("bin/github-sync").toString().replace("file://", ""))

  property var feed: null
  property var now: new Date()

  readonly property var runs: feed && feed.runs ? feed.runs : []
  readonly property var errors: feed && feed.errors ? feed.errors : []
  readonly property bool anyRunning: feed !== null && feed.anyRunning === true
  readonly property int runningCount: runs.filter(function(r) { return r.status !== "completed" }).length

  implicitHeight: content.implicitHeight

  function duration(seconds) {
    seconds = Math.max(0, Math.round(seconds))
    var h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60), s = seconds % 60
    if (h > 0) return h + "h " + m + "m"
    if (m > 0) return m + "m" + (m < 10 && s > 0 ? " " + s + "s" : "")
    return s + "s"
  }

  function ago(iso) {
    var mins = Math.max(0, Math.round((now - new Date(iso)) / 60000))
    if (mins < 1) return "just now"
    if (mins < 60) return mins + "m ago"
    var hours = Math.floor(mins / 60)
    return hours < 24 ? hours + "h ago" : Math.floor(hours / 24) + "d ago"
  }

  function elapsed(run) {
    return run.startedAt ? (now - new Date(run.startedAt)) / 1000 : 0
  }

  function statusText(run) {
    if (run.status !== "completed") {
      if (run.status === "queued" || run.status === "waiting" || run.status === "pending") return "queued"
      return duration(elapsed(run)) + (run.typicalSeconds ? " / ~" + duration(run.typicalSeconds) : "")
    }
    var took = run.startedAt && run.endedAt ? duration((new Date(run.endedAt) - new Date(run.startedAt)) / 1000) : ""
    return took + " · " + ago(run.endedAt)
  }

  function sync() {
    if (!syncProc.running) syncProc.running = true
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

  // Every minute while something runs, otherwise every 5 minutes.
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

  Column {
    id: content
    width: root.width
    spacing: 4

    Item {
      width: parent.width
      height: 24

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Actions"
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Text {
        anchors.right: reloadButton.left
        anchors.rightMargin: Style.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        text: root.errors.length > 0 ? "󰀦 " + root.errors.length : (root.runningCount > 0 ? root.runningCount + " running" : "")
        color: root.errors.length > 0 ? root.failColor : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      IconButton {
        id: reloadButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        size: 24
        glyph: "󰑐"
        foreground: root.dim
        onClicked: root.sync()

        RotationAnimation on rotation {
          running: syncProc.running
          loops: Animation.Infinite
          from: 0
          to: 360
          duration: 900
          onRunningChanged: if (!running) reloadButton.rotation = 0
        }
      }
    }

    Text {
      visible: root.feed !== null && root.runs.length === 0
      text: "No runs in the last 24 hours"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Repeater {
      model: root.runs

      Rectangle {
        id: row
        required property var modelData
        readonly property bool running: modelData.status !== "completed"
        readonly property bool passed: modelData.conclusion === "success"
        readonly property bool failed: !running && !passed && modelData.conclusion !== "cancelled" && modelData.conclusion !== "skipped"
        readonly property real progress: running && modelData.typicalSeconds
          ? Math.min(0.97, root.elapsed(modelData) / modelData.typicalSeconds) : 0

        width: root.width
        height: 42
        radius: 8
        color: rowMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08) : "transparent"

        Text {
          id: icon
          x: 6
          anchors.verticalCenter: parent.verticalCenter
          anchors.verticalCenterOffset: -1
          width: 18
          horizontalAlignment: Text.AlignHCenter
          text: row.running ? "󰑐" : (row.passed ? "󰄬" : (row.failed ? "󰅖" : "󰜺"))
          color: row.running ? root.fg : (row.passed ? root.passColor : (row.failed ? root.failColor : root.dim))
          font.family: root.fontFamily
          font.pixelSize: 15

          RotationAnimation on rotation {
            running: row.running
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1400
          }
        }

        Text {
          id: name
          anchors.left: icon.right
          anchors.leftMargin: 8
          anchors.right: status.left
          anchors.rightMargin: 6
          y: 5
          text: row.modelData.workflow
          color: row.failed ? root.failColor : root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          id: status
          anchors.right: parent.right
          anchors.rightMargin: 6
          anchors.verticalCenter: name.verticalCenter
          text: root.statusText(row.modelData)
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          anchors.left: name.left
          anchors.right: parent.right
          anchors.rightMargin: 6
          anchors.top: name.bottom
          anchors.topMargin: 1
          text: row.modelData.title + (row.modelData.branch ? "  ·  " + row.modelData.branch : "")
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }

        // Progress against the workflow's typical duration.
        Rectangle {
          visible: row.running
          anchors.left: name.left
          anchors.right: parent.right
          anchors.rightMargin: 6
          anchors.bottom: parent.bottom
          height: 2
          radius: 1
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)

          Rectangle {
            width: parent.width * row.progress
            height: parent.height
            radius: 1
            color: Color.accent
          }
        }

        MouseArea {
          id: rowMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["xdg-open", row.modelData.url])
        }
      }
    }
  }
}
