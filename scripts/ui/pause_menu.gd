class_name PauseMenu
extends CanvasLayer

signal continue_pressed
signal save_pressed
signal load_pressed
signal restart_pressed
signal save_select_pressed
signal settings_pressed

const TEXT_COLOR := Color(0.28, 0.12, 0.04, 1.0)
const BUTTON_NAMES := [
	"ContinueButton",
	"SaveButton",
	"LoadButton",
	"RestartButton",
	"SaveSelectButton",
	"SettingsButton",
]

var _settings: SettingsPanel
var _buttons: Array[Button] = []
var _index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	layer = 120
	_settings = get_node_or_null("SettingsPanel") as SettingsPanel
	_style_panel()
	_collect_buttons(true)
	if _settings != null:
		_settings.visible = false
		_settings.closed.connect(_on_settings_closed)
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
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		panel.visible = false
	if _settings != null:
		_settings.visible = true
		_settings.focus_first()


func set_save_options(campaign_save_enabled: bool, can_load: bool) -> void:
	var save_button := _button("SaveButton")
	var load_button := _button("LoadButton")
	if save_button != null:
		save_button.visible = campaign_save_enabled
	if load_button != null:
		load_button.visible = campaign_save_enabled
		load_button.disabled = not can_load
		load_button.text = "Load Game" if can_load else "Load Game (none yet)"
	_collect_buttons(false)
	focus_first()


func _on_settings_closed() -> void:
	if _settings != null:
		_settings.visible = false
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		panel.visible = true
	focus_first()


func _button(button_name: String) -> Button:
	var button := get_node_or_null("Panel/Margin/VBox/%s" % button_name) as Button
	if button == null:
		button = get_node_or_null("Panel/%s" % button_name) as Button
	return button


func _collect_buttons(include_disabled: bool) -> void:
	_buttons.clear()
	for button_name in BUTTON_NAMES:
		var button := _button(button_name)
		if button == null or not button.visible:
			continue
		if include_disabled or not button.disabled:
			_buttons.append(button)


func _connect_buttons() -> void:
	var continue_button := _button("ContinueButton")
	var save_button := _button("SaveButton")
	var load_button := _button("LoadButton")
	var restart_button := _button("RestartButton")
	var select_button := _button("SaveSelectButton")
	var settings_button := _button("SettingsButton")
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


func _style_panel() -> void:
	var panel := get_node_or_null("Panel") as PanelContainer
	if panel != null:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 0.93, 0.78, 1)
		style.set_border_width_all(4)
		style.border_color = Color(0.45, 0.24, 0.08, 1)
		style.set_corner_radius_all(12)
		panel.add_theme_stylebox_override(&"panel", style)
	var title := get_node_or_null("Panel/Margin/VBox/Title") as Label
	if title != null:
		title.add_theme_color_override(&"font_color", TEXT_COLOR)
	for button_name in BUTTON_NAMES:
		var button := _button(button_name)
		if button != null:
			_style_button(button)


func _style_button(button: Button) -> void:
	button.add_theme_color_override(&"font_color", TEXT_COLOR)
	button.add_theme_color_override(&"font_hover_color", Color(0.45, 0.2, 0.06, 1.0))
	button.add_theme_color_override(&"font_pressed_color", TEXT_COLOR)
	button.add_theme_color_override(&"font_disabled_color", Color(0.45, 0.35, 0.28, 1.0))
	button.add_theme_font_size_override(&"font_size", 22)
	button.custom_minimum_size.y = 52
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.95, 0.78, 0.42, 1)
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(3)
	normal.border_color = Color(0.45, 0.24, 0.08, 1)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.86, 0.5, 1)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.85, 0.78, 0.65, 1)
	disabled.border_color = Color(0.6, 0.5, 0.4, 1)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", hover)
	button.add_theme_stylebox_override(&"focus", hover)
	button.add_theme_stylebox_override(&"disabled", disabled)


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
