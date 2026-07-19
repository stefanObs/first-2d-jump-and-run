class_name TiedBanditOverlay
extends Node2D

## Animated rope wraps and knot shown over a captured bandit.

var _progress: float = 0.0
var _phase: float = 0.0


func _process(delta: float) -> void:
	_progress = minf(_progress + delta * 4.5, 1.0)
	_phase += delta
	scale = Vector2.ONE * lerpf(1.25, 1.0, _progress)
	queue_redraw()


func _draw() -> void:
	var rope := Color(0.9, 0.65, 0.27, 1.0)
	var shadow := Color(0.42, 0.23, 0.07, 1.0)
	var width := 3.5
	for y in [-47.0, -39.0, -31.0, -18.0, -10.0]:
		var wobble := sin(_phase * 2.5 + y) * 1.2
		draw_arc(Vector2(wobble, y), 15.0, 0.05, PI - 0.05, 20, shadow, width + 2.0, true)
		draw_arc(Vector2(wobble, y), 15.0, 0.05, PI - 0.05, 20, rope, width, true)
		draw_arc(Vector2(wobble, y), 15.0, PI + 0.05, TAU - 0.05, 20, shadow, width + 2.0, true)
		draw_arc(Vector2(wobble, y), 15.0, PI + 0.05, TAU - 0.05, 20, rope, width, true)
	var knot := Vector2(17.0, -31.0)
	draw_circle(knot, 5.5, shadow)
	draw_circle(knot, 4.0, rope)
	draw_line(knot + Vector2(2, 3), knot + Vector2(11, 13), shadow, 5.0, true)
	draw_line(knot + Vector2(2, 3), knot + Vector2(11, 13), rope, 3.0, true)
	draw_line(knot + Vector2(-1, 4), knot + Vector2(-6, 16), shadow, 5.0, true)
	draw_line(knot + Vector2(-1, 4), knot + Vector2(-6, 16), rope, 3.0, true)
