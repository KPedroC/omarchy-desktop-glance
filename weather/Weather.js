.pragma library

// wttr.in weather code → nerd-font glyph (same mapping as omarchy.weather).
function iconForCode(code, night) {
  var c = parseInt(String(code || "0"), 10)
  switch (c) {
    case 113: return night ? "" : ""
    case 116: return night ? "" : ""
    case 119: case 122: return ""
    case 143: case 248: case 260: return night ? "\ue346" : "\ue313"
    case 176: case 263: case 353: return night ? "" : ""
    case 179: case 227: case 230: case 323: case 326: case 368: return night ? "" : ""
    case 182: case 185: case 281: case 284: case 311: case 314:
    case 317: case 320: case 350: case 362: case 365: case 374: case 377: return ""
    case 200: case 386: case 389: case 392: case 395: return ""
    case 266: case 293: case 296: case 299: case 302: case 305: case 308: case 356: case 359: return ""
    case 329: case 332: case 335: case 338: case 371: return ""
    default: return ""
  }
}

// Location query from omarchy's weather.json: coordinates, name, or empty for IP auto-detect.
function locationQuery(raw) {
  try {
    var data = JSON.parse(String(raw || ""))
    var lat = parseFloat(String(data.latitude))
    var lon = parseFloat(String(data.longitude))
    if (!isNaN(lat) && !isNaN(lon)) return lat + "," + lon
    var name = String(data.name || "").trim()
    return name === "" ? "" : encodeURIComponent(name)
  } catch (e) {
    return ""
  }
}

// "06:43 PM" → minutes since midnight.
function clockMinutes(text) {
  var m = /(\d+):(\d+)\s*(AM|PM)/i.exec(String(text || ""))
  if (!m) return -1
  var h = parseInt(m[1], 10) % 12 + (m[3].toUpperCase() === "PM" ? 12 : 0)
  return h * 60 + parseInt(m[2], 10)
}
