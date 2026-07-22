extends Control

## Handcrafted western title / three-slot save selection screen.

const INK := Color(0.28, 0.12, 0.04, 1.0)
const WOOD := Color(0.82, 0.55, 0.28, 0.96)
const WOOD_HOVER := Color(0.95, 0.72, 0.38, 1.0)
const WOOD_EDGE := Color(0.45, 0.24, 0.08, 1.0)

var _cards: Array[Button] = []
var _index: int = 0
var _prompt: Label
var _hint: Label
var _delete_dialog: ConfirmationDialog
var _settings: SettingsPanel
var _settings_dim: ColorRect


func _ready() -> void:
	_prompt = get_node_or_null("PromptLabel") as Label
	_hint = get_node_or_null("HintLabel") as Label
	_delete_dialog = get_node_or_null("DeleteConfirmation") as ConfirmationDialog
	_settings = get_node_or_null("SettingsPanel") as SettingsPanel
	_settings_dim = get_node_or_null("SettingsDim") as ColorRect
	_localize_static_labels()
	_style_screen()
	if _delete_dialog != null:
		_delete_dialog.confirmed.connect(_confirm_delete)
		_style_delete_dialog()
	if _settings != null:
		# SettingsPanel defaults to WHEN_PAUSED for the in-level menu.
		_settings.process_mode = Node.PROCESS_MODE_ALWAYS
		_settings.visible = false
		_settings.closed.connect(_close_settings)
	if _settings_dim != null:
		_settings_dim.visible = false
		_settings_dim.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
				_close_settings()
		)
	var builder := get_node_or_null("BuildTrailButton") as Button
	if builder != null:
		_style_action_button(builder)
		builder.pressed.connect(func() -> void:
			if _settings_open():
				return
			AudioManager.ensure_gameplay_music()
			GameManager.open_custom_level_hub()
		)
	var translation_editor := get_node_or_null("TranslationEditorButton") as Button
	if translation_editor != null:
		_style_action_button(translation_editor)
		translation_editor.pressed.connect(func() -> void:
			if _settings_open():
				return
			get_tree().change_scene_to_file("res://scenes/ui/translation_editor.tscn")
		)
	var settings_button := get_node_or_null("SettingsButton") as Button
	if settings_button != null:
		_style_action_button(settings_button)
		settings_button.pressed.connect(_open_settings)
	for i in range(3):
		var card := get_node_or_null("Slots/Slot%d" % (i + 1)) as Button
		if card != null:
			_cards.append(card)
			_style_slot_button(card)
			var captured := i
			card.pressed.connect(func() -> void:
				if _settings_open():
					return
				_select_slot(captured)
			)
			card.gui_input.connect(func(event: InputEvent) -> void:
				if _settings_open():
					return
				if (
					event is InputEventMouseButton
					and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT
					and (event as InputEventMouseButton).pressed
				):
					_index = captured
					_highlight()
					_request_delete()
			)
			card.mouse_entered.connect(func() -> void:
				if _settings_open():
					return
				_index = captured
				_highlight()
			)
			card.focus_entered.connect(func() -> void:
				if _settings_open():
					return
				_index = captured
				_highlight()
			)
	GameManager.saves_changed.connect(_refresh)
	InputManager.device_changed.connect(func(_d: Variant) -> void: _refresh_prompts())
	_refresh()
	_refresh_prompts()
	_highlight()
	_pulse_sun()
	_bob_title()
	var subtitle := get_node_or_null("Subtitle") as Label
	if subtitle != null:
		Narrator.speak(tr("Help Lucky Mario Luke on his quest to make the wild west a safer place."))


func _localize_static_labels() -> void:
	var title := get_node_or_null("Title") as Label
	if title != null:
		title.text = tr("Cowboy Trail")
	var subtitle := get_node_or_null("Subtitle") as Label
	if subtitle != null:
		subtitle.text = tr("Help Lucky Mario Luke on his quest to make the wild west a safer place.")
	var builder := get_node_or_null("BuildTrailButton") as Button
	if builder != null:
		builder.text = tr("Campaign Workshop")
	var settings_button := get_node_or_null("SettingsButton") as Button
	if settings_button != null:
		settings_button.text = tr("Settings")
	var translation_editor := get_node_or_null("TranslationEditorButton") as Button
	if translation_editor != null:
		translation_editor.text = tr("Translation Editor")
	if _delete_dialog != null:
		_delete_dialog.title = tr("Delete save?")
		_delete_dialog.dialog_text = tr("Delete the selected save? This cannot be undone.")
		_delete_dialog.ok_button_text = tr("Delete")
		_delete_dialog.cancel_button_text = tr("Keep it")


func _style_screen() -> void:
	# Keep legacy Background node harmless if an older scene layout is loaded.
	var legacy_bg := get_node_or_null("Background") as CanvasItem
	if legacy_bg != null:
		legacy_bg.visible = false


func _style_slot_button(button: Button) -> void:
	button.add_theme_color_override(&"font_color", INK)
	button.add_theme_color_override(&"font_hover_color", Color(0.42, 0.18, 0.05, 1.0))
	button.add_theme_color_override(&"font_pressed_color", INK)
	button.add_theme_color_override(&"font_focus_color", INK)
	button.add_theme_font_size_override(&"font_size", 20)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var normal := _wood_style(WOOD, 14, 18)
	var hover := _wood_style(WOOD_HOVER, 14, 18)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	button.add_theme_stylebox_override(&"focus", hover)


