class_name GameNetwork
extends RefCounted

signal currentPathChanged(path:String)

var networkName: String
var root: Dictionary
var currentPath: Array[String] = []:
	set(v):
		currentPath = v
		currentPathChanged.emit(getCurrentPath())
		
var unlockedPaths: Dictionary = {}

func _init(name: String, fileTree: Dictionary) -> void:
	networkName = name
	root = fileTree

func getCurrentPath() -> String:
	if currentPath.is_empty(): return "/"
	return "/" + "/".join(currentPath)

func getDirectory(path: Array[String] = currentPath) -> Dictionary:
	var directory := root

	for part in path:
		if directory.get("type") != "directory": return {}
		
		directory = directory.get("children", {}).get(part, {})
		if directory.is_empty(): return {}

	return directory

func resolvePath(path: String) -> Array[String]:
	var result: Array[String] = []

	if not path.begins_with("/"): result = currentPath.duplicate()

	for part in path.split("/", false):
		match part:
			"", ".":
				continue
			"..":
				if not result.is_empty():
					result.pop_back()
			_:
				result.append(part)

	return result


func getNode(path: String) -> Dictionary:
	var parts := resolvePath(path)

	if parts.is_empty(): return root

	var node := root

	for part in parts:
		if node.get("type") != "directory": return {}
		node = node.get("children", {}).get(part, {})
		if node.is_empty(): return {}

	return node


func isLocked(path: String) -> bool:
	var parts := resolvePath(path)
	var node := root
	var traversed: Array[String] = []

	for part in parts:
		if node.get("type") != "directory": return false

		node = node.get("children", {}).get(part, {})
		if node.is_empty(): return false

		traversed.append(part)

		var absolutePath := "/" + "/".join(traversed)
		var password: String = node.get("password", "")

		if not password.is_empty() and not unlockedPaths.has(absolutePath):
			return true

	return false


func unlock(path: String, password: String) -> bool:
	var parts := resolvePath(path)
	var node := getNode(path)

	if node.get("type") != "directory":
		return false

	# Parent directories must already be accessible.
	if parts.size() > 1:
		var parentParts := parts.duplicate()
		parentParts.pop_back()

		if isLocked("/" + "/".join(parentParts)):
			return false

	var requiredPassword: String = node.get("password", "")

	if requiredPassword.is_empty(): return true
	if password != requiredPassword: return false

	unlockedPaths["/" + "/".join(parts)] = true
	return true


func changeDirectory(path: String) -> bool:
	var node := getNode(path)
	if node.get("type") != "directory": return false
	if isLocked(path): return false

	currentPath = resolvePath(path)
	return true


func listDirectory(path: String = ".") -> Array[String]:
	var result: Array[String] = []

	var node := getNode(path)

	if node.get("type") != "directory" or isLocked(path):
		return result

	for name in node.get("children", {}):
		var child: Dictionary = node["children"][name]

		if child.get("type") == "directory":
			result.append(name + "/")
		else:
			result.append(name)

	result.sort()
	return result


func readFile(path: String) -> String:
	if isLocked(path): return ""

	var node := getNode(path)
	if node.get("type") != "file": return ""

	return node.get("content", "")

func resetSession() -> void:
	currentPath.clear()
	unlockedPaths.clear()
