class_name NetworkManager
extends Node

# UI listens for connections and path changes; Handle listens for unlocks.
signal networkConnected(network: GameNetwork)
signal pathChanged(path: String)
signal networkDisconnected(network: GameNetwork)

var networks: Dictionary = {}
var activeNetwork: GameNetwork:
  # Rewire the path signal when switching active networks to avoid stale notifications
  set(value):
    # disconnect current signal
    if activeNetwork != null and activeNetwork.currentPathChanged.is_connected(onPathChanged):
      activeNetwork.currentPathChanged.disconnect(onPathChanged)
      
    # assign new network, connect new signal
    activeNetwork = value
    if activeNetwork != null:
      if not activeNetwork.currentPathChanged.is_connected(onPathChanged):
        activeNetwork.currentPathChanged.connect(onPathChanged)
        
    # rebuild prompt
    networkConnected.emit(activeNetwork)


# GameNetwork.currentPathChanged -> NetworkManager.pathChanged -> console UI.
func onPathChanged(path: String) -> void:
  pathChanged.emit(path)


func registerNetwork(network: GameNetwork) -> void:
  print("register; " + str(network))
  if network == null: return

  for registeredName in networks:
    var registered: GameNetwork = networks[registeredName]
    if registered.networkID == network.networkID and registered != network:
      push_error("Duplicate network ID %s" % network.networkID)
      return

  networks[network.networkName] = network


func isConnected() -> bool:
  return activeNetwork != null


func getAvailableNetworks() -> Array[String]:
  var result: Array[String] = []
  for networkName in networks:
    result.append(networkName)
  result.sort()
  return result


# Disconnect the old session first, then activate the requested network.
func connectTo(networkName: String) -> bool:
  print("%s .... %s" %[networkName, str(networks)])
  if not networks.has(networkName): return false

  var nextNetwork: GameNetwork = networks[networkName]
  if activeNetwork == nextNetwork: return true

  var previousNetwork: GameNetwork = activeNetwork
  if previousNetwork != null:
    activeNetwork = null
    # Reset transient directory state; player unlock progress remains in Handle.
    previousNetwork.resetSession()
    networkDisconnected.emit(previousNetwork)

  activateNetwork(nextNetwork)
  return true


# Activation restores recorded locks before publishing networkConnected.
func activateNetwork(network: GameNetwork) -> void:
  if network == null: return

  network.resetSession()

  if Globals.playerHandle != null:
    var handle: Handle = Globals.playerHandle
    handle.ensureNetworkProgress(network.networkID)
    network.restoreUnlocks(handle.getUnlockedLockIDs(network.networkID))

    # Unlock events are forwarded directly to Handle; do not connect twice.
    if not network.directoryUnlocked.is_connected(handle.onLockUnlocked): network.directoryUnlocked.connect(handle.onLockUnlocked)

  activeNetwork = network


# Disconnecting from an external host returns to the authenticated home net.
func disconnectFrom() -> void:
  if activeNetwork == null: return

  var homeNetwork: GameNetwork = null
  if Globals.playerHandle != null and not Globals.playerHandle.realName.is_empty(): homeNetwork = Globals.playerHandle.rig.homeNet

  if activeNetwork == homeNetwork: return

  var previousNetwork: GameNetwork = activeNetwork
  activeNetwork = null
  previousNetwork.resetSession()
  networkDisconnected.emit(previousNetwork)

  if homeNetwork != null: activateNetwork(homeNetwork)

# Validate authored JSON before constructing a live GameNetwork instance.
func loadNetworkJson(path: String) -> void:
  if not FileAccess.file_exists(path):
    push_error("Network JSON not found: " + path)
    return

  var file: FileAccess = FileAccess.open(path, FileAccess.READ)
  if file == null:
    push_error("Failed to open network JSON: " + path)
    return

  var parsed: Variant = JSON.parse_string(file.get_as_text())
  file.close()

  if not parsed is Dictionary:
    push_error("Invalid network JSON: " + path)
    return

  if not parsed.has("name") or not parsed.has("id") or not parsed.has("root"):
    push_error("Missing network name/id/root: " + path)
    return

  if not isValidID(parsed["id"]):
    push_error("Invalid network ID: " + path)
    return

  if not parsed["root"] is Dictionary:
    push_error("Invalid network root: " + path)
    return

  # Convert numeric IDs to integers.
  parsed["id"] = int(parsed["id"])

  # JSON numbers may deserialize as floats; lock/reward IDs need integers.
  if not normalizeNodeIDs(parsed["root"]):
    push_error("Invalid lock or reward ID in network: " + path)
    return

  var network: GameNetwork = GameNetwork.new(
    str(parsed["name"]),
    parsed["id"],
    parsed["root"]
  )

  registerNetwork(network)


func isValidID(value: Variant) -> bool:
  if typeof(value) == TYPE_INT: return value >= 0

  if typeof(value) == TYPE_FLOAT: return is_finite(value) and value >= 0.0 and value == floor(value) and value < 9223372036854775808.0

  return false


# Walk the entire tree, normalizing IDs used to track unlocks and rewards.
func normalizeNodeIDs(node: Dictionary) -> bool:
  if node.has("lock_id"):
    if not isValidID(node["lock_id"]): return false
    node["lock_id"] = int(node["lock_id"])

  if node.has("rewards"):
    var rewards: Dictionary = node["rewards"]

    if rewards.has("reward_id"):
      if not isValidID(rewards["reward_id"]): return false
      rewards["reward_id"] = int(rewards["reward_id"])

  if node.get("type") == "directory":
    var children: Dictionary = node.get("children", {})

    for child in children.values():
      if not child is Dictionary: return false

      if not normalizeNodeIDs(child): return false

  return true
