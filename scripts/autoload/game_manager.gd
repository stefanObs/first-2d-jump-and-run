extends Node

## Owns save slots, settings, and level progression.

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 3
const SLOT_COUNT := 3
const CUSTOM_LEVEL_STORE := preload("res://scripts/levels/custom_level_store.gd")

const LEVEL_SCENES: PackedStringArray = [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/level_04.tscn",
	"res://scenes/levels/level_05.tscn",
	"res://scenes/levels/level_06.tscn",
	"res://scenes/levels/level_07.tscn",
	"res://scenes/levels/level_08.tscn",
	"res://scenes/levels/level_09.tscn",
	"res://scenes/levels/level_10.tscn",
]

const LEVEL_NAMES: PackedStringArray = [
	"Dusty Trail",
	"Badge Meadow",
	"Bronco Springs",
	"Canyon Ferry",
	"Outlaw Cave",
	"Windy Mesa",
	"Sky Ranch",
	"Rail Yard",
	"Moonlight Gulch",
	"Rainbow Saloon",
]

signal saves_changed
signal settings_changed
signal active_slot_changed(slot_index: int)

var active_slot_index: int = -1
var active_custom_slot: int = 0
var custom_return_to_editor: bool = true
var _horse_arrival_pending: bool = false
var _data: Dictionary = {}


func _ready() -> void:
	_data = _default_data()
	load_from_disk()
	_apply_settings()


func get_slot(slot_index: int) -> Dictionary:
	_validate_slot(slot_index)
	_ensure_data()
	return (_data["slots"] as Array)[slot_index]


func is_slot_empty(slot_index: int) -> bool:
	return bool(get_slot(slot_index).get("empty", true))


func start_or_continue_slot(slot_index: int) -> void:
	_validate_slot(slot_index)
	_ensure_data()
	active_slot_index = slot_index
	var slot: Dictionary = get_slot(slot_index)
	if bool(slot.get("empty", true)):
		slot["empty"] = false
		slot["current_level"] = 1
		slot["stars"] = 0
		slot["play_time_sec"] = 0.0
		(_data["slots"] as Array)[slot_index] = slot
		save_to_disk()
	active_slot_changed.emit(slot_index)
	var resume: Variant = slot.get("resume", {})
	if resume is Dictionary and not (resume as Dictionary).is_empty():
		load_level(int((resume as Dictionary).get("level_number", slot.get("current_level", 1))))
	else:
		load_level(int(slot.get("current_level", 1)))


func erase_slot(slot_index: int) -> void:
	_validate_slot(slot_index)
	_ensure_data()
	(_data["slots"] as Array)[slot_index] = _empty_slot()
	if active_slot_index == slot_index:
		active_slot_index = -1
	save_to_disk()
	saves_changed.emit()


func debug_set_slot(slot_index: int, slot_data: Dictionary) -> void:
	_validate_slot(slot_index)
	_ensure_data()
	var slot := _empty_slot()
	slot.merge(slot_data, true)
	(_data["slots"] as Array)[slot_index] = slot


func get_current_level_number() -> int:
	if active_slot_index < 0:
		return 1
	return int(get_slot(active_slot_index).get("current_level", 1))


func add_play_time(seconds: float) -> void:
	if active_slot_index < 0:
		return
	var slot: Dictionary = get_slot(active_slot_index)
	slot["play_time_sec"] = float(slot.get("play_time_sec", 0.0)) + maxf(seconds, 0.0)
	(_data["slots"] as Array)[active_slot_index] = slot


func collect_stars(amount: int) -> void:
	if active_slot_index < 0 or amount <= 0:
		return
	var slot: Dictionary = get_slot(active_slot_index)
	slot["stars"] = int(slot.get("stars", 0)) + amount
	(_data["slots"] as Array)[active_slot_index] = slot


