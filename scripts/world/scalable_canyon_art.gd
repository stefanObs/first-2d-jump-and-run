class_name ScalableCanyonArt
extends Node2D

## Fixed-size handmade cliff rims outside the desert floor, framing a sharp
## cel-shaded canyon center. The center scales to any gap width; rims never
## stretch and never paint over the trail surface.

const RIM_TEXTURE := preload("res://assets/world/canyon_rim_left.png")
const RIM_SIZE := Vector2(220.0, 260.0)
const DEPTH := 320.0

## Crisp western canyon palette — hard cel bands, no soft blur.
const SHADE_SKYWARD := Color(0.94, 0.62, 0.34, 1.0)
const SHADE_MID := Color(0.78, 0.40, 0.26, 1.0)
const SHADE_DEEP := Color(0.48, 0.22, 0.30, 1.0)
const SHADE_FLOOR := Color(0.86, 0.56, 0.30, 1.0)
const STRATA_LIT := Color(0.98, 0.68, 0.34, 1.0)
const STRATA_MID := Color(0.86, 0.46, 0.24, 1.0)
const STRATA_SHADOW := Color(0.58, 0.28, 0.26, 1.0)
const RIVER := Color(0.94, 0.78, 0.44, 1.0)
const OUTLINE := Color(0.22, 0.10, 0.08, 1.0)
const SCRUB := Color(0.32, 0.58, 0.24, 1.0)

var gap_left: float
var gap_right: float
var floor_top: float

var _back_fill: Polygon2D
var _band_root: Node2D
var _floor_band: Polygon2D
var _river: Polygon2D
var _detail_root: Node2D
var _left_walls: Node2D
var _right_walls: Node2D
var _left_rim: Sprite2D
var _right_rim: Sprite2D


func _ready() -> void:
	top_level = true
	# Absolute draw order: above FloorAbyss (-2), below trail dirt/surface (0/1).
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
	if _back_fill == null or _band_root == null:
		return false
	var back := _back_fill.color
	var back_luma := back.r * 0.3 + back.g * 0.59 + back.b * 0.11
	return (
		back_luma > 0.40
		and _band_root.get_child_count() >= 4
		and _left_walls != null
		and _left_walls.get_child_count() > 0
		and _river != null
		and _detail_root != null
		and _detail_root.get_child_count() > 0
	)


func rims_outside_floor() -> bool:
	## Left rim body sits left of the gap; right rim body sits right of the gap.
	if _left_rim == null or _right_rim == null:
		return false
	var half_w := absf(_left_rim.scale.x) * RIM_TEXTURE.get_size().x * 0.5
	var left_right_edge := _left_rim.position.x + half_w
	var right_left_edge := _right_rim.position.x - half_w
	# Cliff lips may kiss the gap by a few pixels, but most of each rim stays outside.
	return left_right_edge <= gap_left + 14.0 and right_left_edge >= gap_right - 14.0


func _ensure_parts() -> void:
	if _back_fill != null:
		return

	# Children stay at relative z >= 0 so absolute order remains above FloorAbyss.
	_back_fill = _make_poly("BackFill", SHADE_SKYWARD, 0)

	_band_root = Node2D.new()
	_band_root.name = "StrataBands"
	_band_root.z_index = 1
	add_child(_band_root)

	_floor_band = _make_poly("CanyonFloor", SHADE_FLOOR, 2)
	_river = _make_poly("DryRiver", RIVER, 3)

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
	# Keep rims under the desert surface tiles so sandy tops never cover the trail.
	_left_rim.z_as_relative = false
	_left_rim.z_index = -1
	add_child(_left_rim)

	_right_rim = Sprite2D.new()
	_right_rim.name = "RightRim"
	_right_rim.texture = RIM_TEXTURE
	_right_rim.centered = true
	_right_rim.flip_h = true
	_right_rim.z_as_relative = false
	_right_rim.z_index = -1
	add_child(_right_rim)


func _make_poly(poly_name: String, color: Color, z: int) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = poly_name
	poly.color = color
	poly.z_index = z
	add_child(poly)
	return poly


