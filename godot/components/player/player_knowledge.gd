class_name PlayerKnowledge
extends RefCounted

# Renders Handle-owned knowledge as the existing /sys files on homenet.
# Rig defines the directory and file nodes; this class only writes their content.
var playerHandle: Handle


func setup(handle: Handle) -> void:
  playerHandle = handle

  # Handle owns knowledge changes; resource setters separately refresh stats.
  playerHandle.knowledgeChanged.connect(refreshFiles)
  playerHandle.creditsChanged.connect(refreshStats)
  playerHandle.intelChanged.connect(refreshStats)
  playerHandle.repChanged.connect(refreshStats)
  playerHandle.heatChanged.connect(refreshStats)

  refreshFiles()


func updateFile(filename: String, content: String) -> void:
  if not playerHandle.rig.homeNet.writeFile("/sys/" + filename, content):
    push_error("Unable to update homenet /sys/" + filename)


func refreshFiles() -> void:
  refreshContacts()
  refreshNetworks()
  refreshStats()
  updateFile("log.txt", "\n".join(playerHandle.activityLog))


func refreshContacts() -> void:
  var lines: Array[String] = ["KNOWN CONTACTS", ""]
  var contacts: Array[String] = []
  contacts.assign(playerHandle.knownContacts.keys())
  contacts.sort()

  for contact in contacts:
    lines.append("%s  %s" % [contact, playerHandle.knownContacts[contact]])

  #updateFile("contacts.txt", "\n".join(lines))


func refreshNetworks() -> void:
  var lines: Array[String] = ["KNOWN NETWORKS", ""]
  var ids: Array[int] = []
  for networkID in playerHandle.networks:
    if playerHandle.networks[networkID].get("known", false): ids.append(networkID)
  ids.sort()

  for networkID in ids:
    var info: Dictionary = playerHandle.networks[networkID]
    lines.append("%s  |  Visits: %d" % [info["name"], int(info.get("visits", 0))])

  updateFile("networks.txt", "\n".join(lines))


func refreshStats() -> void:
  var knownNetworkCount: int = 0
  for info in playerHandle.networks.values():
    if info.get("known", false): knownNetworkCount += 1

  var lines: Array[String] = [
    "PLAYER STATS",
    "",
    "Credits: %s" % playerHandle.credits,
    "Intel: %s" % playerHandle.intel,
    "Rep: %s" % playerHandle.rep,
    "Heat: %s" % playerHandle.heat,
    "",
    "CPU: %0.0d" % playerHandle.rig.cpu,
    "RAM: %0.0d" % playerHandle.rig.ram,
    "NET: %0.0d" % playerHandle.rig.net,
    "DISK: %0.0d" % playerHandle.rig.disk,
    "",
    "Known networks: %0.0d" % knownNetworkCount,
    "Known contacts: %0.0d" % playerHandle.knownContacts.size(),
    "Files read: %0.0d" % playerHandle.readFiles.size()
  ]

  updateFile("stats.txt", "\n".join(lines))
