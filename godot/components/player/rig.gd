class_name Rig
extends Node

var cpu:int = 1 # determines how fast a chain runs
var ram:int = 1 # determines how many chains (threads) run at once
var net:int = 1 # determines how much each successful run pays
var disk:int = 1 # determines how much offline progress is saved

var threads:Dictionary = {1:{}} # a dictionary of the 1-8 threads the handle may have available

var homeFiletree:Dictionary = {
	"type": "directory",
	"children": {
		"welcome.txt": {
			"type": "file",
			"content": "Welcome to your personal terminal.\nYour system is online and ready."
		},
		"todo.txt": {
			"type": "file",
			"content": "1. Explore your files.\n2. Connect to your first external network."
		},
		"documents": {
			"type": "directory",
			"children": {
				"notes.txt": {
					"type": "file",
					"content": "New terminal setup complete. Time to see what's out there."
				},
				"commands.txt": {
					"type": "file",
					"content": "Try 'ls' to list files, 'cd' to change directories, and 'cat' to read files."
				},
				"contacts.txt": {
					"type": "file",
					"content": "ECHO - Unknown contact. Says they have work for me."
				}
			}
		},
		"downloads": {
			"type": "directory",
			"children": {
				"readme.txt": {
					"type": "file",
					"content": "Network utilities installed successfully."
				},
				"packet_001.tmp": {
					"type": "file",
					"content": "0xFF82::7a91##NULL"
				}
			}
		},
		"private": {
			"type": "directory",
			"password": "1234",
			"children": {
				"journal.txt": {
					"type": "file",
					"content": "First day online. Everyone starts somewhere."
				}
			}
		},
		"password_hint.txt": {
			"type": "file",
			"content": "Private folder PIN: 1234. I should really change that."
		}
	}
}

var homeNet:GameNetwork = GameNetwork.new("homenet", 0, homeFiletree)

#var REFLEXES:Dictionary = {1:{} } # a dictionary of the 4 reflex slots and their current configuration
