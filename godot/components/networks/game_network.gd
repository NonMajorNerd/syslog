class_name GameNetwork
extends RefCounted

signal currentPathChanged(path:String)
signal directoryUnlocked(network:GameNetwork, path:String)

var networkName:String
var networkID:int
var root:Dictionary
var currentPath:Array[String] = []:
	set(v):
		currentPath = v
		currentPathChanged.emit(getCurrentPath())
		
var unlockedPaths: Dictionary = {}

func _init(name: String, ID:int, fileTree: Dictionary) -> void:
	networkName = name
	networkID = ID
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

func getAbsolutePath(path: String) -> String:
	var parts: Array[String] = resolvePath(path)
	if parts.is_empty(): return "/"
	return "/" + "/".join(parts)

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
	var absolutePath: String = getAbsolutePath(path)
	var node: Dictionary = getNode(absolutePath)

	if node.get("type") != "directory": return false

	var parts: Array[String] = resolvePath(absolutePath)

	# Parent directories must already be accessible.
	if parts.size() > 1:
		var parentParts: Array[String] = parts.duplicate()
		parentParts.pop_back()

		var parentPath: String = "/" + "/".join(parentParts)

		if isLocked(parentPath): return false

	var requiredPassword: String = node.get("password", "")
	if requiredPassword.is_empty(): return true
	if unlockedPaths.has(absolutePath): return true
	if password != requiredPassword: return false

	unlockedPaths[absolutePath] = true
	directoryUnlocked.emit(self, absolutePath)

	return true
func changeDirectory(path: String) -> bool:
	var node := getNode(path)
	if node.get("type") != "directory": return false
	if isLocked(path): return false

	currentPath = resolvePath(path)
	return true
	
func listDirectory(path: String = ".") -> Array[String]:
	var result: Array[String] = []
	var node: Dictionary = getNode(path)

	if node.get("type") != "directory" or isLocked(path): return result

	var children: Dictionary = node.get("children", {})
	var names: Array = children.keys()
	names.sort()

	for name in names:
		var child: Dictionary = children[name]
		var icon: String = "[~]" # file

		if child.get("type") == "directory":
			var childPath: String = getAbsolutePath( getAbsolutePath(path).path_join(str(name)) )

			if isLocked(childPath): icon = "[!]" # locked dir
			elif not str(child.get("password", "")).is_empty(): icon = "[+]" # unlocked dir
			else: icon = "[#]" # public dir

		result.append("%s %s" % [icon, name])

	return result
	
func readFile(path: String) -> String:
	if isLocked(path): return ""

	var node := getNode(path)
	if node.get("type") != "file": return ""

	return node.get("content", "")

func resetSession() -> void:
	currentPath = [] #.clear() does not trigger setter
	unlockedPaths.clear()
