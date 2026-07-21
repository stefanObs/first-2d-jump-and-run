class_name CustomLevelStore
extends RefCounted

## Versioned local storage for campaign overrides and inserted family trails.

const VERSION := 3
const LEGACY_SLOT_COUNT := 3
const BUILTIN_SLOT_START := 3
const BUILTIN_COUNT := 10
const EXTRA_SLOT_START := 13
const SLOT_COUNT := 20
const SavePaths := preload("res://scripts/autoload/save_paths.gd")
const BUILTIN_SCENES: PackedStringArray = [
	"res://scenes/levels/level_01.tscn", "res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn", "res://scenes/levels/level_04.tscn",
	"res://scenes/levels/level_05.tscn", "res://scenes/levels/level_06.tscn",
	"res://scenes/levels/level_07.tscn", "res://scenes/levels/level_08.tscn",
	"res://scenes/levels/level_09.tscn", "res://scenes/levels/level_10.tscn",
]
const BUILTIN_NAMES: PackedStringArray = [
	"Dusty Trail", "Badge Meadow", "Bronco Springs", "Canyon Ferry", "Outlaw Cave",
	"Windy Mesa", "Sky Ranch", "Rail Yard", "Moonlight Gulch", "Rainbow Saloon",
]


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
		"kind": "standalone",
		"source_level": 0,
		"insert_position": 11,
		"grid": 40,
		"width": 24,
		"height": 10,
		"spawn": [2, 8],
		"objects": objects,
	}


static func save(slot_index: int, data: Dictionary) -> bool:
	var path := SavePaths.custom_level_path(slot_index)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var cleaned := sanitize(data, slot_index)
	file.store_string(JSON.stringify(cleaned, "\t"))
	return true


static func load_level(slot_index: int) -> Dictionary:
	var path := SavePaths.custom_level_path(slot_index)
	if not FileAccess.file_exists(path):
		if slot_index >= BUILTIN_SLOT_START and slot_index < EXTRA_SLOT_START:
			return import_builtin(slot_index - BUILTIN_SLOT_START + 1)
		return default_level(slot_index)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return default_level(slot_index)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_level(slot_index)
	var raw := parsed as Dictionary
	# Older custom-trail formats are discarded.
	if int(raw.get("version", 0)) < VERSION:
		erase(slot_index)
		return default_level(slot_index)
	return sanitize(raw, slot_index)


static func exists(slot_index: int) -> bool:
	return FileAccess.file_exists(SavePaths.custom_level_path(slot_index))


static func erase(slot_index: int) -> void:
	var path := SavePaths.custom_level_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


static func override_slot_for(level_number: int) -> int:
	return BUILTIN_SLOT_START + clampi(level_number, 1, BUILTIN_COUNT) - 1


static func create_extra(insert_position: int) -> int:
	var data := new_extra_draft(insert_position)
	if data.is_empty():
		return -1
	var slot := int(data["slot"])
	save(slot, data)
	return slot


static func new_extra_draft(insert_position: int) -> Dictionary:
	for slot in range(EXTRA_SLOT_START, SLOT_COUNT):
		if exists(slot):
			continue
		var data := default_level(slot)
		data["kind"] = "extra"
		data["insert_position"] = clampi(insert_position, 1, BUILTIN_COUNT + 1)
		data["title"] = "Extra Trail"
		return data
	return {}


static func campaign_entries() -> Array[Dictionary]:
	var extras_by_position: Dictionary = {}
	for slot in range(EXTRA_SLOT_START, SLOT_COUNT):
		if not exists(slot):
			continue
		var extra := load_level(slot)
		if str(extra.get("kind", "")) != "extra":
			continue
		var position := clampi(int(extra.get("insert_position", 11)), 1, BUILTIN_COUNT + 1)
		if not extras_by_position.has(position):
			extras_by_position[position] = []
		(extras_by_position[position] as Array).append({
			"kind": "custom",
			"source_level": 0,
			"custom_slot": slot,
			"title": str(extra.get("title", "Extra Trail")),
		})
	var result: Array[Dictionary] = []
	for level_number in range(1, BUILTIN_COUNT + 1):
		for extra_entry in extras_by_position.get(level_number, []):
			result.append(extra_entry)
		var override_slot := override_slot_for(level_number)
		if exists(override_slot):
			var override := load_level(override_slot)
			result.append({
				"kind": "custom",
				"source_level": level_number,
				"custom_slot": override_slot,
				"title": str(override.get("title", BUILTIN_NAMES[level_number - 1])),
			})
		else:
			result.append({
				"kind": "builtin",
				"source_level": level_number,
				"custom_slot": -1,
				"title": BUILTIN_NAMES[level_number - 1],
				"scene": BUILTIN_SCENES[level_number - 1],
			})
	for extra_entry in extras_by_position.get(BUILTIN_COUNT + 1, []):
		result.append(extra_entry)
	return result


