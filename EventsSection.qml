import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Upcoming events from bin/calendar-sync, grouped by day. Shows as many as
// fit in the height it's given.
Item {
  id: root

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.6)
  readonly property string fontFamily: Style.font.family
  readonly property string syncPath: decodeURIComponent(Qt.resolvedUrl("bin/calendar-sync").toString().replace("file://", ""))

  property var feed: null
  property var now: new Date()

  readonly property var errors: feed && feed.errors ? feed.errors : []
  readonly property var rows: buildRows(feed && feed.events ? feed.events : [], now)

  clip: true

  function dayKey(d) {
    return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate()
  }

  function dayLabel(d) {
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    var diff = Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - today) / 86400000)
    if (diff === 0) return "Today"
    if (diff === 1) return "Tomorrow"
    return Qt.formatDate(d, "dddd d MMM")
  }

  // Flattens events into header + event rows, dropping ones already over.
  // Multi-day all-day events show on today while they're running.
  function buildRows(events, now) {
    var list = []
    var lastKey = ""
    for (var i = 0; i < events.length; i++) {
      var e = events[i]
      var start = new Date(e.start)
      var end = new Date(e.end)
      if (end <= now) continue
      var shown = start < now ? now : start
      var key = dayKey(shown)
      if (key !== lastKey) {
        list.push({ header: true, label: dayLabel(shown) })
        lastKey = key
      }
      list.push({ header: false, event: e, start: start, end: end, live: start <= now && now < end })
    }
    return list
  }

  function timeLabel(row) {
    if (row.event.allDay) return "All day"
    return Qt.formatTime(row.start, "HH:mm") + "–" + Qt.formatTime(row.end, "HH:mm")
  }

  // Join shows from 10 minutes before until the meeting ends.
  function canJoin(row) {
    return !row.event.allDay && row.event.link !== "" && now >= new Date(row.start - 600000) && now < row.end
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

  Column {
    width: root.width
    spacing: 2

    Item {
      width: parent.width
      height: 24

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Upcoming"
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Rectangle {
        id: reloadButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        color: reloadMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : "transparent"

        Text {
          anchors.centerIn: parent
          text: "󰑐"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: 14

          RotationAnimation on rotation {
            running: syncProc.running
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 900
            onRunningChanged: if (!running) parent.rotation = 0
          }
        }

        MouseArea {
          id: reloadMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.sync(true)
        }
      }

      Text {
        anchors.right: reloadButton.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: root.errors.length > 0
        text: "󰀦 " + root.errors.map(function(e) { return e.calendar }).join(", ")
        color: Color.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Text {
      visible: root.feed !== null && root.rows.length === 0
      text: "Nothing in the next 7 days"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }

    Repeater {
      model: root.rows

      Item {
        id: rowItem
        required property var modelData
        readonly property var row: modelData

        width: root.width
        height: row.header ? header.implicitHeight : 30
        // Hide rows cut off at the bottom rather than showing half of one.
        opacity: y + height <= root.height ? 1 : 0

        Text {
          id: header
          visible: rowItem.row.header
          topPadding: 6
          text: rowItem.row.header ? rowItem.row.label : ""
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Rectangle {
          visible: !rowItem.row.header
          anchors.fill: parent
          radius: 6
          color: !rowItem.row.header && rowItem.row.live ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08) : "transparent"

          Rectangle {
            id: dot
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: rowItem.row.header ? "transparent" : rowItem.row.event.color
          }

          Text {
            id: time
            anchors.left: dot.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 84
            text: rowItem.row.header ? "" : root.timeLabel(rowItem.row)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            anchors.left: time.right
            anchors.right: join.visible ? join.left : parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: rowItem.row.header ? "" : rowItem.row.event.title
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: !rowItem.row.header && rowItem.row.live
            elide: Text.ElideRight
          }

          Rectangle {
            id: join
            visible: !rowItem.row.header && root.canJoin(rowItem.row)
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: joinText.implicitWidth + 16
            height: 22
            radius: 11
            color: joinMouse.containsMouse ? Qt.lighter(Color.accent, 1.15) : Color.accent

            Text {
              id: joinText
              anchors.centerIn: parent
              text: "Join"
              color: Color.popups.background
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            MouseArea {
              id: joinMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Quickshell.execDetached(["xdg-open", rowItem.row.event.link])
            }
          }
        }
      }
    }
  }
}
