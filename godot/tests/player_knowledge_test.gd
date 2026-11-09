extends SceneTree

# Run with Godot headless: --headless --path godot --script res://tests/player_knowledge_test.gd
func _initialize() -> void:
  Globals.gameNetworkManager = NetworkManager.new()

  var handle: Handle = Handle.new()
  Globals.playerHandle = handle
  handle.loadHandle("tester")

  var home: GameNetwork = handle.rig.homeNet
  var sysFiles: Dictionary = home.getNode("/sys")["children"]
  for filename in ["contacts.txt", "log.txt", "networks.txt", "stats.txt"]:
    assert(sysFiles.has(filename))
    assert(sysFiles[filename]["type"] == "file")

  assert(home.readFile("/sys/stats.txt").contains("Known networks: 1"))
  assert(handle.networks[0]["known"])
  assert(handle.networks[0]["locksOpened"].is_empty())

  var external: GameNetwork = GameNetwork.new("TestHost", 5, {
    "type": "directory",
    "children": {
      "secret": {
        "type": "directory",
        "password": "123",
        "lock_id": 7,
        "children": {}
      },
      "clue.txt": {
        "type": "file",
        "content": "Clue",
        "rewards": {"reward_id": 2, "currency": 10}
      }
    }
  })
  Globals.gameNetworkManager.registerNetwork(external)

  # Progress entries can exist before the player discovers a network.
  handle.ensureNetworkProgress(5)
  assert(not handle.networks[5]["known"])
  handle.discoverNetwork(external)
  assert(handle.networks[5]["known"])
  assert(handle.networks[5]["visits"] == 0)

  Globals.gameNetworkManager.activateNetwork(external)
  assert(handle.networks[5]["visits"] == 1)
  assert(home.readFile("/sys/networks.txt").contains("TestHost  |  Visits: 1"))
  Globals.gameNetworkManager.activateNetwork(external)
  assert(handle.networks[5]["visits"] == 2)

  handle.recordFileRead(external, "/clue.txt")
  handle.recordFileRead(external, "/clue.txt")
  assert(handle.readFiles.size() == 1)
  assert(home.readFile("/sys/stats.txt").contains("Files read: 1"))

  var rewards: Dictionary = handle.collectFileRewards(external, "/clue.txt")
  assert(rewards["currency"] == 10)
  assert(handle.credits == 10.0)
  assert(handle.networks[5]["rewardsCollected"] == [2])
  assert(handle.collectFileRewards(external, "/clue.txt").is_empty())
  assert(home.readFile("/sys/stats.txt").contains("Credits: 10"))

  assert(external.unlock("/secret", "123"))
  assert(handle.networks[5]["locksOpened"] == [7])
  assert(home.readFile("/sys/log.txt").contains("Unlocked directory"))

  handle.discoverContact("ECHO", "Known contact")
  assert(home.readFile("/sys/contacts.txt").contains("ECHO  Known contact"))
  handle.loadHandle("tester")
  Globals.gameNetworkManager.activateNetwork(external)
  assert(handle.networks[5]["visits"] == 3)

  for n in range(Handle.MAX_LOG_ENTRIES + 10):
    handle.addLog("event %d" % n)
  assert(handle.activityLog.size() == Handle.MAX_LOG_ENTRIES)
  assert(home.readFile("/sys/log.txt").contains("event 109"))
  print("Player knowledge tests passed.")
  quit()
