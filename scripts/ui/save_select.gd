extends Control

## Title / three-slot save selection screen.

var _cards: Array[Button] = []
var _index: int = 0
var _prompt: Label
var _hint: Label
var _delete_dialog: ConfirmationDialog


func _ready() -> void:
	_prompt = get_node_or_null("PromptLabel") as Label
	_hint = get_node_or_null("HintLabel") as Label
	_delete_dialog = get_node_or_null("DeleteConfirmation") as ConfirmationDialog
	if _delete_dialog != null:
		_delete_dialog.confirmed.connect(_confirm_delete)
	var builder := get_node_or_null("BuildTrailButton") as Button
	if builder != null:
		builder.pressed.connect(func() -> void:
			AudioManager.ensure_gameplay_music()
			GameManager.open_custom_level_hub()
		)
	var translation_editor := get_node_or_null("TranslationEditorButton") as Button
	if translation_editor != null:
		translation_editor.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://scenes/ui/translation_editor.tscn")
		)
	for i in range(3):
		var card := get_node_or_null("Slots/Slot%d" % (i + 1)) as Button
		if card != null:
			_cards.append(card)
			var captured := i
			card.pressed.connect(func() -> void: _select_slot(captured))
			card.gui_input.connect(func(event: InputEvent) -> void:
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
				_index = captured
				_highlight()
			)
			card.focus_entered.connect(func() -> void:
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


func _pulse_sun() -> void:
	var sun := get_node_or_null("Sun") as CanvasItem
	if sun == null:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(sun, "modulate", Color(1.0, 1.0, 0.8, 1.0), 1.2)
	tween.tween_property(sun, "modulate", Color(1.0, 0.9, 0.45, 1.0), 1.2)


func _bob_title() -> void:
	var title := get_node_or_null("Title") as Control
	if title == null:
		return
	var base := title.position.y
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(title, "position:y", base - 6.0, 0.9).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "position:y", base + 4.0, 0.9).set_trans(Tween.TRANS_SINE)


func _unhandled_input(event: InputEvent) -> void:
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
