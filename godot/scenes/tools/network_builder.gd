extends PanelContainer

# SETUP AND DATA
@onready var txtNetworkName: LineEdit = $HBoxContainer2/vboxNetwork/PanelContainer2/VBoxContainer/HBoxContainer/txtNetworkName
@onready var txtNetworkID: LineEdit = $HBoxContainer2/vboxNetwork/PanelContainer2/VBoxContainer/HBoxContainer2/txtNetworkID
@onready var networkTree: Tree = $HBoxContainer2/vboxNetwork/Tree

@onready var optType: OptionButton = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer/optType
@onready var txtName: LineEdit = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer5/txtName
@onready var txtLockID: LineEdit = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer7/txtLockID
@onready var txtPassword: LineEdit = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer8/txtPassword
@onready var txtContent: TextEdit = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer2/txtContent
@onready var txtRewardsID: LineEdit = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer3/VBoxContainer/HBoxContainer4/txtRewardID
@onready var txtRewardsCurrency: LineEdit = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer3/VBoxContainer/HBoxContainer2/txtRewardCurrency
@onready var txtRewardsIntel: LineEdit = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer3/VBoxContainer/HBoxContainer3/txtRewardIntel
@onready var txtChildren: TextEdit = $HBoxContainer2/PanelContainer/vboxNode/HBoxContainer4/txtChildren

var networkData: Dictionary = {}
var currentFilePath: String = ""
var pendingDeletePath: String = ""
var pendingMovePath: String = ""
var deleteDialog: ConfirmationDialog
var moveDialog: ConfirmationDialog
var moveDestinationOption: OptionButton


# Bind file/tree selection events and create confirmation dialogs in code.
func _ready() -> void:
  # FileDialog.file_selected passes its chosen path to load/save directly.
  $fdSave.file_selected.connect(saveNetworkJson)
  $fdLoad.file_selected.connect(loadNetworkJson)
  networkTree.item_selected.connect(onTreeItemSelected)

  # create dialogs and popups for delete and move
  deleteDialog = ConfirmationDialog.new()
  deleteDialog.title = "Delete directory"
  # Confirmations act on pendingDeletePath, not whatever is now selected.
  deleteDialog.confirmed.connect(confirmDelete)
  add_child(deleteDialog)

  moveDialog = ConfirmationDialog.new()
  moveDialog.title = "Move node"
  # Move confirmation uses pendingMovePath and the chosen destination.
  moveDialog.confirmed.connect(confirmMove)
  moveDestinationOption = OptionButton.new()
  moveDestinationOption.custom_minimum_size.x = 420
  moveDestinationOption.custom_minimum_size.y = 65
  moveDialog.add_child(moveDestinationOption)
  add_child(moveDialog)

  updateEditorFields()
  clearEditor()

# FILE OPERATIONS
# Parse -> validate -> normalize IDs -> replace editor data -> rebuild tree.
func loadNetworkJson(path: String) -> bool:
  var file: FileAccess = FileAccess.open(path, FileAccess.READ)
  if file == null:
    push_error("Could not open network: %s (error %s)" % [path, FileAccess.get_open_error()])
    return false

  var parser: JSON = JSON.new()
  var result: Error = parser.parse(file.get_as_text())
  file.close()
  if result != OK:
    push_error("Invalid JSON at line %s: %s" % [parser.get_error_line(), parser.get_error_message()])
    return false

  var data: Variant = parser.data
  if not data is Dictionary:
    push_error("Network JSON must contain a dictionary.")
    return false
  if not validateNetworkData(data): return false

  normalizeNetworkData(data)
  networkData = data
  currentFilePath = path
  txtNetworkName.text = str(networkData.get("name", ""))
  txtNetworkID.text = str(networkData["id"])
  refreshTree()
  return true

# Validate current inspector/network before writing JSON
func saveNetworkJson(path: String) -> void:
  if not updateNetworkDetails(): return
  if not validateNetworkData(networkData): return

  normalizeNetworkData(networkData)

  var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
  if file == null:
    push_error("Could not save network: %s (error %s)" % [path, FileAccess.get_open_error()])
    return

  file.store_string(JSON.stringify(networkData, "\t"))
  file.flush()
  var writeError: Error = file.get_error()
  file.close()

  if writeError != OK:
    push_error("Could not finish writing network: %s (error %s)" % [path, writeError])
    return

  currentFilePath = path
  refreshTree(getSelectedPath())

