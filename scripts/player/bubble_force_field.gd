class_name BubbleForceField
extends Node2D

## Layered, animated blue force field surrounding the cowboy.

var _phase: float = 0.0


func _process(delta: float) -> void:
	_phase += delta
	rotation = sin(_phase * 1.7) * 0.025
	queue_redraw()


func _draw() -> void:
	var pulse := 1.0 + sin(_phase * 3.2) * 0.035
	var radius := 43.0 * pulse
	draw_circle(Vector2.ZERO, radius, Color(0.15, 0.65, 1.0, 0.16))
	draw_circle(Vector2.ZERO, radius - 3.0, Color(0.25, 0.78, 1.0, 0.08))
	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		64,
		Color(0.45, 0.9, 1.0, 0.88),
		3.0,
		true
	)
	draw_arc(
		Vector2.ZERO,
		radius - 5.0,
		-2.7 + _phase * 0.5,
		-1.25 + _phase * 0.5,
		22,
		Color(0.85, 0.98, 1.0, 0.9),
		2.5,
		true
	)
	draw_arc(
		Vector2.ZERO,
		radius - 7.0,
		0.25 + _phase * 0.35,
		1.0 + _phase * 0.35,
		18,
		Color(0.2, 0.7, 1.0, 0.72),
		2.0,
		true
	)
	for index in range(4):
		var angle := _phase * (0.7 + index * 0.08) + index * TAU / 4.0
		var point := Vector2(cos(angle), sin(angle)) * (radius + 3.0)
		draw_circle(point, 2.3, Color(0.75, 0.96, 1.0, 0.9))
