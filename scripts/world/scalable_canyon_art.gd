class_name ScalableCanyonArt
extends Node2D

## Fixed-size handmade cliff rims around an illustrated abyss that scales to any gap.

const RIM_TEXTURE := preload("res://assets/world/canyon_rim_left.png")
const RIM_SIZE := Vector2(256.0, 240.0)
const DEPTH := 310.0

## Warm western canyon palette — never flat black.
const SHADE_SKYWARD := Color(0.42, 0.22, 0.18, 1.0)
const SHADE_MID := Color(0.28, 0.12, 0.14, 1.0)
const SHADE_DEEP := Color(0.16, 0.07, 0.12, 1.0)
const SHADE_FLOOR := Color(0.22, 0.11, 0.10, 1.0)
const STRATA_LIT := Color(0.78, 0.42, 0.24, 1.0)
const STRATA_MID := Color(0.62, 0.30, 0.18, 1.0)
const STRATA_SHADOW := Color(0.38, 0.16, 0.18, 1.0)
const RIVER := Color(0.55, 0.38, 0.22, 1.0)
const HAZE := Color(0.55, 0.32, 0.28, 0.35)

var gap_left: float
var gap_right: float
var floor_top: float

var _back_fill: Polygon2D
var _gradient_mid: Polygon2D
var _gradient_deep: Polygon2D
var _floor_band: Polygon2D
var _river: Polygon2D
var _haze: Polygon2D
var _depth_texture: Texture2D
var _depth_tiles: Node2D
var _left_walls: Node2D
var _right_walls: Node2D
var _left_rim: Sprite2D
var _right_rim: Sprite2D


func _ready() -> void:
	top_level = true
	# Sit above TrailFloor/FloorAbyss (-2), behind walkable trail tiles (0).
	z_index = -1
	_ensure_parts()


func configure(new_floor_top: float, new_gap_left: float, new_gap_right: float) -> void:
	top_level = true
	floor_top = new_floor_top
	gap_left = minf(new_gap_left, new_gap_right)
	gap_right = maxf(new_gap_left, new_gap_right)
	_ensure_parts()
	global_position = Vector2.ZERO
	_layout_center()
	_layout_inner_walls()
	_layout_depth_tiles()
	var rim_y := floor_top - 8.0 + RIM_SIZE.y * 0.5
	_left_rim.position = Vector2(gap_left - RIM_SIZE.x * 0.5, rim_y)
	_right_rim.position = Vector2(gap_right + RIM_SIZE.x * 0.5, rim_y)


func opening_width() -> float:
	return gap_right - gap_left


func center_is_illustrated() -> bool:
	if _back_fill == null or _gradient_deep == null:
		return false
	# Flat near-black fills fail this check — illustrated shades stay warmer.
	var deep := _gradient_deep.color
	var back := _back_fill.color
	var deep_luma := deep.r * 0.3 + deep.g * 0.59 + deep.b * 0.11
	var back_luma := back.r * 0.3 + back.g * 0.59 + back.b * 0.11
	return (
		deep_luma > 0.06
		and back_luma > 0.12
		and _left_walls != null
		and _left_walls.get_child_count() > 0
		and _river != null
		and _depth_tiles != null
	)


func _ensure_parts() -> void:
	if _back_fill != null:
		return

	if _depth_texture == null:
		_depth_texture = load("res://assets/world/canyon_depth_tile.png") as Texture2D

	_back_fill = _make_poly("BackFill", SHADE_SKYWARD, -6)
	_gradient_mid = _make_poly("GradientMid", SHADE_MID, -5)
	_gradient_deep = _make_poly("GradientDeep", SHADE_DEEP, -4)
	_floor_band = _make_poly("CanyonFloor", SHADE_FLOOR, -3)
	_river = _make_poly("DryRiver", RIVER, -2)
	_haze = _make_poly("AtmosphericHaze", HAZE, -1)

	_depth_tiles = Node2D.new()
	_depth_tiles.name = "DepthTiles"
	_depth_tiles.z_index = -3
	add_child(_depth_tiles)

	_left_walls = Node2D.new()
	_left_walls.name = "LeftInnerWalls"
	_left_walls.z_index = -2
	add_child(_left_walls)

	_right_walls = Node2D.new()
	_right_walls.name = "RightInnerWalls"
	_right_walls.z_index = -2
	add_child(_right_walls)

	_left_rim = Sprite2D.new()
	_left_rim.name = "LeftRim"
	_left_rim.texture = RIM_TEXTURE
	_left_rim.centered = true
	_left_rim.scale = RIM_SIZE / RIM_TEXTURE.get_size()
	_left_rim.z_index = 0
	add_child(_left_rim)

	_right_rim = Sprite2D.new()
	_right_rim.name = "RightRim"
	_right_rim.texture = RIM_TEXTURE
	_right_rim.centered = true
	_right_rim.flip_h = true
	_right_rim.scale = RIM_SIZE / RIM_TEXTURE.get_size()
	_right_rim.z_index = 0
	add_child(_right_rim)


