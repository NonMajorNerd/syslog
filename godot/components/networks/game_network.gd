
class_name GameNetwork
extends RefCounted

signal currentPathChanged(path: String)
signal directoryUnlocked(network: GameNetwork, path: String)

const ICON_FILE := "[~]"
const ICON_PUBLIC := "[#]"
const ICON_LOCKED := "[!]"
const ICON_UNLOCKED := "[+]"

var networkName: String
var networkID: int
var root: Dictionary

var currentPath: Array[String] = []:
	set(value):
		currentPath = value
		currentPathChanged.emit(getCurrentPath())

var unlockedPaths: Dictionary = {}


func _init(name: String, id: int, fileTree: Dictionary) -> void:
	networkName = name
	networkID = id
	root = fileTree


# PATHS

func resolvePath(path: String) -> Array[String]:
	var parts: Array[String] = []

	if not path.begins_with("/"): parts = currentPath.duplicate()

	for part in path.split("/", false):
		match part:
			"", ".":
				continue
			"..":
				if not parts.is_empty():
					parts.pop_back()
			_:
				parts.append(part)

	return parts


func getAbsolutePath(path: String) -> String:
	var parts: Array[String] = resolvePath(path)

	if parts.is_empty(): return "/"
	return "/" + "/".join(parts)


func getCurrentPath() -> String:
	return getAbsolutePath(".")


# FILESYSTEM TRAVERSAL

func _getNodeUnchecked(path: String) -> Dictionary:
	var node: Dictionary = root

	for part in resolvePath(path):
		if node.get("type") != "directory": return {}
		node = node.get("children", {}).get(part, {})
		if node.is_empty(): return {}

	return node


func getNode(path: String) -> Dictionary:
	if isLocked(path): return {}
	return _getNodeUnchecked(path)


func directoryExists(path: String) -> bool:
	return _getNodeUnchecked(path).get("type") == "directory"


# DIRECTORY LOCKS

func isLocked(path: String) -> bool:
	var node: Dictionary = root
	var traversed: Array[String] = []

	for part in resolvePath(path):
		if node.get("type") != "directory": return false

		node = node.get("children", {}).get(part, {})
		if node.is_empty(): return false

		traversed.append(part)

		var absolutePath: String = "/" + "/".join(traversed)
		var password: String = node.get("password", "")

		if not password.is_empty():
			if not unlockedPaths.has(absolutePath): return true

	return false


func unlock(path: String, password: String) -> bool:
	var absolutePath: String = getAbsolutePath(path)
	var node: Dictionary = _getNodeUnchecked(absolutePath)

	if node.get("type") != "directory": return false

	var parts: Array[String] = resolvePath(absolutePath)

	# All parent directories must already be accessible.
	if parts.size() > 1:
		parts.pop_back()
		var parentPath: String = "/" + "/".join(parts)

		if isLocked(parentPath): return false

	var requiredPassword: String = node.get("password", "")
	if requiredPassword.is_empty(): return true
	if unlockedPaths.has(absolutePath): return true
	if password != requiredPassword: return false

	unlockedPaths[absolutePath] = true
	directoryUnlocked.emit(self, absolutePath)

	return true


func restoreUnlocks(paths: Array) -> void:
	unlockedPaths.clear()

	for path in paths:
		var absolutePath: String = getAbsolutePath(str(path))
		var node: Dictionary = _getNodeUnchecked(absolutePath)

		if node.get("type") != "directory": continue
		if str(node.get("password", "")).is_empty(): continue

		unlockedPaths[absolutePath] = true


# DIRECTORY OPERATIONS

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
			var childPath: String = getAbsolutePath(
				getAbsolutePath(path).path_join(str(name))
			)

			if isLocked(childPath): icon = ICON_LOCKED
			elif not str(child.get("password", "")).is_empty(): icon = ICON_UNLOCKED
			else: icon = ICON_PUBLIC

		result.append("%s %s" % [icon, name])

	return result


# FILE OPERATIONS

func readFile(path: String) -> String:
	var node: Dictionary = getNode(path)

	if node.get("type") != "file": return ""
	
	return str(node.get("content", ""))


# SESSION

func resetSession() -> void:
	currentPath = []
	unlockedPaths.clear()
