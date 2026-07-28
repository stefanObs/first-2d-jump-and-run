class_name DragonFlameball
extends Area2D

## Slow glowing flame orb the cave dragon spits; kids have time to dodge.

signal hurt_player(player: Player)

const TEX := preload("res://assets/world/dragon_flameball.png")

var direction: Vector2 = Vector2(-1, 0.2)
var speed: float = 190.0
var _life: float = 0.0
var _sprite: Sprite2D


func setup(from: Vector2, toward: Vector2) -> void:
	global_position = from
	var delta := toward - from
	if delta.length() < 4.0:
		delta = Vector2(-1, 0.25)
	direction = delta.normalized()


func _ready() -> void:
	add_to_group("hostile_projectile")
	collision_layer = 0
	collision_mask = 3
	monitorable = false
	_sprite = Sprite2D.new()
	_sprite.texture = TEX
	_sprite.centered = true
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	direction.y = move_toward(direction.y, 0.55, delta * 0.35)
	_life += delta
	if _sprite != null:
		_sprite.rotation += delta * 6.0
	if _life >= 5.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		if not player.is_invulnerable():
			hurt_player.emit(player)
		queue_free()
		return
	queue_free()
