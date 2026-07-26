class_name TreasureChestArt
extends Node2D

## Hand-painted western treasure chest (procedural) with an opening lid.

const WOOD := Color(0.62, 0.38, 0.18, 1.0)
const WOOD_DARK := Color(0.42, 0.22, 0.1, 1.0)
const WOOD_LIGHT := Color(0.78, 0.52, 0.28, 1.0)
const METAL := Color(0.72, 0.58, 0.22, 1.0)
const METAL_DARK := Color(0.45, 0.34, 0.12, 1.0)
const INK := Color(0.22, 0.1, 0.04, 1.0)
const GLOW := Color(1.0, 0.82, 0.18, 0.55)

var open_amount: float = 0.0
var sparkle_phase: float = 0.0


func set_open_amount(value: float) -> void:
	open_amount = clampf(value, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	if open_amount < 0.05:
		sparkle_phase += delta * 3.4
		queue_redraw()


func _draw() -> void:
	var body_w := 54.0
	var body_h := 30.0
	var body_top := -8.0
	var body_left := -body_w * 0.5

	# Soft glow while closed.
	if open_amount < 0.08:
		var pulse := 0.65 + sin(sparkle_phase) * 0.2
		draw_circle(Vector2(0.0, -18.0), 28.0, Color(GLOW.r, GLOW.g, GLOW.b, GLOW.a * pulse))

	# Base shadow.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(body_left - 4.0, body_top + body_h + 2.0),
			Vector2(body_left + body_w + 4.0, body_top + body_h + 2.0),
			Vector2(body_left + body_w + 8.0, body_top + body_h + 8.0),
			Vector2(body_left - 8.0, body_top + body_h + 8.0),
		]),
		Color(0.0, 0.0, 0.0, 0.18)
	)

	# Chest body.
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(body_left, body_top + 4.0),
			Vector2(body_left + body_w, body_top + 2.0),
			Vector2(body_left + body_w - 2.0, body_top + body_h),
			Vector2(body_left + 3.0, body_top + body_h + 1.0),
		]),
		WOOD
	)
	draw_line(
		Vector2(body_left + 8.0, body_top + 8.0),
		Vector2(body_left + body_w - 10.0, body_top + 6.0),
		WOOD_LIGHT,
		2.0,
		true
	)
	draw_line(
		Vector2(body_left + 6.0, body_top + body_h - 4.0),
		Vector2(body_left + body_w - 8.0, body_top + body_h - 3.0),
		WOOD_DARK,
		2.0,
		true
	)

	# Metal bands on the body.
	for band_x in [body_left + 10.0, body_left + body_w * 0.5, body_left + body_w - 14.0]:
		draw_line(
			Vector2(band_x, body_top + 3.0),
			Vector2(band_x + (1.0 if band_x < 0.0 else -1.0), body_top + body_h),
			METAL_DARK,
			4.0,
			true
		)
		draw_line(
			Vector2(band_x, body_top + 4.0),
			Vector2(band_x + (1.0 if band_x < 0.0 else -1.0), body_top + body_h - 1.0),
			METAL,
			2.0,
			true
		)

	# Lock plate.
	draw_rect(Rect2(-7.0, body_top + 10.0, 14.0, 16.0), METAL_DARK, true)
	draw_rect(Rect2(-5.0, body_top + 12.0, 10.0, 12.0), METAL, true)
	draw_arc(Vector2(0.0, body_top + 18.0), 3.0, 0.0, TAU, 12, INK, 2.0, true)

	# Lid pivots from the back edge.
	var hinge := Vector2(body_left + 4.0, body_top + 2.0)
	var lid_angle := lerpf(0.0, -1.35, open_amount)
	var lid_points := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(body_w - 6.0, -2.0),
		Vector2(body_w - 4.0, -16.0),
		Vector2(4.0, -14.0),
	])
	var transformed: PackedVector2Array = []
	for point in lid_points:
		transformed.append(hinge + point.rotated(lid_angle))
	draw_colored_polygon(transformed, WOOD_DARK)
	draw_polyline(transformed, INK, 2.0, true)
	draw_line(
		transformed[1] + (transformed[2] - transformed[1]) * 0.35,
		transformed[0] + (transformed[3] - transformed[0]) * 0.35,
		WOOD_LIGHT,
		2.0,
		true
	)

	# Inner treasure glint when opening.
	if open_amount > 0.12:
		var inner_alpha := clampf((open_amount - 0.12) / 0.88, 0.0, 1.0)
		draw_rect(
			Rect2(body_left + 8.0, body_top + 6.0, body_w - 16.0, 12.0),
			Color(1.0, 0.88, 0.35, 0.55 * inner_alpha),
			true
		)
		for sparkle_index in range(3):
			var sx := body_left + 14.0 + sparkle_index * 14.0
			draw_circle(
				Vector2(sx, body_top + 10.0),
				2.0 + sparkle_index * 0.4,
				Color(1.0, 0.95, 0.55, inner_alpha)
			)
