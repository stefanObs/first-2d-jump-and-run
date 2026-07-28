class_name DragonFlameball
extends Area2D

## Flame orb the cave dragon spits in a straight line toward the cowboy.
## Hits the cowboy or dies in a puff when it reaches the arena floor.


signal hurt_player(player: Player)

const TEX := preload("res://assets/world/dragon_flameball.png")
const BALL_RADIUS := 14.0

var direction: Vector2 = Vector2(-1, 0.2)
var speed: float = 220.0
var _life: float = 0.0
var _sprite: Sprite2D
var _floor_y: float = NAN
var _impacting: bool = false


func setup(from: Vector2, toward: Vector2, _target: Player = null) -> void:
	global_position = from
	var delta := toward - from
	if delta.length() < 4.0:
		delta = Vector2(-1, 0.15)
	direction = delta.normalized()


func _ready() -> void:
	add_to_group("hostile_projectile")
	collision_layer = 0
	# Player only — floor contact is handled with a ray probe, not world collision
	# (the dragon body shares the world layer and must never block its own spit).
	collision_mask = 0
	set_collision_mask_value(2, true)
	monitorable = false
	monitoring = false
	z_index = 6
	_sprite = Sprite2D.new()
	_sprite.texture = TEX
	_sprite.centered = true
	add_child(_sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BALL_RADIUS
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	set_physics_process(true)
	call_deferred("_arm_and_probe")


func _arm_and_probe() -> void:
	_floor_y = FloorProbe.hit_y(
		self,
		global_position,
		global_position + Vector2(0.0, 900.0),
		global_position.y + 360.0
	)
	monitoring = true


func _physics_process(delta: float) -> void:
	if _impacting:
		return
	var step := direction * speed * delta
	var next := global_position + step
	if not is_nan(_floor_y):
		var tip_y := next.y + BALL_RADIUS * 0.65
		if tip_y >= _floor_y:
			# Stop on the crust — never tunnel through the floor.
			var t := 1.0
			if absf(step.y) > 0.001:
				t = clampf((_floor_y - BALL_RADIUS * 0.65 - global_position.y) / step.y, 0.0, 1.0)
			global_position = global_position + step * t
			global_position.y = minf(global_position.y, _floor_y - BALL_RADIUS * 0.65)
			_impact_floor()
			return
	global_position = next
	_life += delta
	if _sprite != null:
		_sprite.rotation = direction.angle()
	if _life >= 5.0:
		queue_free()


func _impact_floor() -> void:
	if _impacting:
		return
	_impacting = true
	monitoring = false
	set_physics_process(false)
	if _sprite == null:
		queue_free()
		return
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.55, 0.45), 0.1)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)


func _on_body_entered(body: Node2D) -> void:
	if _impacting:
		return
	if HostileHit.try_hurt_player(self, body):
		queue_free()
