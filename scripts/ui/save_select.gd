extends Control

## Title / three-slot save selection screen.

var _cards: Array[Button] = []
var _index: int = 0
var _erase_hold: float = 0.0
var _prompt: Label
var _hint: Label


func _ready() -> void:
	_prompt = get_node_or_null("PromptLabel") as Label
	_hint = get_node_or_null("HintLabel") as Label
	for i in range(3):
		var card := get_node_or_null("Slots/Slot%d" % (i + 1)) as Button
		if card != null:
			_cards.append(card)
			var captured := i
			card.pressed.connect(func() -> void: _select_slot(captured))
	GameManager.saves_changed.connect(_refresh)
	InputManager.device_changed.connect(func(_d: Variant) -> void: _refresh_prompts())
	_refresh()
	_refresh_prompts()
	_highlight()


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
	if event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		_index = wrapi(_index + 1, 0, _cards.size())
		_highlight()
	elif event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		_index = wrapi(_index - 1, 0, _cards.size())
		_highlight()
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
		_select_slot(_index)


func _select_slot(slot_index: int) -> void:
	GameManager.start_or_continue_slot(slot_index)


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
			_cards[i].text = "%s%s\nLevel %d: %s\nStars %d | Time %dm %ds" % [
				title,
				done,
				level,
				GameManager.level_name_for(level),
				stars,
				seconds / 60,
				seconds % 60,
			]


func _refresh_prompts() -> void:
	if _prompt:
		_prompt.text = InputManager.menu_prompt_line()
	if _hint and _erase_hold <= 0.0:
		_hint.text = "Hold Back + Pause to erase the highlighted save"


func _highlight() -> void:
	for i in range(_cards.size()):
		_cards[i].modulate = Color(1, 1, 0.55, 1) if i == _index else Color(1, 1, 1, 1)
