import QtQuick
import Quickshell
import qs.Commons

// Your open pull requests, what needs you first: unread reviews/comments,
// ready to merge, changes requested. Click a row to open it.
Item {
  id: root

  property var model: null
  property int maxMine: 3

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property color passColor: Color.accent
  readonly property color failColor: Color.urgent
  readonly property string fontFamily: Style.font.family

  readonly property var mine: model ? model.myPulls : []
  readonly property int unreadCount: mine.filter(function(p) { return p.unread }).length
  readonly property bool failed: model !== null && model.errors.some(function(e) { return e.repo === "pull requests" })

  implicitHeight: content.implicitHeight

  function repoName(pr) {
    return pr.repo.split("/")[1] + "#" + pr.number
  }

  function reviewLabel(pr) {
    if (pr.draft) return "Draft"
    if (pr.conflicts) return "Conflicts"
    if (pr.ready) return "Ready to merge"
    if (pr.review === "APPROVED") return "Approved"
    if (pr.review === "CHANGES_REQUESTED") return "Changes requested"
    if (pr.review === "REVIEW_REQUIRED") return "Awaiting review"
    return "Open"
  }

  function reviewColor(pr) {
    if (pr.draft) return dim
    if (pr.conflicts) return failColor
    if (pr.review === "APPROVED") return passColor
    if (pr.review === "CHANGES_REQUESTED") return failColor
    return dim
  }

  function activity(pr) {
    var e = pr.lastEvent
    return e ? e.author + " " + e.verb + " · " + root.model.ago(e.at) : repoName(pr)
  }

  function checksGlyph(pr) {
    if (pr.checks === "SUCCESS") return "󰄬"
    if (pr.checks === "FAILURE" || pr.checks === "ERROR") return "󰅖"
    if (pr.checks === "PENDING" || pr.checks === "EXPECTED") return "󰑐"
    return "󰇘"
  }

  function checksColor(pr) {
    if (pr.checks === "SUCCESS") return passColor
    if (pr.checks === "FAILURE" || pr.checks === "ERROR") return failColor
    return dim
  }

  function open(url) {
    Quickshell.execDetached(["xdg-open", url])
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
        text: "Pull requests"
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Row {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacing.lg

        Text {
          visible: root.failed
          text: "󰀦 offline"
          color: root.failColor
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.unreadCount > 0
          text: "● " + root.unreadCount + " new"
          color: Color.accent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          visible: root.mine.length > 0
          text: root.mine.length + (root.mine.length > root.maxMine ? "  ·  all 󰁔" : "")
          color: allMouse.containsMouse ? root.fg : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption

          MouseArea {
            id: allMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open("https://github.com/pulls")
          }
        }
      }
    }

    Repeater {
      model: root.mine.slice(0, root.maxMine)

      PullRow {
        id: mineRow
        required property var modelData
        glyph: root.checksGlyph(modelData)
        glyphColor: root.checksColor(modelData)
        spinning: modelData.checks === "PENDING" || modelData.checks === "EXPECTED"
        dimmed: modelData.draft
        title: modelData.title
        unread: modelData.unread
        detail: root.activity(modelData)
        statusText: root.reviewLabel(modelData)
        statusColor: root.reviewColor(modelData)
        url: modelData.url
      }
    }

    Text {
      visible: root.model !== null && root.model.feed !== null && root.mine.length === 0
      text: "No open pull requests"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }
  }

  component PullRow: Rectangle {
    id: row
    property string glyph: ""
    property color glyphColor: root.dim
    property bool spinning: false
    property bool dimmed: false
    property bool unread: false
    property string title: ""
    property string detail: ""
    property string statusText: ""
    property color statusColor: root.dim
    property string url: ""

    width: root.width
    height: 40
    radius: 8
    color: mouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08) : "transparent"
    opacity: dimmed ? 0.6 : 1

    Text {
      id: icon
      x: 6
      anchors.verticalCenter: parent.verticalCenter
      width: 18
      horizontalAlignment: Text.AlignHCenter
      text: row.glyph
      color: row.glyphColor
      font.family: root.fontFamily
      font.pixelSize: 15

      RotationAnimation on rotation {
        running: row.spinning
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 1400
        onRunningChanged: if (!running) icon.rotation = 0
      }
    }

    Text {
      id: titleText
      anchors.left: icon.right
      anchors.leftMargin: 8
      anchors.right: unreadDot.visible ? unreadDot.left : parent.right
      anchors.rightMargin: 6
      y: 4
      text: row.title
      color: root.fg
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: row.unread
      elide: Text.ElideRight
    }

    Rectangle {
      id: unreadDot
      visible: row.unread
      anchors.right: parent.right
      anchors.rightMargin: 8
      anchors.verticalCenter: titleText.verticalCenter
      width: 7
      height: 7
      radius: 3.5
      color: Color.accent
    }

    Text {
      id: detailText
      anchors.left: titleText.left
      anchors.right: status.left
      anchors.rightMargin: 6
      anchors.top: titleText.bottom
      anchors.topMargin: 1
      text: row.detail
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    Text {
      id: status
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: detailText.verticalCenter
      text: row.statusText
      color: row.statusColor
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.open(row.url)
    }
  }
}