func updateNetworkDetails() -> bool:
  var networkName: String = txtNetworkName.text.strip_edges()
  var networkID: String = txtNetworkID.text.strip_edges()
  if networkData.is_empty():
    push_error("Create or load a network first.")
    return false
  if networkName.is_empty():
    push_error("Network name is required.")
    return false
  if not validateIntegerField(networkID, "Network ID", true): return false

  networkData["name"] = networkName
  networkData["id"] = int(networkID)
  return true

func isIntegralNumber(value: Variant) -> bool:
  if value is int: return true
  if value is float: return is_finite(value) and value == floor(value) and value >= -9223372036854775808.0 and value < 9223372036854775808.0
  return false

func validateIntegerField(value: String, fieldName: String, required: bool = false) -> bool:
  var cleanValue: String = value.strip_edges()
  if cleanValue.is_empty() and not required: return true
  if not cleanValue.is_valid_int():
    push_error("%s must be an integer." % fieldName)
    return false
  return true

# Validate recursively before load or save
func validateNetworkData(data: Dictionary) -> bool:
  if not data.get("name") is String or str(data.get("name", "")).strip_edges().is_empty():
    push_error("Network must have a nonempty name.")
    return false
  if not data.has("id") or not isIntegralNumber(data["id"]):
    push_error("Network ID must be an integer.")
    return false

  var root: Variant = data.get("root", null)
  if not root is Dictionary or root.get("type") != "directory":
    push_error("Network must contain a root directory.")
    return false
  return validateDirectory(root, "/")

func validateDirectory(directory: Dictionary, path: String) -> bool:
  if directory.has("lock_id") and not isIntegralNumber(directory["lock_id"]):
    push_error("Invalid lock_id at: " + path)
    return false
  if directory.has("password") and not directory["password"] is String:
    push_error("Invalid password at: " + path)
    return false

  var children: Variant = directory.get("children", {})
  if not children is Dictionary:
    push_error("Invalid children dictionary at: " + path)
    return false

  for nodeName in children:
    if not nodeName is String or not isValidName(nodeName):
      push_error("Invalid node name in: " + path)
      return false
    var nodePath: String = joinPath(path, nodeName)
    var node: Variant = children[nodeName]
    if not node is Dictionary:
      push_error("Invalid node at: " + nodePath)
      return false

    match node.get("type"):
      "directory":
        if not validateDirectory(node, nodePath): return false
      "file":
        if node.has("content") and not node["content"] is String:
          push_error("Invalid file content at: " + nodePath)
          return false
        if node.has("rewards"):
          if not node["rewards"] is Dictionary:
            push_error("Rewards must be a dictionary at: " + nodePath)
            return false
          for rewardKey in ["reward_id", "currency", "intel"]:
            if node["rewards"].has(rewardKey) and not isIntegralNumber(node["rewards"][rewardKey]):
              push_error("Invalid %s at: %s" % [rewardKey, nodePath])
              return false
      _:
        push_error("Unknown node type at: " + nodePath)
        return false
  return true

# normalize IDs to integers
func normalizeNetworkData(data: Dictionary) -> void:
  data["id"] = int(data["id"])
  normalizeDirectory(data["root"])

func normalizeDirectory(directory: Dictionary) -> void:
  if directory.has("lock_id"): directory["lock_id"] = int(directory["lock_id"])
  for node in directory.get("children", {}).values():
    if node.get("type") == "directory":
      normalizeDirectory(node)
    elif node.get("type") == "file" and node.has("rewards"):
      for rewardKey in ["reward_id", "currency", "intel"]:
        if node["rewards"].has(rewardKey): node["rewards"][rewardKey] = int(node["rewards"][rewardKey])

# TREE VISUALIZATION
func refreshTree(selectedPath: String = "/") -> void: buildNetworkTree(selectedPath)

