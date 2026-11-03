class_name Handle
extends Node

# The player is a handle running a rig.
# Their work is building scripts, aiming them at targets, setting standing orders, and reading what happened.

var realName:String = "" 										# unique, 3 to 16 characters, chosen at first boot. Used to scan your home net.
var nickName:String = ""										# Name that appears on leaderboards, in rival logs and in chat.

var rig:Rig

var rep:float = 0.0													# score. rises with raids won, raids defended and corp contributions. sets primary leaderboard rank
var credits:float = 0.0											# cash baby
var intel: float = 0.0											# earned with intel exfils, spent to scan targets, variants and layers
var heat:float = 0.0 												# 0-100 how much attention a handle is drawing. Runs add heat, time removes it.

var clearance:int = 0 											# TBD 1-5 the highest target tier the handle has unlocked since last prestige
var echoes: int = 0													# TBD prestige
