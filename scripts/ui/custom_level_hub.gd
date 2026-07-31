extends Control

## Campaign workshop: edit built-in copies or insert extra trails anywhere.

const TRAIL_PACK_FILTER := "*.cowboytrail ; Cowboy Trail Pack"

var _status_label: Label
var _export_dialog: FileDialog
var _import_dialog: FileDialog


func _ready() -> void:
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if _dialog_open():
		return
	if event.is_action_pressed(&"back"):
		GameManager.return_to_save_select()
		get_viewport().set_input_as_handled()


func _dialog_open() -> bool:
	return (
		(_export_dialog != null and _export_dialog.visible)
		or (_import_dialog != null and _import_dialog.visible)
	)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.98, 0.74, 0.45)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	box.add_theme_constant_override(&"separation", 10)
	add_child(box)
	box.add_child(_make_button(
		tr("Back to Cowboy Trail"),
		Vector2(0, 48),
		18,
		GameManager.return_to_save_select
	))
	var title := Label.new()
	title.text = tr("Campaign Workshop")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 38)
	title.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	box.add_child(title)
	var help := Label.new()
	help.text = tr(
		"Self-made trails sit in campaign order. Changed campaign trails are marked. Add a trail before any row."
	)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override(&"font_size", 18)
	box.add_child(help)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 160)
	box.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.name = "TrailRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override(&"separation", 8)
	scroll.add_child(rows)
	var campaign_index := 1
	for entry in CustomLevelStore.campaign_entries():
		_add_campaign_row(rows, entry, campaign_index)
		campaign_index += 1
	rows.add_child(_make_button(
		tr("+ Add a new trail at the end"),
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


func _add_campaign_row(parent: VBoxContainer, entry: Dictionary, campaign_index: int) -> void:
	var entry_kind := str(entry.get("entry_kind", ""))
	if entry_kind.is_empty():
		if int(entry.get("source_level", 0)) == 0:
			entry_kind = "extra"
		elif str(entry.get("kind", "")) == "custom":
			entry_kind = "override"
		else:
			entry_kind = "builtin"
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	row.set_meta("campaign_index", campaign_index)
	row.set_meta("entry_kind", entry_kind)
	row.set_meta("custom_slot", int(entry.get("custom_slot", -1)))
	row.set_meta("source_level", int(entry.get("source_level", 0)))
	parent.add_child(row)
	var label := Label.new()
	label.custom_minimum_size = Vector2(460, 48)
	label.add_theme_font_size_override(&"font_size", 20)
	label.text = _row_label(entry, campaign_index, entry_kind)
	if entry_kind == "extra":
		label.add_theme_color_override(&"font_color", Color(0.18, 0.34, 0.12))
	elif entry_kind == "override":
		label.add_theme_color_override(&"font_color", Color(0.42, 0.22, 0.05))
	else:
		label.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	row.add_child(label)
	var edit_slot := int(entry.get("custom_slot", -1))
	if entry_kind == "builtin":
		edit_slot = CustomLevelStore.override_slot_for(int(entry.get("source_level", 1)))
	row.add_child(_make_button(
		tr("Edit level") if entry_kind != "extra" else tr("Edit"),
		Vector2(190, 48),
		0,
		func() -> void: GameManager.edit_custom_level(edit_slot)
	))
	row.add_child(_make_button(
		tr("Add before"),
		Vector2(190, 48),
		0,
		func() -> void: _add_before_entry(entry, entry_kind)
	))
	if entry_kind == "override":
		row.add_child(_make_button(
			tr("Restore original"),
			Vector2(190, 48),
			0,
			func() -> void:
				CustomLevelStore.erase(int(entry.get("custom_slot", -1)))
				get_tree().reload_current_scene()
		))
	elif entry_kind == "extra":
		row.add_child(_make_button(
			tr("Remove"),
			Vector2(190, 48),
			0,
			func() -> void:
				CustomLevelStore.erase(int(entry.get("custom_slot", -1)))
				get_tree().reload_current_scene()
		))


func _row_label(entry: Dictionary, campaign_index: int, entry_kind: String) -> String:
	var title := str(entry.get("title", tr("Extra Trail")))
	if entry_kind == "extra":
		return "%d: %s (%s)" % [campaign_index, title, tr("self-made")]
	if entry_kind == "override":
		var source := int(entry.get("source_level", 0))
		if source >= 1 and source <= CustomLevelStore.BUILTIN_COUNT:
			title = CustomLevelStore.BUILTIN_NAMES[source - 1]
		return "%d: %s (%s)" % [campaign_index, title, tr("changed")]
	return "%d: %s" % [campaign_index, title]


func _add_before_entry(entry: Dictionary, entry_kind: String) -> void:
	if entry_kind == "extra":
		_add_extra(
			int(entry.get("insert_position", CustomLevelStore.BUILTIN_COUNT + 1)),
			int(entry.get("custom_slot", -1))
		)
		return
	_add_extra(int(entry.get("source_level", 1)))


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


func _add_extra(insert_position: int, before_custom_slot: int = -1) -> void:
	var draft := CustomLevelStore.new_extra_draft(insert_position, before_custom_slot)
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
