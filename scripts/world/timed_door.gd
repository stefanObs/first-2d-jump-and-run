class_name TimedDoor
extends StaticBody2D

@export var open_time: float = 2.8
@export var closed_time: float = 1.6
@export var start_open: bool = false
@export var warn_time: float = 0.85

var _open: bool = false
var _timer: float = 0.0
var _shape: CollisionShape2D
var _visual: ColorRect
var _label: Label
var _blink_phase: float = 0.0


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_visual = get_node_or_null("Visual") as ColorRect
	_label = get_node_or_null("Label") as Label
	_open = start_open
	_timer = open_time if _open else closed_time
	_apply_state()


func _process(delta: float) -> void:
	_timer -= delta
	_blink_phase += delta * 14.0
	if _timer <= 0.0:
		_open = not _open
		_timer = open_time if _open else closed_time
		_apply_state()
		return
	_update_warning_blink()


func _apply_state() -> void:
	if _shape != null:
		_shape.disabled = _open
	if _visual != null:
		_visual.modulate = Color(1, 1, 1, 0.2 if _open else 1.0)
	if _label != null:
		_label.text = "OPEN" if _open else "GATE"
		_label.modulate = Color(0.25, 0.55, 0.2, 1.0) if _open else Color(0.45, 0.18, 0.08, 1.0)


func _update_warning_blink() -> void:
	if _visual == null:
		return
	if _timer > warn_time:
		_visual.modulate = Color(1, 1, 1, 0.2 if _open else 1.0)
		if _label != null and not _open:
			_label.text = "GATE"
		elif _label != null:
			_label.text = "OPEN"
		return
	var pulse := 0.35 + absf(sin(_blink_phase)) * 0.65
	if _open:
		_visual.modulate = Color(1.0, 0.95, 0.35, pulse)
		if _label != null:
			_label.text = "HURRY!"
	else:
		_visual.modulate = Color(1.0, 0.85, 0.3, pulse)
		if _label != null:
			_label.text = "WAIT!"
			_label.add_theme_font_size_override(&"font_size", 16)
