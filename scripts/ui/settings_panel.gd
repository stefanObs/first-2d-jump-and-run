class_name SettingsPanel
extends PanelContainer

signal closed

const TEXT_COLOR := Color(0.28, 0.12, 0.04, 1.0)
const SLIDER_TRACK := Color(0.72, 0.48, 0.22, 1.0)
const SLIDER_FILL := Color(0.95, 0.62, 0.18, 1.0)

var _music: HSlider
var _sfx: HSlider
var _vibration: CheckButton
var _fullscreen: CheckButton
var _index: int = 0
var _controls: Array[Control] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_music = get_node_or_null("Margin/VBox/MusicSlider") as HSlider
	_sfx = get_node_or_null("Margin/VBox/SfxSlider") as HSlider
	_vibration = get_node_or_null("Margin/VBox/VibrationToggle") as CheckButton
	_fullscreen = get_node_or_null("Margin/VBox/FullscreenToggle") as CheckButton
	var back := get_node_or_null("Margin/VBox/BackButton") as Button
	# Fallback for older scene layouts without the Margin wrapper.
	if _music == null:
		_music = get_node_or_null("VBox/MusicSlider") as HSlider
	if _sfx == null:
		_sfx = get_node_or_null("VBox/SfxSlider") as HSlider
	if _vibration == null:
		_vibration = get_node_or_null("VBox/VibrationToggle") as CheckButton
	if _fullscreen == null:
		_fullscreen = get_node_or_null("VBox/FullscreenToggle") as CheckButton
	if back == null:
		back = get_node_or_null("VBox/BackButton") as Button
	_controls = [_music, _sfx, _vibration, _fullscreen, back]
	_controls = _controls.filter(func(c: Control) -> bool: return c != null)
	_style_readable()
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


func _style_readable() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(1, 0.93, 0.78, 1)
	panel.set_border_width_all(4)
	panel.border_color = Color(0.45, 0.24, 0.08, 1)
	panel.set_corner_radius_all(12)
	panel.content_margin_left = 8
	panel.content_margin_top = 8
	panel.content_margin_right = 8
	panel.content_margin_bottom = 8
	add_theme_stylebox_override(&"panel", panel)
	var ink := TEXT_COLOR
	for path in [
		"Margin/VBox/Title",
		"Margin/VBox/MusicLabel",
		"Margin/VBox/SfxLabel",
		"VBox/Title",
		"VBox/MusicLabel",
		"VBox/SfxLabel",
	]:
		var label := get_node_or_null(path) as Label
		if label != null:
			label.add_theme_color_override(&"font_color", ink)
			label.add_theme_font_size_override(&"font_size", maxi(label.get_theme_font_size("font_size"), 22))
	for control in [_vibration, _fullscreen]:
		if control == null:
			continue
		control.add_theme_color_override(&"font_color", ink)
		control.add_theme_color_override(&"font_pressed_color", ink)
		control.add_theme_color_override(&"font_hover_color", Color(0.45, 0.2, 0.06, 1.0))
		control.add_theme_font_size_override(&"font_size", 22)
	var back: Button = null
	if not _controls.is_empty() and _controls[_controls.size() - 1] is Button:
		back = _controls[_controls.size() - 1] as Button
	if back != null:
		back.add_theme_color_override(&"font_color", ink)
		back.add_theme_color_override(&"font_hover_color", Color(0.45, 0.2, 0.06, 1.0))
		back.add_theme_color_override(&"font_pressed_color", ink)
		back.add_theme_font_size_override(&"font_size", 24)
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
		back.add_theme_stylebox_override(&"normal", normal)
		back.add_theme_stylebox_override(&"hover", hover)
		back.add_theme_stylebox_override(&"pressed", hover)
		back.add_theme_stylebox_override(&"focus", hover)
	_style_slider(_music)
	_style_slider(_sfx)


func _style_slider(slider: HSlider) -> void:
	if slider == null:
		return
	slider.custom_minimum_size.y = 36
	var track := StyleBoxFlat.new()
	track.bg_color = SLIDER_TRACK
	track.set_corner_radius_all(8)
	track.content_margin_top = 12
	track.content_margin_bottom = 12
	var fill := StyleBoxFlat.new()
	fill.bg_color = SLIDER_FILL
	fill.set_corner_radius_all(8)
	slider.add_theme_stylebox_override(&"slider", track)
	slider.add_theme_stylebox_override(&"grabber_area", fill)
	slider.add_theme_stylebox_override(&"grabber_area_highlight", fill)
	var knob := _make_knob_texture()
	slider.add_theme_icon_override(&"grabber", knob)
	slider.add_theme_icon_override(&"grabber_highlight", knob)


func _make_knob_texture() -> ImageTexture:
	var image := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(22):
		for x in range(22):
			var dx := float(x) - 10.5
			var dy := float(y) - 10.5
			if dx * dx + dy * dy <= 100.0:
				image.set_pixel(x, y, Color(0.35, 0.16, 0.05, 1.0))
			elif dx * dx + dy * dy <= 121.0:
				image.set_pixel(x, y, Color(0.55, 0.3, 0.1, 1.0))
	return ImageTexture.create_from_image(image)


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
			_controls[i].modulate = Color(1, 1, 0.55, 1) if i == _index else Color(1, 1, 1, 1)
