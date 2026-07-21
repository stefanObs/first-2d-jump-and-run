class_name TranslationEditor
extends Control

const SavePaths := preload("res://scripts/autoload/save_paths.gd")
const INK := Color(0.28, 0.12, 0.04, 1.0)
const ERROR_INK := Color(0.72, 0.08, 0.05, 1.0)

var rows: Array[Dictionary] = []
var _row_controls: Array[Dictionary] = []
var _list: VBoxContainer
var _search: LineEdit
var _status: Label


func _ready() -> void:
	_list = get_node("Page/RowsScroll/Rows") as VBoxContainer
	_search = get_node("Page/Search") as LineEdit
	_status = get_node("Page/Status") as Label
	_search.text_changed.connect(_apply_filter)
	(get_node("Page/Buttons/BackButton") as Button).pressed.connect(_go_back)
	(get_node("Page/Buttons/SaveButton") as Button).pressed.connect(_save_export)
	_style_buttons()
	_load_rows()
	_search.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"back"):
		_go_back()
		get_viewport().set_input_as_handled()


func _load_rows() -> void:
	var parsed := TranslationCsv.load_source()
	var error := String(parsed.get("error", ""))
	if not error.is_empty():
		_status.text = error
		_status.add_theme_color_override(&"font_color", ERROR_INK)
		return
	rows.assign(parsed.get("rows", []))
	for index in range(rows.size()):
		_add_row(index, rows[index])
	_refresh_validation()
	_status.text = "%d entries loaded. Export: %s" % [rows.size(), SavePaths.translation_export_path()]


func _add_row(index: int, row: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.name = "Entry%d" % index
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1.0, 0.93, 0.78, 1.0)
	box.border_color = Color(0.55, 0.30, 0.10, 1.0)
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.content_margin_left = 12
	box.content_margin_top = 12
	box.content_margin_right = 12
	box.content_margin_bottom = 12
	panel.add_theme_stylebox_override(&"panel", box)
	_list.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override(&"separation", 6)
	panel.add_child(content)
	var key_label := Label.new()
	key_label.text = "%d. %s" % [index + 1, String(row["key"])]
	key_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	key_label.add_theme_color_override(&"font_color", INK)
	key_label.add_theme_font_size_override(&"font_size", 18)
	content.add_child(key_label)

	content.add_child(_make_language_label(tr("English")))
	var english := _make_editor(String(row["en"]), "English")
	content.add_child(english)
	var english_example := _make_example_label()
	content.add_child(english_example)

	content.add_child(_make_language_label(tr("Deutsch")))
	var german := _make_editor(String(row["de"]), "Deutsch")
	content.add_child(german)
	var german_example := _make_example_label()
	content.add_child(german_example)

	var validation := Label.new()
	validation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	validation.add_theme_font_size_override(&"font_size", 17)
	content.add_child(validation)
	var controls := {
		"panel": panel,
		"key": key_label,
		"english": english,
		"german": german,
		"english_example": english_example,
		"german_example": german_example,
		"validation": validation,
	}
	_row_controls.append(controls)
	english.text_changed.connect(func() -> void: _row_edited(index))
	german.text_changed.connect(func() -> void: _row_edited(index))
	_refresh_row(index)


func _make_language_label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override(&"font_color", INK)
	label.add_theme_font_size_override(&"font_size", 17)
	return label


func _make_editor(value: String, placeholder: String) -> TextEdit:
	var editor := TextEdit.new()
	editor.text = value
	editor.placeholder_text = placeholder
	editor.custom_minimum_size = Vector2(0, 76)
	editor.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	editor.add_theme_font_size_override(&"font_size", 18)
	editor.add_theme_color_override(&"font_color", INK)
	return editor


func _make_example_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(&"font_color", Color(0.25, 0.34, 0.55, 1.0))
	label.add_theme_font_size_override(&"font_size", 17)
	return label


