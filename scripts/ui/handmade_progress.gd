class_name HandmadeProgress
extends Control

## A deliberately uneven, hand-painted trail sign used instead of a flat UI bar.

const INK := Color(0.30, 0.13, 0.035, 1.0)
const WOOD := Color(0.78, 0.47, 0.19, 0.96)
const WOOD_LIGHT := Color(0.95, 0.72, 0.34, 0.96)
const TRAIL := Color(0.98, 0.80, 0.28, 1.0)

var ratio: float = 0.0
var camp_ratios: Array[float] = []


func _ready() -> void:
	custom_minimum_size = Vector2(340, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_progress(value: float) -> void:
	ratio = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_camps(values: Array) -> void:
	camp_ratios.clear()
	for value in values:
		camp_ratios.append(clampf(float(value), 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	var board := PackedVector2Array([
		Vector2(4, 7), Vector2(333, 3), Vector2(338, 52),
		Vector2(326, 58), Vector2(8, 55), Vector2(1, 45),
	])
	draw_colored_polygon(board, WOOD)
	draw_polyline(PackedVector2Array([board[0], board[1], board[2], board[3], board[4], board[5], board[0]]), INK, 4.0, true)
	draw_line(Vector2(13, 16), Vector2(325, 13), Color(1, 0.78, 0.4, 0.38), 2.0)
	draw_line(Vector2(17, 47), Vector2(321, 49), Color(0.35, 0.14, 0.03, 0.26), 2.0)

	var start := Vector2(20, 32)
	var finish := Vector2(318, 32)
	draw_line(start, finish, INK, 11.0, true)
	draw_line(start, finish, WOOD_LIGHT, 6.0, true)
	draw_line(start, start.lerp(finish, ratio), TRAIL, 7.0, true)
	for camp in camp_ratios:
		var x := lerpf(start.x, finish.x, camp)
		draw_line(Vector2(x - 4, 25), Vector2(x - 4, 40), INK, 3.0, true)
		draw_line(Vector2(x + 4, 25), Vector2(x + 4, 40), INK, 3.0, true)
		draw_line(Vector2(x - 7, 26), Vector2(x + 7, 26), INK, 3.0, true)

	var marker := start.lerp(finish, ratio)
	draw_circle(marker, 9.0, INK)
	draw_circle(marker + Vector2(-1, -1), 6.0, Color(0.88, 0.25, 0.10, 1.0))
	draw_string(
		get_theme_default_font(),
		Vector2(122, 23),
		tr("TRAIL %d%%") % int(round(ratio * 100.0)),
		HORIZONTAL_ALIGNMENT_CENTER,
		96,
		14,
		INK
	)
