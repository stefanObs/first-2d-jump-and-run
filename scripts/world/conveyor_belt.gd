class_name ConveyorBelt
extends StaticBody2D

@export var push_speed: float = 120.0
@export var push_right: bool = true

var _area: Area2D


func _ready() -> void:
	_area = get_node_or_null("PushArea") as Area2D


func _physics_process(_delta: float) -> void:
	if _area == null:
		return
	var direction := 1.0 if push_right else -1.0
	for body in _area.get_overlapping_bodies():
		if body is Player:
			(body as Player).external_velocity.x += push_speed * direction
