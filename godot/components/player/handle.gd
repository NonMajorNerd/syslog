class_name Handle
extends Node

# The player is a handle running a rig.
# Their work is building scripts, aiming them at targets, setting standing orders, and reading what happened.

var realName:String = "" 										# unique, 3 to 16 characters, chosen at first boot. Used to scan your home net.
var nickName:String = ""										# Name that appears on leaderboards, in rival logs and in chat.

var rig:Rig = Rig.new()

var rep:float = 0.0													# score. rises with raids won, raids defended and corp contributions. sets primary leaderboard rank
var credits:float = 0.0											# cash baby
var intel: float = 0.0											# earned with intel exfils, spent to scan targets, variants and layers
var heat:float = 0.0 												# 0-100 how much attention a handle is drawing. Runs add heat, time removes it.

#var clearance:int = 0 											# TBD 1-5 the highest target tier the handle has unlocked since last prestige
#var echoes: int = 0													# TBD prestige

var networks:Dictionary[int,Array] = {0:[]}			# dictionary of networks connected to, each containing an array of locked dirs unlocked
var rewards:Dictionary[int, Array] = {}					# dictionary of files for which rewards have already been collected, by network ID

func loadHandle(username:String) -> void:
	realName = username
	
	var manager:NetworkManager = Globals.gameNetworkManager
	if not manager.networkConnected.is_connected(onNetworkConnected):
		manager.networkConnected.connect(onNetworkConnected)
	
func onNetworkConnected(network:GameNetwork) -> void:
	if network == null: return
	# create base array for storing unlocked paths
	if not networks.has(network.networkID): networks[network.networkID] = []

func onPathUnlocked(network:GameNetwork, path:String) -> void:
	if network == null or path.is_empty(): return
	if not networks[network.networkID].has(path):
		networks[network.networkID] = [path]
	else: networks[network.networkID].append(path)
	
func getUnlockedPaths(networkID: int) -> Array:
	return networks.get(networkID, []).duplicate()

func hasCollectedReward(networkID: int, path: String) -> bool:
	return rewards.get(networkID, []).has(path)

func markRewardCollected(networkID: int, path: String) -> void:
	if not rewards.has(networkID): rewards[networkID] = [path]
	else: rewards[networkID].append(path)

func collectFileRewards(network: GameNetwork, path: String) -> Dictionary:
	if network == null: return {}
	if network.isLocked(path): return {}

	var node: Dictionary = network.getNode(path)

	if node.get("type") != "file": return {}

	var absolutePath: String = network.getAbsolutePath(path)

	if hasCollectedReward(network.networkID, absolutePath): return {}

	var awarded: Dictionary = node.get("rewards", {})
	if awarded.is_empty(): return {}
	#var awarded: Dictionary = rewards.duplicate(true)

	applyRewards(awarded)
	markRewardCollected(network.networkID, absolutePath)

	return awarded

func applyRewards(rw: Dictionary) -> void:
	credits += float(rw.get("credits", 0))
	intel += float(rw.get("intel", 0))
	rep += float(rw.get("rep", 0))
