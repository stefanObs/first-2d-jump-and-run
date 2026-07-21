class_name ScalableCanyonArt
extends Node2D

## Fixed-size handmade cliff rims around a bright, illustrated canyon center.
## The center scales to any gap width; rims never stretch.

const RIM_TEXTURE := preload("res://assets/world/canyon_rim_left.png")
const RIM_SIZE := Vector2(256.0, 240.0)
const DEPTH := 310.0

## Warm western canyon palette — clearly visible, never flat black.
const SHADE_SKYWARD := Color(0.92, 0.58, 0.32, 1.0)
const SHADE_MID := Color(0.72, 0.36, 0.28, 1.0)
const SHADE_DEEP := Color(0.42, 0.20, 0.34, 1.0)
const SHADE_FLOOR := Color(0.78, 0.48, 0.28, 1.0)
const STRATA_LIT := Color(0.96, 0.62, 0.32, 1.0)
const STRATA_MID := Color(0.82, 0.42, 0.24, 1.0)
const STRATA_SHADOW := Color(0.55, 0.26, 0.28, 1.0)
const RIVER := Color(0.90, 0.72, 0.42, 1.0)
const HAZE := Color(0.75, 0.45, 0.55, 0.28)
const SCRUB := Color(0.35, 0.62, 0.28, 1.0)

var gap_left: float
var gap_right: float
var floor_top: float

var _back_fill: Polygon2D
var _gradient_mid: Polygon2D
var _gradient_deep: Polygon2D
var _floor_band: Polygon2D
var _river: Polygon2D
var _haze: Polygon2D
var _detail_root: Node2D
var _left_walls: Node2D
var _right_walls: Node2D
var _left_rim: Sprite2D
var _right_rim: Sprite2D


func _ready() -> void:
	top_level = true
	# Absolute draw order: above TrailFloor/FloorAbyss (-2), below trail tiles (1).
	z_index = -1
	z_as_relative = false
	_ensure_parts()


func configure(new_floor_top: float, new_gap_left: float, new_gap_right: float) -> void:
	top_level = true
	z_index = -1
	z_as_relative = false
	floor_top = new_floor_top
	gap_left = minf(new_gap_left, new_gap_right)
	gap_right = maxf(new_gap_left, new_gap_right)
	_ensure_parts()
	global_position = Vector2.ZERO
	_layout_center()
	_layout_inner_walls()
	_layout_details()
	_layout_rims()


func opening_width() -> float:
	return gap_right - gap_left


func center_is_illustrated() -> bool:
	if _back_fill == null or _gradient_deep == null:
		return false
	var deep := _gradient_deep.color
	var back := _back_fill.color
	var deep_luma := deep.r * 0.3 + deep.g * 0.59 + deep.b * 0.11
	var back_luma := back.r * 0.3 + back.g * 0.59 + back.b * 0.11
	return (
		deep_luma > 0.18
		and back_luma > 0.40
		and _left_walls != null
		and _left_walls.get_child_count() > 0
		and _river != null
		and _detail_root != null
		and _detail_root.get_child_count() > 0
	)