func complete_level(level_number: int, stars_found: int) -> void:
	if active_slot_index < 0:
		return
	var slot: Dictionary = get_slot(active_slot_index)
	slot["stars"] = int(slot.get("stars", 0)) + max(stars_found, 0)
	if level_number >= LEVEL_SCENES.size():
		slot["current_level"] = LEVEL_SCENES.size()
		slot["completed"] = true
	else:
		slot["current_level"] = max(level_number + 1, int(slot.get("current_level", 1)))
	slot["resume"] = {}
	(_data["slots"] as Array)[active_slot_index] = slot
	save_to_disk()
	saves_changed.emit()


func load_level(level_number: int) -> void:
	var index := clampi(level_number, 1, LEVEL_SCENES.size()) - 1
	get_tree().change_scene_to_file(LEVEL_SCENES[index])


func return_to_save_select() -> void:
	active_slot_index = -1
	get_tree().change_scene_to_file("res://scenes/ui/save_select.tscn")


func restart_current_level() -> void:
	load_level(get_current_level_number())


func request_horse_arrival() -> void:
	_horse_arrival_pending = true


func consume_horse_arrival() -> bool:
	var pending := _horse_arrival_pending
	_horse_arrival_pending = false
	return pending


const BOSS_SCENES := {
	3: "res://scenes/bosses/boss_stampede_bull.tscn",
	7: "res://scenes/bosses/boss_midnight_coach.tscn",
	10: "res://scenes/bosses/boss_outlaw_kingpin.tscn",
}

const BOSS_ORDER: Array[int] = [3, 7, 10]


func try_load_boss_after(level_number: int) -> bool:
	if not BOSS_SCENES.has(level_number):
		return false
	get_tree().change_scene_to_file(str(BOSS_SCENES[level_number]))
	return true


func load_boss_for_level(source_level: int) -> void:
	if not BOSS_SCENES.has(source_level):
		return
	get_tree().change_scene_to_file(str(BOSS_SCENES[source_level]))


func load_next_boss(from_source_level: int) -> void:
	var index := BOSS_ORDER.find(from_source_level)
	if index < 0:
		index = 0
	else:
		index = (index + 1) % BOSS_ORDER.size()
	load_boss_for_level(BOSS_ORDER[index])


func finish_boss(source_level: int) -> void:
	if source_level >= LEVEL_SCENES.size():
		get_tree().change_scene_to_file("res://scenes/ui/victory_horizon.tscn")
		return
	request_horse_arrival()
	load_level(source_level + 1)


func save_run_state(
	level_number: int,
	checkpoint_name: String,
	collected_badges: Array[String],
	stars_found: int,
	level_play_time: float,
	tied_opponents: Array[String] = [],
	active_mode: int = 0,
	mode_remaining: float = 0.0
) -> bool:
	if active_slot_index < 0:
		return false
	var slot := get_slot(active_slot_index)
	slot["empty"] = false
	slot["resume"] = {
		"level_number": clampi(level_number, 1, LEVEL_SCENES.size()),
		"checkpoint_name": checkpoint_name,
		"collected_badges": collected_badges.duplicate(),
		"stars_found": maxi(stars_found, 0),
		"level_play_time": maxf(level_play_time, 0.0),
		"tied_opponents": tied_opponents.duplicate(),
		"active_mode": active_mode,
		"mode_remaining": maxf(mode_remaining, 0.0),
	}
	(_data["slots"] as Array)[active_slot_index] = slot
	save_to_disk()
	saves_changed.emit()
	return true


func get_run_state(level_number: int) -> Dictionary:
	if active_slot_index < 0:
		return {}
	var resume: Variant = get_slot(active_slot_index).get("resume", {})
	if not (resume is Dictionary):
		return {}
	var state := resume as Dictionary
	if int(state.get("level_number", -1)) != level_number:
		return {}
	return state.duplicate(true)


func has_run_state(level_number: int) -> bool:
	return not get_run_state(level_number).is_empty()


