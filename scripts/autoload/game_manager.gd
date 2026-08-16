extends Node

## Owns save slots, settings, and level progression.

const SAVE_VERSION := 4
const SLOT_COUNT := 3
## Legacy default when an older Advanced save has no badges_per_life field.
const ADVANCED_START_LIVES := 3
const BADGES_PER_LIFE := 30
## Classic = 0. Advanced tiers = sheriff badges needed for +1 life.
const ADVANCED_BADGE_TIERS: Array[int] = [5, 10, 15, 30]
const PLAYER_COWBOY := "cowboy"
const PLAYER_COWGIRL := "cowgirl"
const CUSTOM_LEVEL_STORE := preload("res://scripts/levels/custom_level_store.gd")
const SavePaths := preload("res://scripts/autoload/save_paths.gd")

## Single source of truth lives on CustomLevelStore; keep these aliases for callers/tests.
const LEVEL_SCENES: PackedStringArray = CUSTOM_LEVEL_STORE.BUILTIN_SCENES
const LEVEL_NAMES: PackedStringArray = CUSTOM_LEVEL_STORE.BUILTIN_NAMES

signal saves_changed
signal settings_changed
signal active_slot_changed(slot_index: int)
signal lives_changed(lives: int)

var active_slot_index: int = -1
var active_custom_slot: int = 0
var custom_level_draft: Dictionary = {}
var custom_return_to_editor: bool = true
## True while a Campaign Workshop Play Test (or its Restart Level) is running.
var custom_playtest_active: bool = false
## Campaign Workshop: stamp grid collapsed for the current game session.
var workshop_grid_collapsed: bool = false
var active_campaign_position: int = 1
var active_campaign_source_level: int = 1
var campaign_custom_active: bool = false
var _campaign_load_pending: bool = false
var _horse_arrival_pending: bool = false
var _data: Dictionary = {}
var _save_dirty: bool = false
var _save_flush_queued: bool = false


func _ready() -> void:
	_data = _default_data()
	SavePaths.migrate_legacy_if_needed()
	CUSTOM_LEVEL_STORE.migrate_extra_slot_shift()
	load_from_disk()
	_apply_settings()


func _notification(what: int) -> void:
	## Flush before quit so a camp touch that only queued a write still lands.
	if (
		what == NOTIFICATION_WM_CLOSE_REQUEST
		or what == NOTIFICATION_PREDELETE
		or what == NOTIFICATION_EXIT_TREE
	):
		flush_save_to_disk()


func get_slot(slot_index: int) -> Dictionary:
	_validate_slot(slot_index)
	_ensure_data()
	return (_data["slots"] as Array)[slot_index]


func is_slot_empty(slot_index: int) -> bool:
	return bool(get_slot(slot_index).get("empty", true))


func slot_is_advanced(slot_index: int) -> bool:
	return slot_badges_per_life(slot_index) > 0


func slot_badges_per_life(slot_index: int) -> int:
	_validate_slot(slot_index)
	var slot := get_slot(slot_index)
	return normalize_badges_per_life(
		slot.get("badges_per_life", -1),
		bool(slot.get("advanced_mode", false))
	)


func is_advanced_mode() -> bool:
	if active_slot_index < 0:
		return false
	return slot_is_advanced(active_slot_index)


func active_badges_per_life() -> int:
	if active_slot_index < 0:
		return 0
	return slot_badges_per_life(active_slot_index)


func normalize_player_character(value: Variant) -> String:
	return PLAYER_COWGIRL if String(value) == PLAYER_COWGIRL else PLAYER_COWBOY


func normalize_badges_per_life(value: Variant, advanced_fallback: bool = false) -> int:
	var amount := int(value) if value != null else -1
	if amount == 0:
		return 0
	if amount in ADVANCED_BADGE_TIERS:
		return amount
	## Older saves only stored advanced_mode=true → keep the classic 30-badge pace.
	if advanced_fallback:
		return BADGES_PER_LIFE
	return 0