# Rebuilding a Tree loses UI state: remember collapsed paths and reselect the
# previous node so editing does not jump back to the root.
func buildNetworkTree(selectedPath: String = "/") -> void:
  var collapsedPaths: Array[String] = []
  var oldRoot: TreeItem = networkTree.get_root()
  if oldRoot != null: collectCollapsedPaths(oldRoot, collapsedPaths)
  networkTree.clear()

  var rootNode: Dictionary = networkData.get("root", {})
  if rootNode.get("type") != "directory":
    clearEditor()
    return

  var rootItem: TreeItem = networkTree.create_item()
  rootItem.set_text(0, "[#] " + str(networkData.get("name", "Network")))
  # Absolute paths in TreeItem metadata are the link to networkData nodes.
  rootItem.set_metadata(0, "/")
  addTreeChildren(rootItem, rootNode, "/", collapsedPaths)
  rootItem.collapsed = "/" in collapsedPaths

  var selectedItem: TreeItem = findTreeItem(rootItem, selectedPath)
  if selectedItem == null: selectedItem = rootItem
  selectedItem.select(0)
  onTreeItemSelected()

# Recursively mirror the authored dictionary without copying node data.
func addTreeChildren(parentItem: TreeItem, parentNode: Dictionary, parentPath: String, collapsedPaths: Array[String]) -> void:
  var children: Dictionary = parentNode.get("children", {})
  var names: Array = children.keys()
  names.sort()

  for nodeName in names:
    var node: Dictionary = children[nodeName]
    var nodePath: String = joinPath(parentPath, nodeName)
    var locked: bool = false
    var itemText: String = ""
    var item: TreeItem = networkTree.create_item(parentItem)
    item.set_metadata(0, nodePath)

    match node.get("type", ""):
      "directory":
        locked = not str(node.get("password", "")).is_empty() or not str(node.get("lock_id", "")).is_empty()
        itemText = ("[!] " if locked else "[#] ") + nodeName
        addTreeChildren(item, node, nodePath, collapsedPaths)
        item.collapsed = nodePath in collapsedPaths
      "file":
        itemText = "[~] %s" % nodeName
      _:
        itemText = "[?] %s" % nodeName

    # Mark reward-bearing files in the editor
    if hasRewards(node): itemText += " ($$)"

    item.set_text(0, itemText)


# Retain expansion state across node edits and tree refreshes.
func collectCollapsedPaths(item: TreeItem, paths: Array[String]) -> void:
  if item.collapsed: paths.append(str(item.get_metadata(0)))
  var child: TreeItem = item.get_first_child()
  while child != null:
    collectCollapsedPaths(child, paths)
    child = child.get_next()


func findTreeItem(item: TreeItem, path: String) -> TreeItem:
  if item == null: return null
  if str(item.get_metadata(0)) == path: return item

  var child: TreeItem = item.get_first_child()
  while child != null:
    var found: TreeItem = findTreeItem(child, path)
    if found != null: return found
    child = child.get_next()
  return null


func hasRewards(node: Dictionary) -> bool:
  var rewards: Dictionary = node.get("rewards", {})
  return not rewards.is_empty()

# INSPECTOR
func clearEditor() -> void:
  txtName.clear()
  txtLockID.clear()
  txtPassword.clear()
  txtContent.clear()
  txtRewardsID.clear()
  txtRewardsCurrency.clear()
  txtRewardsIntel.clear()
  txtChildren.clear()

# Tree.item_selected -> onTreeItemSelected() -> loadEditor().
func loadEditor(data: Dictionary) -> void:
  clearEditor()
  if data.is_empty():
    updateEditorFields()
    return

  var path: String = getSelectedPath()
  txtName.text = str(networkData.get("name", "Network")) if path == "/" else getNodeName(path)
  optType.select(0 if data.get("type") == "directory" else 1)
  txtLockID.text = str(int(data["lock_id"])) if data.has("lock_id") else ""
  txtPassword.text = str(data.get("password", ""))
  txtContent.text = str(data.get("content", ""))

  var rewards: Dictionary = data.get("rewards", {})
  txtRewardsID.text = str(int(rewards["reward_id"])) if rewards.has("reward_id") else ""
  txtRewardsCurrency.text = str(int(rewards["currency"])) if rewards.has("currency") else ""
  txtRewardsIntel.text = str(int(rewards["intel"])) if rewards.has("intel") else ""
  txtChildren.text = str(data.get("children", {})) if data.has("children") else ""
  updateEditorFields()

