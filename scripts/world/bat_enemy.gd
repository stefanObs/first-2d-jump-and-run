class_name BatEnemy
extends Area2D

## Cave bat that flies a smooth curve and hurts on touch (Bubble can block).

signal hurt_player(player: Player)

const TEX_0 := preload("res://assets/world/cave_bat_0.png")
const TEX_1 := preload("res://assets/world/cave_bat_1.png")

@export var patrol_width: float = 180.0
@export var move_speed: float = 70.0
@export var curve_height: float = 48.0

var _origin: Vector2
var _phase: float = 0.0
var _sprite: AnimatedSprite2D
var _dir: float = 1.0


func _ready() -> void:
	_origin = global_position
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "FlapSprite"
	var frames := SpriteFrames.new()
	frames.add_animation(&"flap")
	frames.set_animation_speed(&"flap", 10.0)
	frames.set_animation_loop(&"flap", true)
	frames.add_frame(&"flap", TEX_0)
	frames.add_frame(&"flap", TEX_1)
	_sprite.sprite_frames = frames
	_sprite.centered = true
	_sprite.scale = Vector2(0.85, 0.85)
	_sprite.play(&"flap")
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 16.0
	capsule.height = 48.0
	shape.shape = capsule
	shape.rotation = PI * 0.5
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_phase = randf() * TAU
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_phase += delta * 1.7
	var x := _origin.x + sin(_phase) * patrol_width
	var y := _origin.y + sin(_phase * 2.0) * curve_height * 0.35 + cos(_phase) * curve_height * 0.65
	var next := Vector2(x, y)
	var dx := next.x - global_position.x
	if absf(dx) > 0.2:
		_dir = 1.0 if dx > 0.0 else -1.0
		_sprite.flip_h = _dir < 0.0
	global_position = next


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var player := body as Player
	if player.is_invulnerable():
		return
	if player.get_modes().has_shield():
		player.bounce_from_hazard(global_position)
		return
	hurt_player.emit(player)