func advanced_start_lives(badges_per_life: int = -1) -> int:
	var amount := badges_per_life if badges_per_life >= 0 else get_badges_per_life_setting()
	if amount <= 0:
		return 0
	## Easier Advanced paces start with a fuller heart belt.
	if amount == 5 or amount == 10:
		return 5
	return ADVANCED_START_LIVES


func trail_mode_label(badges_per_life: int = -1) -> String:
	var amount := badges_per_life if badges_per_life >= 0 else get_badges_per_life_setting()
	if amount <= 0:
		return tr("Classic")
	return tr("Advanced ★%d") % amount


func trail_mode_icon_path(badges_per_life: int = -1) -> String:
	var amount := badges_per_life if badges_per_life >= 0 else get_badges_per_life_setting()
	if amount <= 0:
		return "res://assets/ui/menu_trail_mode_classic.png"
	return "res://assets/ui/menu_trail_mode_%d.png" % amount


func cycle_badges_per_life(current: int) -> int:
	var normalized := normalize_badges_per_life(current)
	if normalized <= 0:
		return ADVANCED_BADGE_TIERS[0]
	var index := ADVANCED_BADGE_TIERS.find(normalized)
	if index < 0 or index >= ADVANCED_BADGE_TIERS.size() - 1:
		return 0
	return ADVANCED_BADGE_TIERS[index + 1]


func slot_player_character(slot_index: int) -> String:
	_validate_slot(slot_index)
	return normalize_player_character(get_slot(slot_index).get("player_character", PLAYER_COWBOY))


func get_player_character() -> String:
	## During a run, the active save slot owns the rider; on the title screen, settings do.
	if active_slot_index >= 0:
		return slot_player_character(active_slot_index)
	return normalize_player_character(get_settings().get("player_character", PLAYER_COWBOY))


func get_player_asset_folder() -> String:
	if get_player_character() == PLAYER_COWGIRL:
		return "res://assets/player/cowgirl/"
	return "res://assets/player/"


func get_mounted_horse_texture(frame: String) -> Texture2D:
	var prefix := "cowgirl" if get_player_character() == PLAYER_COWGIRL else "cowboy"
	return load("res://assets/world/%s_horse_%s.png" % [prefix, frame]) as Texture2D


func is_advanced_mode_setting() -> bool:
	return get_badges_per_life_setting() > 0


func get_badges_per_life_setting() -> int:
	var settings := get_settings()
	return normalize_badges_per_life(
		settings.get("badges_per_life", -1),
		bool(settings.get("advanced_mode", false))
	)


func set_badges_per_life_setting(value: int) -> void:
	var amount := normalize_badges_per_life(value)
	_ensure_data()
	var settings: Dictionary = _data["settings"]
	settings["badges_per_life"] = amount
	settings["advanced_mode"] = amount > 0
	_data["settings"] = settings
	_apply_settings()
	save_to_disk()
	settings_changed.emit()


func reset_trail_mode_to_classic() -> void:
	## Title screen always offers Simple/Classic first. Hearts stay off until picked.
	if get_badges_per_life_setting() == 0:
		return
	set_badges_per_life_setting(0)


func get_lives() -> int:
	if not is_advanced_mode() or active_slot_index < 0:
		return 0
	return int(get_slot(active_slot_index).get("lives", advanced_start_lives(active_badges_per_life())))


func prepare_slot_for_start(slot_index: int) -> void:
	_validate_slot(slot_index)
	_ensure_data()
	var slot: Dictionary = get_slot(slot_index)
	var badges_per_life := get_badges_per_life_setting()
	var advanced_mode := badges_per_life > 0
	var character := normalize_player_character(get_settings().get("player_character", PLAYER_COWBOY))
	var was_advanced := slot_badges_per_life(slot_index) > 0
	var start_lives := advanced_start_lives(badges_per_life)
	slot["advanced_mode"] = advanced_mode
	slot["badges_per_life"] = badges_per_life
	slot["player_character"] = character
	if bool(slot.get("empty", true)):
		slot["lives"] = start_lives
		slot["lifetime_badges"] = 0
		slot["badge_life_tier"] = 0
	elif advanced_mode:
		var lifetime := int(slot.get("lifetime_badges", 0))
		## Avoid a sudden pile of free lives when switching badge pace.
		slot["badge_life_tier"] = lifetime / badges_per_life
		if not was_advanced or int(slot.get("lives", 0)) <= 0:
			slot["lives"] = start_lives
	else:
		slot["lives"] = 0
		slot["badge_life_tier"] = 0
	(_data["slots"] as Array)[slot_index] = slot


