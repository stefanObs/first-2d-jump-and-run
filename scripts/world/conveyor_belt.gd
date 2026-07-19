class_name ConveyorBelt
extends StaticBody2D

signal first_ride

@export var push_speed: float = 95.0
@export var push_right: bool = true

var _area: Area2D
var _visual: Node2D
var _scroll: float = 0.0
var _taught: bool = false


func _ready() -> void:
	_area = get_node_or_null("PushArea") as Area2D
	_visual = get_node_or_null("Visual") as Node2D
	var arrow := get_node_or_null("Arrow") as Label
	if arrow != null:
		arrow.text = ">>>" if push_right else "<<<"


func _process(delta: float) -> void:
	if _visual == null:
		return
	var direction := 1.0 if push_right else -1.0
	_scroll = fmod(_scroll + delta * 2.4 * direction, TAU)
	_visual.position.x = sin(_scroll) * 3.0


func _physics_process(_delta: float) -> void:
	if _area == null:
		return
	var direction := 1.0 if push_right else -1.0
	for body in _area.get_overlapping_bodies():
		if body is Player:
			(body as Player).external_velocity.x += push_speed * direction
			if not _taught:
				_taught = true
				first_ride.emit()