func _layout_center() -> void:
	var top := floor_top + 1.0
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

	_clear_children(_band_root)
	# Hard cel strata across the open center — sharp edges, no soft haze.
	var bands := [
		{"y": 0.0, "h": 42.0, "color": STRATA_LIT},
		{"y": 42.0, "h": 46.0, "color": STRATA_MID},
		{"y": 88.0, "h": 50.0, "color": STRATA_SHADOW},
		{"y": 138.0, "h": 52.0, "color": SHADE_MID},
		{"y": 190.0, "h": 54.0, "color": SHADE_DEEP},
		{"y": 244.0, "h": 76.0, "color": Color(0.36, 0.16, 0.24, 1.0)},
	]
	for i in range(bands.size()):
		var band: Dictionary = bands[i]
		var y0: float = top + float(band["y"])
		var y1: float = y0 + float(band["h"])
		var jag := 3.0 + float(i % 2) * 2.0
		var fill := Polygon2D.new()
		fill.name = "Band%d" % i
		fill.color = band["color"]
		fill.polygon = PackedVector2Array([
			Vector2(left, y0),
			Vector2(right, y0 + jag * 0.25),
			Vector2(right, y1),
			Vector2(left, y1 - jag * 0.15),
		])
		_band_root.add_child(fill)
		var edge := Line2D.new()
		edge.name = "BandEdge%d" % i
		edge.width = 2.0
		edge.default_color = OUTLINE
		edge.points = PackedVector2Array([
			Vector2(left, y0),
			Vector2(right, y0 + jag * 0.25),
		])
		_band_root.add_child(edge)

	var inset := minf(width * 0.18, 90.0)
	_floor_band.polygon = PackedVector2Array([
		Vector2(left + inset * 0.2, bottom - 92.0),
		Vector2(right - inset * 0.2, bottom - 92.0),
		Vector2(right - inset, bottom - 8.0),
		Vector2(left + inset, bottom - 8.0),
	])
	_floor_band.color = SHADE_FLOOR

	var mid := (left + right) * 0.5
	var river_w := clampf(width * 0.12, 16.0, 44.0)
	_river.polygon = PackedVector2Array([
		Vector2(mid - river_w * 0.2, bottom - 88.0),
		Vector2(mid + river_w * 0.55, bottom - 88.0),
		Vector2(mid + river_w * 0.25, bottom - 50.0),
		Vector2(mid + river_w * 0.9, bottom - 12.0),
		Vector2(mid - river_w * 0.35, bottom - 12.0),
		Vector2(mid - river_w * 0.7, bottom - 50.0),
	])
	_river.color = RIVER


func _layout_inner_walls() -> void:
	_clear_children(_left_walls)
	_clear_children(_right_walls)
	var top := floor_top + 1.0
	var width := gap_right - gap_left
	# Visible cliff shelves INSIDE the gap only — never over desert floor.
	var ledge_w := clampf(width * 0.20, 18.0, 72.0)
	if width < 200.0:
		ledge_w = minf(ledge_w, width * 0.26)
	var bands := [
		{"y": 4.0, "h": 36.0, "inset": 0.0, "color": STRATA_LIT},
		{"y": 38.0, "h": 40.0, "inset": 6.0, "color": STRATA_MID},
		{"y": 76.0, "h": 44.0, "inset": 14.0, "color": STRATA_SHADOW},
		{"y": 118.0, "h": 48.0, "inset": 24.0, "color": STRATA_MID},
		{"y": 164.0, "h": 52.0, "inset": 34.0, "color": STRATA_SHADOW},
		{"y": 214.0, "h": 56.0, "inset": 46.0, "color": Color(0.42, 0.18, 0.26, 1.0)},
	]
	for i in range(bands.size()):
		var band: Dictionary = bands[i]
		var y0: float = top + float(band["y"])
		var y1: float = y0 + float(band["h"])
		var inset: float = float(band["inset"])
		var color: Color = band["color"]
		var jag := 4.0 + float(i % 3) * 2.0

		var left_poly := Polygon2D.new()
		left_poly.name = "LeftStrata%d" % i
		left_poly.color = color
		left_poly.polygon = PackedVector2Array([
			Vector2(gap_left, y0),
			Vector2(gap_left + ledge_w - inset + jag, y0 + 2.0),
			Vector2(gap_left + ledge_w - inset - jag * 0.3, y1),
			Vector2(gap_left, y1),
		])
		_left_walls.add_child(left_poly)
		var left_outline := Line2D.new()
		left_outline.name = "LeftEdge%d" % i
		left_outline.width = 2.0
		left_outline.default_color = OUTLINE
		left_outline.points = PackedVector2Array([
			Vector2(gap_left + ledge_w - inset + jag, y0 + 2.0),
			Vector2(gap_left + ledge_w - inset - jag * 0.3, y1),
		])
		_left_walls.add_child(left_outline)

		var right_poly := Polygon2D.new()
		right_poly.name = "RightStrata%d" % i
		right_poly.color = color.darkened(0.04)
		right_poly.polygon = PackedVector2Array([
			Vector2(gap_right, y0),
			Vector2(gap_right - (ledge_w - inset + jag), y0 + 2.0),
			Vector2(gap_right - (ledge_w - inset - jag * 0.3), y1),
			Vector2(gap_right, y1),
		])
		_right_walls.add_child(right_poly)
		var right_outline := Line2D.new()
		right_outline.name = "RightEdge%d" % i
		right_outline.width = 2.0
		right_outline.default_color = OUTLINE
		right_outline.points = PackedVector2Array([
			Vector2(gap_right - (ledge_w - inset + jag), y0 + 2.0),
			Vector2(gap_right - (ledge_w - inset - jag * 0.3), y1),
		])
		_right_walls.add_child(right_outline)


