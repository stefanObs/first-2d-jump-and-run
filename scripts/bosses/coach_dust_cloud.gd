class_name CoachDustCloud
extends Area2D

## Speed-burst dust that shoves the cowboy and briefly soft-fails on contact.

signal hit_player(player: Player)

var _life: float = 0.0
var _max_life: float = 1.1
var _push_dir: float = 1.0


func setup(facing: float, lifetime: float = 1.1) -> void:
	_push_dir = 1.0 if facing >= 0.0 else -1.0
	_max_life = lifetime


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(120, 70)
	shape.shape = rect
	shape.position = Vector2(0, -20)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	z_index = 3
	queue_redraw()


func _physics_process(delta: float) -> void:
	_life += delta
	modulate.a = clampf(1.0 - _life / _max_life, 0.0, 1.0)
	if _life >= _max_life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _life * 10.0
	for i in range(5):
		var ox := float(i - 2) * 18.0 + sin(t + i) * 6.0
		var oy := -10.0 - float(i % 3) * 8.0 + cos(t * 0.7 + i) * 4.0
		var r := 16.0 + float(i) * 3.0
		draw_circle(Vector2(ox, oy), r, Color(0.75, 0.62, 0.4, 0.28))
		draw_circle(Vector2(ox + 6.0 * _push_dir, oy - 4.0), r * 0.6, Color(0.85, 0.72, 0.48, 0.22))


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var p := body as Player
		if p.is_invulnerable():
			return
		# Shove first; arena decides soft-fail.
		p.velocity.x = _push_dir * 380.0
		p.velocity.y = minf(p.velocity.y, -180.0)
		hit_player.emit(p)
