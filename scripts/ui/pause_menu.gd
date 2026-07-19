class_name PauseMenu
extends CanvasLayer

signal continue_pressed
signal save_pressed
signal load_pressed
signal restart_pressed
signal save_select_pressed
signal settings_pressed

var _settings: SettingsPanel
var _buttons: Array[Button] = []
var _index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 120
	_settings = get_node_or_null("SettingsPanel") as SettingsPanel
	for name in [
		"ContinueButton",
		"SaveButton",
		"LoadButton",
		"RestartButton",
		"SaveSelectButton",
		"SettingsButton",
	]:
		var button := get_node_or_null("Panel/%s" % name) as Button
		if button != null:
			_buttons.append(button)
	if _settings != null:
		_settings.visible = false
		_settings.closed.connect(func() -> void: _settings.visible = false)
	_connect_buttons()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or (_settings != null and _settings.visible):
		return
	if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_right"):
		_move(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_left"):
		_move(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
		_activate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"back") or event.is_action_pressed(&"pause"):
		continue_pressed.emit()
		get_viewport().set_input_as_handled()


func focus_first() -> void:
	_index = 0
	_highlight()


func show_settings() -> void:
	if _settings != null:
		_settings.visible = true
		_settings.focus_first()


func set_save_options(campaign_save_enabled: bool, can_load: bool) -> void:
	var save_button := get_node_or_null("Panel/SaveButton") as Button
	var load_button := get_node_or_null("Panel/LoadButton") as Button
	if save_button != null:
		save_button.visible = campaign_save_enabled
	if load_button != null:
		load_button.visible = campaign_save_enabled
		load_button.disabled = not can_load
		load_button.text = "Load Game" if can_load else "Load Game (none yet)"
	_buttons.clear()
	for name in [
		"ContinueButton",
		"SaveButton",
		"LoadButton",
		"RestartButton",
		"SaveSelectButton",
		"SettingsButton",
	]:
		var button := get_node_or_null("Panel/%s" % name) as Button
		if button != null and button.visible and not button.disabled:
			_buttons.append(button)
	focus_first()


func _connect_buttons() -> void:
	var continue_button := get_node_or_null("Panel/ContinueButton") as Button
	var save_button := get_node_or_null("Panel/SaveButton") as Button
	var load_button := get_node_or_null("Panel/LoadButton") as Button
	var restart_button := get_node_or_null("Panel/RestartButton") as Button
	var select_button := get_node_or_null("Panel/SaveSelectButton") as Button
	var settings_button := get_node_or_null("Panel/SettingsButton") as Button
	if continue_button != null:
		continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	if save_button != null:
		save_button.pressed.connect(func() -> void: save_pressed.emit())
	if load_button != null:
		load_button.pressed.connect(func() -> void: load_pressed.emit())
	if restart_button != null:
		restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	if select_button != null:
		select_button.pressed.connect(func() -> void: save_select_pressed.emit())
	if settings_button != null:
		settings_button.pressed.connect(func() -> void: settings_pressed.emit())


func _move(delta: int) -> void:
	if _buttons.is_empty():
		return
	_index = wrapi(_index + delta, 0, _buttons.size())
	_highlight()


func _activate() -> void:
	if _buttons.is_empty():
		return
	_buttons[_index].pressed.emit()


func _highlight() -> void:
	for i in range(_buttons.size()):
		_buttons[i].modulate = Color(1, 1, 0.6, 1) if i == _index else Color(1, 1, 1, 1)
