class_name DragonFlameball
extends Area2D

## Flame orb the cave dragon spits in a straight line toward the cowboy.


signal hurt_player(player: Player)

const TEX := preload("res://assets/world/dragon_flameball.png")

var direction: Vector2 = Vector2(-1, 0.2)
var speed: float = 220.0
var _life: float = 0.0
var _sprite: Sprite2D


func setup(from: Vector2, toward: Vector2, _target: Player = null) -> void:
	global_position = from
	var delta := toward - from
	if delta.length() < 4.0:
		delta = Vector2(-1, 0.15)
	direction = delta.normalized()


func _ready() -> void:
	add_to_group("hostile_projectile")
	collision_layer = 0
	# Player only — floor/world must not stop the shot (dragon body shares world layer).
	collision_mask = 0
	set_collision_mask_value(2, true)
	monitorable = false
	monitoring = false
	# Draw above TrailFloor so shots stay visible while they pass through the crust.
	z_index = 6
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
	global_position += direction * speed * delta
	_life += delta
	if _sprite != null:
		_sprite.rotation = direction.angle()
	if _life >= 5.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if HostileHit.try_hurt_player(self, body):
		queue_free()
