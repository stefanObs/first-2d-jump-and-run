extends Control

## Grid/stamp editor for making short family trails without touching campaign data.

const TYPES := [
	["ground", "Dirt"],
	["platform", "Plank"],
	["star", "Badge"],
	["cactus", "Cactus"],
	["canyon", "Canyon"],
	["checkpoint", "Camp"],
	["spring", "Spring"],
	["bandit", "Bandit"],
	["goal", "Saloon"],
	["erase", "Erase"],
]

var _data: Dictionary
var _selected_type: String = "ground"
var _cells: Array[Button] = []
var _status: Label
var _title_edit: LineEdit
var _preview: LevelPreview
var _save_button: Button
var _reset_button: Button
var _reset_dialog: ConfirmationDialog
var _saved_data: Dictionary
var _initial_data: Dictionary
var _has_saved_state := false
var _dirty := false
var _grid: GridContainer
var _hover_column: int = -1


func _ready() -> void:
	var draft: Dictionary = GameManager.custom_level_draft
	if (
		not draft.is_empty()
		and int(draft.get("slot", -1)) == GameManager.active_custom_slot
	):
		_data = draft.duplicate(true)
		GameManager.custom_level_draft = {}
	else:
		_data = CustomLevelStore.load_level(GameManager.active_custom_slot)
	_data = CustomLevelStore.sanitize(_data, GameManager.active_custom_slot)
	_initial_data = _data.duplicate(true)
	_has_saved_state = CustomLevelStore.exists(GameManager.active_custom_slot)
	_saved_data = (
		CustomLevelStore.load_level(GameManager.active_custom_slot)
		if _has_saved_state
		else _initial_data.duplicate(true)
	)
	_dirty = not _has_saved_state
	_build_ui()
	_refresh_grid()
	_update_action_state()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.55, 0.8, 0.98)
	add_child(background)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	root.add_theme_constant_override(&"separation", 8)
	add_child(root)

	var heading := HBoxContainer.new()
	root.add_child(heading)
	var title := Label.new()
	title.text = (
		tr("Edit Campaign Level")
		if str(_data.get("kind", "")) == "override"
		else tr("Add Campaign Level")
	)
	title.add_theme_font_size_override(&"font_size", 28)
	title.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	title.custom_minimum_size.x = 320
	heading.add_child(title)
	_title_edit = LineEdit.new()
	_title_edit.text = str(_data.get("title", "Family Trail"))
	_title_edit.placeholder_text = tr("Trail name")
	_title_edit.custom_minimum_size = Vector2(340, 42)
	_title_edit.text_changed.connect(_on_title_changed)
	heading.add_child(_title_edit)

	_preview = LevelPreview.new()
	_preview.name = "LevelPreview"
	_preview.custom_minimum_size = Vector2(0, 210)
	_preview.hover_column_changed.connect(_on_preview_hover_column)
	root.add_child(_preview)

	var instructions := Label.new()
	instructions.text = tr("1. Pick a stamp   2. Pick a square   3. Save or Play Test")
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override(&"font_size", 17)
	root.add_child(instructions)

	var trail_help := Label.new()
	trail_help.text = tr("Bottom row is the trail: Dirt or Canyon sets the ground and what sits below it.")
	trail_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trail_help.add_theme_font_size_override(&"font_size", 15)
	trail_help.add_theme_color_override(&"font_color", Color(0.4, 0.2, 0.08))
	root.add_child(trail_help)

	var palette := HBoxContainer.new()
	palette.alignment = BoxContainer.ALIGNMENT_CENTER
	palette.add_theme_constant_override(&"separation", 6)
	root.add_child(palette)
	for item in TYPES:
		var button := Button.new()
		button.text = tr(str(item[1]))
		button.custom_minimum_size = Vector2(108, 44)
		button.add_theme_font_size_override(&"font_size", 16)
		var captured := str(item[0])
		button.pressed.connect(func() -> void:
			_selected_type = captured
			_status.text = "%s: %s" % [tr("Stamp"), tr(str(item[1]))]
		)
		palette.add_child(button)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 210)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = int(_data.get("width", 24))
	_grid.add_theme_constant_override(&"h_separation", 2)
	_grid.add_theme_constant_override(&"v_separation", 2)
	scroll.add_child(_grid)
	var width := int(_data.get("width", 24))
	var height := int(_data.get("height", 8))
	for y in range(height):
		for x in range(width):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(38, 30)
			cell.add_theme_font_size_override(&"font_size", 9)
			var cell_x := x
			var cell_y := y
			cell.pressed.connect(func() -> void: _place(cell_x, cell_y))
			cell.mouse_entered.connect(func() -> void: _set_hover_column(cell_x))
			_grid.add_child(cell)
			_cells.append(cell)

	_status = Label.new()
	_status.text = tr("Stamp: Dirt — keep a dirt path under the cowboy and saloon.")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override(&"font_size", 16)
	root.add_child(_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override(&"separation", 12)
	root.add_child(actions)
	_save_button = _add_action(actions, tr("Save Trail"), _save, "SaveButton")
	_reset_button = _add_action(actions, tr("Reset Changes"), _request_reset, "ResetButton")
	_add_action(actions, tr("Play Test"), _play_test, "PlayTestButton")
	_add_action(
		actions,
		tr("Back to Campaign Workshop"),
		GameManager.open_custom_level_hub,
		"BackButton"
	)

	_reset_dialog = ConfirmationDialog.new()
	_reset_dialog.name = "ResetConfirmation"
	_reset_dialog.title = tr("Reset trail?")
	_reset_dialog.dialog_text = tr("Discard unsaved changes and return to the last saved trail?")
	_reset_dialog.ok_button_text = tr("Reset")
	_reset_dialog.cancel_button_text = tr("Keep editing")
	_reset_dialog.confirmed.connect(_reset)
	add_child(_reset_dialog)


func _add_action(
	parent: Control, text: String, action: Callable, node_name: String
) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(200, 52)
	button.add_theme_font_size_override(&"font_size", 18)
	button.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _trail_y() -> int:
	return CustomLevelStore.trail_row(int(_data.get("height", 8)))


func _set_hover_column(column: int) -> void:
	_hover_column = column
	if _preview != null:
		_preview.set_hover_column(column)


func _on_preview_hover_column(column: int) -> void:
	_hover_column = column
	_refresh_grid_highlights()


func _place(x: int, y: int) -> void:
	var objects := _objects()
	var before := objects.duplicate(true)
	var trail := _trail_y()
	if _selected_type == "erase":
		_erase_at(objects, x, y)
	elif _selected_type == "canyon" or _selected_type == "pit":
		# Canyon belongs on the trail row: it defines the opening below the surface.
		_erase_at(objects, x, trail, true)
		objects.append({"type": "canyon", "x": x, "y": trail})
	elif _selected_type == "ground":
		# Dirt on the trail row sets the bank; dirt above it builds a step ledge.
		var target_y := y if y <= trail else trail
		if not _has_type_at(objects, x, target_y, "ground"):
			objects.append({"type": "ground", "x": x, "y": target_y})
		# Stamping dirt above the trail also keeps the trail bank underneath.
		if target_y < trail and not _has_type_at(objects, x, trail, "ground"):
			if not _has_type_at(objects, x, trail, "canyon"):
				objects.append({"type": "ground", "x": x, "y": trail})
		# Dirt replaces a canyon opening on the trail row.
		if target_y == trail:
			for i in range(objects.size() - 1, -1, -1):
				var object := objects[i] as Dictionary
				if (
					int(object.get("x", -1)) == x
					and int(object.get("y", -1)) == trail
					and str(object.get("type", "")) in ["canyon", "pit"]
				):
					objects.remove_at(i)
	else:
		_remove_foreground_at(objects, x, y)
		if _selected_type == "goal":
			for i in range(objects.size() - 1, -1, -1):
				if str(objects[i].get("type", "")) == "goal":
					objects.remove_at(i)
		objects.append({"type": _selected_type, "x": x, "y": y})
	if objects == before:
		return
	_data["objects"] = objects
	_mark_dirty()
	_refresh_grid()


func _objects() -> Array:
	return (_data.get("objects", []) as Array).duplicate(true)


func _erase_at(objects: Array, x: int, y: int, include_ground: bool = false) -> void:
	var removed_foreground := false
	for i in range(objects.size() - 1, -1, -1):
		var object := objects[i] as Dictionary
		if int(object.get("x", -1)) != x or int(object.get("y", -1)) != y:
			continue
		if str(object.get("type", "")) != "ground":
			objects.remove_at(i)
			removed_foreground = true
	if include_ground or not removed_foreground:
		for i in range(objects.size() - 1, -1, -1):
			var object := objects[i] as Dictionary
			if (
				int(object.get("x", -1)) == x
				and int(object.get("y", -1)) == y
				and str(object.get("type", "")) == "ground"
			):
				objects.remove_at(i)


func _remove_foreground_at(objects: Array, x: int, y: int) -> void:
	for i in range(objects.size() - 1, -1, -1):
		var object := objects[i] as Dictionary
		if (
			int(object.get("x", -1)) == x
			and int(object.get("y", -1)) == y
			and str(object.get("type", "")) != "ground"
		):
			objects.remove_at(i)


func _has_type_at(objects: Array, x: int, y: int, type_name: String) -> bool:
	for value in objects:
		var object := value as Dictionary
		if (
			int(object.get("x", -1)) == x
			and int(object.get("y", -1)) == y
			and str(object.get("type", "")) == type_name
		):
			return true
	return false


func _refresh_grid() -> void:
	var width := int(_data.get("width", 24))
	var height := int(_data.get("height", 8))
	var trail := _trail_y()
	for y in range(height):
		for x in range(width):
			var cell := _cells[y * width + x]
			var type_name := _display_type_at(x, y)
			cell.text = _short_label(type_name)
			if y == trail and type_name.is_empty():
				cell.text = "···"
			cell.modulate = _type_color(type_name)
			if y == trail:
				cell.modulate = cell.modulate.darkened(0.04)
				if type_name.is_empty():
					cell.modulate = Color(0.82, 0.7, 0.5)
	_refresh_grid_highlights()
	if _preview != null:
		_preview.show_level(_data)
		if _hover_column >= 0:
			_preview.set_hover_column(_hover_column)


func _refresh_grid_highlights() -> void:
	var width := int(_data.get("width", 24))
	var height := int(_data.get("height", 8))
	for y in range(height):
		for x in range(width):
			var cell := _cells[y * width + x]
			if x == _hover_column:
				cell.self_modulate = Color(1.15, 1.1, 0.85)
			else:
				cell.self_modulate = Color.WHITE


func _display_type_at(x: int, y: int) -> String:
	var ground := false
	for value in _data.get("objects", []):
		var object := value as Dictionary
		if int(object.get("x", -1)) != x or int(object.get("y", -1)) != y:
			continue
		var type_name := str(object.get("type", ""))
		if type_name != "ground":
			return type_name
		ground = true
	return "ground" if ground else ""


func _short_label(type_name: String) -> String:
	var labels := {
		"ground": "DIRT", "platform": "WOOD", "star": "STAR",
		"cactus": "OUCH", "canyon": "CANYON", "pit": "CANYON", "checkpoint": "CAMP",
		"spring": "BOING", "bandit": "BANDIT", "goal": "END",
	}
	return str(labels.get(type_name, ""))


func _type_color(type_name: String) -> Color:
	var colors := {
		"": Color(1, 1, 1), "ground": Color(0.86, 0.68, 0.38),
		"platform": Color(0.62, 0.4, 0.22), "star": Color(1, 0.85, 0.2),
		"cactus": Color(0.35, 0.75, 0.3), "canyon": Color(0.55, 0.28, 0.14), "pit": Color(0.55, 0.28, 0.14),
		"checkpoint": Color(0.95, 0.45, 0.2), "spring": Color(0.3, 0.9, 0.45),
		"bandit": Color(0.32, 0.18, 0.08), "goal": Color(0.85, 0.3, 0.2),
	}
	return colors.get(type_name, Color.WHITE)


func _on_title_changed(value: String) -> void:
	_data["title"] = value.strip_edges().left(40) if not value.strip_edges().is_empty() else "Family Trail"
	_mark_dirty()


func _save() -> void:
	var title := _title_edit.text.strip_edges().left(40)
	_data["title"] = title if not title.is_empty() else "Family Trail"
	_title_edit.set_block_signals(true)
	_title_edit.text = str(_data["title"])
	_title_edit.set_block_signals(false)
	if CustomLevelStore.save(GameManager.active_custom_slot, _data):
		_data = CustomLevelStore.load_level(GameManager.active_custom_slot)
		_saved_data = _data.duplicate(true)
		_has_saved_state = true
		_dirty = false
		_status.text = tr("Trail saved!")
		_update_action_state()
	else:
		_status.text = tr("Could not save the trail.")


func _request_reset() -> void:
	if not _dirty:
		_status.text = tr("No unsaved changes to reset.")
		return
	_reset_dialog.popup_centered(Vector2i(560, 190))


func _reset() -> void:
	_data = (
		_saved_data.duplicate(true)
		if _has_saved_state
		else _initial_data.duplicate(true)
	)
	_title_edit.set_block_signals(true)
	_title_edit.text = str(_data.get("title", "Family Trail"))
	_title_edit.set_block_signals(false)
	_dirty = false
	_refresh_grid()
	_update_action_state()
	_status.text = (
		tr("Trail reset to the last saved version.")
		if _has_saved_state
		else tr("New trail reset to its starting layout.")
	)


func _mark_dirty() -> void:
	_dirty = _data != _saved_data
	_update_action_state()


func _update_action_state() -> void:
	if _save_button != null:
		_save_button.disabled = not _dirty and _has_saved_state
	if _reset_button != null:
		_reset_button.disabled = not _dirty


func _play_test() -> void:
	_save()
	var has_goal := false
	var has_ground := false
	for value in _data.get("objects", []):
		var type_name := str((value as Dictionary).get("type", ""))
		has_goal = has_goal or type_name == "goal"
		has_ground = has_ground or type_name == "ground"
	if not has_goal or not has_ground:
		_status.text = tr("Add Dirt and a Saloon before play-testing.")
		return
	GameManager.play_custom_level(GameManager.active_custom_slot, true)
