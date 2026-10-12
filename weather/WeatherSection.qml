import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Weather.js" as Weather

// Current conditions and a 3-day forecast from wttr.in. Uses omarchy's
// weather location when set, otherwise wttr.in's IP lookup.
Item {
  id: root

  readonly property color fg: Color.popups.text
  readonly property color dim: Qt.darker(fg, 1.55)
  readonly property string fontFamily: Style.font.family

  property string locationQuery: ""
  // Last good wttr.in j1 report; kept on failure so stale data stays visible.
  // Off: no fetching.
  property bool active: true
  property var report: null

  readonly property var current: report && report.current_condition ? report.current_condition[0] : null
  readonly property var forecast: report && report.weather ? report.weather : []
  readonly property string area: report && report.nearest_area ? report.nearest_area[0].areaName[0].value : ""
  readonly property bool night: {
    var astro = forecast.length > 0 && forecast[0].astronomy ? forecast[0].astronomy[0] : null
    if (!astro) return false
    var now = new Date()
    var mins = now.getHours() * 60 + now.getMinutes()
    return mins < Weather.clockMinutes(astro.sunrise) || mins >= Weather.clockMinutes(astro.sunset)
  }

  implicitHeight: content.implicitHeight

  onActiveChanged: refresh()

  function refresh() {
    if (!root.active) return
    fetch.command = ["curl", "-fsS", "--max-time", "10", "https://wttr.in/" + root.locationQuery + "?format=j1"]
    if (!fetch.running) fetch.running = true
  }

  function dayLabel(index, date) {
    if (index === 0) return "Today"
    return Qt.formatDate(new Date(date + "T12:00:00"), "ddd")
  }

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { root.locationQuery = Weather.locationQuery(text()); root.refresh() }
    onLoadFailed: { root.locationQuery = ""; root.refresh() }
  }

  Process {
    id: fetch
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.report = JSON.parse(text)
          retry.stop()
        } catch (e) {
          retry.restart()
        }
      }
    }
    onExited: function(code) { if (code !== 0) retry.restart() }
  }

  Timer {
    interval: 30 * 60000
    repeat: true
    running: root.active
    onTriggered: root.refresh()
  }

  Timer {
    id: retry
    interval: 2 * 60000
    onTriggered: root.refresh()
  }

  Column {
    id: content
    width: root.width
    spacing: 4

    Text {
      textFormat: Text.PlainText
      text: root.area || "Weather"
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.subtitle
    }

    Row {
      spacing: 14

      Text {
        textFormat: Text.PlainText
        anchors.verticalCenter: parent.verticalCenter
        text: root.current ? Weather.iconForCode(root.current.weatherCode, root.night) : "󰖐"
        color: root.fg
        font.family: root.fontFamily
        font.pixelSize: 44
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter

        Text {
          textFormat: Text.PlainText
          text: root.current ? root.current.temp_C + "°" : "--"
          color: root.fg
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
          font.bold: true
        }

        Text {
          textFormat: Text.PlainText
          text: root.current ? root.current.weatherDesc[0].value : "Loading…"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }
      }
    }

    Text {
      textFormat: Text.PlainText
      visible: root.current !== null
      text: root.current
        ? "Feels " + root.current.FeelsLikeC + "°  ·  󰖎 " + root.current.humidity + "%  ·  󰖝 " + root.current.windspeedKmph + " km/h"
        : ""
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    Item { width: 1; height: 8 }

    Row {
      width: parent.width

      Repeater {
        model: root.forecast

        Column {
          required property var modelData
          required property int index
          width: content.width / Math.max(1, root.forecast.length)
          spacing: 2

          Text {
            textFormat: Text.PlainText
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.dayLabel(index, modelData.date)
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            textFormat: Text.PlainText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Weather.iconForCode(modelData.hourly && modelData.hourly[4] ? modelData.hourly[4].weatherCode : 113, false)
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: 22
          }

          Text {
            textFormat: Text.PlainText
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.maxtempC + "° / " + modelData.mintempC + "°"
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
