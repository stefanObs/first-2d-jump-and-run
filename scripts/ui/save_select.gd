extends Control

## Title / three-slot save selection screen.

var _cards: Array[Button] = []
var _index: int = 0
var _erase_hold: float = 0.0
var _prompt: Label
var _hint: Label
var _delete_button: Button
var _delete_armed_slot: int = -1
var _delete_selected: bool = false


func _ready() -> void:
	_prompt = get_node_or_null("PromptLabel") as Label
	_hint = get_node_or_null("HintLabel") as Label
	_delete_button = get_node_or_null("DeleteSaveButton") as Button
	if _delete_button != null:
		_delete_button.pressed.connect(_request_delete)
		_delete_button.mouse_entered.connect(func() -> void:
			_delete_selected = true
			_highlight()
		)
		_delete_button.focus_entered.connect(func() -> void:
			_delete_selected = true
			_highlight()
		)
	var builder := get_node_or_null("BuildTrailButton") as Button
	if builder != null:
		builder.pressed.connect(func() -> void:
			AudioManager.ensure_gameplay_music()
			GameManager.open_custom_level_hub()
		)
	for i in range(3):
		var card := get_node_or_null("Slots/Slot%d" % (i + 1)) as Button
		if card != null:
			_cards.append(card)
			var captured := i
			card.pressed.connect(func() -> void: _select_slot(captured))
			card.mouse_entered.connect(func() -> void:
				_index = captured
				_delete_selected = false
				_cancel_delete_confirmation()
				_highlight()
			)
			card.focus_entered.connect(func() -> void:
				_index = captured
				_delete_selected = false
				_cancel_delete_confirmation()
				_highlight()
			)
	GameManager.saves_changed.connect(_refresh)
	InputManager.device_changed.connect(func(_d: Variant) -> void: _refresh_prompts())
	_refresh()
	_refresh_prompts()
	_highlight()
	_pulse_sun()
	_bob_title()


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


func _process(delta: float) -> void:
	if Input.is_action_pressed(&"back") and Input.is_action_pressed(&"pause"):
		_erase_hold += delta
		if _hint:
			_hint.text = "Hold to erase slot %d... %.0f%%" % [_index + 1, clampf(_erase_hold / 1.5, 0.0, 1.0) * 100.0]
		if _erase_hold >= 1.5:
			GameManager.erase_slot(_index)
			_erase_hold = 0.0
			_refresh()
	else:
		_erase_hold = 0.0
		_refresh_prompts()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_down"):
		_delete_selected = true
		_highlight()
	elif event.is_action_pressed(&"ui_up"):
		_delete_selected = false
		_highlight()
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		_index = wrapi(_index + 1, 0, _cards.size())
		_delete_selected = false
		_cancel_delete_confirmation()
		_highlight()
	elif event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		_index = wrapi(_index - 1, 0, _cards.size())
		_delete_selected = false
		_cancel_delete_confirmation()
		_highlight()
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
		if _delete_selected:
			_request_delete()
		else:
			_select_slot(_index)


func _select_slot(slot_index: int) -> void:
	_cancel_delete_confirmation()
	AudioManager.ensure_gameplay_music()
	GameManager.start_or_continue_slot(slot_index)


func _request_delete() -> void:
	if GameManager.is_slot_empty(_index):
		return
	if _delete_armed_slot == _index:
		_delete_armed_slot = -1
		GameManager.erase_slot(_index)
		_refresh()
		_refresh_prompts()
		return
	_delete_armed_slot = _index
	_update_delete_button()
	if _hint != null:
		_hint.text = "Press the red button again to delete Save %d" % (_index + 1)


func _cancel_delete_confirmation() -> void:
	if _delete_armed_slot < 0:
		return
	_delete_armed_slot = -1
	_update_delete_button()


func _refresh() -> void:
	for i in range(_cards.size()):
		var slot := GameManager.get_slot(i)
		var title := "Save %d" % (i + 1)
		if bool(slot.get("empty", true)):
			_cards[i].text = "%s\nEmpty\nPress to start" % title
		else:
			var level := int(slot.get("current_level", 1))
			var stars := int(slot.get("stars", 0))
			var seconds := int(slot.get("play_time_sec", 0.0))
			var done := " DONE" if bool(slot.get("completed", false)) else ""
			_cards[i].text = "%s%s\nTrail %d: %s\nBadges %d | Time %dm %ds" % [
				title,
				done,
				level,
				GameManager.level_name_for(level),
				stars,
				seconds / 60,
				seconds % 60,
			]
	_update_delete_button()


func _update_delete_button() -> void:
	if _delete_button == null:
		return
	var empty := GameManager.is_slot_empty(_index)
	_delete_button.disabled = empty
	if empty:
		_delete_button.text = "Delete Save %d (empty)" % (_index + 1)
	elif _delete_armed_slot == _index:
		_delete_button.text = "CONFIRM DELETE SAVE %d" % (_index + 1)
	else:
		_delete_button.text = "Delete Save %d" % (_index + 1)


func _refresh_prompts() -> void:
	if _prompt:
		_prompt.text = InputManager.menu_prompt_line()
	if _hint and _erase_hold <= 0.0:
		if _delete_armed_slot == _index:
			_hint.text = "Press the red button again to delete Save %d" % (_index + 1)
		else:
			_hint.text = "Select a save, then use the Delete Save button below"


func _highlight() -> void:
	for i in range(_cards.size()):
		_cards[i].modulate = (
			Color(1, 1, 0.55, 1)
			if i == _index and not _delete_selected
			else Color(1, 1, 1, 1)
		)
	if _delete_button != null:
		_delete_button.modulate = (
			Color(1, 1, 0.55, 1) if _delete_selected else Color(1, 1, 1, 1)
		)
	_update_delete_button()
