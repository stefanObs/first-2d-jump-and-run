class_name Carrion
extends Area2D

## A slow flying obstacle used in Wings sections.

signal hurt_player(player: Player)

@export var patrol_width: float = 150.0
@export var move_speed: float = 52.0
@export var bob_height: float = 18.0

var _origin: Vector2
var _direction: float = 1.0
var _phase: float = 0.0
var _sprite: Sprite2D
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_origin = global_position
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null:
		_base_scale = _sprite.scale
	body_entered.connect(_on_body_entered)
	_apply_facing()


func _physics_process(delta: float) -> void:
	_phase += delta * 2.2
	var next_x := global_position.x + _direction * move_speed * delta
	if next_x >= _origin.x + patrol_width:
		next_x = _origin.x + patrol_width
		_direction = -1.0
		_apply_facing()
	elif next_x <= _origin.x - patrol_width:
		next_x = _origin.x - patrol_width
		_direction = 1.0
		_apply_facing()
	var next_position := Vector2(next_x, _origin.y + sin(_phase) * bob_height)
	if _would_hit_solid(next_position):
		_direction *= -1.0
		_apply_facing()
	else:
		global_position = next_position
	if _sprite != null:
		var flap := 1.0 + sin(_phase * 2.0) * 0.06
		_sprite.scale = Vector2(_base_scale.x, _base_scale.y * flap)


func _apply_facing() -> void:
	if _sprite != null:
		# The painted bird faces right.
		_sprite.flip_h = _direction < 0.0


func _would_hit_solid(next_position: Vector2) -> bool:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null or get_world_2d() == null:
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape_node.shape
	query.transform = Transform2D(shape_node.global_rotation, next_position + shape_node.position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var player := body as Player
	if player.is_invulnerable():
		return
	hurt_player.emit(player)
