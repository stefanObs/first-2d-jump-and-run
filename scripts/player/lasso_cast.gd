class_name LassoCast
extends Area2D

## Short, animated rope throw that ties the first bandit it reaches.

const MAX_REACH := 190.0
const OUT_TIME := 0.18
const RETURN_TIME := 0.16

var _direction: float = 1.0
var _elapsed: float = 0.0
var _returning: bool = false
var _caught: bool = false
var _reach: float = 0.0
var _shape: CollisionShape2D


func setup(direction: float) -> void:
	_direction = 1.0 if direction >= 0.0 else -1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	_shape.shape = circle
	add_child(_shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _returning:
		var t := minf(_elapsed / RETURN_TIME, 1.0)
		_reach = lerpf(MAX_REACH if not _caught else _reach, 0.0, t)
		if t >= 1.0:
			queue_free()
			return
	else:
		var t := minf(_elapsed / OUT_TIME, 1.0)
		_reach = ease(t, -1.6) * MAX_REACH
		if t >= 1.0:
			_returning = true
			_elapsed = 0.0
	_update_shape()
	queue_redraw()


func _update_shape() -> void:
	if _shape != null:
		_shape.position = Vector2(_reach * _direction, 0.0)


func _draw() -> void:
	var end := Vector2(_reach * _direction, 0.0)
	var bend := Vector2(end.x * 0.5, -10.0 - sin(_reach * 0.06) * 6.0)
	draw_polyline(
		PackedVector2Array([Vector2.ZERO, bend, end]),
		Color(0.76, 0.48, 0.18, 1.0),
		3.5,
		true
	)
	var loop_radius := 10.0 + minf(_reach / MAX_REACH, 1.0) * 10.0
	draw_arc(
		end,
		loop_radius,
		0.0,
		TAU,
		28,
		Color(0.9, 0.66, 0.3, 1.0),
		4.0,
		true
	)
	draw_circle(end + Vector2(-4.0 * _direction, 0.0), 3.0, Color(0.45, 0.25, 0.08, 1.0))


func _on_body_entered(body: Node2D) -> void:
	if _caught or not (body is Opponent):
		return
	var opponent := body as Opponent
	if opponent.is_tied():
		return
	_caught = true
	monitoring = false
	opponent.tie_up()
	_returning = true
	_elapsed = 0.0
