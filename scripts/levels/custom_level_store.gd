class_name CustomLevelStore
extends RefCounted

## Versioned local storage for campaign overrides and inserted family trails.

const VERSION := 4
const SHARE_PACK_FORMAT := "cowboy_trail_pack"
const SHARE_PACK_VERSION := 1
const BUILTIN_SLOT_START := 3
const BUILTIN_COUNT := 15
const EXTRA_SLOT_START := 18
const SLOT_COUNT := 26
const SavePaths := preload("res://scripts/autoload/save_paths.gd")
const BUILTIN_SCENES: PackedStringArray = [
	"res://scenes/levels/level_01.tscn", "res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn", "res://scenes/levels/level_04.tscn",
	"res://scenes/levels/level_05.tscn", "res://scenes/levels/level_06.tscn",
	"res://scenes/levels/level_07.tscn", "res://scenes/levels/level_08.tscn",
	"res://scenes/levels/level_09.tscn", "res://scenes/levels/level_10.tscn",
	"res://scenes/levels/level_11.tscn", "res://scenes/levels/level_12.tscn",
	"res://scenes/levels/level_13.tscn", "res://scenes/levels/level_14.tscn",
	"res://scenes/levels/level_15.tscn",
]
const BUILTIN_NAMES: PackedStringArray = [
	"Dusty Trail", "Badge Meadow", "Bronco Springs", "Canyon Ferry", "Outlaw Cave",
	"Windy Mesa", "Sky Ranch", "Rail Yard", "Moonlight Gulch", "Rainbow Saloon",
	"Crystal Mouth", "Bat Gallery", "Acid Veins", "Ladder Grotto", "Dragon Gate",
]
## Workshop defaults and resize limits — match typical built-in campaign width (goal ~column 177).
const MIN_WIDTH := 12
const MAX_WIDTH := 180
const DEFAULT_WIDTH := 180
const DEFAULT_HEIGHT := 8
const WIDTH_STEP := 12
const PIT_PIXEL_SIZE := Vector2(128.0, 64.0)
const GRID_SIZE := 40.0

static func trail_row(height: int) -> int:
	return maxi(height - 1, 0)

const GROUND_STANDING_TYPES: PackedStringArray = [
	"cactus", "checkpoint", "spring", "bandit", "bounty_bandit", "bull", "ninja",
	"rattlesnake", "goal", "chest", "wings", "boots", "speed", "shield", "ladder",
	"conveyor", "timed_door", "fence",
]
const CEILING_HANGING_TYPES: PackedStringArray = ["acid_drip", "stalactite", "stalactite_static"]
const STYLE_DESERT := "desert"
const STYLE_CAVE := "cave"
const LADDER_HEIGHT_CELLS := 3

static func is_ground_standing(type_name: String) -> bool:
	return type_name in GROUND_STANDING_TYPES

static func is_ceiling_hanging(type_name: String) -> bool:
	return type_name in CEILING_HANGING_TYPES

static func normalize_style(value: Variant) -> String:
	return LevelStyle.normalize(value)

static func placement_row(type_name: String, click_y: int, trail: int) -> int:
	if is_ceiling_hanging(type_name):
		return clampi(mini(click_y, 1), 0, trail)
	if is_ground_standing(type_name) and click_y >= trail - 1:
		return maxi(trail - 1, 0)
	return clampi(click_y, 0, trail)

static func stamp_footprint(type_name: String) -> Vector2:
	match type_name:
		"platform", "ladder_ledge":
			return Vector2(2.0, 1.0)
		"pit":
			return Vector2(PIT_PIXEL_SIZE.x / GRID_SIZE, 1.0)
		"ladder":
			return Vector2(1.0, float(LADDER_HEIGHT_CELLS))
		"conveyor", "fence":
			return Vector2(4.0, 1.0)
		"timed_door":
			return Vector2(2.0, 1.0)
		_:
			return Vector2(1.0, 1.0)

