class_name Rig
extends Node

var cpu: int = 1
var ram: int = 1
var net: int = 1
var disk: int = 1

var threads: Dictionary = {1: {}}

var homeFiletree: Dictionary = {
  "type": "directory",
  "children": {
      "documents": {
        "children": {
          "commands.txt": {
            "content": "Try 'ls' to list files, 'cd' to change directories, and 'cat' to read files.",
            "type": "file"
          },
          "notes.txt": {
            "content": "New terminal setup complete. Time to see what's out there.",
            "type": "file"
          }
        },
        "type": "directory"
      },
      "downloads": {
        "children": {
          "packet_001.tmp": {
            "content": "0xFF82::7a91##NULL",
            "type": "file"
          },
          "readme.txt": {
            "content": "Network utilities installed successfully.",
            "type": "file"
          }
        },
        "type": "directory"
      },
      "password_hint.txt": {
        "content": "Private folder PIN: 1234. I should really change that.",
        "type": "file"
      },
      "private": {
        "children": {
          "journal.txt": {
            "content": "First day online. Everyone starts somewhere.",
            "type": "file"
          }
        },
        "lock_id": 0,
        "password": "1234",
        "type": "directory"
      },
      "sys": {
        "children": {
          "log.txt": {
            "content": "",
            "type": "file"
          },
          "networks.txt": {
            "content": "",
            "type": "file"
          },
          "stats.txt": {
            "content": "",
            "type": "file"
          }
        },
        "type": "directory"
      },
      "todo.txt": {
        "content": "1. Explore your files.\n2. Connect to your first external network.",
        "type": "file"
      },
      "welcome.txt": {
        "content": "Welcome to your personal terminal.\nYour system is online and ready.",
        "type": "file"
      }
    }
}

# This local network becomes active after successful sign-on.
var homeNet: GameNetwork = GameNetwork.new("homenet", 0, homeFiletree)
