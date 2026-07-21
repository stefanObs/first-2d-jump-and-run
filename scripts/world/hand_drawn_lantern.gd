class_name HandDrawnLantern
extends Node2D

## Small, irregular western lantern drawn in the same outlined palette as the ranch art.

const INK := Color(0.16, 0.09, 0.045, 1.0)
const METAL := Color(0.30, 0.19, 0.11, 1.0)
const METAL_LIT := Color(0.53, 0.34, 0.16, 1.0)
const WARM_CORE := Color(1.0, 0.86, 0.42, 1.0)

var glow_color := Color(0.92, 0.27, 0.10, 1.0)
var glow_strength: float = 1.0


func _ready() -> void:
	queue_redraw()


func set_glow(color: Color, strength: float = 1.0) -> void:
	glow_color = color
	glow_strength = clampf(strength, 0.35, 1.25)
	queue_redraw()


func _draw() -> void:
	# Crooked hook and short chain visibly fasten the lantern to the gate rail.
	draw_arc(Vector2(0, 1), 5.0, PI, TAU, 10, INK, 2.4, true)
	draw_line(Vector2(-5, 1), Vector2(-5, 5), INK, 2.4, true)
	draw_line(Vector2(0, 5), Vector2(1, 11), INK, 2.2, true)
	draw_circle(Vector2(0, 7), 1.7, METAL_LIT)

	# Soft, borderless glow stays behind the opaque hand-inked frame.
	var halo := Color(glow_color.r, glow_color.g, glow_color.b, 0.10 * glow_strength)
	var inner_halo := Color(glow_color.r, glow_color.g, glow_color.b, 0.18 * glow_strength)
	draw_circle(Vector2(0, 24), 15.5, halo)
	draw_circle(Vector2(0, 24), 11.5, inner_halo)

	var glass := PackedVector2Array([
		Vector2(-6.5, 16), Vector2(5.5, 15),
		Vector2(8.0, 29), Vector2(-7.0, 30),
	])
	var glass_color := Color(
		lerpf(glow_color.r, WARM_CORE.r, 0.22),
		lerpf(glow_color.g, WARM_CORE.g, 0.22),
		lerpf(glow_color.b, WARM_CORE.b, 0.16),
		0.94
	)
	draw_colored_polygon(glass, glass_color)
	draw_polyline(
		PackedVector2Array([glass[0], glass[1], glass[2], glass[3], glass[0]]),
		INK,
		2.6,
		true
	)

	# Uneven cap, feet and side braces give it a handmade silhouette.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-7.5, 15.5), Vector2(-4.5, 11.5),
			Vector2(4.0, 11), Vector2(7.0, 15),
		]),
		METAL
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(-7.5, 15.5), Vector2(-4.5, 11.5),
			Vector2(4.0, 11), Vector2(7.0, 15),
		]),
		INK,
		2.3,
		true
	)
	draw_line(Vector2(-6.5, 17), Vector2(-4.8, 29), METAL, 2.2, true)
	draw_line(Vector2(5.5, 16), Vector2(6.0, 29), METAL, 2.2, true)
	draw_line(Vector2(-8, 30), Vector2(8.5, 29), INK, 3.0, true)
	draw_line(Vector2(-5.5, 32), Vector2(5.5, 31.5), METAL_LIT, 2.4, true)

	# A warm painted flame remains visible through every gameplay state color.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-2.4, 27), Vector2(-1.0, 20),
			Vector2(1.0, 17.5), Vector2(3.0, 23),
			Vector2(1.6, 27.5),
		]),
		Color(WARM_CORE.r, WARM_CORE.g, WARM_CORE.b, 0.88)
	)
	draw_line(Vector2(-2.8, 20), Vector2(3.8, 19), Color(1, 0.94, 0.64, 0.55), 1.3, true)
