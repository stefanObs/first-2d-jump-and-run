class_name SettingsPanel
extends PanelContainer

signal closed

var _music: HSlider
var _sfx: HSlider
var _vibration: CheckButton
var _fullscreen: CheckButton
var _index: int = 0
var _controls: Array[Control] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_music = get_node_or_null("VBox/MusicSlider") as HSlider
	_sfx = get_node_or_null("VBox/SfxSlider") as HSlider
	_vibration = get_node_or_null("VBox/VibrationToggle") as CheckButton
	_fullscreen = get_node_or_null("VBox/FullscreenToggle") as CheckButton
	var back := get_node_or_null("VBox/BackButton") as Button
	_controls = [_music, _sfx, _vibration, _fullscreen, back]
	_load_values()
	if _music:
		_music.value_changed.connect(func(v: float) -> void: GameManager.set_setting("music_volume", v))
	if _sfx:
		_sfx.value_changed.connect(func(v: float) -> void: GameManager.set_setting("sfx_volume", v))
	if _vibration:
		_vibration.toggled.connect(func(v: bool) -> void: GameManager.set_setting("vibration", v))
	if _fullscreen:
		_fullscreen.toggled.connect(func(v: bool) -> void: GameManager.set_setting("fullscreen", v))
	if back:
		back.pressed.connect(func() -> void: closed.emit())


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_right"):
		_index = wrapi(_index + 1, 0, _controls.size())
		_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_left"):
		_index = wrapi(_index - 1, 0, _controls.size())
		_highlight()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
		_activate()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"back"):
		closed.emit()
		get_viewport().set_input_as_handled()


func focus_first() -> void:
	_index = 0
	_highlight()


func _load_values() -> void:
	var settings := GameManager.get_settings()
	if _music:
		_music.value = float(settings.get("music_volume", 0.8))
	if _sfx:
		_sfx.value = float(settings.get("sfx_volume", 0.8))
	if _vibration:
		_vibration.button_pressed = bool(settings.get("vibration", true))
	if _fullscreen:
		_fullscreen.button_pressed = bool(settings.get("fullscreen", false))


func _activate() -> void:
	var control := _controls[_index]
	if control is CheckButton:
		(control as CheckButton).button_pressed = not (control as CheckButton).button_pressed
	elif control is Button:
		(control as Button).pressed.emit()


func _highlight() -> void:
	for i in range(_controls.size()):
		if _controls[i] != null:
			_controls[i].modulate = Color(1, 1, 0.6, 1) if i == _index else Color(1, 1, 1, 1)
