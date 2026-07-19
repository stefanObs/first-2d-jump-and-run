class_name CustomLevelStore
extends RefCounted

## Versioned local storage for three parent-built trails.

const DIRECTORY := "user://custom_levels"
const VERSION := 1
const SLOT_COUNT := 3


static func default_level(slot_index: int) -> Dictionary:
	var objects: Array[Dictionary] = []
	for x in range(24):
		objects.append({"type": "ground", "x": x, "y": 9})
	objects.append({"type": "star", "x": 7, "y": 7})
	objects.append({"type": "cactus", "x": 11, "y": 8})
	objects.append({"type": "checkpoint", "x": 15, "y": 8})
	objects.append({"type": "goal", "x": 22, "y": 8})
	return {
		"version": VERSION,
		"slot": clampi(slot_index, 0, SLOT_COUNT - 1),
		"title": "Family Trail %d" % (slot_index + 1),
		"grid": 40,
		"width": 24,
		"height": 10,
		"spawn": [2, 8],
		"objects": objects,
	}


static func save(slot_index: int, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var file := FileAccess.open(_path(slot_index), FileAccess.WRITE)
	if file == null:
		return false
	var cleaned := sanitize(data, slot_index)
	file.store_string(JSON.stringify(cleaned, "\t"))
	return true


static func load_level(slot_index: int) -> Dictionary:
	if not FileAccess.file_exists(_path(slot_index)):
		return default_level(slot_index)
	var file := FileAccess.open(_path(slot_index), FileAccess.READ)
	if file == null:
		return default_level(slot_index)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_level(slot_index)
	return sanitize(parsed as Dictionary, slot_index)


static func exists(slot_index: int) -> bool:
	return FileAccess.file_exists(_path(slot_index))


static func erase(slot_index: int) -> void:
	var path := _path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


static func sanitize(source: Dictionary, slot_index: int) -> Dictionary:
	var result := default_level(slot_index)
	result["title"] = str(source.get("title", result["title"])).left(40)
	result["spawn"] = source.get("spawn", result["spawn"])
	var objects: Array[Dictionary] = []
	var source_objects: Variant = source.get("objects", [])
	if source_objects is Array:
		for value in source_objects:
			if value is Dictionary and _valid_object(value as Dictionary):
				objects.append((value as Dictionary).duplicate(true))
				if objects.size() >= 80:
					break
	if not objects.is_empty():
		result["objects"] = objects
	return result


static func _valid_object(object: Dictionary) -> bool:
	var valid_types := [
		"ground", "platform", "star", "cactus", "pit",
		"checkpoint", "spring", "goal",
	]
	var type_name := str(object.get("type", ""))
	if type_name not in valid_types:
		return false
	var x := int(object.get("x", -1))
	var y := int(object.get("y", -1))
	return x >= 0 and x < 24 and y >= 0 and y < 10


static func _path(slot_index: int) -> String:
	return "%s/trail_%d.json" % [DIRECTORY, clampi(slot_index, 0, SLOT_COUNT - 1) + 1]
