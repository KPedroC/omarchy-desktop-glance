import QtQuick
import Quickshell
import qs.Commons

// Upcoming events grouped by day, or one day's events when a date is picked
// in the calendar. Shows as many as fit in the height it's given.
Item {
  id: root

  property var model: null
  property var selectedDate: null
  signal cleared()

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property string fontFamily: Style.font.family

  readonly property var now: model ? model.now : new Date()
  readonly property var errors: model ? model.errors : []
  readonly property var rows: selectedDate
    ? buildDayRows(model ? model.eventsOn(selectedDate) : [], selectedDate, now)
    : buildRows(model ? model.events : [], now)

  clip: true

  function dayKey(d) {
    return d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate()
  }

  function dayLabel(d) {
    var today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    var diff = Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - today) / 86400000)
    if (diff === 0) return "Today"
    if (diff === 1) return "Tomorrow"
    if (diff === -1) return "Yesterday"
    return Qt.formatDate(d, "dddd d MMM")
  }

  function eventRow(e, now) {
    var start = new Date(e.start)
    var end = new Date(e.end)
    return { header: false, event: e, start: start, end: end, live: start <= now && now < end, past: end <= now }
  }

  // Flattens events into header + event rows, dropping ones already over.
  // Multi-day all-day events show on today while they're running.
  function buildRows(events, now) {
    var list = []
    var lastKey = ""
    for (var i = 0; i < events.length; i++) {
      var row = eventRow(events[i], now)
      if (row.past) continue
      var shown = row.start < now ? now : row.start
      var key = dayKey(shown)
      if (key !== lastKey) {
        list.push({ header: true, label: dayLabel(shown) })
        lastKey = key
      }
      list.push(row)
    }
    return list
  }

  function buildDayRows(events, day, now) {
    var list = []
    for (var i = 0; i < events.length; i++) list.push(eventRow(events[i], now))
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

  Column {
    width: root.width
    spacing: 2

    Item {
      width: parent.width
      height: 26

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.selectedDate ? root.dayLabel(root.selectedDate) : "Upcoming"
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }

      IconButton {
        id: closeButton
        visible: root.selectedDate !== null
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: visible ? 24 : 0
        size: 24
        glyph: "󰅖"
        foreground: root.dim
        onClicked: root.cleared()
      }

      IconButton {
        id: reloadButton
        anchors.right: closeButton.left
        anchors.verticalCenter: parent.verticalCenter
        size: 24
        glyph: "󰑐"
        foreground: root.dim
        onClicked: if (root.model) root.model.sync(true)

        RotationAnimation on rotation {
          running: root.model !== null && root.model.syncing
          loops: Animation.Infinite
          from: 0
          to: 360
          duration: 900
          onRunningChanged: if (!running) reloadButton.rotation = 0
        }
      }

      Text {
        anchors.right: reloadButton.left
        anchors.rightMargin: Style.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        visible: root.errors.length > 0
        text: "󰀦 " + root.errors.map(function(e) { return e.calendar }).join(", ")
        color: Color.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Text {
      visible: root.model !== null && root.model.feed !== null && root.rows.length === 0
      text: root.selectedDate ? "No events" : "Nothing coming up"
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
          radius: 8
          color: !rowItem.row.header && rowItem.row.live ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08) : "transparent"

          Rectangle {
            id: dot
            x: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 16
            radius: 1.5
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
            color: !rowItem.row.header && rowItem.row.past ? root.dim : root.fg
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
            height: 20
            radius: 10
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
