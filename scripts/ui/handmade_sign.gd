class_name HandmadeSign
extends Control

## Uneven western wood sign board — replaces flat cream HUD rectangles.

const INK := Color(0.28, 0.12, 0.04, 1.0)
const WOOD := Color(0.82, 0.55, 0.28, 0.94)
const WOOD_DARK := Color(0.55, 0.30, 0.12, 0.95)
const WOOD_LIGHT := Color(0.95, 0.78, 0.48, 0.55)

@export var board_inset: float = 4.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 8.0 or h < 8.0:
		return
	var i := board_inset
	# Irregular six-point board so it never reads as a UI card.
	var board := PackedVector2Array([
		Vector2(i + 2.0, i + 5.0),
		Vector2(w - i - 1.0, i + 2.0),
		Vector2(w - i + 1.0, h * 0.42),
		Vector2(w - i - 3.0, h - i - 1.0),
		Vector2(i + 6.0, h - i + 1.0),
		Vector2(i - 1.0, h * 0.55),
	])
	draw_colored_polygon(board, WOOD)
	draw_polyline(
		PackedVector2Array([board[0], board[1], board[2], board[3], board[4], board[5], board[0]]),
		INK,
		3.5,
		true
	)
	# Left nail strip (warm western accent instead of a flat edge bar).
	draw_line(Vector2(i + 10.0, i + 8.0), Vector2(i + 8.0, h - i - 6.0), WOOD_DARK, 7.0, true)
	draw_line(Vector2(i + 18.0, i + 10.0), Vector2(w - i - 14.0, i + 7.0), WOOD_LIGHT, 2.0, true)
	draw_line(Vector2(i + 16.0, h - i - 8.0), Vector2(w - i - 12.0, h - i - 5.0), Color(0.35, 0.14, 0.04, 0.28), 2.0, true)
	draw_circle(Vector2(i + 10.0, i + 12.0), 3.0, INK)
	draw_circle(Vector2(i + 9.0, h - i - 10.0), 3.0, INK)
