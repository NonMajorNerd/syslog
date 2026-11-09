class_name GameNetwork
extends RefCounted

signal currentPathChanged(path: String) # notifies NetworkManager, which forwards it to the UI.
signal directoryUnlocked(network: GameNetwork, lockID: int) # NetworkManager connects this to Handle

const ICON_FILE := "[~]"
const ICON_PUBLIC := "[#]"
const ICON_LOCKED := "[!]"
const ICON_UNLOCKED := "[+]"

var networkName: String
var networkID: int
var root: Dictionary

var currentPath: Array[String] = []:
  # The setter is the single notification point for working-directory changes.
  set(value):
    currentPath = value
    currentPathChanged.emit(getCurrentPath())

# Session cache only. Persistent player progression lives in Handle.networks.
var unlockedLocks: Dictionary[int, bool] = {}
var definedLockIDs: Dictionary[int, bool] = {}
var invalidLockIDs: Dictionary[int, bool] = {}


func _init(name: String, id: int, fileTree: Dictionary) -> void:
  networkName = name
  networkID = id
  root = fileTree
  _indexLocks(root, "/")


# Index lock IDs up front; invalid or reused IDs must not grant access.
func _indexLocks(node: Dictionary, path: String) -> void:
  if node.get("type") != "directory": return

  var password: String = str(node.get("password", ""))
  if not password.is_empty():
    var lockID: Variant = node.get("lock_id", null)
    if typeof(lockID) != TYPE_INT or lockID < 0:
      push_error("Network %s: locked directory %s needs a nonnegative integer lock_id" % [networkName, path])
    elif definedLockIDs.has(lockID):
      invalidLockIDs[lockID] = true
      push_error("Network %s: duplicate lock_id %s at %s" % [networkName, lockID, path])
    else:
      definedLockIDs[lockID] = true

  var children: Dictionary = node.get("children", {})
  for childName in children:
    var child: Variant = children[childName]
    if child is Dictionary and child.get("type") == "directory": _indexLocks(child, path.path_join(str(childName)))


# Normalize relative paths, '.', and '..'
func resolvePath(path: String) -> Array[String]:
  var parts: Array[String] = []

  if not path.begins_with("/"): parts = currentPath.duplicate()

  for part in path.split("/", false):
    match part:
      "", ".": continue
      "..": if not parts.is_empty(): parts.pop_back()
      _: parts.append(part)

  return parts


func getAbsolutePath(path: String) -> String:
  var parts: Array[String] = resolvePath(path)
  if parts.is_empty(): return "/"
  return "/" + "/".join(parts)


func getCurrentPath() -> String:
  return getAbsolutePath(".")


# Internal traversal which ignores locks
func _getNodeUnchecked(path: String) -> Dictionary:
  var node: Dictionary = root

  for part in resolvePath(path):
    if node.get("type") != "directory": return {}
    node = node.get("children", {}).get(part, {})
    if node.is_empty(): return {}

  return node


# Public read, never expose a node in a locked directory.
func getNode(path: String) -> Dictionary:
  if isLocked(path): return {}
  return _getNodeUnchecked(path)


func directoryExists(path: String) -> bool:
  return _getNodeUnchecked(path).get("type") == "directory"


func _isProtectedNodeUnlocked(node: Dictionary) -> bool:
  var password: String = str(node.get("password", ""))
  if password.is_empty(): return true

  var lockID: Variant = node.get("lock_id", null)
  if typeof(lockID) != TYPE_INT or lockID < 0: return false
  if invalidLockIDs.has(lockID): return false
  return unlockedLocks.has(lockID)


# Check each ancestor before granting access.
func isLocked(path: String) -> bool:
  var node: Dictionary = root

  for part in resolvePath(path):
    if node.get("type") != "directory": return false
    node = node.get("children", {}).get(part, {})
    if node.is_empty(): return false
    if not _isProtectedNodeUnlocked(node): return true

  return false


func unlock(path: String, password: String) -> bool:
  var absolutePath: String = getAbsolutePath(path)
  var node: Dictionary = _getNodeUnchecked(absolutePath)
  if node.get("type") != "directory": return false

  # A nested lock can only be opened after parent directories are opened
  var parts: Array[String] = resolvePath(absolutePath)
  if parts.size() > 1:
    parts.pop_back()
    if isLocked("/" + "/".join(parts)): return false

  var requiredPassword: String = str(node.get("password", ""))
  if requiredPassword.is_empty(): return true

  var lockID: Variant = node.get("lock_id", null)
  if typeof(lockID) != TYPE_INT or lockID < 0: return false
  if invalidLockIDs.has(lockID): return false
  if unlockedLocks.has(lockID): return true
  if password != requiredPassword: return false

  unlockedLocks[lockID] = true
  # Handle records this lock ID for later session restoration.
  directoryUnlocked.emit(self, lockID)
  return true


# Restore only IDs declared by this network
func restoreUnlocks(lockIDs: Array) -> void:
  unlockedLocks.clear()

  for value in lockIDs:
    if typeof(value) != TYPE_INT or value < 0: continue
    if not definedLockIDs.has(value) or invalidLockIDs.has(value): continue
    unlockedLocks[value] = true


func changeDirectory(path: String) -> bool:
  var node: Dictionary = getNode(path)
  if node.get("type") != "directory": return false
  currentPath = resolvePath(path)
  return true


func listDirectory(path: String = ".") -> Array[String]:
  var result: Array[String] = []
  var node: Dictionary = getNode(path)
  if node.get("type") != "directory": return result

  var children: Dictionary = node.get("children", {})
  var names: Array = children.keys()
  names.sort()

  for name in names:
    var child: Dictionary = children[name]
    var icon: String = ICON_FILE

    if child.get("type") == "directory":
      var childPath: String = getAbsolutePath(path).path_join(str(name))
      if isLocked(childPath): icon = ICON_LOCKED
      elif not str(child.get("password", "")).is_empty(): icon = ICON_UNLOCKED
      else: icon = ICON_PUBLIC

    result.append("%s %s" % [icon, name])

  return result


func readFile(path: String) -> String:
  var node: Dictionary = getNode(path)
  if node.get("type") != "file": return ""
  return str(node.get("content", ""))



func writeFile(path: String, content: String) -> bool:
  var parts: Array[String] = resolvePath(path)
  if parts.is_empty(): return false

  var filename: String = parts.pop_back()
  var parentPath: String = "/" + "/".join(parts)
  var parent: Dictionary = getNode(parentPath)


  if parent.get("type") != "directory": return false

  var children: Dictionary = parent.get("children", {})

  # Don't overwrite a directory with a file.
  if children.has(filename): if children[filename].get("type") != "file": return false

  # Replace the existing file or create a new one.
  children[filename] = { "type": "file", "content": content }

  parent["children"] = children
  return true

# Session navigation and cached unlocks reset when leaving a network
func resetSession() -> void:
  currentPath = []
  unlockedLocks.clear()
