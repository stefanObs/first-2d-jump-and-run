class_name HandmadeSign
extends Control

## Uneven western wood sign board — replaces flat cream HUD rectangles.
## STANDARD matches trail HUD ink boards; SALOON adds weathered red-paint accents.

enum BoardStyle { STANDARD, SALOON }

const INK := Color(0.28, 0.12, 0.04, 1.0)
const WOOD := Color(0.82, 0.55, 0.28, 0.94)
const WOOD_DARK := Color(0.55, 0.30, 0.12, 0.95)
const WOOD_LIGHT := Color(0.95, 0.78, 0.48, 0.55)
const SALOON_WOOD := Color(0.78, 0.48, 0.22, 0.96)
const SALOON_WOOD_DEEP := Color(0.52, 0.28, 0.10, 0.95)
const SALOON_RED := Color(0.62, 0.18, 0.10, 0.88)
const SALOON_RED_CHIP := Color(0.72, 0.26, 0.12, 0.55)

@export var board_inset: float = 4.0
@export var board_style: BoardStyle = BoardStyle.STANDARD
## Optional painted board texture (e.g. saloon title plank). Drawn instead of the polygon fill.
@export var board_texture: Texture2D


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
	if board_texture != null:
		_draw_textured_board(w, h)
		return
	if board_style == BoardStyle.SALOON:
		_draw_saloon_board(w, h)
	else:
		_draw_standard_board(w, h)


func _draw_textured_board(w: float, h: float) -> void:
	draw_texture_rect(board_texture, Rect2(0.0, 0.0, w, h), false)


func _draw_standard_board(w: float, h: float) -> void:
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


func _draw_saloon_board(w: float, h: float) -> void:
	var i := board_inset
	# Arched saloon silhouette — soft painted plank board with peeling red rim.
	var board := PackedVector2Array([
		Vector2(i + 8.0, i + 10.0),
		Vector2(w * 0.28, i + 2.0),
		Vector2(w * 0.50, i - 1.0),
		Vector2(w * 0.72, i + 2.0),
		Vector2(w - i - 6.0, i + 9.0),
		Vector2(w - i + 1.0, h * 0.48),
		Vector2(w - i - 8.0, h - i - 6.0),
		Vector2(w * 0.70, h - i + 1.0),
		Vector2(w * 0.50, h - i + 3.0),
		Vector2(w * 0.30, h - i + 1.0),
		Vector2(i + 10.0, h - i - 5.0),
		Vector2(i - 1.0, h * 0.52),
	])
	draw_colored_polygon(board, SALOON_WOOD)
	# Soft plank seams.
	for t in [0.28, 0.48, 0.68]:
		var y := lerpf(i + 8.0, h - i - 8.0, t)
		draw_line(Vector2(i + 16.0, y), Vector2(w - i - 16.0, y + 1.0), SALOON_WOOD_DEEP, 1.6, true)
	# Peeling red paint accents along the rim (not a solid fill).
	_draw_peeling_red_rim(w, h, i)
	draw_polyline(
		PackedVector2Array([
			board[0], board[1], board[2], board[3], board[4], board[5],
			board[6], board[7], board[8], board[9], board[10], board[11], board[0],
		]),
		INK,
		3.8,
		true
	)
	# Corner nails.
	for p in [
		Vector2(i + 14.0, i + 14.0),
		Vector2(w - i - 14.0, i + 14.0),
		Vector2(i + 14.0, h - i - 14.0),
		Vector2(w - i - 14.0, h - i - 14.0),
	]:
		draw_circle(p, 3.4, INK)
		draw_circle(p + Vector2(-0.8, -0.8), 1.2, WOOD_LIGHT)


func _draw_peeling_red_rim(w: float, h: float, i: float) -> void:
	var patches := [
		Rect2(i + 4.0, i + 4.0, w * 0.22, 10.0),
		Rect2(w * 0.55, i + 3.0, w * 0.28, 9.0),
		Rect2(i + 3.0, h - i - 14.0, w * 0.26, 10.0),
		Rect2(w * 0.52, h - i - 13.0, w * 0.30, 9.0),
		Rect2(i + 3.0, h * 0.30, 9.0, h * 0.34),
		Rect2(w - i - 12.0, h * 0.28, 9.0, h * 0.36),
	]
	for rect in patches:
		draw_rect(rect, SALOON_RED, true)
	# Chip speckles so the red reads as peeling paint, not a flat border.
	var chips := [
		Vector2(w * 0.18, i + 14.0),
		Vector2(w * 0.42, i + 11.0),
		Vector2(w * 0.78, i + 15.0),
		Vector2(w * 0.22, h - i - 16.0),
		Vector2(w * 0.66, h - i - 15.0),
		Vector2(i + 16.0, h * 0.55),
		Vector2(w - i - 18.0, h * 0.42),
	]
	for c in chips:
		draw_circle(c, 3.0, SALOON_RED_CHIP)
