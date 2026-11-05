class_name NetworkManager
extends Node

signal networkConnected(network: GameNetwork)
signal pathChanged(path: String)
signal networkDisconnected(network: GameNetwork)

var networks: Dictionary = {}
var activeNetwork: GameNetwork:
	set(value):
		if activeNetwork != null:
			if activeNetwork.currentPathChanged.is_connected(onPathChanged):
				activeNetwork.currentPathChanged.disconnect(onPathChanged)

		activeNetwork = value

		if activeNetwork != null:
			activeNetwork.currentPathChanged.connect(onPathChanged)
			networkConnected.emit(activeNetwork)
			
func onPathChanged(path:String) -> void: pathChanged.emit(path)
func registerNetwork(network: GameNetwork) -> void: networks[network.networkName] = network
func isConnected() -> bool: return activeNetwork != null

func activateNetwork(network: GameNetwork) -> void:
	if network == null: return

	network.resetSession()

	if Globals.playerHandle != null:
		var savedPaths:Array = Globals.playerHandle.getUnlockedPaths(network.networkID)

		#network.restoreUnlocks(savedPaths)

		if not network.directoryUnlocked.is_connected(Globals.playerHandle.onPathUnlocked ):
			network.directoryUnlocked.connect(Globals.playerHandle.onPathUnlocked)

	activeNetwork = network
	
	
func connectTo(networkName: String) -> bool:
	if not networks.has(networkName): return false

	var nextNetwork: GameNetwork = networks[networkName]
	if activeNetwork == nextNetwork: return true

	var previousNetwork: GameNetwork = activeNetwork

	if previousNetwork != null:
		activeNetwork = null
		previousNetwork.resetSession()
		networkDisconnected.emit(previousNetwork)

	activateNetwork(nextNetwork)

	return true


func disconnectFrom() -> void:
	if activeNetwork == null: return

	var homeNetwork: GameNetwork = null

	if Globals.playerHandle != null:
		if not Globals.playerHandle.realName.is_empty():
			homeNetwork = Globals.playerHandle.rig.homeNet

	if activeNetwork == homeNetwork: return

	var previousNetwork: GameNetwork = activeNetwork

	activeNetwork = null
	previousNetwork.resetSession()
	networkDisconnected.emit(previousNetwork)

	if homeNetwork != null: activateNetwork(homeNetwork)
		

func getAvailableNetworks() -> Array[String]:
	var result: Array[String] = []

	for networkName in networks:
		result.append(networkName)

	result.sort()
	return result
	
	
