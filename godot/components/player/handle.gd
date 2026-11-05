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

func onNetworkConnected(network:GameNetwork) -> void:
	if not network: return
	if not networks.keys().has(network.networkID): networks[network.networkID] = []

func onPathUnlocked(network:GameNetwork, path:String) -> void:
	if not network or not path: return
	if not networks.keys().has(network.networkID): networks[network.networkID] = [path]
	else: networks[network.networkID].append(path)
	
func loadHandle(username:String) -> void:
	if not username: return
	
	realName = username
	
	Globals.gameNetworkManager.connect("networkConnected", onNetworkConnected)
	
