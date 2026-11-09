class_name CommandCompletion
extends RefCounted

static func paths(partial: String, directoriesOnly: bool = false, filesOnly: bool = false) -> Array[String]:
  var result: Array[String] = []
  if Globals.gameNetworkManager == null: return result
  var network: GameNetwork = Globals.gameNetworkManager.activeNetwork
  if network == null: return result

  var slash: int = partial.rfind("/")
  var parent: String = partial.substr(0, slash + 1) if slash >= 0 else ""
  var stem: String = partial.substr(slash + 1) if slash >= 0 else partial
  var parentPath: String = parent if not parent.is_empty() else "."

  var node: Dictionary = network.getNode(parentPath)
  if node.get("type") != "directory": return result

  for entry in node.get("children", {}):
    var child: Dictionary = node["children"][entry]

    var isDirectory: bool = child.get("type") == "directory"
    if directoriesOnly and not isDirectory: continue
    if filesOnly and isDirectory: continue

    if str(entry).begins_with(stem): result.append(parent + str(entry) + ("/" if isDirectory else ""))

  result.sort()
  return result
