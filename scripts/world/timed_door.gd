class_name TimedDoor
extends StaticBody2D

@export var open_time: float = 2.0
@export var closed_time: float = 2.0
@export var start_open: bool = false

var _open: bool = false
var _timer: float = 0.0
var _shape: CollisionShape2D
var _visual: ColorRect


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_visual = get_node_or_null("Visual") as ColorRect
	_open = start_open
	_timer = open_time if _open else closed_time
	_apply_state()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_open = not _open
	_timer = open_time if _open else closed_time
	_apply_state()


func _apply_state() -> void:
	if _shape != null:
		_shape.disabled = _open
	if _visual != null:
		_visual.modulate.a = 0.2 if _open else 1.0
