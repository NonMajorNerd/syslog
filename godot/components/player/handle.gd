class_name Handle
extends Node

# Resource setters signal the UI
signal creditsChanged
signal heatChanged
signal intelChanged
signal repChanged
signal knowledgeChanged

var realName: String = ""
var nickName: String = ""

var rig: Rig = Rig.new()
var knowledge: PlayerKnowledge

# /sys data. each network also retains its lock/reward IDs
var knownContacts: Dictionary[String, String] = {}
var readFiles: Dictionary[String, bool] = {}
var activityLog: Array[String] = []

const MAX_LOG_ENTRIES: int = 100

var rep: float = 0.0:
  set(val):
    rep = val
    repChanged.emit()
var credits: float = 0.0:
  set(val):
    credits = val
    creditsChanged.emit()
var intel: float = 0.0:
  set(val):
    intel = val
    intelChanged.emit()
var heat: float = 0.0:
  set(val):
    heat = val
    heatChanged.emit()

# Per-network progression: unlocked lock IDs and one-time reward IDs.
var networks: Dictionary[int, Dictionary] = {
  0: {
    "locksOpened": [],
    "rewardsCollected": [],
    "known": true,
    "name": "homenet",
    "visits": 0
  }
}


func loadHandle(username: String) -> void:
  realName = username

  # Reuse the instance across sign-ons to avoid duplicate signal listeners.
  if knowledge == null:
    knowledge = PlayerKnowledge.new()
    knowledge.setup(self)

  if not Globals.gameNetworkManager.networkConnected.is_connected(onNetworkConnected):
    Globals.gameNetworkManager.networkConnected.connect(onNetworkConnected)


func ensureNetworkProgress(networkID: int) -> void:
  if networks.has(networkID): return

  # A progress entry does not mean the player has discovered the network.
  networks[networkID] = {
    "locksOpened": [],
    "rewardsCollected": [],
    "known": false,
    "name": "",
    "visits": 0
  }


func discoverNetwork(network: GameNetwork) -> void:
  if network == null: return

  ensureNetworkProgress(network.networkID)
  var record: Dictionary = networks[network.networkID]
  if record.get("known", false): return

  record["known"] = true
  record["name"] = network.networkName
  addLog("Discovered network: " + network.networkName)


func onNetworkConnected(network: GameNetwork) -> void:
  # Ignore transient disconnections and the player's own home network.
  if network == null or network == rig.homeNet: return

  discoverNetwork(network)
  var record: Dictionary = networks[network.networkID]
  record["name"] = network.networkName
  record["visits"] = int(record.get("visits", 0)) + 1
  addLog("Connected to " + network.networkName)


func discoverContact(contact: String, note: String = "") -> void:
  if contact.is_empty() or knownContacts.has(contact): return

  knownContacts[contact] = note
  addLog("Discovered contact: " + contact)


func recordFileRead(network: GameNetwork, path: String) -> void:
  if network == null or network.getNode(path).get("type") != "file": return

  var fileID: String = "%d:%s" % [network.networkID, network.getAbsolutePath(path)]
  if readFiles.has(fileID): return

  readFiles[fileID] = true
  addLog("Read file: " + fileID)


func addLog(message: String) -> void:
  activityLog.append("[%s] %s" % [Time.get_datetime_string_from_system(), message])
  #if activityLog.size() > MAX_LOG_ENTRIES: activityLog.pop_front()
  knowledgeChanged.emit() # signal PlayerKnowledge to update /sys/ entries


# GameNetwork.directoryUnlocked -> this handler, connected by NetworkManager.
func onLockUnlocked(network: GameNetwork, lockID: int) -> void:
  if network == null or lockID < 0: return
  ensureNetworkProgress(network.networkID)

  var opened: Array = networks[network.networkID]["locksOpened"]
  if not opened.has(lockID):
    opened.append(lockID)
    addLog("Unlocked directory (network %d, lock %d)" % [network.networkID, lockID])


func getUnlockedLockIDs(networkID: int) -> Array:
  ensureNetworkProgress(networkID)
  return networks[networkID]["locksOpened"].duplicate()


func hasCollectedReward(networkID: int, rewardID: int) -> bool:
  ensureNetworkProgress(networkID)
  return networks[networkID]["rewardsCollected"].has(rewardID)


func markRewardCollected(networkID: int, rewardID: int) -> void:
  if rewardID < 0: return
  ensureNetworkProgress(networkID)

  var collected: Array = networks[networkID]["rewardsCollected"]
  if not collected.has(rewardID):
    collected.append(rewardID)
    addLog("Collected reward (network %d, reward %d)" % [networkID, rewardID])


# check file, validate reward ID, pay the man, mark the reward as collected
func collectFileRewards(network: GameNetwork, path: String) -> Dictionary:
  if network == null: return {}

  var node: Dictionary = network.getNode(path)
  if node.get("type") != "file": return {}

  var definition: Variant = node.get("rewards", {})
  if not definition is Dictionary or definition.is_empty(): return {}

  var rewardID: Variant = definition.get("reward_id", null)
  if typeof(rewardID) != TYPE_INT or rewardID < 0:
    push_error("Missing or invalid reward_id: %s" % network.getAbsolutePath(path))
    return {}

  # reward can only be claimed once per network/progress record.
  if hasCollectedReward(network.networkID, rewardID): return {}

  var awarded: Dictionary = {}
  for resource in ["currency", "intel", "rep"]:
    if definition.has(resource):
      var amount: Variant = definition[resource]
      if typeof(amount) != TYPE_INT and typeof(amount) != TYPE_FLOAT:
        push_error("Invalid %s reward: %s" % [resource, network.getAbsolutePath(path)])
        return {}
      if amount < 0:
        push_error("Negative %s reward: %s" % [resource, network.getAbsolutePath(path)])
        return {}
      awarded[resource] = amount

  if awarded.is_empty(): return {}

  # Resource setters emit the signals observed by the console sidebar.
  applyRewards(awarded)
  markRewardCollected(network.networkID, rewardID)
  return awarded


func applyRewards(awarded: Dictionary) -> void:
  # Authored network reward data uses "currency" for the credits resource.
  credits += float(awarded.get("currency", 0))
  intel += float(awarded.get("intel", 0))
  rep += float(awarded.get("rep", 0))
