extends RefCounted

## Resolves where campaign and custom-trail saves live.
## Editor / Godot CLI → <project>/savegames/
## Exported exe → <exe folder>/savegames/

const FOLDER_NAME := "savegames"
const CAMPAIGN_FILE := "save_data.json"
const CUSTOM_SUBDIR := "custom_levels"
const LEGACY_USER_SAVE := "user://save_data.json"
const LEGACY_USER_CUSTOM := "user://custom_levels"


static func root_dir() -> String:
	var absolute := _preferred_root()
	DirAccess.make_dir_recursive_absolute(absolute)
	return absolute


static func campaign_path() -> String:
	return root_dir().path_join(CAMPAIGN_FILE)


static func custom_levels_dir() -> String:
	var path := root_dir().path_join(CUSTOM_SUBDIR)
	DirAccess.make_dir_recursive_absolute(path)
	return path


static func custom_level_path(slot_index: int) -> String:
	return custom_levels_dir().path_join("trail_%d.json" % (clampi(slot_index, 0, 2) + 1))


static func migrate_legacy_if_needed() -> void:
	var campaign := campaign_path()
	if not FileAccess.file_exists(campaign) and FileAccess.file_exists(LEGACY_USER_SAVE):
		_copy_file(LEGACY_USER_SAVE, campaign)
	for i in range(3):
		var dest := custom_level_path(i)
		if FileAccess.file_exists(dest):
			continue
		var legacy := "%s/trail_%d.json" % [LEGACY_USER_CUSTOM, i + 1]
		if FileAccess.file_exists(legacy):
			_copy_file(legacy, dest)


static func _preferred_root() -> String:
	if OS.has_feature("editor") or _is_godot_tools_binary():
		return ProjectSettings.globalize_path("res://").path_join(FOLDER_NAME)
	return OS.get_executable_path().get_base_dir().path_join(FOLDER_NAME)


static func _is_godot_tools_binary() -> bool:
	var name := OS.get_executable_path().get_file().to_lower()
	return name.contains("godot")


static func _copy_file(from_path: String, to_path: String) -> void:
	var src := FileAccess.open(from_path, FileAccess.READ)
	if src == null:
		return
	var parent := to_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(parent)
	var dst := FileAccess.open(to_path, FileAccess.WRITE)
	if dst == null:
		return
	dst.store_buffer(src.get_buffer(src.get_length()))
