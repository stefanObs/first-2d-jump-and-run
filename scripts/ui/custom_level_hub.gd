extends Control

## Campaign workshop: edit built-in copies or insert extra trails anywhere.

const TRAIL_PACK_FILTER := "*.cowboytrail ; Cowboy Trail Pack"

var _status_label: Label
var _export_dialog: FileDialog
var _import_dialog: FileDialog


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
	title.text = tr("Campaign Workshop")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 38)
	title.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	box.add_child(title)
	var help := Label.new()
	help.text = tr("Edit a copy of any campaign level, or insert a new trail before any level.")
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
		tr("+ Add a new level after Level 10"),
		Vector2(0, 48),
		19,
		func() -> void: _add_extra(CustomLevelStore.BUILTIN_COUNT + 1)
	))
	var share_row := HBoxContainer.new()
	share_row.alignment = BoxContainer.ALIGNMENT_CENTER
	share_row.add_theme_constant_override(&"separation", 12)
	box.add_child(share_row)
	share_row.add_child(_make_button(
		tr("Export Trails"),
		Vector2(220, 48),
		18,
		_open_export_dialog
	))
	share_row.add_child(_make_button(
		tr("Import Trails"),
		Vector2(220, 48),
		18,
		_open_import_dialog
	))
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override(&"font_size", 16)
	_status_label.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	box.add_child(_status_label)
	box.add_child(_make_button(
		tr("Back to Cowboy Trail"),
		Vector2(0, 56),
		20,
		GameManager.return_to_save_select
	))
	_export_dialog = FileDialog.new()
	_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog.filters = PackedStringArray([TRAIL_PACK_FILTER])
	_export_dialog.title = tr("Export Trails")
	_export_dialog.file_selected.connect(_on_export_selected)
	add_child(_export_dialog)
	_import_dialog = FileDialog.new()
	_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog.filters = PackedStringArray([TRAIL_PACK_FILTER])
	_import_dialog.title = tr("Import Trails")
	_import_dialog.file_selected.connect(_on_import_selected)
	add_child(_import_dialog)
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
		tr("Edit level"),
		Vector2(190, 48),
		0,
		func() -> void: GameManager.edit_custom_level(slot)
	))
	row.add_child(_make_button(
		tr("Add before"),
		Vector2(190, 48),
		0,
		func() -> void: _add_extra(level_number)
	))
	if CustomLevelStore.exists(slot):
		row.add_child(_make_button(
			tr("Restore original"),
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
	label.text = tr("Extra before position %d: %s") % [
		int(data.get("insert_position", 11)),
		str(data.get("title", tr("Extra Trail"))),
	]
	label.add_theme_font_size_override(&"font_size", 18)
	row.add_child(label)
	row.add_child(_make_button(
		tr("Edit"),
		Vector2(190, 44),
		0,
		func() -> void: GameManager.edit_custom_level(slot)
	))
	row.add_child(_make_button(
		tr("Remove"),
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


func _open_export_dialog() -> void:
	if CustomLevelStore.existing_custom_slots().is_empty():
		_set_status(tr("No custom trails to export."))
		return
	_export_dialog.popup_centered(Vector2i(900, 600))


func _open_import_dialog() -> void:
	_import_dialog.popup_centered(Vector2i(900, 600))


func _on_export_selected(path: String) -> void:
	var export_path := _ensure_pack_extension(path)
	if CustomLevelStore.export_share_pack(export_path):
		_set_status(tr("Exported %d trail(s).") % CustomLevelStore.existing_custom_slots().size())
	else:
		_set_status(tr("Could not write trail pack."))


func _on_import_selected(path: String) -> void:
	var result := CustomLevelStore.import_share_pack(path)
	if bool(result.get("ok", false)):
		get_tree().reload_current_scene()
		return
	var message := str(result.get("message", tr("Could not import trail pack.")))
	_set_status(message)


func _ensure_pack_extension(path: String) -> String:
	if path.get_extension().is_empty():
		return "%s.cowboytrail" % path
	return path


func _set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message
