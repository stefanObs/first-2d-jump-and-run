class_name RevolverOverlay
extends Node2D

## Readable arm-raise and muzzle-flash animation for bandit shots.

var facing: float = 1.0
var aim_amount: float = 0.0
var flash_amount: float = 0.0


func show_aim(direction: float) -> void:
	facing = 1.0 if direction >= 0.0 else -1.0
	aim_amount = 1.0
	flash_amount = 0.0
	visible = true
	queue_redraw()


func show_flash() -> void:
	flash_amount = 1.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_flash, 1.0, 0.0, 0.16)


func hide_gun() -> void:
	visible = false
	aim_amount = 0.0
	flash_amount = 0.0


func muzzle_position() -> Vector2:
	return Vector2(34.0 * facing, -39.0)


func _set_flash(value: float) -> void:
	flash_amount = value
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var side := facing
	var shoulder := Vector2(8.0 * side, -43.0)
	var hand := Vector2(20.0 * side, -40.0)
	var muzzle := muzzle_position()
	draw_line(shoulder, hand, Color(0.32, 0.22, 0.18, 1.0), 8.0, true)
	draw_circle(hand, 5.0, Color(0.73, 0.45, 0.25, 1.0))
	draw_line(hand, muzzle, Color(0.16, 0.18, 0.2, 1.0), 7.0, true)
	draw_circle(Vector2(23.0 * side, -39.0), 6.0, Color(0.32, 0.34, 0.36, 1.0))
	draw_line(
		Vector2(22.0 * side, -36.0),
		Vector2(18.0 * side, -29.0),
		Color(0.28, 0.16, 0.08, 1.0),
		5.0,
		true
	)
	if flash_amount > 0.0:
		var size := 13.0 * flash_amount
		var points := PackedVector2Array()
		for index in range(12):
			var radius := size if index % 2 == 0 else size * 0.42
			var angle := index * TAU / 12.0
			points.append(muzzle + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, Color(1.0, 0.78, 0.08, flash_amount))