static func stamp_world_size(type_name: String, style: String = STYLE_DESERT) -> Vector2:
	var resolved := normalize_style(style)
	match type_name:
		"platform", "ladder_ledge":
			return Vector2(GRID_SIZE * 2.0, 24.0)
		"pit":
			return PIT_PIXEL_SIZE
		"chest":
			return _texture_pixel_size("res://assets/world/treasure_chest_closed.png")
		"spring":
			return _texture_pixel_size("res://assets/world/spring.png")
		"cactus", "bandit", "bounty_bandit", "rattlesnake", "carrion", "checkpoint", "goal", "bat":
			var scale := 1.15 if type_name in ["bandit", "bounty_bandit"] else 1.0
			return _texture_pixel_size(LevelStyle.stamp_icon_path(type_name, resolved), scale)
		"bull":
			return _bull_stamp_world_size(resolved)
		"ninja":
			return _texture_pixel_size("res://assets/world/ninja_idle.png", 1.15)
		"star":
			return _texture_pixel_size("res://assets/world/star_badge.png")
		"acid_drip":
			return _texture_pixel_size("res://assets/world/acid_drip.png")
		"stalactite":
			return _texture_pixel_size("res://assets/world/stalactite.png")
		"stalactite_static":
			return _texture_pixel_size("res://assets/world/stalactite_static.png")
		"ladder":
			return Vector2(48.0, float(LADDER_HEIGHT_CELLS) * GRID_SIZE)
		"conveyor":
			return _texture_pixel_size("res://assets/world/conveyor.png", 0.95)
		"timed_door":
			return Vector2(56.0, 100.0)
		"fence":
			return _texture_pixel_size("res://assets/world/fence.png")
		"wings", "boots", "speed", "shield":
			return _texture_pixel_size(LevelStyle.stamp_icon_path(type_name))
		_:
			return Vector2(GRID_SIZE, GRID_SIZE)

static func _texture_pixel_size(path: String, scale: float = 1.0) -> Vector2:
	if path.is_empty() or not ResourceLoader.exists(path):
		return Vector2(GRID_SIZE, GRID_SIZE)
	var texture := load(path) as Texture2D
	if texture == null:
		return Vector2(GRID_SIZE, GRID_SIZE)
	return texture.get_size() * scale

static func _bull_stamp_world_size(style: String = STYLE_DESERT) -> Vector2:
	const TARGET_HEIGHT := 92.0
	var path := LevelStyle.stamp_icon_path("bull", style)
	var texture := load(path) as Texture2D
	if texture == null:
		return Vector2(GRID_SIZE, GRID_SIZE)
	var tex_size := texture.get_size()
	var scale := TARGET_HEIGHT / maxf(tex_size.y, 1.0)
	return tex_size * scale

