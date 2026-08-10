extends Control

## Boot loading — desert skyline + saloon boards with a filling trail progress bar.

const LOAD_DURATION := 1.2
const TRACK_INK := Color(0.32, 0.14, 0.05, 0.95)
const TRACK_WOOD := Color(0.55, 0.30, 0.12, 0.92)
const FILL_GOLD := Color(0.95, 0.72, 0.28, 1.0)
const FILL_WARM := Color(0.98, 0.55, 0.18, 1.0)
const PAD := 5.0

var _elapsed: float = 0.0
var _label: Label
var _bar_fill: ColorRect
var _bar_track: Control
var _done: bool = false


func _ready() -> void:
	_label = get_node_or_null("LoadingLabel") as Label
	var title := get_node_or_null("Title") as Label
	if title != null:
		title.text = tr("Cowboy Trail")
	_ensure_progress_bar()
	_set_progress(0.0)
	AudioManager.play_boot_intro()


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	var t := clampf(_elapsed / LOAD_DURATION, 0.0, 1.0)
	## Ease-out so the bar feels like it settles into the saloon.
	var eased := 1.0 - pow(1.0 - t, 2.2)
	_set_progress(eased)
	if _label != null:
		_label.text = tr("Saddling up") + ".".repeat(int(_elapsed * 3.0) % 4)
	if t >= 1.0:
		_done = true
		set_process(false)
		get_tree().change_scene_to_file("res://scenes/ui/save_select.tscn")


func _ensure_progress_bar() -> void:
	_bar_track = get_node_or_null("ProgressTrack") as Control
	_bar_fill = get_node_or_null("ProgressTrack/ProgressFill") as ColorRect
	if _bar_track == null:
		_bar_track = Control.new()
		_bar_track.name = "ProgressTrack"
		_bar_track.set_anchors_preset(Control.PRESET_CENTER)
		_bar_track.offset_left = -220.0
		_bar_track.offset_top = 88.0
		_bar_track.offset_right = 220.0
		_bar_track.offset_bottom = 118.0
		_bar_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bar_track)
	_bar_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rim := _bar_track.get_node_or_null("TrackRim") as ColorRect
	if rim == null:
		rim = ColorRect.new()
		rim.name = "TrackRim"
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rim.color = TRACK_INK
		_bar_track.add_child(rim)
		_bar_track.move_child(rim, 0)
	rim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bed := _bar_track.get_node_or_null("TrackBed") as ColorRect
	if bed == null:
		bed = ColorRect.new()
		bed.name = "TrackBed"
		bed.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bed.color = TRACK_WOOD
		_bar_track.add_child(bed)
		_bar_track.move_child(bed, 1)
	bed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bed.offset_left = 3.0
	bed.offset_top = 3.0
	bed.offset_right = -3.0
	bed.offset_bottom = -3.0
	if _bar_fill == null:
		_bar_fill = ColorRect.new()
		_bar_fill.name = "ProgressFill"
		_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar_track.add_child(_bar_fill)
	_bar_fill.color = FILL_GOLD
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_progress(amount: float) -> void:
	if _bar_track == null or _bar_fill == null:
		return
	var track_w := _bar_track.size.x
	var track_h := _bar_track.size.y
	if track_w < 8.0 or track_h < 8.0:
		track_w = maxf(1.0, _bar_track.offset_right - _bar_track.offset_left)
		track_h = maxf(1.0, _bar_track.offset_bottom - _bar_track.offset_top)
	var max_w := maxf(track_w - PAD * 2.0, 1.0)
	var h := maxf(track_h - PAD * 2.0, 8.0)
	var w := max_w * clampf(amount, 0.0, 1.0)
	_bar_fill.position = Vector2(PAD, PAD)
	_bar_fill.size = Vector2(w, h)
	_bar_fill.color = FILL_GOLD.lerp(FILL_WARM, clampf(amount, 0.0, 1.0))


func get_load_progress() -> float:
	## Test helper: 0..1 visual fill amount.
	if _bar_fill == null or _bar_track == null:
		return 0.0
	var max_w := maxf(_bar_track.size.x - PAD * 2.0, 1.0)
	if max_w < 2.0:
		max_w = maxf((_bar_track.offset_right - _bar_track.offset_left) - PAD * 2.0, 1.0)
	return clampf(_bar_fill.size.x / max_w, 0.0, 1.0)