func updateEditorFields() -> void:
  var isDirectory: bool = optType.get_item_text(optType.selected) == "directory" if optType.selected >= 0 else false
  txtLockID.editable = isDirectory
  txtPassword.editable = isDirectory
  txtContent.editable = not isDirectory
  txtRewardsID.editable = not isDirectory
  txtRewardsCurrency.editable = not isDirectory
  txtRewardsIntel.editable = not isDirectory
  txtChildren.editable = false

func validateRewardInputs() -> bool:
  if not validateIntegerField(txtRewardsID.text, "Reward ID"): return false
  if not validateIntegerField(txtRewardsCurrency.text, "Currency"): return false
  if not validateIntegerField(txtRewardsIntel.text, "Intel"): return false
  return true

func getEditorRewards() -> Dictionary:
  var rewards: Dictionary = {}
  if not txtRewardsID.text.is_empty(): rewards["reward_id"] = int(txtRewardsID.text)
  if not txtRewardsCurrency.text.is_empty(): rewards["currency"] = int(txtRewardsCurrency.text)
  if not txtRewardsIntel.text.is_empty(): rewards["intel"] = int(txtRewardsIntel.text)
  return rewards

# Apply inspector edits to existing dictionary; keep selection after refresh.
func saveSelectedNode() -> void:
  var path: String = getSelectedPath()
  var node: Dictionary = getSelectedNode()
  if node.is_empty(): return
  if path != "/" and not isValidName(txtName.text):
    push_error("Invalid node name.")
    return
  if (node.get("type") == "directory") != (optType.text == "directory"):
    push_error("Node types cannot be changed after creation.")
    return
  if node.get("type") == "file" and not validateRewardInputs(): return
  if node.get("type") == "directory" and not validateIntegerField(txtLockID.text, "Lock ID"): return

  var newPath: String = path
  if path == "/":
    if txtName.text.strip_edges().is_empty():
      push_error("Network name cannot be empty.")
      return
    networkData["name"] = txtName.text.strip_edges()
    txtNetworkName.text = str(networkData["name"])
  # Rename without refreshing; other fields still need to save
  elif txtName.text != getNodeName(path):
    if not renameNode(path, txtName.text, false): return
    newPath = joinPath(getParentPath(path), txtName.text)

  match node.get("type"):
    "directory":
      if txtLockID.text.strip_edges().is_empty(): node.erase("lock_id")
      else: node["lock_id"] = int(txtLockID.text.strip_edges())
      if txtPassword.text.is_empty(): node.erase("password")
      else: node["password"] = txtPassword.text
    "file":
      node["content"] = txtContent.text
      #var rewards: Dictionary = node.get("rewards", {}).duplicate(true)
      #for rewardKey in ["reward_id", "currency", "intel"]: rewards.erase(rewardKey)
      #rewards.merge(getEditorRewards(), true)
      #if rewards.is_empty(): node.erase("rewards")
      #else: 
      node["rewards"] = getEditorRewards()

  refreshTree(newPath)

# PATH AND NODE LOOKUP
func joinPath(parentPath: String, nodeName: String) -> String:
  if parentPath == "/": return "/" + nodeName
  return parentPath + "/" + nodeName

func getParentPath(path: String) -> String:
  if path == "/": return "/"
  return path.get_base_dir()

func getNodeName(path: String) -> String: return path.get_file()

func isValidName(nodeName: String) -> bool:
  if nodeName.is_empty() or nodeName == "." or nodeName == "..": return false
  if "/" in nodeName or "\\" in nodeName: return false
  return true

func isValidPath(path: String) -> bool:
  if path == "/": return true
  if not path.begins_with("/") or path.ends_with("/") or "//" in path: return false
  for part in path.split("/", false):
    if not isValidName(part): return false
  return true

func getNode(path: String) -> Dictionary:
  if networkData.is_empty() or not isValidPath(path): return {}
  var node: Dictionary = networkData.get("root", {})
  if path == "/": return node

  for part in path.split("/", false):
    if node.get("type") != "directory": return {}
    node = node.get("children", {}).get(part, {})
    if node.is_empty(): return {}
  return node