func apply_play_settings_from_slot(slot_index: int) -> void:
	## Title-screen focus: filled doors restore their rider. Trail mode stays
	## Classic unless the player picks hearts on the title screen or in Settings.
	_validate_slot(slot_index)
	_ensure_data()
	var slot: Dictionary = get_slot(slot_index)
	if bool(slot.get("empty", true)):
		return
	var character := normalize_player_character(slot.get("player_character", PLAYER_COWBOY))
	var settings: Dictionary = _data["settings"]
	if normalize_player_character(settings.get("player_character", PLAYER_COWBOY)) == character:
		return
	settings["player_character"] = character
	_data["settings"] = settings
	save_to_disk()
	settings_changed.emit()


func commit_play_settings_to_slot(slot_index: int) -> void:
	## Keep a focused filled door in sync when the title-screen picks change.
	_validate_slot(slot_index)
	_ensure_data()
	var slot: Dictionary = get_slot(slot_index)
	if bool(slot.get("empty", true)):
		return
	var character := normalize_player_character(get_settings().get("player_character", PLAYER_COWBOY))
	var badges_per_life := get_badges_per_life_setting()
	var dirty := false
	if normalize_player_character(slot.get("player_character", PLAYER_COWBOY)) != character:
		slot["player_character"] = character
		dirty = true
	if slot_badges_per_life(slot_index) != badges_per_life:
		slot["badges_per_life"] = badges_per_life
		slot["advanced_mode"] = badges_per_life > 0
		dirty = true
	if not dirty:
		return
	(_data["slots"] as Array)[slot_index] = slot
	save_to_disk()
	saves_changed.emit()


func lose_life() -> bool:
	## Advanced Mode only. Returns false when no lives remain.
	if not is_advanced_mode() or active_slot_index < 0:
		return true
	var slot: Dictionary = get_slot(active_slot_index)
	var lives := maxi(int(slot.get("lives", advanced_start_lives())) - 1, 0)
	slot["lives"] = lives
	(_data["slots"] as Array)[active_slot_index] = slot
	save_to_disk()
	lives_changed.emit(lives)
	return lives > 0


func register_badges_collected(count: int) -> void:
	if not is_advanced_mode() or active_slot_index < 0 or count <= 0:
		return
	var slot: Dictionary = get_slot(active_slot_index)
	var badges_per_life := maxi(slot_badges_per_life(active_slot_index), 1)
	var total := int(slot.get("lifetime_badges", 0)) + count
	slot["lifetime_badges"] = total
	var tier := total / badges_per_life
	var awarded := int(slot.get("badge_life_tier", 0))
	if tier > awarded:
		slot["lives"] = int(slot.get("lives", advanced_start_lives(badges_per_life))) + (tier - awarded)
		slot["badge_life_tier"] = tier
		lives_changed.emit(int(slot["lives"]))
	(_data["slots"] as Array)[active_slot_index] = slot
	save_to_disk()


func trigger_game_over() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")


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
	elif is_advanced_mode() and int(slot.get("lives", 0)) <= 0:
		slot["lives"] = advanced_start_lives(slot_badges_per_life(slot_index))
		(_data["slots"] as Array)[slot_index] = slot
		save_to_disk()
	else:
		save_to_disk()
	active_slot_changed.emit(slot_index)
	if is_advanced_mode():
		lives_changed.emit(get_lives())
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
	flush_save_to_disk()
	custom_playtest_active = false
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
		_goto_game_scene("res://scenes/levels/custom_level_runtime.tscn")
		return
	campaign_custom_active = false
	_goto_game_scene(str(entry.get("scene", LEVEL_SCENES[0])))


