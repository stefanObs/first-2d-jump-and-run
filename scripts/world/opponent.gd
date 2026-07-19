class_name Opponent
extends AnimatableBody2D

## Slow predictable foe. Touching it hurts unless the player has a shield.

signal hurt_player(player: Player)

@export var point_a: Vector2 = Vector2(-80, 0)
@export var point_b: Vector2 = Vector2(80, 0)
@export var move_speed: float = 45.0
@export var vertical_patrol: bool = false

var _origin: Vector2
var _going_to_b: bool = true
var _area: Area2D


func _ready() -> void:
	_origin = global_position
	_area = get_node_or_null("HurtArea") as Area2D
	if _area != null:
		_area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var target := _origin + (point_b if _going_to_b else point_a)
	global_position = global_position.move_toward(target, move_speed * delta)
	if global_position.distance_to(target) < 2.0:
		_going_to_b = not _going_to_b


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		if player.is_invulnerable():
			return
		hurt_player.emit(player)