# metadata stores absolute path
func getSelectedPath() -> String:
  var selectedItem: TreeItem = networkTree.get_selected()
  if selectedItem == null: return ""
  return str(selectedItem.get_metadata(0))

func getSelectedNode() -> Dictionary:
  var path: String = getSelectedPath()
  if path.is_empty(): return {}
  return getNode(path)

# Adding from a selected file inserts at same level
func getInsertionPath() -> String:
  var path: String = getSelectedPath()
  if path.is_empty(): return ""
  if getSelectedNode().get("type") == "directory": return path
  return getParentPath(path)

# NETWORK NODE OPERATIONS
func addNode(parentPath: String, nodeName: String, data: Dictionary) -> bool:
  if not isValidName(nodeName):
    push_error("Invalid node name.")
    return false
  var parent: Dictionary = getNode(parentPath)
  if parent.get("type") != "directory":
    push_error("Cannot add node: parent is not a directory at " + parentPath)
    return false

  var children: Dictionary = parent.get("children", {})
  if children.has(nodeName):
    push_error("A node with this name already exists.")
    return false

  children[nodeName] = data
  parent["children"] = children
  refreshTree(joinPath(parentPath, nodeName))
  return true

func addFile(parentPath: String, fileName: String, content: String = "", rewards: Dictionary = {}) -> bool:
  var data: Dictionary = {"type": "file", "content": content}
  if not rewards.is_empty(): data["rewards"] = rewards.duplicate(true)
  return addNode(parentPath, fileName, data)

func addDirectory(parentPath: String, directoryName: String, password: String = "", lockID: String = "") -> bool:
  if not validateIntegerField(lockID, "Lock ID"): return false
  var data: Dictionary = {"type": "directory", "children": {}}
  if not password.is_empty(): data["password"] = password
  if not lockID.strip_edges().is_empty(): data["lock_id"] = int(lockID.strip_edges())
  return addNode(parentPath, directoryName, data)

func removeNode(path: String) -> bool:
  if path.is_empty() or path == "/":
    push_error("Cannot delete the network root or an empty path.")
    return false
  var parentPath: String = getParentPath(path)
  var parent: Dictionary = getNode(parentPath)
  if parent.get("type") != "directory":
    push_error("Cannot delete: parent directory not found at " + parentPath)
    return false
  var children: Dictionary = parent.get("children", {})
  if not children.has(getNodeName(path)):
    push_error("Cannot delete: node not found at " + path)
    return false

  children.erase(getNodeName(path))
  refreshTree(parentPath)
  return true

func renameNode(path: String, newName: String, refresh: bool = true) -> bool:
  if path.is_empty() or path == "/" or not isValidName(newName):
    push_error("Cannot rename the root or use an invalid node name.")
    return false
  var parentPath: String = getParentPath(path)
  var parent: Dictionary = getNode(parentPath)
  if parent.get("type") != "directory":
    push_error("Cannot rename: parent directory not found at " + parentPath)
    return false
  var children: Dictionary = parent.get("children", {})
  var oldName: String = getNodeName(path)
  if not children.has(oldName):
    push_error("Cannot rename: node not found at " + path)
    return false
  if newName == oldName: return true
  if children.has(newName):
    push_error("A node with that name already exists.")
    return false

  var node: Dictionary = children[oldName]
  children.erase(oldName)
  children[newName] = node
  if refresh: refreshTree(joinPath(parentPath, newName))
  return true

# Validate before mutation: never allow cycles or name collisions.
func moveNode(sourcePath: String, destinationPath: String) -> bool:
  if sourcePath.is_empty() or sourcePath == "/":
    push_error("Cannot move the network root.")
    return false
  if not isValidPath(sourcePath) or not isValidPath(destinationPath):
    push_error("Move requires valid absolute paths.")
    return false
  # Moving into a descendant would make a recursive 5-dimensional hyper tree.
  if destinationPath == sourcePath or destinationPath.begins_with(sourcePath + "/"):
    push_error("Cannot move a directory into itself or a descendant.")
    return false

  var sourceNode: Dictionary = getNode(sourcePath)
  var destination: Dictionary = getNode(destinationPath)
  if sourceNode.is_empty():
    push_error("Source node not found: " + sourcePath)
    return false
  if destination.get("type") != "directory":
    push_error("Destination is not a directory: " + destinationPath)
    return false

  var sourceParentPath: String = getParentPath(sourcePath)
  if sourceParentPath == destinationPath: return true
  var sourceParent: Dictionary = getNode(sourceParentPath)
  var sourceChildren: Dictionary = sourceParent.get("children", {})
  var destinationChildren: Dictionary = destination.get("children", {})
  var sourceName: String = getNodeName(sourcePath)
  if destinationChildren.has(sourceName):
    push_error("Destination already contains this name.")
    return false

  # Preserve the same node dictionary while relocating its parent link.
  destinationChildren[sourceName] = sourceNode
  sourceChildren.erase(sourceName)
  sourceParent["children"] = sourceChildren
  destination["children"] = destinationChildren
  refreshTree(joinPath(destinationPath, sourceName))
  return true

