extends Node

## Owns save slots, settings, and level progression.

const SAVE_VERSION := 4
const SLOT_COUNT := 3
const CUSTOM_LEVEL_STORE := preload("res://scripts/levels/custom_level_store.gd")
const SavePaths := preload("res://scripts/autoload/save_paths.gd")

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
var custom_level_draft: Dictionary = {}
var custom_return_to_editor: bool = true
var active_campaign_position: int = 1
var active_campaign_source_level: int = 1
var campaign_custom_active: bool = false
var _campaign_load_pending: bool = false
var _horse_arrival_pending: bool = false
var _data: Dictionary = {}


func _ready() -> void:
	_data = _default_data()
	SavePaths.migrate_legacy_if_needed()
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
	var count := campaign_level_count()
	if level_number >= count:
		slot["current_level"] = count
		slot["completed"] = true
	else:
		slot["current_level"] = max(level_number + 1, int(slot.get("current_level", 1)))
	slot["resume"] = {}
	(_data["slots"] as Array)[active_slot_index] = slot
	save_to_disk()
	saves_changed.emit()


func load_level(level_number: int) -> void:
	var entries := campaign_entries()
	var index := clampi(level_number, 1, entries.size()) - 1
	var entry := entries[index]
	active_campaign_position = index + 1
	active_campaign_source_level = int(entry.get("source_level", 0))
	_campaign_load_pending = true
	if str(entry.get("kind", "builtin")) == "custom":
		active_custom_slot = int(entry.get("custom_slot", 0))
		custom_return_to_editor = false
		campaign_custom_active = true
		get_tree().change_scene_to_file("res://scenes/levels/custom_level_runtime.tscn")
		return
	campaign_custom_active = false
	get_tree().change_scene_to_file(str(entry.get("scene", LEVEL_SCENES[0])))


func consume_campaign_context() -> Dictionary:
	if not _campaign_load_pending:
		return {}
	_campaign_load_pending = false
	return {
		"position": active_campaign_position,
		"source_level": active_campaign_source_level,
		"count": campaign_level_count(),
		"custom": campaign_custom_active,
	}


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
	var source_level := active_campaign_source_level
	if source_level <= 0 or not BOSS_SCENES.has(source_level):
		return false
	get_tree().change_scene_to_file(str(BOSS_SCENES[source_level]))
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


func load_next_boss_from_level(level_number: int) -> void:
	## From a campaign trail: open the next boss at or after this level.
	## Levels 1–3 → Bull, 4–7 → Coach, 8–10 → Kingpin; from a boss, use load_next_boss.
	var target := BOSS_ORDER[0]
	for boss_level in BOSS_ORDER:
		if level_number <= boss_level:
			target = boss_level
			break
		target = boss_level
	# If already past the last boss level number while still on L10, still open Kingpin.
	if level_number > BOSS_ORDER[BOSS_ORDER.size() - 1]:
		target = BOSS_ORDER[BOSS_ORDER.size() - 1]
	# Double-tap again from the matching boss level should advance to the next arena.
	# First entry from trails always lands on the boss for that stretch.
	load_boss_for_level(target)


func finish_boss(source_level: int) -> void:
	if active_campaign_position >= campaign_level_count():
		get_tree().change_scene_to_file("res://scenes/ui/victory_horizon.tscn")
		return
	request_horse_arrival()
	load_level(active_campaign_position + 1)


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
		"level_number": clampi(level_number, 1, campaign_level_count()),
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


func restart_campaign_from_start() -> void:
	reset_campaign_to_start()
	load_level(1)


func reset_campaign_to_start() -> void:
	## Return the active save to Level 1 without deleting earned badges or time.
	## This makes "Restart from Start" genuinely restart the whole trail instead
	## of merely restarting whichever level happens to be open.
	if active_slot_index >= 0:
		var slot := get_slot(active_slot_index)
		slot["empty"] = false
		slot["current_level"] = 1
		slot["completed"] = false
		slot["resume"] = {}
		(_data["slots"] as Array)[active_slot_index] = slot
		save_to_disk()
		saves_changed.emit()


func clear_run_state() -> void:
	if active_slot_index < 0:
		return
	var slot := get_slot(active_slot_index)
	slot["resume"] = {}
	(_data["slots"] as Array)[active_slot_index] = slot
	save_to_disk()


func edit_custom_level(slot_index: int) -> void:
	active_custom_slot = clampi(slot_index, 0, CUSTOM_LEVEL_STORE.SLOT_COUNT - 1)
	custom_level_draft = {}
	get_tree().change_scene_to_file("res://scenes/ui/level_editor.tscn")


func edit_new_custom_level(slot_index: int, draft: Dictionary) -> void:
	active_custom_slot = clampi(slot_index, 0, CUSTOM_LEVEL_STORE.SLOT_COUNT - 1)
	custom_level_draft = draft.duplicate(true)
	custom_level_draft["slot"] = active_custom_slot
	get_tree().change_scene_to_file("res://scenes/ui/level_editor.tscn")


func play_custom_level(slot_index: int, return_to_editor: bool = true) -> void:
	active_custom_slot = clampi(slot_index, 0, CUSTOM_LEVEL_STORE.SLOT_COUNT - 1)
	custom_return_to_editor = return_to_editor
	_campaign_load_pending = false
	campaign_custom_active = false
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


func save_path() -> String:
	return SavePaths.campaign_path()


func save_to_disk() -> void:
	_ensure_data()
	var path := save_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % path)
		return
	file.store_string(JSON.stringify(_data, "\t"))


func load_from_disk() -> void:
	var path := save_path()
	if not FileAccess.file_exists(path):
		_data = _default_data()
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_data = _default_data()
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_data = _default_data()
		return
	var raw := parsed as Dictionary
	var incoming_version := int(raw.get("version", 0))
	# Older save formats are intentionally incompatible — start fresh.
	if incoming_version < SAVE_VERSION:
		_data = _default_data()
		save_to_disk()
		saves_changed.emit()
		return
	_data = _migrate_save(raw)
	_ensure_data()
	saves_changed.emit()


func level_scene_for(level_number: int) -> String:
	var entries := campaign_entries()
	var entry := entries[clampi(level_number, 1, entries.size()) - 1]
	return (
		"res://scenes/levels/custom_level_runtime.tscn"
		if str(entry.get("kind", "builtin")) == "custom"
		else str(entry.get("scene", LEVEL_SCENES[0]))
	)


func level_name_for(level_number: int) -> String:
	var entries := campaign_entries()
	var number := clampi(level_number, 1, entries.size())
	return "%d: %s" % [number, tr(str(entries[number - 1].get("title", "Trail")))]


func campaign_entries() -> Array[Dictionary]:
	return CUSTOM_LEVEL_STORE.campaign_entries()


func campaign_level_count() -> int:
	return campaign_entries().size()


func finish_campaign() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/victory_horizon.tscn")


func _ensure_data() -> void:
	if typeof(_data) != TYPE_DICTIONARY or not _data.has("slots") or not _data.has("settings"):
		_data = _default_data()


func _apply_settings() -> void:
	_ensure_data()
	var settings: Dictionary = _data["settings"]
	TranslationServer.set_locale(String(settings.get("language", "de")))
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
			"language": "de",
			"narration": true,
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
	## Same SAVE_VERSION only — older files are discarded in load_from_disk.
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
