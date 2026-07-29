class_name BanditBullet
extends Area2D

## Slow, bright cartoon bullet that gives children time to react.
## Cave skeletons fire arrows; optional aim_dir supports upward shots at flyers.

signal hurt_player(player: Player)

var direction: float = 1.0
var speed: float = 145.0
var _life: float = 0.0
var _as_arrow: bool = false
var _arrow_sprite: Sprite2D
var _aim: Vector2 = Vector2.RIGHT


func setup(facing: float, as_arrow: bool = false, aim_dir: Vector2 = Vector2.ZERO) -> void:
	direction = 1.0 if facing >= 0.0 else -1.0
	_as_arrow = as_arrow
	if aim_dir.length_squared() > 0.01:
		_aim = aim_dir.normalized()
		direction = 1.0 if _aim.x >= 0.0 else -1.0
	else:
		_aim = Vector2(direction, 0.0)


func _ready() -> void:
	add_to_group("hostile_projectile")
	collision_layer = 0
	# world | player: stop on boards and hurt the cowboy.
	collision_mask = 3
	monitorable = false
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	var upward := _as_arrow and absf(_aim.y) > absf(_aim.x)
	if upward:
		shape.size = Vector2(10, 28)
	else:
		shape.size = Vector2(20, 12) if not _as_arrow else Vector2(28, 10)
	shape_node.shape = shape
	add_child(shape_node)
	if _as_arrow:
		_arrow_sprite = Sprite2D.new()
		_arrow_sprite.texture = load("res://assets/world/skeleton_arrow.png")
		_arrow_sprite.centered = true
		# Texture points right; rotate to match aim (no flip when angled).
		_arrow_sprite.rotation = _aim.angle()
		add_child(_arrow_sprite)
	body_entered.connect(_on_body_entered)
	if not _as_arrow:
		queue_redraw()


func _physics_process(delta: float) -> void:
	position += _aim * speed * delta
	_life += delta
	if _life >= 4.0:
		queue_free()


func _draw() -> void:
	if _as_arrow:
		return
	var tail := Vector2(-18.0 * direction, 0)
	draw_line(tail, Vector2.ZERO, Color(1.0, 0.45, 0.08, 0.7), 7.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color(0.45, 0.16, 0.03, 1.0))
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.88, 0.18, 1.0))
	draw_circle(Vector2(2.0 * direction, -2.0), 1.8, Color.WHITE)


func _on_body_entered(body: Node2D) -> void:
	# Pass through other bandits so a shot is not cancelled by its shooter.
	if body is Opponent:
		return
	if HostileHit.try_hurt_player(self, body):
		queue_free()
		return
	# Hit desert boards / platforms before the shot travels forever.
	queue_free()
