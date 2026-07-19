class_name MovingPlatform
extends AnimatableBody2D

@export var point_a: Vector2 = Vector2(-100, 0)
@export var point_b: Vector2 = Vector2(100, 0)
@export var move_speed: float = 60.0

var _origin: Vector2
var _to_b: bool = true
var _label: Label


func _ready() -> void:
	_origin = global_position
	_label = get_node_or_null("Label") as Label
	_update_label()


func _physics_process(delta: float) -> void:
	var target := _origin + (point_b if _to_b else point_a)
	global_position = global_position.move_toward(target, move_speed * delta)
	if global_position.distance_to(target) < 2.0:
		_to_b = not _to_b
		_update_label()


func _update_label() -> void:
	if _label == null:
		return
	var delta := point_b - point_a
	if absf(delta.x) >= absf(delta.y):
		_label.text = "RAFT >>" if (_to_b and delta.x >= 0.0) or (not _to_b and delta.x < 0.0) else "<< RAFT"
	else:
		_label.text = "RAFT"
