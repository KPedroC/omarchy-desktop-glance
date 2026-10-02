import QtQuick
import Quickshell
import qs.Commons

// Open pull requests: ones waiting on your review, then your own with their
// review state and checks. Click a row to open it.
Item {
  id: root

  property var model: null
  property int maxReview: 3
  property int maxMine: 4

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property color passColor: Color.accent
  readonly property color failColor: Color.urgent
  readonly property string fontFamily: Style.font.family

  readonly property var review: model ? model.reviewPulls : []
  readonly property var mine: model ? model.myPulls : []
  readonly property bool failed: model !== null && model.errors.some(function(e) { return e.repo === "pull requests" })

  implicitHeight: content.implicitHeight

  function repoName(pr) {
    return pr.repo.split("/")[1] + "#" + pr.number
  }

  function reviewLabel(pr) {
    if (pr.draft) return "Draft"
    if (pr.review === "APPROVED") return "Approved"
    if (pr.review === "CHANGES_REQUESTED") return "Changes requested"
    if (pr.review === "REVIEW_REQUIRED") return "Awaiting review"
    return "Open"
  }

  function reviewColor(pr) {
    if (pr.draft) return dim
    if (pr.review === "APPROVED") return passColor
    if (pr.review === "CHANGES_REQUESTED") return failColor
    return dim
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

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.failed
        text: "󰀦 offline"
        color: root.failColor
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    GroupHeader {
      visible: root.review.length > 0
      label: "Needs your review"
      count: root.review.length
      limit: root.maxReview
      url: "https://github.com/pulls/review-requested"
    }

    Repeater {
      model: root.review.slice(0, root.maxReview)

      PullRow {
        required property var modelData
        glyph: "󰳏"
        glyphColor: Color.accent
        title: modelData.title
        detail: root.repoName(modelData) + "  ·  " + modelData.author + "  ·  " + root.model.ago(modelData.createdAt)
        url: modelData.url
      }
    }

    GroupHeader {
      visible: root.mine.length > 0
      label: "Yours"
      count: root.mine.length
      limit: root.maxMine
      url: "https://github.com/pulls"
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
        detail: root.repoName(modelData)
        statusText: root.reviewLabel(modelData)
        statusColor: root.reviewColor(modelData)
        url: modelData.url
      }
    }

    Text {
      visible: root.model !== null && root.model.feed !== null && root.review.length === 0 && root.mine.length === 0
      text: "No open pull requests"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
    }
  }

  // "Needs your review · 2" with a "+N more" link when the list is cut short.
  component GroupHeader: Item {
    id: group
    property string label: ""
    property int count: 0
    property int limit: 0
    property string url: ""

    width: root.width
    height: 22

    Text {
      anchors.bottom: parent.bottom
      text: group.label
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    Text {
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.bottom: parent.bottom
      text: group.count + (group.count > group.limit ? "  ·  all 󰁔" : "")
      color: moreMouse.containsMouse ? root.fg : root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption

      MouseArea {
        id: moreMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open(group.url)
      }
    }
  }

  component PullRow: Rectangle {
    id: row
    property string glyph: ""
    property color glyphColor: root.dim
    property bool spinning: false
    property bool dimmed: false
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
      anchors.right: parent.right
      anchors.rightMargin: 6
      y: 4
      text: row.title
      color: root.fg
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
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
