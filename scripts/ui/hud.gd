class_name Hud
extends CanvasLayer

var _level_label: Label
var _stars_label: Label
var _mode_label: Label
var _prompt_label: Label
var _progress_fill: ColorRect
var _progress_label: Label
var _default_prompt: String = "Controls"
var _toast_remaining: float = 0.0


func _ready() -> void:
	layer = 50
	_level_label = get_node_or_null("LevelLabel") as Label
	_stars_label = get_node_or_null("StarsLabel") as Label
	_mode_label = get_node_or_null("ModeLabel") as Label
	_prompt_label = get_node_or_null("PromptLabel") as Label
	_progress_fill = get_node_or_null("ProgressFill") as ColorRect
	_progress_label = get_node_or_null("ProgressLabel") as Label
	_ensure_progress_widgets()
	set_stars(0)
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
		_level_label.text = title


func set_stars(count: int) -> void:
	if _stars_label != null:
		_stars_label.text = "Badges: %d" % count


func set_mode(mode_name: String, remaining: float) -> void:
	if _mode_label == null:
		return
	if mode_name == "None" or remaining <= 0.0:
		_mode_label.text = "Power: -"
	else:
		_mode_label.text = "Power: %s (%.0fs)" % [mode_name, remaining]


func set_prompt(text: String) -> void:
	_default_prompt = text
	if _toast_remaining <= 0.0 and _prompt_label != null:
		_prompt_label.text = text


func show_toast(text: String, duration: float = 2.0) -> void:
	if _prompt_label == null:
		return
	_prompt_label.text = text
	_toast_remaining = duration


func set_trail_progress(ratio: float) -> void:
	_ensure_progress_widgets()
	var clamped := clampf(ratio, 0.0, 1.0)
	if _progress_fill != null:
		_progress_fill.size.x = 300.0 * clamped
		# Cheerful color shift toward the saloon.
		_progress_fill.color = Color(0.35, 0.72, 0.35, 1.0).lerp(Color(0.95, 0.7, 0.2, 1.0), clamped)
	if _progress_label != null:
		_progress_label.text = "Trail %d%%" % int(round(clamped * 100.0))


func mark_camps(ratios: Array) -> void:
	_ensure_progress_widgets()
	for child in get_children():
		if String(child.name).begins_with("CampMark"):
			child.queue_free()
	for i in range(ratios.size()):
		var mark := ColorRect.new()
		mark.name = "CampMark%d" % i
		var x := 482.0 + 300.0 * clampf(float(ratios[i]), 0.0, 1.0) - 2.0
		mark.position = Vector2(x, 22)
		mark.size = Vector2(4, 22)
		mark.color = Color(0.85, 0.25, 0.15, 1.0)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mark)


func _ensure_progress_widgets() -> void:
	if _progress_fill != null and _progress_label != null:
		return
	var track := get_node_or_null("ProgressTrack") as ColorRect
	if track == null:
		track = ColorRect.new()
		track.name = "ProgressTrack"
		track.position = Vector2(480, 24)
		track.size = Vector2(304, 18)
		track.color = Color(0.85, 0.7, 0.45, 0.9)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(track)
	_progress_fill = get_node_or_null("ProgressFill") as ColorRect
	if _progress_fill == null:
		_progress_fill = ColorRect.new()
		_progress_fill.name = "ProgressFill"
		_progress_fill.position = Vector2(482, 26)
		_progress_fill.size = Vector2(0, 14)
		_progress_fill.color = Color(0.35, 0.72, 0.35, 1.0)
		_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_progress_fill)
	_progress_label = get_node_or_null("ProgressLabel") as Label
	if _progress_label == null:
		_progress_label = Label.new()
		_progress_label.name = "ProgressLabel"
		_progress_label.position = Vector2(480, 44)
		_progress_label.size = Vector2(304, 24)
		_progress_label.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05, 1.0))
		_progress_label.add_theme_font_size_override(&"font_size", 16)
		_progress_label.text = "Trail 0%"
		add_child(_progress_label)