static func stamp_hover_cells(
	type_name: String, hover_col: int, hover_row: int, trail: int, width: int
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if type_name in ["erase", "ground", "canyon"] or hover_col < 0 or hover_row < 0:
		return cells
	if type_name == "pit":
		if hover_row != trail:
			return cells
		var span := pit_column_span({"type": "pit", "x": hover_col, "y": trail})
		for col in range(span.x, span.y + 1):
			cells.append(Vector2i(col, trail))
		return cells
	var place_row := placement_row(type_name, hover_row, trail)
	var footprint := stamp_footprint(type_name)
	var start_col := hover_col
	if footprint.x > 1.0:
		start_col -= int(floor((footprint.x - 1.0) * 0.5))
	start_col = clampi(start_col, 0, width - int(footprint.x))
	for dx in range(int(footprint.x)):
		for dy in range(int(footprint.y)):
			var row := place_row + dy
			if type_name == "ladder":
				# Ladder grows upward from the standing row.
				row = place_row - dy
			if row < 0 or row > trail:
				continue
			cells.append(Vector2i(start_col + dx, row))
	return cells

static func stamp_visual_world_rect(
	type_name: String,
	hover_col: int,
	hover_row: int,
	trail: int,
	width: int,
	grid: float = GRID_SIZE,
	style: String = STYLE_DESERT
) -> Rect2:
	if type_name in ["erase", "ground", "canyon"] or hover_col < 0 or hover_row < 0:
		return Rect2()
	var size := stamp_world_size(type_name, style)
	if type_name == "pit":
		if hover_row != trail:
			return Rect2()
		var center := pit_world_position({"type": "pit", "x": hover_col, "y": trail}, grid, trail)
		return Rect2(center - size * 0.5, size)
	if type_name == "platform":
		var cells := stamp_hover_cells(type_name, hover_col, hover_row, trail, width)
		if cells.is_empty():
			return Rect2()
		var left_col := cells[0].x
		return Rect2(float(left_col) * grid, float(trail) * grid - size.y, size.x, size.y)
	var place_row := placement_row(type_name, hover_row, trail)
	var object := {"type": type_name, "x": hover_col, "y": place_row}
	var anchor := object_world_position(object, grid, trail)
	if is_ceiling_hanging(type_name):
		return Rect2(anchor.x - size.x * 0.5, anchor.y, size.x, size.y)
	if type_name == "ladder":
		return Rect2(anchor.x - size.x * 0.5, anchor.y - size.y, size.x, size.y)
	if is_ground_standing(type_name):
		return Rect2(anchor.x - size.x * 0.5, anchor.y - size.y, size.x, size.y)
	if type_name == "carrion" or type_name == "bat":
		return Rect2(anchor.x - size.x * 0.5, anchor.y - size.y * 0.5, size.x, size.y)
	return Rect2(anchor.x - size.x * 0.5, anchor.y - size.y, size.x, size.y)

static func pit_world_position(object: Dictionary, grid: float, trail: int) -> Vector2:
	var cell_x := float(object.get("x", 0))
	var center_x := (cell_x + 0.5) * grid
	var surface_y := float(trail) * grid
	return Vector2(center_x, surface_y)

static func pit_column_span(object: Dictionary, grid: float = GRID_SIZE) -> Vector2i:
	var center_x := (float(object.get("x", 0)) + 0.5) * grid
	var left := center_x - PIT_PIXEL_SIZE.x * 0.5
	var right := center_x + PIT_PIXEL_SIZE.x * 0.5
	return Vector2i(int(floor(left / grid)), int(floor((right - 0.001) / grid)))

static func pit_fits_on_dirt(objects: Array, center_x: int, trail: int) -> bool:
	var probe := {"type": "pit", "x": center_x, "y": trail}
	var span := pit_column_span(probe)
	for col in range(span.x, span.y + 1):
		if not _has_ground_at(objects, col, trail):
			return false
	return true

static func _has_ground_at(objects: Array, x: int, y: int) -> bool:
	for value in objects:
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		if int(object.get("x", -1)) == x and int(object.get("y", -1)) == y:
			if str(object.get("type", "")) == "ground":
				return true
	return false


static func has_canyon_at(objects: Array, x: int, trail: int) -> bool:
	for value in objects:
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		if (
			int(object.get("x", -1)) == x
			and int(object.get("y", -1)) == trail
			and str(object.get("type", "")) == "canyon"
		):
			return true
	return false


static func trail_column_is_solid_dirt(objects: Array, x: int, trail: int) -> bool:
	## Walkable trail crust — not a canyon stamp and not inside a pit mouth.
	if not _has_ground_at(objects, x, trail):
		return false
	if has_canyon_at(objects, x, trail):
		return false
	var hole := pit_hole_columns({"objects": objects}, trail)
	return not hole.has(x)


static func bull_stamp_allowed(objects: Array, x: int, trail: int) -> bool:
	## Trail bulls / cave lizards never stand on pits or canyon mouths.
	return trail_column_is_solid_dirt(objects, x, trail)


static func remove_bulls_at_columns(objects: Array, columns: Array, trail: int) -> void:
	var blocked := {}
	for col in columns:
		blocked[int(col)] = true
	if blocked.is_empty():
		return
	for i in range(objects.size() - 1, -1, -1):
		var object := objects[i] as Dictionary
		if str(object.get("type", "")) != "bull":
			continue
		if int(object.get("y", -1)) != maxi(trail - 1, 0):
			continue
		if blocked.has(int(object.get("x", -1))):
			objects.remove_at(i)


## Trail columns whose crust the cowboy actually drops through — the ones whose
## cell centre sits inside the painted pit mouth. The dirt bank stays solid on
## the shoulders so the hole reads as dug into the trail, not floating in air.
static func pit_hole_columns(data: Dictionary, trail: int, grid: float = GRID_SIZE) -> Dictionary:
	var hole := {}
	for value in data.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		if str(object.get("type", "")) != "pit":
			continue
		if int(object.get("y", -1)) != trail:
			continue
		var center_x := (float(object.get("x", 0)) + 0.5) * grid
		var mouth_left := center_x - PIT_PIXEL_SIZE.x * 0.5
		var mouth_right := center_x + PIT_PIXEL_SIZE.x * 0.5
		var span := pit_column_span(object, grid)
		for col in range(span.x, span.y + 1):
			var col_center := (float(col) + 0.5) * grid
			if col_center >= mouth_left and col_center <= mouth_right:
				hole[col] = true
	return hole

static func object_world_position(object: Dictionary, grid: float, trail: int) -> Vector2:
	var type_name := str(object.get("type", ""))
	var cell_x := float(object.get("x", 0))
	var cell_y := float(object.get("y", 0))
	var world_x := (cell_x + 0.5) * grid
	if is_ceiling_hanging(type_name):
		return Vector2(world_x, cell_y * grid + 8.0)
	if is_ground_standing(type_name):
		return Vector2(world_x, (cell_y + 1.0) * grid)
	if type_name == "carrion" or type_name == "bat":
		return Vector2(world_x, (cell_y + 0.5) * grid)
	return Vector2(world_x, cell_y * grid)

static func default_level(slot_index: int) -> Dictionary:
	var height := DEFAULT_HEIGHT
	var width := DEFAULT_WIDTH
	var trail := trail_row(height)
	var objects: Array[Dictionary] = []
	for x in range(width):
		objects.append({"type": "ground", "x": x, "y": trail})
	objects.append({"type": "star", "x": 7, "y": trail - 2})
	objects.append({"type": "cactus", "x": 11, "y": trail - 1})
	objects.append({"type": "pit", "x": 18, "y": trail})
	append_ladder_branch(objects, trail, 28)
	objects.append({"type": "checkpoint", "x": width / 2, "y": trail - 1})
	objects.append({"type": "goal", "x": width - 3, "y": trail - 1})
	return {
		"version": VERSION,
		"slot": clampi(slot_index, 0, SLOT_COUNT - 1),
		"title": "Family Trail %d" % (slot_index + 1),
		"kind": "standalone",
		"style": STYLE_DESERT,
		"source_level": 0,
		"insert_position": BUILTIN_COUNT + 1,
		"grid": 40,
		"width": width,
		"height": height,
		"spawn": [2, trail],
		"objects": objects,
	}

static func resize_width(source: Dictionary, new_width: int, slot_index: int = -1) -> Dictionary:
	var slot := slot_index if slot_index >= 0 else int(source.get("slot", 0))
	var old_width := int(source.get("width", DEFAULT_WIDTH))
	var clamped_width := clampi(new_width, MIN_WIDTH, MAX_WIDTH)
	if clamped_width == old_width:
		return sanitize(source, slot)
	var trail := trail_row(int(source.get("height", DEFAULT_HEIGHT)))
	var objects: Array[Dictionary] = []
	for value in source.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := (value as Dictionary).duplicate(true)
		if int(object.get("x", -1)) < clamped_width:
			objects.append(object)
	if clamped_width > old_width:
		for x in range(old_width, clamped_width):
			_append_unique(objects, {"type": "ground", "x": x, "y": trail})
	var result := source.duplicate(true)
	result["width"] = clamped_width
	result["objects"] = objects
	var spawn: Array = result.get("spawn", [2, trail])
	if spawn is Array and spawn.size() >= 2:
		result["spawn"] = [
			clampi(int(spawn[0]), 0, clamped_width - 1),
			clampi(int(spawn[1]), 0, trail),
		]
	return sanitize(result, slot)

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
	var version := int(raw.get("version", 0))
	# Formats older than the three-row trail grid are discarded.
	if version < 3:
		erase(slot_index)
		return default_level(slot_index)
	if version == 3:
		raw = migrate_v3_to_v4(raw)
	return sanitize(raw, slot_index)

static func exists(slot_index: int) -> bool:
	return FileAccess.file_exists(SavePaths.custom_level_path(slot_index))

static func existing_custom_slots() -> Array[int]:
	var slots: Array[int] = []
	for slot in range(BUILTIN_SLOT_START, SLOT_COUNT):
		if exists(slot):
			slots.append(slot)
	return slots

static func free_extra_slots() -> Array[int]:
	var slots: Array[int] = []
	for slot in range(EXTRA_SLOT_START, SLOT_COUNT):
		if not exists(slot):
			slots.append(slot)
	return slots

static func export_share_pack(path: String, slots: Array = []) -> bool:
	var target_slots: Array[int] = []
	if slots.is_empty():
		target_slots = existing_custom_slots()
	else:
		for value in slots:
			var slot := int(value)
			if slot >= BUILTIN_SLOT_START and slot < SLOT_COUNT and exists(slot):
				target_slots.append(slot)
	if target_slots.is_empty():
		return false
	var trails: Array = []
	for slot in target_slots:
		trails.append(sanitize(load_level(slot), slot))
	return write_share_pack(path, trails)

static func write_share_pack(path: String, trail_docs: Array) -> bool:
	var trails: Array = []
	for value in trail_docs:
		if not (value is Dictionary):
			continue
		var source := value as Dictionary
		var slot := int(source.get("slot", 0))
		trails.append(sanitize(source, slot))
	if trails.is_empty():
		return false
	var pack := {
		"format": SHARE_PACK_FORMAT,
		"version": SHARE_PACK_VERSION,
		"exported_at": Time.get_datetime_string_from_system(true),
		"trails": trails,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(pack, "\t"))
	return true

static func import_share_pack(path: String) -> Dictionary:
	var result := {
		"ok": false,
		"imported_count": 0,
		"message": "",
		"errors": PackedStringArray(),
	}
	if not FileAccess.file_exists(path):
		result["message"] = "Pack file not found."
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result["message"] = "Could not read pack file."
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		result["message"] = "Invalid pack format."
		return result
	var pack := parsed as Dictionary
	if str(pack.get("format", "")) != SHARE_PACK_FORMAT:
		result["message"] = "Unsupported pack format."
		return result
	if int(pack.get("version", 0)) != SHARE_PACK_VERSION:
		result["message"] = "Unsupported pack version."
		return result
	var trails: Variant = pack.get("trails", [])
	if not (trails is Array) or (trails as Array).is_empty():
		result["message"] = "Pack contains no trails."
		return result
	var free_slots := free_extra_slots()
	var imported := 0
	var errors: PackedStringArray = []
	for value in trails:
		if imported >= free_slots.size():
			errors.append("No free extra slots remaining.")
			break
		if not (value is Dictionary):
			errors.append("Skipped invalid trail entry.")
			continue
		var slot := free_slots[imported]
		var doc := sanitize(value as Dictionary, slot)
		doc["kind"] = "extra"
		doc["source_level"] = 0
		if not save(slot, doc):
			errors.append("Could not save imported trail.")
			continue
		imported += 1
	result["imported_count"] = imported
	result["ok"] = imported > 0
	if imported == 0:
		result["message"] = errors[0] if not errors.is_empty() else "No trails imported."
	elif errors.is_empty():
		result["message"] = "Imported %d trail(s)." % imported
	else:
		result["message"] = "Imported %d trail(s) with warnings." % imported
	result["errors"] = errors
	return result

static func read_share_pack(path: String) -> Dictionary:
	var result := {
		"ok": false,
		"message": "",
		"trails": [],
		"trail_count": 0,
	}
	if not FileAccess.file_exists(path):
		result["message"] = "Pack file not found."
		return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result["message"] = "Could not read pack file."
		return result
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		result["message"] = "Invalid pack format."
		return result
	var pack := parsed as Dictionary
	if str(pack.get("format", "")) != SHARE_PACK_FORMAT:
		result["message"] = "Unsupported pack format."
		return result
	if int(pack.get("version", 0)) != SHARE_PACK_VERSION:
		result["message"] = "Unsupported pack version."
		return result
	var trails: Variant = pack.get("trails", [])
	if not (trails is Array) or (trails as Array).is_empty():
		result["message"] = "Pack contains no trails."
		return result
	var trail_docs: Array = []
	for value in trails:
		if value is Dictionary:
			trail_docs.append(value as Dictionary)
	if trail_docs.is_empty():
		result["message"] = "Pack contains no trails."
		return result
	result["trails"] = trail_docs
	result["trail_count"] = trail_docs.size()
	result["ok"] = true
	return result

static func merge_imported_trail(
	current: Dictionary, imported: Dictionary, slot_index: int
) -> Dictionary:
	var merged := sanitize(imported, slot_index)
	merged["kind"] = str(current.get("kind", merged.get("kind", "standalone")))
	merged["source_level"] = clampi(
		int(current.get("source_level", merged.get("source_level", 0))), 0, BUILTIN_COUNT
	)
	merged["insert_position"] = clampi(
		int(current.get("insert_position", merged.get("insert_position", BUILTIN_COUNT + 1))),
		1,
		BUILTIN_COUNT + 1,
	)
	merged["slot"] = slot_index
	return merged

static func erase(slot_index: int) -> void:
	var path := SavePaths.custom_level_path(slot_index)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

static func override_slot_for(level_number: int) -> int:
	return BUILTIN_SLOT_START + clampi(level_number, 1, BUILTIN_COUNT) - 1

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
		var position := clampi(int(extra.get("insert_position", BUILTIN_COUNT + 1)), 1, BUILTIN_COUNT + 1)
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

## Collapse the old bottom three stamp rows into one trail row.
## Old y=H-1 (bottom / 3rd of the lower trio) defined dirt vs canyon underside;
## props on H-2 sat on that surface; H-3 held near-trail air / short steps.
static func migrate_v3_to_v4(source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	var old_height := clampi(int(source.get("height", 10)), 8, 16)
	var new_height := clampi(old_height - 2, 6, 14)
	var old_trail_bottom := old_height - 1
	var old_surface := old_height - 2
	var old_near := old_height - 3
	var trail := trail_row(new_height)
	var objects: Array[Dictionary] = []
	var source_objects: Variant = source.get("objects", [])
	if source_objects is Array:
		for value in source_objects:
			if not (value is Dictionary):
				continue
			var object := (value as Dictionary).duplicate(true)
			var y := int(object.get("y", 0))
			var type_name := str(object.get("type", ""))
			if y >= old_near:
				if type_name == "ground" or type_name == "canyon" or type_name == "pit":
					# Keep a one-cell step when dirt was stamped on the near-trail row.
					if y == old_near and type_name == "ground":
						object["y"] = maxi(trail - 1, 0)
					else:
						object["y"] = trail
				elif y == old_near:
					object["y"] = maxi(trail - 1, 0)
				else:
					# The H-2 walk surface collapses onto the single trail row, so its
					# surface props (cactus, goal, ...) share that row with the dirt.
					object["y"] = trail
			else:
				# Shift sky/platform rows down by the two removed rows.
				object["y"] = clampi(y, 0, trail)
			objects.append(object)
	var spawn: Array = source.get("spawn", [2, old_surface])
	if spawn.size() >= 2:
		var spawn_y := int(spawn[1])
		if spawn_y >= old_near:
			spawn_y = trail
		result["spawn"] = [int(spawn[0]), spawn_y]
	result["height"] = new_height
	result["objects"] = objects
	result["version"] = VERSION
	return result

static func import_builtin(level_number: int) -> Dictionary:
	var number := clampi(level_number, 1, BUILTIN_COUNT)
	var slot := override_slot_for(number)
	## Levels 11–15 are stamp layouts (not hand scenes); import the cave catalog directly.
	if number >= 11 and number <= 15:
		var cave := CaveCampaignLevels.level_data(number)
		cave["kind"] = "override"
		cave["source_level"] = number
		cave["title"] = BUILTIN_NAMES[number - 1]
		return sanitize(cave, slot)
	var result := default_level(slot)
	result["kind"] = "override"
	result["source_level"] = number
	result["title"] = BUILTIN_NAMES[number - 1]
	result["style"] = STYLE_CAVE if CaveCampaignLevels.is_cave_source(number) else STYLE_DESERT
	result["height"] = 10
	var packed := load(BUILTIN_SCENES[number - 1]) as PackedScene
	if packed == null:
		return result
	var level := packed.instantiate()
	var grid := float(result["grid"])
	var objects: Array[Dictionary] = []
	var max_x := DEFAULT_WIDTH
	var max_ground_y := 0
	for node in level.find_children("*", "Node2D", true, false):
		var world_pos := (node as Node2D).global_position
		var cell_x := maxi(0, int(round(world_pos.x / grid)))
		var cell_y := clampi(int(round(world_pos.y / grid)), 0, 15)
		max_x = maxi(max_x, cell_x + 3)
		var type_name := _import_type_for(node)
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
			max_ground_y = maxi(max_ground_y, y)
			for x in range(maxi(first_x, 0), mini(last_x + 1, 180)):
				_append_unique(objects, {"type": "ground", "x": x, "y": y})
		elif "plank" in body_name or "platform" in body_name:
			_append_unique(objects, {
				"type": "platform",
				"x": maxi(0, int(round(center.x / grid))),
				"y": clampi(int(round(center.y / grid)), 0, 15),
			})
	# Fit height so the deepest ground sits on the single trail row.
	var height := clampi(maxi(max_ground_y + 1, 8), 8, 14)
	var trail := trail_row(height)
	var shift := trail - max_ground_y if max_ground_y > 0 else 0
	if shift != 0:
		for object in objects:
			object["y"] = clampi(int(object.get("y", 0)) + shift, 0, trail)
	result["height"] = height
	result["width"] = clampi(max_x, MIN_WIDTH, MAX_WIDTH)
	# Walk-surface props stand one stamp row above dirt; snap near-trail imports there.
	if not objects.is_empty():
		for object in objects:
			var type_name := str(object.get("type", ""))
			if not is_ground_standing(type_name):
				continue
			if int(object.get("y", 0)) >= trail - 1:
				object["y"] = maxi(trail - 1, 0)
		result["objects"] = objects
	if number == 1:
		result["start_mounted"] = true
	if CaveCampaignLevels.is_cave_source(number):
		var cave_objects: Array = result.get("objects", [])
		if cave_objects is Array:
			var typed: Array[Dictionary] = []
			for value in cave_objects:
				if value is Dictionary:
					typed.append(value as Dictionary)
			append_ladder_branch(typed, trail, 42)
			result["objects"] = typed
	var spawn_marker := level.get_node_or_null("SpawnPoint") as Node2D
	var player := level.get_node_or_null("Player") as Node2D
	var spawn_node: Node2D = spawn_marker if spawn_marker != null else player
	if spawn_node != null:
		result["spawn"] = [
			maxi(0, int(round(spawn_node.global_position.x / grid))),
			clampi(int(round(spawn_node.global_position.y / grid)) + shift, 0, trail),
		]
	level.free()
	return result

static func _import_type_for(node: Node) -> String:
	if node is Star:
		return "star"
	if node is TreasureChest:
		return "chest"
	if node is Checkpoint:
		return "checkpoint"
	if node is SpringPad:
		return "spring"
	if node is Goal:
		return "goal"
	if node is Opponent:
		return "bounty_bandit" if (node as Opponent).bounty_bandit else "bandit"
	if node is BullEnemy:
		return "bull"
	if node is NinjaEnemy:
		return "ninja"
	if node is Carrion:
		return "carrion"
	if node is Rattlesnake:
		return "rattlesnake"
	if node is Hazard:
		var body := node as Node2D
		if node.has_meta("fixed_pit") and bool(node.get_meta("fixed_pit")):
			return "pit"
		return "canyon" if maxf(absf(body.scale.x), absf(body.scale.y)) > 1.35 else "cactus"
	return ""

static func append_ladder_branch(
	objects: Array[Dictionary], trail: int, start_x: int = 28
) -> void:
	## Lower dirt path + ladder up to a ledge run; drop off the end back to dirt (no down ladder).
	## Ledge cell Y equals climb_top row (trail - LADDER_HEIGHT_CELLS): ladder bottom sits on the
	## trail surface, so climb_top world Y is that row's world Y; plank center matches climb_top.
	var upper := maxi(trail - LADDER_HEIGHT_CELLS, 0)
	_append_unique(objects, {"type": "ladder", "x": start_x, "y": maxi(trail - 1, 0)})
	for x in range(start_x, start_x + 16, 2):
		_append_unique(objects, {"type": "ladder_ledge", "x": x, "y": upper})
	_append_unique(objects, {"type": "star", "x": start_x + 6, "y": maxi(upper - 1, 0)})


static func append_platform_run(
	objects: Array[Dictionary],
	trail: int,
	start_x: int,
	count: int = 3,
	height_cells: int = 2
) -> void:
	## Floating plank/crystal-ledge run for hop routes (not tied to a ladder).
	var y := maxi(trail - height_cells, 0)
	for i in range(maxi(count, 1)):
		_append_unique(objects, {"type": "platform", "x": start_x + i * 2, "y": y})


static func append_conveyor_gate(
	objects: Array[Dictionary],
	trail: int,
	belt_x: int,
	door_x: int,
	push_right: bool = true
) -> void:
	## Belt + timed ranch gate on solid trail (never over a canyon mouth).
	var y := maxi(trail - 1, 0)
	_append_unique(
		objects,
		{"type": "conveyor", "x": belt_x, "y": y, "push_right": push_right}
	)
	_append_unique(objects, {"type": "timed_door", "x": door_x, "y": y})


static func append_fence_run(
	objects: Array[Dictionary], trail: int, start_x: int, count: int = 2
) -> void:
	var y := maxi(trail - 1, 0)
	for i in range(maxi(count, 1)):
		_append_unique(objects, {"type": "fence", "x": start_x + i * 4, "y": y})


static func realign_ladder_ledges(objects: Array, trail: int) -> void:
	## Repair older stamp packs that put ledges one cell above climb_top.
	var expected_upper := maxi(trail - LADDER_HEIGHT_CELLS, 0)
	var legacy_upper := maxi(trail - 1 - LADDER_HEIGHT_CELLS, 0)
	if expected_upper == legacy_upper:
		return
	var ladder_xs: Array[int] = []
	for object in objects:
		if str(object.get("type", "")) == "ladder":
			ladder_xs.append(int(object.get("x", 0)))
	if ladder_xs.is_empty():
		return
	for object in objects:
		var type_name := str(object.get("type", ""))
		if type_name != "ladder_ledge" and type_name != "star":
			continue
		var x := int(object.get("x", 0))
		var y := int(object.get("y", 0))
		var near_ladder := false
		for lx in ladder_xs:
			if x >= lx and x <= lx + 16:
				near_ladder = true
				break
		if not near_ladder:
			continue
		if type_name == "ladder_ledge" and y == legacy_upper:
			object["y"] = expected_upper
		elif type_name == "star" and y == maxi(legacy_upper - 1, 0):
			object["y"] = maxi(expected_upper - 1, 0)

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
	result["insert_position"] = clampi(int(source.get("insert_position", BUILTIN_COUNT + 1)), 1, BUILTIN_COUNT + 1)
	result["width"] = clampi(int(source.get("width", result["width"])), MIN_WIDTH, MAX_WIDTH)
	result["height"] = clampi(int(source.get("height", result["height"])), 6, 14)
	result["version"] = VERSION
	result["start_mounted"] = bool(source.get("start_mounted", false)) or int(result["source_level"]) == 1
	var default_style := STYLE_CAVE if CaveCampaignLevels.is_cave_source(int(result["source_level"])) else STYLE_DESERT
	result["style"] = normalize_style(source.get("style", default_style))
	var trail := trail_row(int(result["height"]))
	var objects: Array[Dictionary] = []
	var source_objects: Variant = source.get("objects", [])
	if source_objects is Array:
		for value in source_objects:
			if value is Dictionary and _valid_object(value as Dictionary, trail):
				var object := (value as Dictionary).duplicate(true)
				object["y"] = clampi(int(object.get("y", 0)), 0, trail)
				var type_name := str(object.get("type", ""))
				if is_ground_standing(type_name) and int(object.get("y", 0)) == trail:
					object["y"] = maxi(trail - 1, 0)
				if is_ceiling_hanging(type_name):
					object["y"] = clampi(int(object.get("y", 0)), 0, mini(1, trail))
				objects.append(object)
				if objects.size() >= 900:
					break
		realign_ladder_ledges(objects, trail)
		_strip_bulls_off_gaps(objects, trail)
		result["objects"] = objects
	var spawn: Array = result["spawn"]
	if spawn is Array and spawn.size() >= 2:
		result["spawn"] = [int(spawn[0]), clampi(int(spawn[1]), 0, trail)]
	return result


static func _strip_bulls_off_gaps(objects: Array, trail: int) -> void:
	## Drop trail-bull / cave-lizard stamps that landed on a pit mouth or canyon.
	for i in range(objects.size() - 1, -1, -1):
		var object := objects[i] as Dictionary
		if str(object.get("type", "")) != "bull":
			continue
		if not bull_stamp_allowed(objects, int(object.get("x", 0)), trail):
			objects.remove_at(i)


static func _valid_object(object: Dictionary, trail: int) -> bool:
	var valid_types := [
		"ground", "platform", "ladder_ledge", "star", "chest", "cactus", "canyon", "pit",
		"checkpoint", "spring", "goal", "bandit", "bounty_bandit", "bull", "ninja",
		"rattlesnake", "carrion", "bat", "acid_drip", "stalactite", "stalactite_static", "ladder",
		"conveyor", "timed_door", "fence",
		"wings", "boots", "speed", "shield",
	]
	var type_name := str(object.get("type", ""))
	if type_name not in valid_types:
		return false
	var x := int(object.get("x", -1))
	var y := int(object.get("y", -1))
	return x >= 0 and x < 180 and y >= 0 and y <= trail
