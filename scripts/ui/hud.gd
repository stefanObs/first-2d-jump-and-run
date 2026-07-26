class_name Hud
extends CanvasLayer

var _level_label: Label
var _stars_label: Label
var _lives_hearts_label: Label
var _lives_panel: PanelContainer
var _mode_label: Label
var _prompt_label: Label
var _trail_bar: HandmadeProgress
var _power_track: ColorRect
var _power_fill: ColorRect
var _default_prompt: String = "Controls"
var _toast_remaining: float = 0.0
var _mode_max: float = 1.0
var _mode_name_active: String = "None"


func _ready() -> void:
	layer = 50
	_level_label = get_node_or_null("LevelLabel") as Label
	_stars_label = get_node_or_null("StarsLabel") as Label
	_mode_label = get_node_or_null("ModeLabel") as Label
	_prompt_label = get_node_or_null("PromptLabel") as Label
	_ensure_lives_display()
	_ensure_progress_widgets()
	_ensure_power_bar()
	set_stars(0)
	set_lives(0, false)
	set_mode("None", 0.0)
	set_trail_progress(0.0)


func _process(delta: float) -> void:
	if _toast_remaining <= 0.0:
		return
	_toast_remaining = maxf(_toast_remaining - delta, 0.0)
	if _toast_remaining <= 0.0 and _prompt_label != null:
		_prompt_label.text = _default_prompt


func set_level_title(title: String) -> void:
	if _level_label != null:
		_level_label.text = tr(title)


func set_stars(count: int) -> void:
	if _stars_label != null:
		_stars_label.text = tr("Badges: %d") % count


func set_lives(count: int, show: bool) -> void:
	_ensure_lives_display()
	if _lives_panel != null:
		_lives_panel.show() if show else _lives_panel.hide()
	if _lives_hearts_label == null:
		return
	if show:
		_lives_hearts_label.show()
	else:
		_lives_hearts_label.hide()
	if not show:
		return
	var filled := ""
	for i in range(maxi(count, 0)):
		filled += "♥"
		if i < count - 1:
			filled += " "
	_lives_hearts_label.text = filled if filled != "" else "♡"
	_lives_hearts_label.modulate = Color(1, 1, 1, 1)
	_bring_lives_to_front()


func _bring_lives_to_front() -> void:
	if _lives_panel != null:
		_lives_panel.z_index = 40
		_lives_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		move_child(_lives_panel, get_child_count() - 1)
	if _lives_hearts_label == null:
		return
	_lives_hearts_label.z_index = 1
	_lives_hearts_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_mode(mode_name: String, remaining: float) -> void:
	_ensure_power_bar()
	if _mode_label == null:
		return
	if mode_name == "None" or remaining <= 0.0:
		_mode_label.text = tr("Power: -")
		_mode_max = 1.0
		_mode_name_active = "None"
		if _power_fill != null:
			_power_fill.size.x = 0.0
		if _power_track != null:
			_power_track.visible = false
		return
	if mode_name != _mode_name_active:
		_mode_name_active = mode_name
		_mode_max = maxf(remaining, 0.01)
	elif remaining > _mode_max:
		_mode_max = remaining
	_mode_label.text = tr("Power: %s (%.0fs)") % [tr(mode_name), remaining]
	if _power_track != null:
		_power_track.visible = true
	if _power_fill != null:
		var ratio := clampf(remaining / maxf(_mode_max, 0.01), 0.0, 1.0)
		_power_fill.size.x = 200.0 * ratio
		_power_fill.color = Color(0.35, 0.75, 1.0, 1.0).lerp(Color(1.0, 0.45, 0.25, 1.0), 1.0 - ratio)


func set_prompt(text: String) -> void:
	_default_prompt = tr(text)
	if _toast_remaining <= 0.0 and _prompt_label != null:
		_prompt_label.text = _default_prompt


func show_toast(text: String, duration: float = 2.0) -> void:
	if _prompt_label == null:
		return
	_prompt_label.text = tr(text)
	_toast_remaining = duration


func set_trail_progress(ratio: float) -> void:
	_ensure_progress_widgets()
	if _trail_bar != null:
		_trail_bar.set_progress(ratio)


func mark_camps(ratios: Array) -> void:
	_ensure_progress_widgets()
	if _trail_bar != null:
		_trail_bar.set_camps(ratios)


func _ensure_power_bar() -> void:
	_power_track = get_node_or_null("PowerTrack") as ColorRect
	_power_fill = get_node_or_null("PowerFill") as ColorRect
	if _power_track != null and _power_fill != null:
		return
	_power_track = ColorRect.new()
	_power_track.name = "PowerTrack"
	_power_track.position = Vector2(36, 118)
	_power_track.size = Vector2(204, 12)
	_power_track.color = Color(0.55, 0.32, 0.14, 0.9)
	_power_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_power_track.visible = false
	add_child(_power_track)
	_power_fill = ColorRect.new()
	_power_fill.name = "PowerFill"
	_power_fill.position = Vector2(38, 120)
	_power_fill.size = Vector2(0, 8)
	_power_fill.color = Color(0.35, 0.75, 1.0, 1.0)
	_power_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_power_fill)


func _ensure_lives_display() -> void:
	if _lives_panel == null:
		_lives_panel = get_node_or_null("LivesPanel") as PanelContainer
	if _lives_hearts_label == null and _lives_panel != null:
		_lives_hearts_label = _lives_panel.get_node_or_null("LivesHeartsLabel") as Label
	if _lives_hearts_label == null:
		_lives_hearts_label = get_node_or_null("LivesHeartsLabel") as Label
	if _lives_panel == null:
		return
	if _lives_panel.get_theme_stylebox(&"panel") == null:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0.42, 0.18, 0.08, 0.92)
		panel_style.set_corner_radius_all(10)
		panel_style.set_border_width_all(3)
		panel_style.border_color = Color(0.92, 0.72, 0.28, 1.0)
		panel_style.content_margin_left = 14
		panel_style.content_margin_right = 14
		panel_style.content_margin_top = 4
		panel_style.content_margin_bottom = 4
		_lives_panel.add_theme_stylebox_override(&"panel", panel_style)
	if _lives_hearts_label == null:
		_lives_hearts_label = Label.new()
		_lives_hearts_label.name = "LivesHeartsLabel"
		_lives_hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lives_hearts_label.add_theme_font_size_override(&"font_size", 34)
		_lives_hearts_label.add_theme_color_override(&"font_color", Color(1.0, 0.28, 0.32, 1))
		_lives_hearts_label.add_theme_color_override(&"font_outline_color", Color(0.12, 0.02, 0.02, 1))
		_lives_hearts_label.add_theme_constant_override(&"outline_size", 8)
		_lives_panel.add_child(_lives_hearts_label)


func _ensure_progress_widgets() -> void:
	_trail_bar = get_node_or_null("TrailProgress") as HandmadeProgress
	if _trail_bar != null:
		return
	_trail_bar = HandmadeProgress.new()
	_trail_bar.name = "TrailProgress"
	_trail_bar.position = Vector2(820, 10)
	_trail_bar.size = Vector2(340, 64)
	add_child(_trail_bar)
