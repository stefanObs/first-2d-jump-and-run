class_name StalactiteHazard
extends Area2D

## Ceiling spike. Dropping ones wiggle free, fall, and shatter on the floor.
## Static ones stay part of the ceiling decoration.

signal hurt(player: Player)

const HANG_TEX := preload("res://assets/world/stalactite.png")
const STATIC_TEX := preload("res://assets/world/stalactite_static.png")
const IMPACT_TEX := preload("res://assets/world/stalactite_impact.png")
const TRIGGER_X := 150.0
const TRIGGER_Y := 420.0
const FALL_GRAVITY := 1600.0
const MAX_FALL := 900.0
const IMPACT_TIME := 0.55
const RESPAWN_TIME := 2.4
const RELEASE_TIME := 0.42

@export var drops: bool = true
## When true, hanging look matches ceiling rock until the release animation.
@export var fuse_with_ceiling: bool = false

var _origin: Vector2
var _sprite: Sprite2D
var _shape: CollisionShape2D
var _state: String = "hanging"
var _vel_y: float = 0.0
var _timer: float = 0.0
var _wiggle: float = 0.0
var _release: float = 0.0
var _floor_y: float = NAN
var _hang_h: float = 96.0
var _hang_w: float = 48.0
const FUSED_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const LIVE_MODULATE := Color(1.06, 1.02, 1.08, 1.0)


func _ready() -> void:
	_origin = global_position
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	# Hang art for dropping teeth; distinct (shorter) static frame when not dropping.
	var tex: Texture2D = HANG_TEX if drops else STATIC_TEX
	_hang_w = float(tex.get_width())
	_hang_h = float(tex.get_height())
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite2D"
	_sprite.texture = tex
	# Flat top of the texture attaches at local y=0 (ceiling joint).
	_sprite.centered = false
	_sprite.position = Vector2(-_hang_w * 0.5, 0.0)
	add_child(_sprite)
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(_hang_w * 0.55, _hang_h * 0.78)
	_shape.shape = rect
	# Body hangs below the ceiling joint.
	_shape.position = Vector2(0.0, _hang_h * 0.52)
	add_child(_shape)
	body_entered.connect(_on_body_entered)
	if drops:
		call_deferred("_probe_floor")
	else:
		# Decorative only — never hurt the cowboy.
		monitoring = false
	_apply_hang_look(true)
	set_physics_process(drops)


func _apply_hang_look(fused: bool) -> void:
	if _sprite == null:
		return
	# Static décor always reads as ceiling rock; dropping teeth stay fused until release.
	if fuse_with_ceiling and (fused or not drops):
		_sprite.modulate = FUSED_MODULATE
		_sprite.z_index = -1
	else:
		_sprite.modulate = LIVE_MODULATE
		_sprite.z_index = 0


func _probe_floor() -> void:
	_floor_y = FloorProbe.hit_y(
		self,
		_origin + Vector2(0, 20),
		_origin + Vector2(0, MAX_FALL),
		_origin.y + 280.0
	)


func _physics_process(delta: float) -> void:
	if not drops:
		return
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
			# Still fused while trembling; reveal as a separate tooth on release.
			_apply_hang_look(true)
			_sprite.rotation = sin(Time.get_ticks_msec() * 0.04) * 0.12
			_sprite.position.y = sin(Time.get_ticks_msec() * 0.05) * 1.2
			if _wiggle <= 0.0:
				_state = "releasing"
				_release = RELEASE_TIME
				_sprite.rotation = 0.0
				_apply_hang_look(false)
		"releasing":
			# Pull free from the ceiling rock before the drop.
			_release -= delta
			var t := 1.0 - clampf(_release / RELEASE_TIME, 0.0, 1.0)
			_apply_hang_look(false)
			_sprite.modulate = FUSED_MODULATE.lerp(LIVE_MODULATE, t)
			_sprite.position.y = t * 18.0
			_sprite.scale = Vector2(1.0 + t * 0.08, 1.0 - t * 0.12)
			_sprite.rotation = sin(t * TAU * 2.0) * 0.12
			if _release <= 0.0:
				_state = "falling"
				_vel_y = 80.0
				_sprite.scale = Vector2.ONE
				_sprite.modulate = LIVE_MODULATE
				_sprite.rotation = 0.0
				_sprite.position = Vector2(-_hang_w * 0.5, 0.0)
				_sprite.z_index = 0
		"falling":
			_vel_y += FALL_GRAVITY * delta
			global_position.y += _vel_y * delta
			var tip_y := global_position.y + _hang_h
			if tip_y >= _floor_y:
				global_position.y = _floor_y - _hang_h * 0.35
				_state = "impact"
				_timer = IMPACT_TIME
				_sprite.texture = IMPACT_TEX
				var iw := float(IMPACT_TEX.get_width())
				var ih := float(IMPACT_TEX.get_height())
				_sprite.centered = false
				_sprite.position = Vector2(-iw * 0.5, _hang_h - ih)
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
	_hang_w = float(HANG_TEX.get_width())
	_hang_h = float(HANG_TEX.get_height())
	_sprite.centered = false
	_sprite.position = Vector2(-_hang_w * 0.5, 0.0)
	_sprite.scale = Vector2.ONE
	_sprite.rotation = 0.0
	_apply_hang_look(true)


func _on_body_entered(body: Node2D) -> void:
	if not drops:
		return
	if _state != "falling" and _state != "wiggle" and _state != "releasing":
		return
	if body is Player:
		hurt.emit(body as Player)


func _find_player() -> Player:
	return PlayerLookup.find_in_tree(self)
