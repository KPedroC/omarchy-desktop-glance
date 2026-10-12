.pragma library

function findPlayer(players) {
  for (var i = 0; i < players.length; i++)
    if (String(players[i].dbusName || "").indexOf("spotify") !== -1) return players[i]
  return null
}