static func import_builtin(level_number: int) -> Dictionary:
	var number := clampi(level_number, 1, BUILTIN_COUNT)
	var slot := override_slot_for(number)
	var result := default_level(slot)
	result["kind"] = "override"
	result["source_level"] = number
	result["title"] = BUILTIN_NAMES[number - 1]
	result["height"] = 12
	var packed := load(BUILTIN_SCENES[number - 1]) as PackedScene
	if packed == null:
		return result
	var level := packed.instantiate()
	var grid := float(result["grid"])
	var objects: Array[Dictionary] = []
	var max_x := 24
	for node in _all_descendants(level):
		if not (node is Node2D):
			continue
		var world_pos := (node as Node2D).global_position
		var cell_x := maxi(0, int(round(world_pos.x / grid)))
		var cell_y := clampi(int(round(world_pos.y / grid)), 0, 15)
		max_x = maxi(max_x, cell_x + 3)
		var type_name := ""
		if node is Star:
			type_name = "star"
		elif node is Checkpoint:
			type_name = "checkpoint"
		elif node is SpringPad:
			type_name = "spring"
		elif node is Goal:
			type_name = "goal"
		elif node is Opponent:
			type_name = "bandit"
		elif node is Hazard:
			type_name = "pit" if maxf(absf((node as Node2D).scale.x), absf((node as Node2D).scale.y)) > 1.35 else "cactus"
		if not type_name.is_empty():
			_append_unique(objects, {"type": type_name, "x": cell_x, "y": cell_y})
	for child in level.get_children():
		if not (child is StaticBody2D):
			continue
		var body := child as StaticBody2D
		var body_name := String(body.name).to_lower()
		var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node == null or not (shape_node.shape is RectangleShape2D):
			continue
		var rect := shape_node.shape as RectangleShape2D
		var center := body.position + shape_node.position
		if body_name.begins_with("ground"):
			var first_x := int(floor((center.x - rect.size.x * 0.5) / grid))
			var last_x := int(ceil((center.x + rect.size.x * 0.5) / grid))
			var y := clampi(int(round(center.y / grid)), 0, 15)
			for x in range(maxi(first_x, 0), mini(last_x + 1, 180)):
				_append_unique(objects, {"type": "ground", "x": x, "y": y})
		elif "plank" in body_name or "platform" in body_name:
			_append_unique(objects, {
				"type": "platform",
				"x": maxi(0, int(round(center.x / grid))),
				"y": clampi(int(round(center.y / grid)), 0, 15),
			})
	result["width"] = clampi(max_x, 24, 180)
	result["objects"] = objects if not objects.is_empty() else result["objects"]
	level.free()
	return result


static func _all_descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	var pending: Array[Node] = []
	for child in root.get_children():
		pending.append(child)
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		result.append(node)
		for child in node.get_children():
			pending.append(child)
	return result


static func _append_unique(objects: Array[Dictionary], object: Dictionary) -> void:
	for existing in objects:
		if (
			str(existing.get("type", "")) == str(object.get("type", ""))
			and int(existing.get("x", -1)) == int(object.get("x", -1))
			and int(existing.get("y", -1)) == int(object.get("y", -1))
		):
			return
	objects.append(object)


static func sanitize(source: Dictionary, slot_index: int) -> Dictionary:
	var result := default_level(slot_index)
	result["title"] = str(source.get("title", result["title"])).left(40)
	result["spawn"] = source.get("spawn", result["spawn"])
	result["kind"] = str(source.get("kind", result["kind"]))
	result["source_level"] = clampi(int(source.get("source_level", 0)), 0, BUILTIN_COUNT)
	result["insert_position"] = clampi(int(source.get("insert_position", 11)), 1, BUILTIN_COUNT + 1)
	result["width"] = clampi(int(source.get("width", result["width"])), 12, 180)
	result["height"] = clampi(int(source.get("height", result["height"])), 8, 16)
	var objects: Array[Dictionary] = []
	var source_objects: Variant = source.get("objects", [])
	if source_objects is Array:
		for value in source_objects:
			if value is Dictionary and _valid_object(value as Dictionary):
				objects.append((value as Dictionary).duplicate(true))
				if objects.size() >= 900:
					break
	if source_objects is Array:
		result["objects"] = objects
	return result


static func _valid_object(object: Dictionary) -> bool:
	var valid_types := [
		"ground", "platform", "star", "cactus", "pit",
		"checkpoint", "spring", "goal", "bandit",
	]
	var type_name := str(object.get("type", ""))
	if type_name not in valid_types:
		return false
	var x := int(object.get("x", -1))
	var y := int(object.get("y", -1))
	return x >= 0 and x < 180 and y >= 0 and y < 16
