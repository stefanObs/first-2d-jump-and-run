class_name NinjaShuriken
extends Area2D

## Spinning throwing star aimed at a flying cowboy.

signal hurt_player(player: Player)

const TEX := preload("res://assets/world/ninja_shuriken.png")

var _velocity: Vector2 = Vector2.ZERO
var _life: float = 0.0
var _spin: float = 0.0
var _sprite: Sprite2D


func setup(target: Vector2, from: Vector2, speed: float = 260.0) -> void:
	var delta := target - from
	if delta.length_squared() < 1.0:
		delta = Vector2.RIGHT
	_velocity = delta.normalized() * speed


func _ready() -> void:
	add_to_group("hostile_projectile")
	collision_layer = 0
	collision_mask = 3
	monitorable = false
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	shape_node.shape = shape
	add_child(shape_node)
	_sprite = Sprite2D.new()
	_sprite.name = "StarSprite"
	_sprite.texture = TEX
	_sprite.centered = true
	var tex_h := float(TEX.get_height()) if TEX != null else 28.0
	var scale := 1.0 if tex_h <= 0.0 else 1.0
	_sprite.scale = Vector2(scale, scale)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += _velocity * delta
	_spin += delta * 16.0
	if _sprite != null:
		_sprite.rotation = _spin
	_life += delta
	if _life >= 4.5:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_tied") and body.has_method("tie_up"):
		return
	if HostileHit.try_hurt_player(self, body):
		queue_free()
		return
	queue_free()
