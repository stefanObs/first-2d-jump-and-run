class_name DisappearingPlatform
extends StaticBody2D

@export var visible_time: float = 2.0
@export var hidden_time: float = 1.5
@export var start_delay: float = 0.0
@export var warn_time: float = 0.55

var _timer: float = 0.0
var _solid: bool = true
var _started: bool = false
var _shape: CollisionShape2D
var _visual: ColorRect
var _label: Label
var _extras: Array[CanvasItem] = []
var _blink_phase: float = 0.0


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_visual = get_node_or_null("Visual") as ColorRect
	_label = get_node_or_null("Label") as Label
	for child in get_children():
		if child is CanvasItem and (String(child.name).begins_with("Fluff") or child == _visual):
			_extras.append(child as CanvasItem)
	_timer = start_delay
	_started = start_delay <= 0.0
	_apply_state()


func _process(delta: float) -> void:
	_timer -= delta
	_blink_phase += delta * 14.0
	if not _started:
		if _timer > 0.0:
			return
		_started = true
		_solid = true
		_timer = visible_time
		_apply_state()
		return

	if _timer <= 0.0:
		_solid = not _solid
		_timer = visible_time if _solid else hidden_time
		_apply_state()
		return

	_update_warning_blink()


func _apply_state() -> void:
	if _shape != null:
		_shape.disabled = not _solid
	var alpha := 1.0 if _solid else 0.25
	for item in _extras:
		item.modulate = Color(1, 1, 1, alpha)
	if _label != null:
		_label.text = "CLOUD" if _solid else "..."
		_label.modulate = Color(1, 1, 1, alpha)


func _update_warning_blink() -> void:
	if not _solid:
		return
	if _timer > warn_time:
		for item in _extras:
			item.modulate = Color(1, 1, 1, 1.0)
		if _label != null:
			_label.text = "CLOUD"
			_label.modulate = Color(1, 1, 1, 1)
		return
	var pulse := 0.4 + absf(sin(_blink_phase)) * 0.6
	var warn := Color(1.0, 0.9, 0.35, pulse)
	for item in _extras:
		item.modulate = warn
	if _label != null:
		_label.text = "WAIT!"
		_label.modulate = Color(0.85, 0.35, 0.1, 1.0)
