class_name CoachLantern
extends Area2D

## Glowing lantern toss that lands as a short-lived trail hazard.

signal hit_player(player: Player)

var _velocity: Vector2 = Vector2.ZERO
var _life: float = 0.0
var _grounded: bool = false
var _ground_y: float = 320.0


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
	body_entered.connect(_on_body_entered)
	z_index = 6
	queue_redraw()


func _physics_process(delta: float) -> void:
	_life += delta
	if not _grounded:
		_velocity.y += 780.0 * delta
		global_position += _velocity * delta
		if global_position.y >= _ground_y:
			global_position.y = _ground_y
			_velocity = Vector2.ZERO
			_grounded = true
			_life = 0.0
			# Wider puddle hitbox once on the ground.
			var shape := get_child(0) as CollisionShape2D
			if shape != null and shape.shape is CircleShape2D:
				(shape.shape as CircleShape2D).radius = 28.0
			queue_redraw()
		elif _life > 3.5:
			queue_free()
		else:
			queue_redraw()
		return
	if _life >= 3.2:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _grounded:
		var pulse := 0.55 + 0.25 * sin(_life * 8.0)
		draw_circle(Vector2.ZERO, 30.0, Color(1.0, 0.45, 0.08, 0.35 * pulse))
		draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.7, 0.15, 0.55))
		draw_circle(Vector2(0, -6), 8.0, Color(1.0, 0.9, 0.35, 0.9))
	else:
		# Hanging lantern in flight.
		draw_rect(Rect2(-7, -4, 14, 16), Color(0.75, 0.55, 0.15, 1.0))
		draw_rect(Rect2(-5, -2, 10, 10), Color(1.0, 0.85, 0.25, 0.95))
		draw_line(Vector2(0, -4), Vector2(0, -12), Color(0.35, 0.25, 0.1, 1.0), 2.0)
		draw_circle(Vector2(0, -2), 3.0, Color(1.0, 0.95, 0.6, 1.0))


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var p := body as Player
		if not p.is_invulnerable():
			hit_player.emit(p)
		if not _grounded:
			queue_free()
