class_name MovingPlatform
extends AnimatableBody2D

@export var point_a: Vector2 = Vector2(-100, 0)
@export var point_b: Vector2 = Vector2(100, 0)
@export var move_speed: float = 70.0

var _origin: Vector2
var _to_b: bool = true


func _ready() -> void:
	_origin = global_position


func _physics_process(delta: float) -> void:
	var target := _origin + (point_b if _to_b else point_a)
	global_position = global_position.move_toward(target, move_speed * delta)
	if global_position.distance_to(target) < 2.0:
		_to_b = not _to_b
