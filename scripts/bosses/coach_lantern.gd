class_name CoachLantern
extends Area2D

## Glowing hand-drawn lantern toss that lands as a short-lived trail hazard.

signal hit_player(player: Player)

const FLY_0 := preload("res://assets/world/lantern_fly_0.png")
const FLY_1 := preload("res://assets/world/lantern_fly_1.png")
const GROUND := preload("res://assets/world/lantern_ground.png")

var _velocity: Vector2 = Vector2.ZERO
var _life: float = 0.0
var _grounded: bool = false
var _ground_y: float = 320.0
var _sprite: Sprite2D
var _glow: Sprite2D
var _anim_t: float = 0.0


func setup(from: Vector2, toward_x: float, ground_y: float) -> void:
	global_position = from
	_ground_y = ground_y
	var dx := toward_x - from.x
	_velocity = Vector2(clampf(dx * 0.9, -220.0, 220.0), -320.0)


func _ready() -> void:
	add_to_group("hostile_projectile")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	add_child(shape)
	_glow = Sprite2D.new()
	_glow.z_index = -1
	_glow.modulate = Color(1.0, 0.7, 0.2, 0.45)
	_glow.scale = Vector2(1.4, 1.4)
	add_child(_glow)
	_sprite = Sprite2D.new()
	_sprite.texture = FLY_0
	_sprite.scale = Vector2(0.85, 0.85)
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	z_index = 6


func _physics_process(delta: float) -> void:
	_life += delta
	_anim_t += delta
	if not _grounded:
		_velocity.y += 780.0 * delta
		global_position += _velocity * delta
		if _sprite != null:
			_sprite.texture = FLY_0 if int(_anim_t * 8.0) % 2 == 0 else FLY_1
			_sprite.rotation = _velocity.x * 0.002 + sin(_anim_t * 10.0) * 0.25
			_sprite.scale = Vector2(0.85, 0.85)
		if _glow != null:
			_glow.texture = FLY_0
			_glow.modulate = Color(1.0, 0.75, 0.2, 0.35 + 0.15 * sin(_anim_t * 12.0))
			_glow.scale = Vector2(1.5, 1.5)
		if global_position.y >= _ground_y:
			global_position.y = _ground_y
			_velocity = Vector2.ZERO
			_grounded = true
			_life = 0.0
			_land()
		elif _life > 3.5:
			queue_free()
		return
	if _glow != null:
		var pulse := 0.4 + 0.2 * sin(_life * 9.0)
		_glow.modulate = Color(1.0, 0.55, 0.12, pulse)
		_glow.scale = Vector2(1.8 + sin(_life * 8.0) * 0.15, 1.5 + cos(_life * 7.0) * 0.1)
	if _life >= 3.2:
		var fade := create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.25)
		fade.tween_callback(queue_free)
		set_physics_process(false)


func _land() -> void:
	var shape := get_child(0) as CollisionShape2D
	if shape != null and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = 30.0
	if _sprite != null:
		_sprite.texture = GROUND
		_sprite.rotation = 0.0
		_sprite.scale = Vector2(0.95, 0.95)
		_sprite.position = Vector2(0, -8)
	if _glow != null:
		_glow.texture = GROUND
		_glow.position = Vector2(0, -4)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var p := body as Player
		if not p.is_invulnerable():
			hit_player.emit(p)
		if not _grounded:
			queue_free()