func _row_edited(index: int) -> void:
	if index < 0 or index >= _row_controls.size():
		return
	var controls := _row_controls[index]
	rows[index]["en"] = (controls["english"] as TextEdit).text
	rows[index]["de"] = (controls["german"] as TextEdit).text
	_refresh_row(index)
	_refresh_status()


func _refresh_row(index: int) -> void:
	var row := rows[index]
	var controls := _row_controls[index]
	var english := String(row["en"])
	var german := String(row["de"])
	var english_example := controls["english_example"] as Label
	var german_example := controls["german_example"] as Label
	if english_example != null:
		english_example.text = "%s: %s" % [tr("Example"), TranslationCsv.example(english)]
		english_example.visible = TranslationCsv.has_placeholders(english)
	if german_example != null:
		german_example.text = "%s: %s" % [tr("Example"), TranslationCsv.example(german)]
		german_example.visible = TranslationCsv.has_placeholders(german)
	var validation := controls["validation"] as Label
	if TranslationCsv.placeholders_match(english, german):
		validation.text = ""
		validation.visible = false
	else:
		validation.visible = true
		validation.text = "%s  EN %s  /  DE %s" % [
			tr("Placeholder mismatch"),
			str(TranslationCsv.placeholder_signature(english)),
			str(TranslationCsv.placeholder_signature(german)),
		]
		validation.add_theme_color_override(&"font_color", ERROR_INK)


func _refresh_validation() -> int:
	var mismatch_count := 0
	for index in range(rows.size()):
		_refresh_row(index)
		if not TranslationCsv.placeholders_match(String(rows[index]["en"]), String(rows[index]["de"])):
			mismatch_count += 1
	return mismatch_count


func _refresh_status() -> void:
	var mismatches := _refresh_validation()
	if mismatches > 0:
		_status.text = "%d placeholder mismatch(es). Fix them before export.\n%s" % [
			mismatches,
			SavePaths.translation_export_path(),
		]
		_status.add_theme_color_override(&"font_color", ERROR_INK)
	else:
		_status.text = "%s: %s" % [tr("Export location"), SavePaths.translation_export_path()]
		_status.add_theme_color_override(&"font_color", INK)


func _apply_filter(query: String) -> void:
	var needle := query.strip_edges().to_lower()
	for index in range(_row_controls.size()):
		var row := rows[index]
		var haystack := "%s\n%s\n%s" % [row["key"], row["en"], row["de"]]
		(_row_controls[index]["panel"] as Control).visible = needle.is_empty() or haystack.to_lower().contains(needle)


func _save_export() -> void:
	if _refresh_validation() > 0:
		_refresh_status()
		return
	var path := SavePaths.translation_export_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_status.text = "%s: %s" % [tr("Could not export translations"), path]
		_status.add_theme_color_override(&"font_color", ERROR_INK)
		return
	file.store_string(TranslationCsv.serialize(rows))
	file.close()
	_status.text = "%s\n%s" % [tr("Translations exported"), path]
	_status.add_theme_color_override(&"font_color", Color(0.12, 0.45, 0.18, 1.0))


func _go_back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/save_select.tscn")


func _style_buttons() -> void:
	for button in [
		get_node("Page/Buttons/BackButton") as Button,
		get_node("Page/Buttons/SaveButton") as Button,
	]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(0.95, 0.72, 0.32, 1.0)
		normal.border_color = Color(0.45, 0.24, 0.08, 1.0)
		normal.set_border_width_all(3)
		normal.set_corner_radius_all(10)
		button.add_theme_stylebox_override(&"normal", normal)
		var focus := normal.duplicate() as StyleBoxFlat
		focus.bg_color = Color(1.0, 0.86, 0.48, 1.0)
		button.add_theme_stylebox_override(&"hover", focus)
		button.add_theme_stylebox_override(&"focus", focus)
		button.add_theme_stylebox_override(&"pressed", focus)