func _ensure_parts() -> void:
	if _back_fill != null:
		return

	# Children use non-negative relative z so absolute order stays >= parent (-1),
	# which keeps the illustrated center ABOVE FloorAbyss (-2). Negative relative
	# z previously buried every fill under the global abyss.
	_back_fill = _make_poly("BackFill", SHADE_SKYWARD, 0)
	_gradient_mid = _make_poly("GradientMid", SHADE_MID, 1)
	_gradient_deep = _make_poly("GradientDeep", SHADE_DEEP, 2)
	_floor_band = _make_poly("CanyonFloor", SHADE_FLOOR, 3)
	_river = _make_poly("DryRiver", RIVER, 4)
	_haze = _make_poly("AtmosphericHaze", HAZE, 5)

	_detail_root = Node2D.new()
	_detail_root.name = "CanyonDetails"
	_detail_root.z_index = 3
	add_child(_detail_root)

	_left_walls = Node2D.new()
	_left_walls.name = "LeftInnerWalls"
	_left_walls.z_index = 4
	add_child(_left_walls)

	_right_walls = Node2D.new()
	_right_walls.name = "RightInnerWalls"
	_right_walls.z_index = 4
	add_child(_right_walls)

	_left_rim = Sprite2D.new()
	_left_rim.name = "LeftRim"
	_left_rim.texture = RIM_TEXTURE
	_left_rim.centered = true
	_left_rim.z_index = 6
	add_child(_left_rim)

	_right_rim = Sprite2D.new()
	_right_rim.name = "RightRim"
	_right_rim.texture = RIM_TEXTURE
	_right_rim.centered = true
	_right_rim.flip_h = true
	_right_rim.z_index = 6
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
	_back_fill.color = SHADE_SKYWARD
	_gradient_mid.polygon = PackedVector2Array([
		Vector2(left, top + 40.0),
		Vector2(right, top + 40.0),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
	_gradient_mid.color = SHADE_MID
	_gradient_deep.polygon = PackedVector2Array([
		Vector2(left, top + 110.0),
		Vector2(right, top + 110.0),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
	_gradient_deep.color = SHADE_DEEP

	var inset := minf(width * 0.20, 100.0)
	_floor_band.polygon = PackedVector2Array([
		Vector2(left + inset * 0.25, bottom - 88.0),
		Vector2(right - inset * 0.25, bottom - 88.0),
		Vector2(right - inset, bottom - 10.0),
		Vector2(left + inset, bottom - 10.0),
	])
	_floor_band.color = SHADE_FLOOR

	var mid := (left + right) * 0.5
	var river_w := clampf(width * 0.12, 18.0, 48.0)
	_river.polygon = PackedVector2Array([
		Vector2(mid - river_w * 0.15, bottom - 84.0),
		Vector2(mid + river_w * 0.55, bottom - 84.0),
		Vector2(mid + river_w * 0.20, bottom - 48.0),
		Vector2(mid + river_w * 0.95, bottom - 14.0),
		Vector2(mid - river_w * 0.40, bottom - 14.0),
		Vector2(mid - river_w * 0.75, bottom - 48.0),
	])
	_river.color = RIVER
	_haze.polygon = PackedVector2Array([
		Vector2(left + 6.0, top + 28.0),
		Vector2(right - 6.0, top + 28.0),
		Vector2(right - inset * 0.45, bottom - 96.0),
		Vector2(left + inset * 0.45, bottom - 96.0),
	])
	_haze.color = HAZE


func _layout_inner_walls() -> void:
	_clear_children(_left_walls)
	_clear_children(_right_walls)
	var top := floor_top - 2.0
	var width := gap_right - gap_left
	# Keep a visible open center even in narrow tutorial pits.
	var ledge_w := clampf(width * 0.22, 22.0, 88.0)
	if width < 200.0:
		ledge_w = minf(ledge_w, width * 0.28)
	var bands := [
		{"y": 6.0, "h": 34.0, "inset": 0.0, "color": STRATA_LIT},
		{"y": 38.0, "h": 40.0, "inset": 8.0, "color": STRATA_MID},
		{"y": 76.0, "h": 46.0, "inset": 18.0, "color": STRATA_SHADOW},
		{"y": 118.0, "h": 50.0, "inset": 28.0, "color": STRATA_MID},
		{"y": 164.0, "h": 54.0, "inset": 40.0, "color": STRATA_SHADOW},
		{"y": 214.0, "h": 58.0, "inset": 52.0, "color": Color(0.48, 0.22, 0.30, 1.0)},
	]
	for i in range(bands.size()):
		var band: Dictionary = bands[i]
		var y0: float = top + float(band["y"])
		var y1: float = y0 + float(band["h"])
		var inset: float = float(band["inset"])
		var color: Color = band["color"]
		var jag := 5.0 + float(i % 3) * 2.5
		var left_poly := Polygon2D.new()
		left_poly.name = "LeftStrata%d" % i
		left_poly.color = color
		left_poly.polygon = PackedVector2Array([
			Vector2(gap_left, y0),
			Vector2(gap_left + ledge_w - inset + jag, y0 + 3.0),
			Vector2(gap_left + ledge_w - inset - jag * 0.35, y1),
			Vector2(gap_left, y1),
		])
		_left_walls.add_child(left_poly)

		var right_poly := Polygon2D.new()
		right_poly.name = "RightStrata%d" % i
		right_poly.color = color.darkened(0.05)
		right_poly.polygon = PackedVector2Array([
			Vector2(gap_right, y0),
			Vector2(gap_right - (ledge_w - inset + jag), y0 + 3.0),
			Vector2(gap_right - (ledge_w - inset - jag * 0.35), y1),
			Vector2(gap_right, y1),
		])
		_right_walls.add_child(right_poly)

		if i <= 2:
			var lip := Polygon2D.new()
			lip.name = "LeftLip%d" % i
			lip.color = Color(1.0, 0.78, 0.42, 0.9)
			lip.polygon = PackedVector2Array([
				Vector2(gap_left + 2.0, y0 + 1.0),
				Vector2(gap_left + ledge_w - inset + jag - 3.0, y0 + 4.0),
				Vector2(gap_left + ledge_w - inset + jag - 7.0, y0 + 10.0),
				Vector2(gap_left + 2.0, y0 + 7.0),
			])
			_left_walls.add_child(lip)
			var lip_r := Polygon2D.new()
			lip_r.name = "RightLip%d" % i
			lip_r.color = Color(0.98, 0.72, 0.38, 0.85)
			lip_r.polygon = PackedVector2Array([
				Vector2(gap_right - 2.0, y0 + 1.0),
				Vector2(gap_right - (ledge_w - inset + jag - 3.0), y0 + 4.0),
				Vector2(gap_right - (ledge_w - inset + jag - 7.0), y0 + 10.0),
				Vector2(gap_right - 2.0, y0 + 7.0),
			])
			_right_walls.add_child(lip_r)


func _layout_details() -> void:
	_clear_children(_detail_root)
	var top := floor_top - 2.0
	var bottom := top + DEPTH
	var width := gap_right - gap_left
	var mid := (gap_left + gap_right) * 0.5

	# Receding shelf bands across the open center (procedural, not a stretched tile).
	var shelves := [
		{"y": 70.0, "inset": 0.18, "h": 10.0, "color": Color(0.88, 0.50, 0.30, 0.85)},
		{"y": 120.0, "inset": 0.26, "h": 9.0, "color": Color(0.70, 0.34, 0.30, 0.8)},
		{"y": 175.0, "inset": 0.34, "h": 8.0, "color": Color(0.52, 0.24, 0.34, 0.75)},
	]
	for i in range(shelves.size()):
		var shelf: Dictionary = shelves[i]
		var inset: float = width * float(shelf["inset"])
		var y0: float = top + float(shelf["y"])
		var y1: float = y0 + float(shelf["h"])
		var poly := Polygon2D.new()
		poly.name = "Shelf%d" % i
		poly.color = shelf["color"]
		poly.polygon = PackedVector2Array([
			Vector2(gap_left + inset, y0),
			Vector2(gap_right - inset, y0),
			Vector2(gap_right - inset - 8.0, y1),
			Vector2(gap_left + inset + 8.0, y1),
		])
		_detail_root.add_child(poly)

	# Tiny scrub tufts near the upper lips for a handmade western read.
	if width >= 90.0:
		for side_i in [-1, 1]:
			var side := float(side_i)
			var scrub := Polygon2D.new()
			scrub.name = "Scrub%s" % ("L" if side < 0.0 else "R")
			scrub.color = SCRUB
			var edge: float = mid + side * width * 0.28
			scrub.polygon = PackedVector2Array([
				Vector2(edge - 4.0, top + 18.0),
				Vector2(edge, top + 6.0),
				Vector2(edge + 4.0, top + 18.0),
				Vector2(edge + 1.0, top + 18.0),
				Vector2(edge, top + 12.0),
				Vector2(edge - 1.0, top + 18.0),
			])
			_detail_root.add_child(scrub)

	# Soft sun shaft so the distant floor stays readable.
	var shaft := Polygon2D.new()
	shaft.name = "SunShaft"
	shaft.color = Color(1.0, 0.90, 0.55, 0.16)
	shaft.polygon = PackedVector2Array([
		Vector2(mid - width * 0.08, top + 8.0),
		Vector2(mid + width * 0.10, top + 8.0),
		Vector2(mid + width * 0.04, bottom - 20.0),
		Vector2(mid - width * 0.05, bottom - 20.0),
	])
	_detail_root.add_child(shaft)


func _layout_rims() -> void:
	var tex_size := RIM_TEXTURE.get_size()
	var base_scale := RIM_SIZE / tex_size
	# Narrow pits shrink rims so the cliff face still frames the gap without
	# burying the trail under oversized sandy ledges. Wide pits keep the
	# handmade size and never stretch past it.
	var width := opening_width()
	var fit := 1.0
	if width < 200.0:
		fit = clampf(width / 200.0, 0.42, 1.0)
	var rim_scale := base_scale * fit
	_left_rim.scale = rim_scale
	_right_rim.scale = rim_scale
	_right_rim.flip_h = true
	var half_w := RIM_SIZE.x * 0.5 * fit
	var rim_y := floor_top - 8.0 + RIM_SIZE.y * 0.5 * fit
	_left_rim.position = Vector2(gap_left - half_w + 8.0 * fit, rim_y)
	_right_rim.position = Vector2(gap_right + half_w - 8.0 * fit, rim_y)


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.free()
