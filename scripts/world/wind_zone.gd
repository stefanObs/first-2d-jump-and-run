class_name WindZone
extends Area2D

@export var wind_force: Vector2 = Vector2(180, 0)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			(body as Player).external_velocity += wind_force * _delta_safe()


func _delta_safe() -> float:
	return get_physics_process_delta_time()