func return_to_save_select() -> void:
	flush_save_to_disk()
	active_slot_index = -1
	custom_playtest_active = false
	_goto_game_scene("res://scenes/ui/save_select.tscn")


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
	16: "res://scenes/bosses/boss_cave_dragon.tscn",
}

const BOSS_ORDER: Array[int] = [3, 7, 10, 16]


func try_load_boss_after(_level_number: int) -> bool:
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
	## Levels 1–3 → Bull, 4–7 → Coach, 8–10 → Kingpin, 11–16 → Dragon; from a boss, use load_next_boss.
	var target := BOSS_ORDER[BOSS_ORDER.size() - 1]
	for boss_level in BOSS_ORDER:
		if level_number <= boss_level:
			target = boss_level
			break
	load_boss_for_level(target)


func finish_boss(_source_level: int) -> void:
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
		## level_number is already the live trail index — avoid rebuilding campaign_entries() here.
		"level_number": maxi(level_number, 1),
		"checkpoint_name": checkpoint_name,
		"collected_badges": collected_badges.duplicate(),
		"stars_found": maxi(stars_found, 0),
		"level_play_time": maxf(level_play_time, 0.0),
		"tied_opponents": tied_opponents.duplicate(),
		"active_mode": active_mode,
		"mode_remaining": maxf(mode_remaining, 0.0),
	}
	(_data["slots"] as Array)[active_slot_index] = slot
	## Defer the disk write so camp activation does not hitch the gameplay frame.
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


func restart_current_level(level_number: int) -> void:
	## Reload the open trail from its start camp without wiping campaign progress.
	clear_run_state()
	if active_slot_index >= 0:
		var slot := get_slot(active_slot_index)
		slot["current_level"] = maxi(int(slot.get("current_level", 1)), clampi(level_number, 1, campaign_level_count()))
		slot["completed"] = false
		(_data["slots"] as Array)[active_slot_index] = slot
		save_to_disk()
		saves_changed.emit()
	load_level(clampi(level_number, 1, maxi(campaign_level_count(), 1)))


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
	custom_playtest_active = false
	_goto_game_scene("res://scenes/ui/level_editor.tscn")


func edit_new_custom_level(slot_index: int, draft: Dictionary) -> void:
	active_custom_slot = clampi(slot_index, 0, CUSTOM_LEVEL_STORE.SLOT_COUNT - 1)
	custom_level_draft = draft.duplicate(true)
	custom_level_draft["slot"] = active_custom_slot
	custom_playtest_active = false
	_goto_game_scene("res://scenes/ui/level_editor.tscn")


func begin_custom_playtest(slot_index: int, return_to_editor: bool = true) -> void:
	active_custom_slot = clampi(slot_index, 0, CUSTOM_LEVEL_STORE.SLOT_COUNT - 1)
	custom_return_to_editor = return_to_editor
	custom_playtest_active = true
	_campaign_load_pending = false
	campaign_custom_active = false


func play_custom_level(slot_index: int, return_to_editor: bool = true) -> void:
	begin_custom_playtest(slot_index, return_to_editor)
	_goto_game_scene("res://scenes/levels/custom_level_runtime.tscn")


func open_custom_level_hub() -> void:
	custom_playtest_active = false
	_goto_game_scene("res://scenes/ui/custom_level_hub.tscn")


func return_from_custom_level() -> void:
	if custom_return_to_editor:
		edit_custom_level(active_custom_slot)
	else:
		open_custom_level_hub()


func _goto_game_scene(path: String) -> void:
	var tree := get_tree()
	if tree == null or path.is_empty():
		return
	tree.paused = false
	call_deferred("_apply_game_scene", path)


func scene_change_is_reload(current_path: String, target_path: String) -> bool:
	return not target_path.is_empty() and current_path == target_path


func _apply_game_scene(path: String) -> void:
	var tree := get_tree()
	if tree == null or path.is_empty():
		return
	tree.paused = false
	var current := tree.current_scene
	var current_path := str(current.scene_file_path) if current != null else ""
	if scene_change_is_reload(current_path, path):
		if tree.reload_current_scene() == OK:
			return
	tree.change_scene_to_file(path)


