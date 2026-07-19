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
var _blink_phase: float = 0.0


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_visual = get_node_or_null("Visual") as ColorRect
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
	if _visual != null:
		_visual.modulate = Color(1, 1, 1, 1.0 if _solid else 0.25)


func _update_warning_blink() -> void:
	if _visual == null or not _solid:
		return
	if _timer > warn_time:
		_visual.modulate = Color(1, 1, 1, 1.0)
		return
	var pulse := 0.4 + absf(sin(_blink_phase)) * 0.6
	_visual.modulate = Color(1.0, 0.9, 0.35, pulse)
