import QtQuick
import Quickshell
import Quickshell.Io

// Synced events shared by the calendar and events sections. Runs
// calendar-sync every 5 minutes and reloads when its output changes.
Item {
  id: root
  visible: false

  readonly property string syncPath: decodeURIComponent(Qt.resolvedUrl("calendar-sync").toString().replace("file://", ""))

  property var feed: null
  property var now: new Date()

  readonly property var events: feed && feed.events ? feed.events : []
  readonly property var errors: feed && feed.errors ? feed.errors : []
  readonly property bool syncing: syncProc.running
  // "yyyy-M-d" → unique calendar colors with events that day.
  readonly property var colorsByDay: buildColorsByDay(events)

  function dayKey(d) {
    return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate()
  }

  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
  }

  // All-day ends are exclusive; timed events ending at midnight don't spill
  // into the next day.
  function lastDay(e) {
    return new Date(new Date(e.end).getTime() - 1)
  }

  function buildColorsByDay(events) {
    var map = {}
    for (var i = 0; i < events.length; i++) {
      var e = events[i]
      var day = new Date(e.start)
      day = new Date(day.getFullYear(), day.getMonth(), day.getDate())
      var last = lastDay(e)
      for (var n = 0; day <= last && n < 62; n++) {
        var key = dayKey(day)
        var colors = map[key] || (map[key] = [])
        if (colors.indexOf(e.color) === -1) colors.push(e.color)
        day = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1)
      }
    }
    return map
  }

  function eventsOn(date) {
    var dayStart = new Date(date.getFullYear(), date.getMonth(), date.getDate())
    var dayEnd = new Date(dayStart.getFullYear(), dayStart.getMonth(), dayStart.getDate() + 1)
    return events.filter(function(e) {
      return new Date(e.start) < dayEnd && new Date(e.end) > dayStart
    })
  }

  function sync(force) {
    if (syncProc.running) return
    syncProc.command = force ? [root.syncPath, "--force"] : [root.syncPath]
    syncProc.running = true
  }

  FileView {
    path: Quickshell.env("HOME") + "/.cache/omarchy-desk/events.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.feed = JSON.parse(text()) } catch (e) { root.feed = null }
    }
  }

  Process {
    id: syncProc
  }

  Timer {
    interval: 5 * 60000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.sync(false)
  }

  Timer {
    interval: 30000
    repeat: true
    running: true
    onTriggered: root.now = new Date()
  }
}