func get_settings() -> Dictionary:
	_ensure_data()
	return _data["settings"]


func set_setting(key: String, value: Variant) -> void:
	_ensure_data()
	var settings: Dictionary = _data["settings"]
	if key == "advanced_mode":
		## Legacy callers: true keeps/chooses ★30 Advanced, false returns to Classic.
		if bool(value):
			var current := normalize_badges_per_life(settings.get("badges_per_life", 0))
			settings["badges_per_life"] = current if current > 0 else BADGES_PER_LIFE
			settings["advanced_mode"] = true
		else:
			settings["badges_per_life"] = 0
			settings["advanced_mode"] = false
	elif key == "badges_per_life":
		var amount := normalize_badges_per_life(value)
		settings["badges_per_life"] = amount
		settings["advanced_mode"] = amount > 0
	else:
		settings[key] = value
	_data["settings"] = settings
	_apply_settings()
	save_to_disk()
	settings_changed.emit()


func save_path() -> String:
	return SavePaths.campaign_path()


func save_to_disk() -> void:
	## Mark dirty and write on the next idle frame so camp touches stay smooth.
	_ensure_data()
	_save_dirty = true
	if _save_flush_queued:
		return
	_save_flush_queued = true
	call_deferred("flush_save_to_disk")


func flush_save_to_disk() -> void:
	_save_flush_queued = false
	if not _save_dirty:
		return
	_save_dirty = false
	_ensure_data()
	var path := save_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save file: %s" % path)
		## Keep dirty so a later flush / quit can retry.
		_save_dirty = true
		if not _save_flush_queued:
			_save_flush_queued = true
			call_deferred("flush_save_to_disk")
		return
	## Compact JSON — pretty tabs made every camp save hitch on the main thread.
	file.store_string(JSON.stringify(_data))


func load_from_disk() -> void:
	flush_save_to_disk()
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
		_save_dirty = true
		flush_save_to_disk()
		saves_changed.emit()
		return
	_data = _migrate_save(raw)
	_ensure_data()
	saves_changed.emit()



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
	## Wait until the window exists. Setting fullscreen during autoload boot on
	## Windows can leave mouse hits offset from the painted buttons.
	call_deferred("_apply_window_mode")


func _apply_window_mode() -> void:
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
			"language": "de",
			"player_character": PLAYER_COWBOY,
			"advanced_mode": false,
			"badges_per_life": 0,
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
		"advanced_mode": false,
		"badges_per_life": 0,
		"player_character": PLAYER_COWBOY,
		"lives": 0,
		"lifetime_badges": 0,
		"badge_life_tier": 0,
	}


func _migrate_save(raw: Dictionary) -> Dictionary:
	## Same SAVE_VERSION only — older files are discarded in load_from_disk.
	var data := _default_data()
	if raw.has("settings") and typeof(raw["settings"]) == TYPE_DICTIONARY:
		var merged: Dictionary = data["settings"]
		merged.merge(raw["settings"] as Dictionary, true)
		merged["badges_per_life"] = normalize_badges_per_life(
			merged.get("badges_per_life", -1),
			bool(merged.get("advanced_mode", false))
		)
		merged["advanced_mode"] = int(merged["badges_per_life"]) > 0
		data["settings"] = merged
	if raw.has("slots") and typeof(raw["slots"]) == TYPE_ARRAY:
		var slots: Array = data["slots"]
		var incoming: Array = raw["slots"]
		for i in range(mini(SLOT_COUNT, incoming.size())):
			if typeof(incoming[i]) == TYPE_DICTIONARY:
				var slot: Dictionary = _empty_slot()
				slot.merge(incoming[i] as Dictionary, true)
				slot["badges_per_life"] = normalize_badges_per_life(
					slot.get("badges_per_life", -1),
					bool(slot.get("advanced_mode", false))
				)
				slot["advanced_mode"] = int(slot["badges_per_life"]) > 0
				slots[i] = slot
		data["slots"] = slots
	data["version"] = SAVE_VERSION
	return data


func _validate_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		push_error("Invalid save slot: %d" % slot_index)