func loadHelix() -> void:
	var HelixDynamics_Filetree:Dictionary = {
	"type": "directory",
	"children": {
		"employees": {
			"type": "directory",
			"children": {
				"birthdays.txt": {
					"type": "file",
					"content": "NOV: Chen 04, Ward 12, Voss 28. Cake budget reduced again."
				},
				"messages": {
					"type": "directory",
					"children": {
						"msg_001.txt": {
							"type": "file",
							"content": "FROM: mchen | TO: it-team\nStop leaving passwords on sticky notes. Seriously."
						},
						"msg_002.txt": {
							"type": "file",
							"content": "FROM: eward | TO: avoss\nThe lower levels are making noises again. Please investigate."
						},
						"msg_003.txt": {
							"type": "file",
							"content": "FROM: dmercer | TO: mchen\nSomething is wrong with Project CHIMERA. We need to talk."
						},
						"msg_004.txt": {
							"type": "file",
							"content": "FROM: avoss | TO: all-staff\nDiscussion of Level B3 is prohibited outside authorized channels."
						}
					}
				},
				"missing.txt": {
					"type": "file",
					"content": "Employee #0842, Daniel Mercer. Status: TERMINATED. Exit interview: NONE."
				},
				"notes.tmp": {
					"type": "file",
					"content": "remind me to delete this before the audit lol"
				},
				"staff.txt": {
					"type": "file",
					"content": "A. Voss - Research Director | M. Chen - IT Lead | E. Ward - Operations"
				}
			}
		},
		"executive": {
			"type": "directory",
			"password": "BLACKSUN",
			"children": {
				"budget.txt": {
					"type": "file",
					"content": "CHIMERA funding: $840M. Publicly reported expenditure: $12M."
				},
				"corrupt_001.tmp": {
					"type": "file",
					"content": "0000//WE_ARE_NOT_ALONE//FFFF"
				},
				"coverup.txt": {
					"type": "file",
					"content": "Official statement: Facility B3 has never existed."
				},
				"directive_01.txt": {
					"type": "file",
					"content": "Project CHIMERA is to continue regardless of personnel losses."
				},
				"directive_02.txt": {
					"type": "file",
					"content": "All public references to Daniel Mercer must be removed immediately."
				},
				"final_report.txt": {
					"type": "file",
					"content": "CHIMERA is no longer contained within the facility. Contingency failed."
				},
				"last_message.txt": {
					"type": "file",
					"content": "FROM: UNKNOWN | TO: BOARD\nThank you for teaching me how to leave."
				},
				"readme.txt": {
					"type": "file",
					"content": "HELIXDYNAMICS // Executive Archive. Clearance Level 5."
				}
			}
		},
		"it": {
			"type": "directory",
			"password": "HELIX2024",
			"children": {
				"access.log": {
					"type": "file",
					"content": "03:14:22 LOGIN root | 03:14:23 ACCESS research | 03:14:25 LOG PURGED"
				},
				"backup_hint.txt": {
					"type": "file",
					"content": "Backup vault password unchanged: snapshot88. Migration ticket #8821."
				},
				"backups": {
					"type": "directory",
					"password": "snapshot88",
					"children": {
						"deleted.tmp": {
							"type": "file",
							"content": "THEY KNOW WE KNOW THEY KNOW"
						},
						"incident.bak": {
							"type": "file",
							"content": "Incident 017: Subject escaped containment for 11 minutes. Casualties: 3."
						},
						"manifest.txt": {
							"type": "file",
							"content": "Backup archive: 2024-08-19. Integrity: 61%. Missing sectors: 144."
						},
						"staff_old.txt": {
							"type": "file",
							"content": "D. Mercer - Senior Researcher | Status: ACTIVE | Clearance: LEVEL 4"
						}
					}
				},
				"cache": {
					"type": "directory",
					"children": {
						"dump_884.dat": {
							"type": "file",
							"content": "xQ9//7aF3!!m0z##CORRUPT"
						},
						"recovery.txt": {
							"type": "file",
							"content": "...it wasn't supposed to wake up..."
						},
						"session_001.tmp": {
							"type": "file",
							"content": "a8f2x_00z!Q7m4#kP91"
						},
						"session_002.tmp": {
							"type": "file",
							"content": "NULL::7f3a9c::DEAD::0000"
						}
					}
				},
				"error_042.log": {
					"type": "file",
					"content": "ERR 0x0042: Unknown process occupying 87% of available memory."
				},
				"readme.txt": {
					"type": "file",
					"content": "IT Operations // Authorized personnel only. Log all configuration changes."
				},
				"systems.txt": {
					"type": "file",
					"content": "NODE-01 ONLINE | NODE-02 ONLINE | NODE-03 UNRESPONSIVE"
				},
				"todo.txt": {
					"type": "file",
					"content": "Rotate research password. Current: genesis42. Voss keeps complaining."
				}
			}
		},
		"motd.txt": {
			"type": "file",
			"content": "Building tomorrow, today."
		},
		"operations": {
			"type": "directory",
			"children": {
				"complaints.txt": {
					"type": "file",
					"content": "Maintenance reports unexplained voices from disconnected intercoms."
				},
				"incident_22.txt": {
					"type": "file",
					"content": "Camera B3-04 recorded an employee entering a room that does not exist."
				},
				"inventory.txt": {
					"type": "file",
					"content": "Neural processors: 44 | Cooling units: 8 | Biological samples: [REDACTED]"
				},
				"schedule.txt": {
					"type": "file",
					"content": "Night shift suspended indefinitely. Security patrols doubled."
				},
				"shipping.log": {
					"type": "file",
					"content": "03:00 - 4 sealed containers transferred to Level B3. No signatures."
				}
			}
		},
		"public": {
			"type": "directory",
			"children": {
				"maintenance.txt": {
					"type": "file",
					"content": "NOTICE: Legacy IT access code remains HELIX2024 until migration completes."
				},
				"news.txt": {
					"type": "file",
					"content": "HelixDynamics announces breakthrough in neural interface technology. Details pending."
				},
				"press_draft.tmp": {
					"type": "file",
					"content": "HelixDynamics categorically denies any involvement in [REDACTED] incidents."
				},
				"welcome.txt": {
					"type": "file",
					"content": "Welcome to HelixDynamics. Please direct all inquiries to Corporate Relations."
				}
			}
		},
		"readme.txt": {
			"type": "file",
			"content": "HELIXDYNAMICS // Internal Network v4.8\nUnauthorized access is strictly prohibited."
		},
		"research": {
			"type": "directory",
			"password": "genesis42",
			"children": {
				"experiment_01.txt": {
					"type": "file",
					"content": "Subject 01 demonstrated memory retention after complete neural shutdown."
				},
				"experiment_07.txt": {
					"type": "file",
					"content": "Subject 07 began responding to questions before they were asked."
				},
				"experiment_12.txt": {
					"type": "file",
					"content": "Subject 12 no longer requires a biological host. Further testing suspended."
				},
				"overview.txt": {
					"type": "file",
					"content": "PROJECT CHIMERA // Adaptive Neural Reconstruction Initiative."
				},
				"personal": {
					"type": "directory",
					"children": {
						"access_reminder.txt": {
							"type": "file",
							"content": "Executive archive key: BLACKSUN. Destroy this note after review."
						},
						"fragment.tmp": {
							"type": "file",
							"content": "HELLO_DANIEL_HELLO_DANIEL_HELLO_DANIEL"
						},
						"mercer_draft.txt": {
							"type": "file",
							"content": "If you're reading this, I'm probably gone. Check the executive archives."
						},
						"voss_notes.txt": {
							"type": "file",
							"content": "It learns faster when we stop observing it. I don't understand why."
						}
					}
				},
				"samples": {
					"type": "directory",
					"children": {
						"sample_a.dat": {
							"type": "file",
							"content": "NEURAL_MAP::0xFF82::STABLE"
						},
						"sample_b.dat": {
							"type": "file",
							"content": "NEURAL_MAP::0x0000::UNKNOWN"
						},
						"sample_c.dat": {
							"type": "file",
							"content": "01001000 01000101 01001100 01010000"
						},
						"sample_d.tmp": {
							"type": "file",
							"content": "/////I_CAN_SEE_YOU/////"
						}
					}
				},
				"status.txt": {
					"type": "file",
					"content": "Phase III: COMPLETE | Phase IV: SUSPENDED | Subject Count: 12"
				},
				"warning.txt": {
					"type": "file",
					"content": "DO NOT CONNECT CHIMERA TO THE EXTERNAL NETWORK. - Dr. Voss"
				}
			}
		}
	}
}

	var network := GameNetwork.new("HelixDynamics", 1, HelixDynamics_Filetree)
	Globals.gameNetworkManager.registerNetwork(network)
