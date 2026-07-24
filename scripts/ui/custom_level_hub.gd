extends Control

## Campaign workshop: edit built-in copies or insert extra trails anywhere.


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.98, 0.74, 0.45)
	add_child(background)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	box.add_theme_constant_override(&"separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = "Campaign Workshop"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 38)
	title.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	box.add_child(title)
	var help := Label.new()
	help.text = "Edit a copy of any campaign level, or insert a new trail before any level."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override(&"font_size", 20)
	box.add_child(help)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override(&"separation", 8)
	scroll.add_child(rows)
	for level_number in range(1, CustomLevelStore.BUILTIN_COUNT + 1):
		_add_builtin_row(rows, level_number)
	for entry in CustomLevelStore.campaign_entries():
		if int(entry.get("source_level", 0)) == 0:
			_add_extra_row(rows, entry)
	rows.add_child(_make_button(
		"+ Add a new level after Level 10",
		Vector2(0, 48),
		19,
		func() -> void: _add_extra(CustomLevelStore.BUILTIN_COUNT + 1)
	))
	box.add_child(_make_button(
		"Back to Cowboy Trail",
		Vector2(0, 56),
		20,
		GameManager.return_to_save_select
	))
	if rows.get_child_count() > 0:
		(rows.get_child(0) as Control).grab_focus()


func _add_builtin_row(parent: VBoxContainer, level_number: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	parent.add_child(row)
	var label := Label.new()
	label.custom_minimum_size = Vector2(440, 48)
	label.add_theme_font_size_override(&"font_size", 20)
	var slot := CustomLevelStore.override_slot_for(level_number)
	label.text = "%d: %s%s" % [
		level_number,
		CustomLevelStore.BUILTIN_NAMES[level_number - 1],
		" (edited)" if CustomLevelStore.exists(slot) else "",
	]
	row.add_child(label)
	row.add_child(_make_button(
		"Edit level",
		Vector2(190, 48),
		0,
		func() -> void: GameManager.edit_custom_level(slot)
	))
	row.add_child(_make_button(
		"Add before",
		Vector2(190, 48),
		0,
		func() -> void: _add_extra(level_number)
	))
	if CustomLevelStore.exists(slot):
		row.add_child(_make_button(
			"Restore original",
			Vector2(190, 48),
			0,
			func() -> void:
				CustomLevelStore.erase(slot)
				get_tree().reload_current_scene()
		))


func _add_extra_row(parent: VBoxContainer, entry: Dictionary) -> void:
	var slot := int(entry.get("custom_slot", -1))
	if slot < 0:
		return
	var data := CustomLevelStore.load_level(slot)
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.custom_minimum_size = Vector2(440, 44)
	label.text = "Extra before position %d: %s" % [
		int(data.get("insert_position", 11)),
		str(data.get("title", "Extra Trail")),
	]
	label.add_theme_font_size_override(&"font_size", 18)
	row.add_child(label)
	row.add_child(_make_button(
		"Edit",
		Vector2(190, 44),
		0,
		func() -> void: GameManager.edit_custom_level(slot)
	))
	row.add_child(_make_button(
		"Remove",
		Vector2(190, 44),
		0,
		func() -> void:
			CustomLevelStore.erase(slot)
			get_tree().reload_current_scene()
	))


func _make_button(
	text: String,
	min_size: Vector2,
	font_size: int,
	action: Callable
) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	if font_size > 0:
		button.add_theme_font_size_override(&"font_size", font_size)
	button.pressed.connect(action)
	return button


func _add_extra(insert_position: int) -> void:
	var draft := CustomLevelStore.new_extra_draft(insert_position)
	if not draft.is_empty():
		GameManager.edit_new_custom_level(int(draft["slot"]), draft)