func _layout_details() -> void:
	_clear_children(_detail_root)
	var top := floor_top + 1.0
	var bottom := top + DEPTH
	var width := gap_right - gap_left
	var mid := (gap_left + gap_right) * 0.5

	# Receding hard shelves — crisp rectangles, not soft gradients.
	var shelves := [
		{"y": 68.0, "inset": 0.22, "h": 8.0, "color": Color(0.92, 0.54, 0.28, 1.0)},
		{"y": 118.0, "inset": 0.30, "h": 8.0, "color": Color(0.72, 0.34, 0.28, 1.0)},
		{"y": 172.0, "inset": 0.38, "h": 7.0, "color": Color(0.50, 0.22, 0.30, 1.0)},
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
			Vector2(gap_right - inset - 6.0, y1),
			Vector2(gap_left + inset + 6.0, y1),
		])
		_detail_root.add_child(poly)
		var edge := Line2D.new()
		edge.name = "ShelfEdge%d" % i
		edge.width = 1.5
		edge.default_color = OUTLINE
		edge.points = PackedVector2Array([
			Vector2(gap_left + inset, y0),
			Vector2(gap_right - inset, y0),
		])
		_detail_root.add_child(edge)

	if width >= 90.0:
		for side_i in [-1, 1]:
			var side := float(side_i)
			var scrub := Polygon2D.new()
			scrub.name = "Scrub%s" % ("L" if side < 0.0 else "R")
			scrub.color = SCRUB
			var edge_x: float = mid + side * width * 0.22
			scrub.polygon = PackedVector2Array([
				Vector2(edge_x - 4.0, top + 16.0),
				Vector2(edge_x, top + 4.0),
				Vector2(edge_x + 4.0, top + 16.0),
				Vector2(edge_x + 1.0, top + 16.0),
				Vector2(edge_x, top + 10.0),
				Vector2(edge_x - 1.0, top + 16.0),
			])
			_detail_root.add_child(scrub)

	# Distant floor tick marks for depth without blur.
	for i in range(3):
		var tick := Line2D.new()
		tick.name = "FloorTick%d" % i
		tick.width = 2.0
		tick.default_color = Color(0.55, 0.28, 0.18, 1.0)
		var tx := mid + float(i - 1) * clampf(width * 0.12, 20.0, 50.0)
		tick.points = PackedVector2Array([
			Vector2(tx, bottom - 70.0),
			Vector2(tx + 8.0, bottom - 18.0),
		])
		_detail_root.add_child(tick)


func _layout_rims() -> void:
	var tex_size := RIM_TEXTURE.get_size()
	var base_scale := RIM_SIZE / tex_size
	var width := opening_width()
	var fit := 1.0
	if width < 200.0:
		fit = clampf(width / 200.0, 0.45, 1.0)
	var rim_scale := base_scale * fit
	_left_rim.scale = rim_scale
	_right_rim.scale = rim_scale
	_right_rim.flip_h = true
	_left_rim.z_as_relative = false
	_right_rim.z_as_relative = false
	_left_rim.z_index = -1
	_right_rim.z_index = -1

	# Place rims OUTSIDE the desert floor gap: cliff lip at the bank edge,
	# rock body under the trail bank (covered by floor tiles), never over sand.
	var half_w := RIM_SIZE.x * 0.5 * fit
	var rim_y := floor_top + 6.0 + RIM_SIZE.y * 0.45 * fit
	_left_rim.position = Vector2(gap_left - half_w - 2.0 * fit, rim_y)
	_right_rim.position = Vector2(gap_right + half_w + 2.0 * fit, rim_y)


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		node.remove_child(child)
		child.free()
