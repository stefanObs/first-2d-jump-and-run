class_name RevolverOverlay
extends Node2D

## Readable arm-raise and muzzle-flash animation for bandit shots.

enum AimStyle { RAISED, HIP }

var facing: float = 1.0
var aim_amount: float = 0.0
var flash_amount: float = 0.0
var aim_style: AimStyle = AimStyle.RAISED


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
	if aim_style == AimStyle.HIP:
		return Vector2(36.0 * facing, -30.0)
	return Vector2(34.0 * facing, -39.0)


func _set_flash(value: float) -> void:
	flash_amount = value
	queue_redraw()


func _draw() -> void:
	if not visible:
		return
	var side := facing
	var shoulder: Vector2
	var elbow: Vector2
	var hand: Vector2
	if aim_style == AimStyle.HIP:
		shoulder = Vector2(4.0 * side, -36.0)
		elbow = Vector2(14.0 * side, -32.0)
		hand = Vector2(24.0 * side, -30.0)
	else:
		shoulder = Vector2(6.0 * side, -46.0)
		elbow = Vector2(14.0 * side, -42.0)
		hand = Vector2(22.0 * side, -40.0)
	var muzzle := muzzle_position()
	draw_line(shoulder, elbow, Color(0.28, 0.2, 0.16, 1.0), 9.0, true)
	draw_line(elbow, hand, Color(0.32, 0.22, 0.18, 1.0), 8.0, true)
	draw_circle(hand, 6.0, Color(0.73, 0.45, 0.25, 1.0))
	draw_line(hand + Vector2(-2.0 * side, 4.0), hand + Vector2(2.0 * side, -2.0), Color(0.28, 0.16, 0.08, 1.0), 6.0, true)
	draw_line(hand, muzzle, Color(0.14, 0.16, 0.18, 1.0), 8.0, true)
	draw_circle(hand + Vector2(4.0 * side, -1.0), 7.0, Color(0.28, 0.3, 0.32, 1.0))
	draw_rect(Rect2(Vector2(minf(hand.x, muzzle.x), muzzle.y - 4.0), Vector2(absf(muzzle.x - hand.x), 8.0)), Color(0.18, 0.2, 0.22, 1.0))
	if flash_amount > 0.0:
		var size := 13.0 * flash_amount
		var points := PackedVector2Array()
		for index in range(12):
			var radius := size if index % 2 == 0 else size * 0.42
			var angle := index * TAU / 12.0
			points.append(muzzle + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, Color(1.0, 0.78, 0.08, flash_amount))