func load_saved_run(level_number: int) -> bool:
	if not has_run_state(level_number):
		return false
	load_level(level_number)
	return true


func restart_level_from_start(level_number: int) -> void:
	clear_run_state()
	load_level(level_number)


func clear_run_state() -> void:
	if active_slot_index < 0:
		return
	var slot := get_slot(active_slot_index)
	slot["resume"] = {}
	(_data["slots"] as Array)[active_slot_index] = slot
	save_to_disk()


func edit_custom_level(slot_index: int) -> void:
	active_custom_slot = clampi(slot_index, 0, CUSTOM_LEVEL_STORE.SLOT_COUNT - 1)
	get_tree().change_scene_to_file("res://scenes/ui/level_editor.tscn")


func play_custom_level(slot_index: int, return_to_editor: bool = true) -> void:
	active_custom_slot = clampi(slot_index, 0, CUSTOM_LEVEL_STORE.SLOT_COUNT - 1)
	custom_return_to_editor = return_to_editor
	get_tree().change_scene_to_file("res://scenes/levels/custom_level_runtime.tscn")


func open_custom_level_hub() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/custom_level_hub.tscn")


func return_from_custom_level() -> void:
	if custom_return_to_editor:
		edit_custom_level(active_custom_slot)
	else:
		open_custom_level_hub()


func get_settings() -> Dictionary:
	_ensure_data()
	return _data["settings"]


func set_setting(key: String, value: Variant) -> void:
	_ensure_data()
	var settings: Dictionary = _data["settings"]
	settings[key] = value
	_data["settings"] = settings
	_apply_settings()
	save_to_disk()
	settings_changed.emit()


func save_to_disk() -> void:
	_ensure_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file.")
		return
	file.store_string(JSON.stringify(_data, "\t"))


func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = _default_data()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		_data = _default_data()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_data = _default_data()
		return
	_data = _migrate_save(parsed as Dictionary)
	_ensure_data()
	saves_changed.emit()


func level_scene_for(level_number: int) -> String:
	var index := clampi(level_number, 1, LEVEL_SCENES.size()) - 1
	return LEVEL_SCENES[index]


func level_name_for(level_number: int) -> String:
	var index := clampi(level_number, 1, LEVEL_NAMES.size()) - 1
	return LEVEL_NAMES[index]


func _ensure_data() -> void:
	if typeof(_data) != TYPE_DICTIONARY or not _data.has("slots") or not _data.has("settings"):
		_data = _default_data()


func _apply_settings() -> void:
	_ensure_data()
	var settings: Dictionary = _data["settings"]
	if bool(settings.get("fullscreen", false)):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"slots": [_empty_slot(), _empty_slot(), _empty_slot()],
		"settings": {
			"music_volume": 0.8,
			"sfx_volume": 0.8,
			"vibration": true,
			"fullscreen": false,
		},
	}


func _empty_slot() -> Dictionary:
	return {
		"empty": true,
		"current_level": 1,
		"stars": 0,
		"play_time_sec": 0.0,
		"completed": false,
		"resume": {},
	}


func _migrate_save(raw: Dictionary) -> Dictionary:
	var data := _default_data()
	if raw.has("settings") and typeof(raw["settings"]) == TYPE_DICTIONARY:
		var merged: Dictionary = data["settings"]
		merged.merge(raw["settings"] as Dictionary, true)
		data["settings"] = merged
	if raw.has("slots") and typeof(raw["slots"]) == TYPE_ARRAY:
		var slots: Array = data["slots"]
		var incoming: Array = raw["slots"]
		for i in range(mini(SLOT_COUNT, incoming.size())):
			if typeof(incoming[i]) == TYPE_DICTIONARY:
				var slot: Dictionary = _empty_slot()
				slot.merge(incoming[i] as Dictionary, true)
				slots[i] = slot
		data["slots"] = slots
	data["version"] = SAVE_VERSION
	return data


func _validate_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		push_error("Invalid save slot: %d" % slot_index)
