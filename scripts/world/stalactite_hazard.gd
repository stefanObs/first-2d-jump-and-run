class_name StalactiteHazard
extends Area2D

## Ceiling spike that drops when the cowboy nears, then shatters on the floor.

signal hurt(player: Player)

const HANG_TEX := preload("res://assets/world/stalactite.png")
const IMPACT_TEX := preload("res://assets/world/stalactite_impact.png")
const TRIGGER_X := 150.0
const TRIGGER_Y := 420.0
const FALL_GRAVITY := 1600.0
const MAX_FALL := 900.0
const IMPACT_TIME := 0.55
const RESPAWN_TIME := 2.4

var _origin: Vector2
var _sprite: Sprite2D
var _state: String = "hanging"
var _vel_y: float = 0.0
var _timer: float = 0.0
var _wiggle: float = 0.0
var _floor_y: float = NAN


func _ready() -> void:
	_origin = global_position
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	_sprite.texture = HANG_TEX
	_sprite.centered = true
	_sprite.position = Vector2(0, 40)
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 70)
	shape.shape = rect
	shape.position = Vector2(0, 40)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	call_deferred("_probe_floor")
	set_physics_process(true)


func _probe_floor() -> void:
	var world := get_world_2d()
	if world == null:
		_floor_y = _origin.y + 280.0
		return
	var query := PhysicsRayQueryParameters2D.create(
		_origin + Vector2(0, 20),
		_origin + Vector2(0, MAX_FALL),
		1
	)
	query.collide_with_areas = false
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_floor_y = _origin.y + 280.0
	else:
		_floor_y = float(hit["position"].y)


func _physics_process(delta: float) -> void:
	match _state:
		"hanging":
			var player := _find_player()
			if player != null:
				var dx := absf(player.global_position.x - global_position.x)
				var dy := player.global_position.y - global_position.y
				if dx <= TRIGGER_X and dy > 0.0 and dy <= TRIGGER_Y:
					_state = "wiggle"
					_wiggle = 0.28
		"wiggle":
			_wiggle -= delta
			_sprite.rotation = sin(Time.get_ticks_msec() * 0.04) * 0.18
			if _wiggle <= 0.0:
				_state = "falling"
				_vel_y = 40.0
				_sprite.rotation = 0.0
		"falling":
			_vel_y += FALL_GRAVITY * delta
			global_position.y += _vel_y * delta
			var tip_y := global_position.y + 70.0
			if tip_y >= _floor_y:
				global_position.y = _floor_y - 36.0
				_state = "impact"
				_timer = IMPACT_TIME
				_sprite.texture = IMPACT_TEX
				_sprite.position = Vector2(0, 20)
				_sprite.modulate = Color.WHITE
		"impact":
			_timer -= delta
			_sprite.modulate.a = clampf(_timer / IMPACT_TIME, 0.0, 1.0)
			if _timer <= 0.0:
				_state = "gone"
				_timer = RESPAWN_TIME
				_sprite.visible = false
		"gone":
			_timer -= delta
			if _timer <= 0.0:
				_respawn()


func _respawn() -> void:
	global_position = _origin
	_vel_y = 0.0
	_state = "hanging"
	_sprite.visible = true
	_sprite.texture = HANG_TEX
	_sprite.position = Vector2(0, 40)
	_sprite.modulate = Color.WHITE
	_sprite.rotation = 0.0


func _on_body_entered(body: Node2D) -> void:
	if _state != "falling" and _state != "wiggle":
		return
	if body is Player:
		hurt.emit(body as Player)


func _find_player() -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Player:
			return node as Player
	return null
