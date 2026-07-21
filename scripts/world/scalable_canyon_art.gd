class_name ScalableCanyonArt
extends Node2D

## Two fixed-size handmade cliff rims around an abyss whose center can be any width.

const RIM_TEXTURE := preload("res://assets/world/canyon_rim_left.png")
const RIM_SIZE := Vector2(256.0, 240.0)
const DEPTH := 310.0

var gap_left: float
var gap_right: float
var floor_top: float
var _abyss: Polygon2D
var _deep_shadow: Polygon2D
var _left_rim: Sprite2D
var _right_rim: Sprite2D


func _ready() -> void:
	top_level = true
	z_index = -2
	_ensure_parts()


func configure(new_floor_top: float, new_gap_left: float, new_gap_right: float) -> void:
	top_level = true
	floor_top = new_floor_top
	gap_left = minf(new_gap_left, new_gap_right)
	gap_right = maxf(new_gap_left, new_gap_right)
	_ensure_parts()
	global_position = Vector2.ZERO
	var top := floor_top - 2.0
	_abyss.polygon = PackedVector2Array([
		Vector2(gap_left, top),
		Vector2(gap_right, top),
		Vector2(gap_right, top + DEPTH),
		Vector2(gap_left, top + DEPTH),
	])
	_deep_shadow.polygon = PackedVector2Array([
		Vector2(gap_left, top + 70.0),
		Vector2(gap_right, top + 70.0),
		Vector2(gap_right, top + DEPTH),
		Vector2(gap_left, top + DEPTH),
	])
	var rim_y := floor_top - 8.0 + RIM_SIZE.y * 0.5
	_left_rim.position = Vector2(gap_left - RIM_SIZE.x * 0.5, rim_y)
	_right_rim.position = Vector2(gap_right + RIM_SIZE.x * 0.5, rim_y)


func opening_width() -> float:
	return gap_right - gap_left


func _ensure_parts() -> void:
	if _abyss != null:
		return
	_abyss = Polygon2D.new()
	_abyss.name = "Abyss"
	_abyss.color = Color(0.12, 0.045, 0.055, 1.0)
	_abyss.z_index = -2
	add_child(_abyss)
	_deep_shadow = Polygon2D.new()
	_deep_shadow.name = "DeepShadow"
	_deep_shadow.color = Color(0.035, 0.012, 0.025, 1.0)
	_deep_shadow.z_index = -1
	add_child(_deep_shadow)
	_left_rim = Sprite2D.new()
	_left_rim.name = "LeftRim"
	_left_rim.texture = RIM_TEXTURE
	_left_rim.centered = true
	_left_rim.z_index = 0
	add_child(_left_rim)
	_right_rim = Sprite2D.new()
	_right_rim.name = "RightRim"
	_right_rim.texture = RIM_TEXTURE
	_right_rim.centered = true
	_right_rim.flip_h = true
	_right_rim.z_index = 0
	add_child(_right_rim)
