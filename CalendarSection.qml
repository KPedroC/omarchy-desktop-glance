import QtQuick
import qs.Commons

// Month grid, Monday first, with ISO week numbers.
Item {
  id: root

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.6)
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
    spacing: 4

    Item {
      width: parent.width
      height: 28

      Text {
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
        spacing: 4

        StepButton { glyph: "󰅁"; onClicked: root.step(-1) }
        StepButton { glyph: "󰅂"; onClicked: root.step(1) }
      }
    }

    Row {
      Repeater {
        model: ["", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

        Text {
          required property string modelData
          width: root.cell
          height: 22
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: modelData
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
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
          width: root.cell
          height: root.cell * 0.8
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: root.isoWeek(week.monday)
          color: Qt.rgba(root.dim.r, root.dim.g, root.dim.b, 0.6)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Repeater {
          model: 7

          Item {
            required property int index
            readonly property var date: root.days[week.index * 7 + index]
            readonly property bool isToday: root.sameDay(date, root.today)
            readonly property bool inMonth: date.getMonth() === root.viewMonth

            width: root.cell
            height: root.cell * 0.8

            Rectangle {
              anchors.centerIn: parent
              width: Math.min(parent.width, parent.height) - 4
              height: width
              radius: width / 2
              color: Color.accent
              visible: parent.isToday
            }

            Text {
              anchors.centerIn: parent
              text: parent.date.getDate()
              color: parent.isToday ? Color.popups.background : (parent.inMonth ? root.fg : Qt.rgba(root.dim.r, root.dim.g, root.dim.b, 0.5))
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: parent.isToday
            }
          }
        }
      }
    }
  }

  component StepButton: Rectangle {
    id: button

    property string glyph: ""
    signal clicked()

    width: 26
    height: 26
    radius: 13
    color: mouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : "transparent"

    Text {
      anchors.centerIn: parent
      text: button.glyph
      color: root.fg
      font.family: root.fontFamily
      font.pixelSize: 16
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }
}
