class_name DragonFlameball
extends Area2D

## Flame orb the cave dragon spits straight toward the cowboy (light home, no drop).

signal hurt_player(player: Player)

const TEX := preload("res://assets/world/dragon_flameball.png")

var direction: Vector2 = Vector2(-1, 0.2)
var speed: float = 220.0
var _life: float = 0.0
var _sprite: Sprite2D
var _target: WeakRef


func setup(from: Vector2, toward: Vector2, target: Player = null) -> void:
	global_position = from
	var delta := toward - from
	if delta.length() < 4.0:
		delta = Vector2(-1, 0.15)
	direction = delta.normalized()
	_target = weakref(target) if target != null else null


func _ready() -> void:
	add_to_group("hostile_projectile")
	collision_layer = 0
	# Player only — never collide with the dragon body / ground or shots vanish instantly.
	collision_mask = 2
	monitorable = false
	monitoring = false
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
	# Arm hit detection next frame so spawn at the mouth never self-hits.
	call_deferred("_arm_monitoring")


func _arm_monitoring() -> void:
	monitoring = true


func _physics_process(delta: float) -> void:
	var player := _resolve_target()
	if player != null:
		var desired := (player.global_position + Vector2(0, -24.0) - global_position).normalized()
		# Gentle steer so kids can still dodge, but always toward the cowboy.
		direction = direction.lerp(desired, clampf(delta * 2.4, 0.0, 1.0)).normalized()
	global_position += direction * speed * delta
	_life += delta
	if _sprite != null:
		_sprite.rotation = direction.angle()
	if _life >= 5.0:
		queue_free()


func _resolve_target() -> Player:
	if _target == null:
		return null
	var node: Variant = _target.get_ref()
	if node is Player and is_instance_valid(node):
		return node as Player
	return null


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		if not player.is_invulnerable():
			hurt_player.emit(player)
		queue_free()