func _style_action_button(button: Button) -> void:
	button.add_theme_color_override(&"font_color", INK)
	button.add_theme_color_override(&"font_hover_color", Color(0.42, 0.18, 0.05, 1.0))
	button.add_theme_color_override(&"font_pressed_color", INK)
	button.add_theme_color_override(&"font_focus_color", INK)
	var normal := _wood_style(WOOD, 10, 10)
	var hover := _wood_style(WOOD_HOVER, 10, 10)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	button.add_theme_stylebox_override(&"focus", hover)


func _wood_style(fill: Color, radius: int, pad_v: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(4)
	style.border_color = WOOD_EDGE
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = pad_v
	style.content_margin_bottom = pad_v
	style.shadow_color = Color(0.25, 0.1, 0.03, 0.35)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2, 3)
	return style


func _style_delete_dialog() -> void:
	if _delete_dialog == null:
		return
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(1.0, 0.93, 0.78, 1.0)
	panel.set_border_width_all(4)
	panel.border_color = WOOD_EDGE
	panel.set_corner_radius_all(12)
	_delete_dialog.add_theme_stylebox_override(&"panel", panel)


func _pulse_sun() -> void:
	var sun := get_node_or_null("Sun") as CanvasItem
	if sun == null:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(sun, "modulate", Color(1.0, 1.0, 0.85, 1.0), 1.2)
	tween.tween_property(sun, "modulate", Color(1.0, 0.88, 0.55, 1.0), 1.2)


func _bob_title() -> void:
	var title := get_node_or_null("Title") as Control
	var board := get_node_or_null("TitleBoard") as Control
	if title == null:
		return
	var base := title.position.y
	var board_base := board.position.y if board != null else 0.0
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(title, "position:y", base - 6.0, 0.9).set_trans(Tween.TRANS_SINE)
	if board != null:
		tween.parallel().tween_property(board, "position:y", board_base - 6.0, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "position:y", base + 4.0, 0.9).set_trans(Tween.TRANS_SINE)
	if board != null:
		tween.parallel().tween_property(board, "position:y", board_base + 4.0, 0.9).set_trans(Tween.TRANS_SINE)


func _settings_open() -> bool:
	return _settings != null and _settings.visible


func _open_settings() -> void:
	if _settings == null:
		return
	if _settings_dim != null:
		_settings_dim.visible = true
	_settings.visible = true
	_settings.focus_first()


func _close_settings() -> void:
	if _settings != null:
		_settings.visible = false
	if _settings_dim != null:
		_settings_dim.visible = false
	_refresh_prompts()
	_highlight()


func _unhandled_input(event: InputEvent) -> void:
	if _settings_open():
		return
	if _delete_dialog != null and _delete_dialog.visible:
		if event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
			_delete_dialog.hide()
			_confirm_delete()
		elif event.is_action_pressed(&"back"):
			_delete_dialog.hide()
		return
	if event.is_action_pressed(&"delete_save"):
		_request_delete()
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		_index = wrapi(_index + 1, 0, _cards.size())
		_highlight()
	elif event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		_index = wrapi(_index - 1, 0, _cards.size())
		_highlight()
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
		_select_slot(_index)


func _select_slot(slot_index: int) -> void:
	AudioManager.ensure_gameplay_music()
	GameManager.start_or_continue_slot(slot_index)


func _request_delete() -> void:
	if GameManager.is_slot_empty(_index):
		if _hint != null:
			_hint.text = tr("Save %d is already empty.") % (_index + 1)
		return
	if _delete_dialog == null:
		return
	_delete_dialog.dialog_text = tr("Delete Save %d? This cannot be undone.") % (_index + 1)
	_delete_dialog.popup_centered(Vector2i(460, 190))


func _confirm_delete() -> void:
	GameManager.erase_slot(_index)
	_refresh()
	_refresh_prompts()


func _refresh() -> void:
	for i in range(_cards.size()):
		var slot := GameManager.get_slot(i)
		var title := tr("Save %d") % (i + 1)
		if bool(slot.get("empty", true)):
			_cards[i].text = "%s\n%s\n%s" % [title, tr("Empty"), tr("Press to start")]
		else:
			var level := int(slot.get("current_level", 1))
			var stars := int(slot.get("stars", 0))
			var seconds := int(slot.get("play_time_sec", 0.0))
			var done := " " + tr("DONE") if bool(slot.get("completed", false)) else ""
			_cards[i].text = "%s%s\n%s\n%s" % [
				title,
				done,
				tr("Trail %s") % GameManager.level_name_for(level),
				tr("Badges %d | Time %dm %ds") % [stars, seconds / 60, seconds % 60],
			]


func _refresh_prompts() -> void:
	if _prompt:
		_prompt.text = InputManager.menu_prompt_line()
	if _hint:
		_hint.text = tr("Delete save: right-click, Space, or controller Y")


func _highlight() -> void:
	for i in range(_cards.size()):
		_cards[i].modulate = Color(1, 1, 0.55, 1) if i == _index else Color(1, 1, 1, 1)