# DELETE AND MOVE DIALOGS
# Nonempty directories require confirmation; files and empty folders do not.
func requestDelete() -> void:
  var path: String = getSelectedPath()
  if path.is_empty() or path == "/": return
  var node: Dictionary = getNode(path)
  if node.get("type") == "directory" and not node.get("children", {}).is_empty():
    pendingDeletePath = path
    deleteDialog.dialog_text = "Delete '%s' and all of its contents?" % getNodeName(path)
    deleteDialog.popup_centered()
  else:
    removeNode(path)

func confirmDelete() -> void:
  if not pendingDeletePath.is_empty(): removeNode(pendingDeletePath)
  pendingDeletePath = ""

func getDirectoryPaths(node: Dictionary, path: String, paths: Array[String]) -> void:
  if node.get("type") != "directory": return
  paths.append(path)
  for nodeName in node.get("children", {}):
    var child: Dictionary = node["children"][nodeName]
    if child.get("type") == "directory": getDirectoryPaths(child, joinPath(path, nodeName), paths)

# Filter invalid destinations before showing the move confirmation dialog.
func requestMove() -> void:
  var sourcePath: String = getSelectedPath()
  if sourcePath.is_empty() or sourcePath == "/": return

  moveDestinationOption.clear()
  var paths: Array[String] = []
  getDirectoryPaths(networkData.get("root", {}), "/", paths)
  paths.sort()
  for path in paths:
    if path == sourcePath or path.begins_with(sourcePath + "/"): continue
    if path == getParentPath(sourcePath): continue
    if getNode(path).get("children", {}).has(getNodeName(sourcePath)): continue
    moveDestinationOption.add_item(path)

  if moveDestinationOption.item_count == 0:
    push_warning("No valid destination directories are available.")
    return
  pendingMovePath = sourcePath
  moveDialog.dialog_text = "Move '%s' into:" % getNodeName(sourcePath)
  moveDialog.popup_centered()

# Confirmation reuses the path saved when the dialog was opened.
func confirmMove() -> void:
  if moveDestinationOption.selected < 0: return
  moveNode(pendingMovePath, moveDestinationOption.get_item_text(moveDestinationOption.selected))
  pendingMovePath = ""

# UI SIGNAL HANDLERS wired in _ready()
func onLoadPressed() -> void: $fdLoad.popup_centered()
func onSavePressed() -> void: $fdSave.popup_centered()
func onDeletePressed() -> void: requestDelete()
func onMovePressed() -> void: requestMove()
func onSaveSelectedPressed() -> void: saveSelectedNode()
func onTypeSelected(_index: int) -> void: updateEditorFields()
func onTreeItemSelected() -> void: loadEditor(getSelectedNode())

func onAddNewPressed() -> void:
  var parentPath: String = getInsertionPath()
  if parentPath.is_empty():
    push_error("Select a directory or file before adding a node.")
    return
  if not isValidName(txtName.text):
    push_error("Invalid node name.")
    return

  if optType.text == "directory":
    addDirectory(parentPath, txtName.text, txtPassword.text, txtLockID.text)
  elif optType.text == "file":
    if not validateRewardInputs(): return
    addFile(parentPath, txtName.text, txtContent.text, getEditorRewards())

func onNewNetworkPressed() -> void:
  if loadNetworkJson("res://components/networks/gameNetworks/NetworkTemplate.json"): currentFilePath = ""