func _make_poly(poly_name: String, color: Color, z: int) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = poly_name
	poly.color = color
	poly.z_index = z
	add_child(poly)
	return poly


func _layout_center() -> void:
	var top := floor_top - 2.0
	var bottom := top + DEPTH
	var left := gap_left
	var right := gap_right
	var width := right - left

	_back_fill.polygon = PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
	_gradient_mid.polygon = PackedVector2Array([
		Vector2(left, top + 55.0),
		Vector2(right, top + 55.0),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
	_gradient_deep.polygon = PackedVector2Array([
		Vector2(left, top + 130.0),
		Vector2(right, top + 130.0),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
	# Distant canyon floor band (receding trapezoid).
	var inset := minf(width * 0.22, 110.0)
	_floor_band.polygon = PackedVector2Array([
		Vector2(left + inset * 0.35, bottom - 78.0),
		Vector2(right - inset * 0.35, bottom - 78.0),
		Vector2(right - inset, bottom - 8.0),
		Vector2(left + inset, bottom - 8.0),
	])
	# Winding dry river / trail down the middle.
	var mid := (left + right) * 0.5
	var river_w := clampf(width * 0.08, 14.0, 36.0)
	_river.polygon = PackedVector2Array([
		Vector2(mid - river_w * 0.2, bottom - 76.0),
		Vector2(mid + river_w * 0.55, bottom - 76.0),
		Vector2(mid + river_w * 0.15, bottom - 42.0),
		Vector2(mid + river_w * 0.9, bottom - 12.0),
		Vector2(mid - river_w * 0.35, bottom - 12.0),
		Vector2(mid - river_w * 0.7, bottom - 42.0),
	])
	_river.color = RIVER
	_haze.polygon = PackedVector2Array([
		Vector2(left + 8.0, top + 40.0),
		Vector2(right - 8.0, top + 40.0),
		Vector2(right - inset * 0.5, bottom - 90.0),
		Vector2(left + inset * 0.5, bottom - 90.0),
	])


func _layout_inner_walls() -> void:
	_clear_children(_left_walls)
	_clear_children(_right_walls)
	var top := floor_top - 2.0
	var width := gap_right - gap_left
	var ledge_w := clampf(width * 0.16, 36.0, 92.0)
	var bands := [
		{"y": 8.0, "h": 38.0, "inset": 0.0, "color": STRATA_LIT},
		{"y": 44.0, "h": 42.0, "inset": 10.0, "color": STRATA_MID},
		{"y": 84.0, "h": 48.0, "inset": 22.0, "color": STRATA_SHADOW},
		{"y": 128.0, "h": 52.0, "inset": 34.0, "color": STRATA_MID},
		{"y": 176.0, "h": 58.0, "inset": 48.0, "color": STRATA_SHADOW},
		{"y": 230.0, "h": 54.0, "inset": 62.0, "color": Color(0.30, 0.12, 0.14, 1.0)},
	]
	for i in range(bands.size()):
		var band: Dictionary = bands[i]
		var y0: float = top + float(band["y"])
		var y1: float = y0 + float(band["h"])
		var inset: float = float(band["inset"])
		var color: Color = band["color"]
		var jag := 6.0 + float(i % 3) * 3.0
		# Left inner wall steps into the canyon.
		var left_poly := Polygon2D.new()
		left_poly.name = "LeftStrata%d" % i
		left_poly.color = color
		left_poly.polygon = PackedVector2Array([
			Vector2(gap_left, y0),
			Vector2(gap_left + ledge_w - inset + jag, y0 + 4.0),
			Vector2(gap_left + ledge_w - inset - jag * 0.4, y1),
			Vector2(gap_left, y1),
		])
		_left_walls.add_child(left_poly)
		# Matching right wall.
		var right_poly := Polygon2D.new()
		right_poly.name = "RightStrata%d" % i
		right_poly.color = color.darkened(0.06)
		right_poly.polygon = PackedVector2Array([
			Vector2(gap_right, y0),
			Vector2(gap_right - (ledge_w - inset + jag), y0 + 4.0),
			Vector2(gap_right - (ledge_w - inset - jag * 0.4), y1),
			Vector2(gap_right, y1),
		])
		_right_walls.add_child(right_poly)
		# Thin highlight lip on upper strata.
		if i <= 2:
			var lip := Polygon2D.new()
			lip.name = "LeftLip%d" % i
			lip.color = Color(0.92, 0.62, 0.34, 0.85)
			lip.polygon = PackedVector2Array([
				Vector2(gap_left + 2.0, y0 + 2.0),
				Vector2(gap_left + ledge_w - inset + jag - 4.0, y0 + 5.0),
				Vector2(gap_left + ledge_w - inset + jag - 8.0, y0 + 11.0),
				Vector2(gap_left + 2.0, y0 + 8.0),
			])
			_left_walls.add_child(lip)
			var lip_r := Polygon2D.new()
			lip_r.name = "RightLip%d" % i
			lip_r.color = Color(0.88, 0.56, 0.30, 0.75)
			lip_r.polygon = PackedVector2Array([
				Vector2(gap_right - 2.0, y0 + 2.0),
				Vector2(gap_right - (ledge_w - inset + jag - 4.0), y0 + 5.0),
				Vector2(gap_right - (ledge_w - inset + jag - 8.0), y0 + 11.0),
				Vector2(gap_right - 2.0, y0 + 8.0),
			])
			_right_walls.add_child(lip_r)

	# Soft shadow strips under a couple of overhangs for hand-drawn depth.
	for side in [-1, 1]:
		var shadow := Polygon2D.new()
		shadow.name = "OverhangShadow%s" % ("L" if side < 0 else "R")
		shadow.color = Color(0.12, 0.05, 0.10, 0.55)
		var edge := gap_left if side < 0 else gap_right
		var into := ledge_w * 0.55 * float(side)
		shadow.polygon = PackedVector2Array([
			Vector2(edge, top + 40.0),
			Vector2(edge + into, top + 48.0),
			Vector2(edge + into * 0.7, top + 70.0),
			Vector2(edge, top + 66.0),
		])
		if side < 0:
			_left_walls.add_child(shadow)
		else:
			_right_walls.add_child(shadow)


func _layout_depth_tiles() -> void:
	_clear_children(_depth_tiles)
	if _depth_texture == null:
		_depth_texture = load("res://assets/world/canyon_depth_tile.png") as Texture2D
	if _depth_texture == null:
		return
	var top := floor_top + 24.0
	var tex_size := _depth_texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var target_h := DEPTH - 40.0
	var scale_y := target_h / tex_size.y
	var tile_w := tex_size.x * scale_y
	var index := 0
	var width := gap_right - gap_left
	# Keep a little inset so rim art frames the tiled depth.
	var inset := minf(18.0, width * 0.04)
	var x := gap_left + inset
	var right_limit := gap_right - inset
	while x < right_limit - 1.0:
		var remaining := right_limit - x
		var use_w := minf(tile_w, remaining)
		var sprite := Sprite2D.new()
		sprite.name = "DepthTile%d" % index
		sprite.texture = _depth_texture
		sprite.centered = false
		sprite.position = Vector2(x, top)
		sprite.scale = Vector2(use_w / tex_size.x, scale_y)
		sprite.modulate = Color(1.0, 0.97, 0.94, 0.88)
		_depth_tiles.add_child(sprite)
		if remaining <= tile_w:
			break
		x += tile_w - 12.0
		index += 1
		if index > 40:
			break


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.free()
