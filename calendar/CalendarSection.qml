import QtQuick
import qs.Commons
import "../common"

// Month grid, Monday first, with ISO week numbers. Days with events get a
// dot per calendar; clicking a day selects it.
Item {
  id: root

  property var model: null
  property var selectedDate: null
  signal dateClicked(var date)

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property string fontFamily: Style.font.family

  property var today: new Date()
  property int viewYear: today.getFullYear()
  property int viewMonth: today.getMonth()

  readonly property real cell: width / 8
  readonly property var days: buildDays(viewYear, viewMonth)
  readonly property int weeks: {
    var first = new Date(viewYear, viewMonth, 1)
    var lead = (first.getDay() + 6) % 7
    return Math.ceil((lead + new Date(viewYear, viewMonth + 1, 0).getDate()) / 7)
  }

  implicitHeight: content.implicitHeight

  function step(delta) {
    var d = new Date(viewYear, viewMonth + delta, 1)
    viewYear = d.getFullYear()
    viewMonth = d.getMonth()
  }

  function resetView() {
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
  }

  function isoWeek(date) {
    var d = new Date(date.getFullYear(), date.getMonth(), date.getDate())
    d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7)
    var week1 = new Date(d.getFullYear(), 0, 4)
    return 1 + Math.round(((d - week1) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7)
  }

  // Six weeks starting on the Monday on/before the 1st.
  function buildDays(year, month) {
    var first = new Date(year, month, 1)
    var start = new Date(year, month, 1 - (first.getDay() + 6) % 7)
    var list = []
    for (var i = 0; i < 42; i++)
      list.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i))
    return list
  }

  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
  }

  // Roll over at midnight.
  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: {
      var now = new Date()
      if (!root.sameDay(now, root.today)) {
        var following = root.viewYear === root.today.getFullYear() && root.viewMonth === root.today.getMonth()
        root.today = now
        if (following) root.resetView()
      }
    }
  }

  Column {
    id: content
    width: root.width
    spacing: Style.spacing.sm

    Item {
      width: parent.width
      height: 26

      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.resetView()
        }
      }

      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.xs

        IconButton { glyph: "󰅁"; size: 24; onClicked: root.step(-1) }
        IconButton { glyph: "󰅂"; size: 24; onClicked: root.step(1) }
      }
    }

    Row {
      Repeater {
        model: ["", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

        Text {
          textFormat: Text.PlainText
          required property string modelData
          width: root.cell
          height: 20
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: modelData
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }
    }

    Repeater {
      model: root.weeks

      Row {
        id: week
        required property int index
        readonly property var monday: root.days[index * 7]

        Text {
          textFormat: Text.PlainText
          width: root.cell
          height: root.cell * 0.78
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          bottomPadding: 6
          text: root.isoWeek(week.monday)
          color: Qt.rgba(root.dim.r, root.dim.g, root.dim.b, 0.6)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Repeater {
          model: 7

          Item {
            id: cell
            required property int index
            readonly property var date: root.days[week.index * 7 + index]
            readonly property bool isToday: root.sameDay(date, root.today)
            readonly property bool isSelected: root.selectedDate !== null && root.sameDay(date, root.selectedDate)
            readonly property bool inMonth: date.getMonth() === root.viewMonth
            readonly property var colors: root.model ? (root.model.colorsByDay[root.model.dayKey(date)] || []) : []

            width: root.cell
            height: root.cell * 0.78

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              y: 1
              width: Math.min(parent.width, parent.height) - 4
              height: width
              radius: width / 2
              color: cell.isToday ? Color.accent
                : (cellMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.1) : "transparent")
              border.width: cell.isSelected ? 1 : 0
              border.color: cell.isToday ? root.fg : Color.accent
            }

            Text {
              textFormat: Text.PlainText
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.verticalCenter: parent.verticalCenter
              anchors.verticalCenterOffset: -2
              text: cell.date.getDate()
              color: cell.isToday ? Color.popups.background : (cell.inMonth ? root.fg : Qt.rgba(root.dim.r, root.dim.g, root.dim.b, 0.5))
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: cell.isToday || cell.isSelected
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 1
              spacing: 2
              opacity: cell.inMonth ? 1 : 0.5

              Repeater {
                model: cell.colors.slice(0, 4)

                Rectangle {
                  required property string modelData
                  width: 4
                  height: 4
                  radius: 2
                  color: cell.isToday ? Color.popups.background : modelData
                }
              }
            }

            MouseArea {
              id: cellMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.dateClicked(cell.date)
            }
          }
        }
      }
    }
  }
}
