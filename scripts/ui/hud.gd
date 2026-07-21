class_name Hud
extends CanvasLayer

var _level_label: Label
var _stars_label: Label
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
	_ensure_progress_widgets()
	_ensure_power_bar()
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
		_level_label.text = tr(title)


func set_stars(count: int) -> void:
	if _stars_label != null:
		_stars_label.text = tr("Badges: %d") % count


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
	Narrator.speak(_prompt_label.text)


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


func _ensure_progress_widgets() -> void:
	_trail_bar = get_node_or_null("TrailProgress") as HandmadeProgress
	if _trail_bar != null:
		return
	_trail_bar = HandmadeProgress.new()
	_trail_bar.name = "TrailProgress"
	_trail_bar.position = Vector2(470, 10)
	_trail_bar.size = Vector2(340, 64)
	add_child(_trail_bar)
