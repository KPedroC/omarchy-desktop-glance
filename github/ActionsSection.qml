import QtQuick
import Quickshell
import qs.Commons
import "../common"

// Tracked GitHub Actions runs: running ones first with
// progress against the workflow's typical duration, then recent results.
Item {
  id: root

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property color passColor: Color.accent
  readonly property color failColor: Color.urgent
  readonly property string fontFamily: Style.font.family
  property var model: null
  property int maxRuns: 2

  readonly property var now: model ? model.now : new Date()
  readonly property var runs: model ? model.runs : []
  readonly property var errors: model ? model.errors.filter(function(e) { return e.repo !== "pull requests" }) : []
  readonly property int runningCount: runs.filter(function(r) { return r.status !== "completed" }).length

  implicitHeight: content.implicitHeight

  function duration(seconds) {
    seconds = Math.max(0, Math.round(seconds))
    var h = Math.floor(seconds / 3600), m = Math.floor((seconds % 3600) / 60), s = seconds % 60
    if (h > 0) return h + "h " + m + "m"
    if (m > 0) return m + "m" + (m < 10 && s > 0 ? " " + s + "s" : "")
    return s + "s"
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
    return took + " · " + root.model.ago(run.endedAt)
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
        onClicked: if (root.model) root.model.sync()

        RotationAnimation on rotation {
          running: root.model !== null && root.model.syncing
          loops: Animation.Infinite
          from: 0
          to: 360
          duration: 900
          onRunningChanged: if (!running) reloadButton.rotation = 0
        }
      }
    }

    Text {
      visible: root.model !== null && root.model.feed !== null && root.runs.length === 0
      text: "No runs in the last 24 hours"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Repeater {
      model: root.runs.slice(0, root.maxRuns)

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
