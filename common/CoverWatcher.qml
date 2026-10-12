import QtQuick
import Quickshell.Io

// Tracks whether a window on the visible workspace overlaps a rect
// (monitor-local, logical px) via desk-covered.
Item {
  id: root
  visible: false

  property var screen: null
  property real rectX: 0
  property real rectY: 0
  property real rectWidth: 0
  property real rectHeight: 0
  property bool covered: false

  readonly property string scriptPath: decodeURIComponent(Qt.resolvedUrl("desk-covered").toString().replace("file://", ""))

  function check() {
    if (!screen) return
    proc.command = [scriptPath, screen.name, String(Math.round(rectX)), String(Math.round(rectY)),
      String(Math.round(rectWidth)), String(Math.round(rectHeight))]
    if (proc.running) retry.restart()
    else proc.running = true
  }

  Process {
    id: proc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.covered = text.trim() === "1"
    }
  }

  Timer {
    id: retry
    interval: 80
    onTriggered: root.check()
  }
}
