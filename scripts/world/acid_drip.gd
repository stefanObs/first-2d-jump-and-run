class_name AcidDrip
extends Area2D

## Pink mineral drops from the cave ceiling. Hitting the player sends them to camp.
## Bubble Shield does not block these (same idea as canyon/pit falls).

signal hurt(player: Player)

const DRIP_TEX := preload("res://assets/world/acid_drip.png")
const FALL_SPEED := 220.0
const RESPAWN_DELAY := 1.35
const TELEGRAPH := 0.35

var _origin: Vector2
var _sprite: Sprite2D
var _state: String = "idle"
var _timer: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_origin = global_position
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	_sprite.texture = DRIP_TEX
	_sprite.centered = true
	_sprite.position = Vector2(0, 10)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var rect := CircleShape2D.new()
	rect.radius = 10.0
	shape.shape = rect
	shape.position = Vector2(0, 12)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	_timer = randf_range(0.4, 1.6)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	_phase += delta
	_timer -= delta
	match _state:
		"idle":
			_sprite.modulate = Color(1.0, 0.85 + sin(_phase * 6.0) * 0.15, 0.95, 0.55)
			_sprite.position.y = 8.0 + sin(_phase * 3.0) * 2.0
			if _timer <= 0.0:
				_state = "telegraph"
				_timer = TELEGRAPH
		"telegraph":
			_sprite.modulate = Color(1.15, 0.55, 0.9, 1.0)
			_sprite.scale = Vector2.ONE * (1.0 + sin(_phase * 18.0) * 0.12)
			if _timer <= 0.0:
				_state = "falling"
				_sprite.scale = Vector2.ONE
				_sprite.modulate = Color.WHITE
		"falling":
			global_position.y += FALL_SPEED * delta
			_sprite.rotation = sin(_phase * 10.0) * 0.15
			if global_position.y >= _origin.y + 520.0:
				_reset_drop()
		"cooldown":
			_sprite.visible = false
			if _timer <= 0.0:
				_reset_drop()


func _reset_drop() -> void:
	global_position = _origin
	_state = "idle"
	_timer = RESPAWN_DELAY + randf_range(0.0, 0.8)
	_sprite.visible = true
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE
	_sprite.modulate = Color(1, 1, 1, 0.55)


func _on_body_entered(body: Node2D) -> void:
	if _state != "falling":
		return
	if body is Player:
		hurt.emit(body as Player)
		_state = "cooldown"
		_timer = RESPAWN_DELAY
		_sprite.visible = false
