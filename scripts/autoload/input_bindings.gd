extends Node

## Registers keyboard and Xbox controller actions used by the game.
## Gameplay code must only read these named actions.


func _ready() -> void:
	_ensure_action(
		&"move_left",
		[
			_key(KEY_A),
			_key(KEY_LEFT),
			_joy_button(JOY_BUTTON_DPAD_LEFT),
			_joy_axis(JOY_AXIS_LEFT_X, -1.0),
		]
	)
	_ensure_action(
		&"move_right",
		[
			_key(KEY_D),
			_key(KEY_RIGHT),
			_joy_button(JOY_BUTTON_DPAD_RIGHT),
			_joy_axis(JOY_AXIS_LEFT_X, 1.0),
		]
	)
	_ensure_action(
		&"jump",
		[
			_key(KEY_SPACE),
			_key(KEY_W),
			_key(KEY_UP),
			_joy_button(JOY_BUTTON_A),
		]
	)
	_ensure_action(
		&"pause",
		[
			_key(KEY_ESCAPE),
			_joy_button(JOY_BUTTON_START),
		]
	)
	_ensure_action(
		&"confirm",
		[
			_key(KEY_ENTER),
			_joy_button(JOY_BUTTON_A),
		]
	)
	_ensure_action(
		&"back",
		[
			_key(KEY_ESCAPE),
			_joy_button(JOY_BUTTON_B),
		]
	)
	_ensure_action(
		&"ui_up",
		[
			_key(KEY_UP),
			_key(KEY_W),
			_joy_button(JOY_BUTTON_DPAD_UP),
			_joy_axis(JOY_AXIS_LEFT_Y, -1.0),
		]
	)
	_ensure_action(
		&"ui_down",
		[
			_key(KEY_DOWN),
			_key(KEY_S),
			_joy_button(JOY_BUTTON_DPAD_DOWN),
			_joy_axis(JOY_AXIS_LEFT_Y, 1.0),
		]
	)
	_ensure_action(
		&"ui_left",
		[
			_key(KEY_LEFT),
			_key(KEY_A),
			_joy_button(JOY_BUTTON_DPAD_LEFT),
			_joy_axis(JOY_AXIS_LEFT_X, -1.0),
		]
	)
	_ensure_action(
		&"ui_right",
		[
			_key(KEY_RIGHT),
			_key(KEY_D),
			_joy_button(JOY_BUTTON_DPAD_RIGHT),
			_joy_axis(JOY_AXIS_LEFT_X, 1.0),
		]
	)


func _ensure_action(action: StringName, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for event in events:
		if not _action_has_equivalent_event(action, event):
			InputMap.action_add_event(action, event)


func _action_has_equivalent_event(action: StringName, candidate: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action):
		if existing.as_text() == candidate.as_text():
			return true
	return false


func _key(physical_keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_keycode
	return event


func _joy_button(button_index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	return event


func _joy_axis(axis: JoyAxis, axis_value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	return event
