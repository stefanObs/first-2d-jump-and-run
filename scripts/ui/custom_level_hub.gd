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
	var add_after := Button.new()
	add_after.text = "+ Add a new level after Level 10"
	add_after.custom_minimum_size.y = 48
	add_after.add_theme_font_size_override(&"font_size", 19)
	add_after.pressed.connect(func() -> void: _add_extra(CustomLevelStore.BUILTIN_COUNT + 1))
	rows.add_child(add_after)
	var back := Button.new()
	back.custom_minimum_size = Vector2(0, 56)
	back.text = "Back to Cowboy Trail"
	back.add_theme_font_size_override(&"font_size", 20)
	back.pressed.connect(GameManager.return_to_save_select)
	box.add_child(back)
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
	var edit := Button.new()
	edit.text = "Edit level"
	edit.custom_minimum_size = Vector2(190, 48)
	edit.pressed.connect(func() -> void: GameManager.edit_custom_level(slot))
	row.add_child(edit)
	var insert := Button.new()
	insert.text = "Add before"
	insert.custom_minimum_size = Vector2(190, 48)
	insert.pressed.connect(func() -> void: _add_extra(level_number))
	row.add_child(insert)
	if CustomLevelStore.exists(slot):
		var reset := Button.new()
		reset.text = "Restore original"
		reset.custom_minimum_size = Vector2(190, 48)
		reset.pressed.connect(func() -> void:
			CustomLevelStore.erase(slot)
			get_tree().reload_current_scene()
		)
		row.add_child(reset)


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
	var edit := Button.new()
	edit.text = "Edit"
	edit.custom_minimum_size = Vector2(190, 44)
	edit.pressed.connect(func() -> void: GameManager.edit_custom_level(slot))
	row.add_child(edit)
	var remove := Button.new()
	remove.text = "Remove"
	remove.custom_minimum_size = Vector2(190, 44)
	remove.pressed.connect(func() -> void:
		CustomLevelStore.erase(slot)
		get_tree().reload_current_scene()
	)
	row.add_child(remove)


func _add_extra(insert_position: int) -> void:
	var draft := CustomLevelStore.new_extra_draft(insert_position)
	if not draft.is_empty():
		GameManager.edit_new_custom_level(int(draft["slot"]), draft)
