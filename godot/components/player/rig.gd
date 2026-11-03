class_name Rig
extends Node

var cpu:int = 1 # determines how fast a chain runs
var ram:int = 1 # determines how many chains (threads) run at once
var net:int = 1 # determines how much each successful run pays
var disk:int = 1 # determines how much offline progress is saved

var threads:Dictionary = {1:{}} # a dictionary of the 1-8 threads the handle may have available


#var REFLEXES:Dictionary = {1:{} } # a dictionary of the 4 reflex slots and their current configuration
