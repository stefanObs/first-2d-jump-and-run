class_name ScalableCanyonArt
extends Node2D

## Hand-painted cliff rims outside the desert floor, framing an open canyon
## interior with sky showing through. Rims stay warm and trail-matched; the
## interior uses cooler depth + sky so it never blends into the rim walls.

const RIM_TEXTURE := preload("res://assets/world/canyon_rim_left.png")
const RIM_SIZE := Vector2(220.0, 260.0)
const DEPTH := 320.0

## Interior is cool/open so it stays distinct from warm hand-painted rims.
const SKY := Color(0.55, 0.78, 0.95, 1.0)
const SKY_DEEP := Color(0.38, 0.58, 0.82, 1.0)
const DEPTH_PURPLE := Color(0.42, 0.28, 0.48, 1.0)
const DEPTH_SHADOW := Color(0.28, 0.16, 0.32, 1.0)
const FAR_FLOOR := Color(0.62, 0.42, 0.36, 1.0)
const RIVER := Color(0.72, 0.78, 0.55, 1.0)
const INNER_LIT := Color(0.72, 0.40, 0.34, 1.0)
const INNER_MID := Color(0.52, 0.28, 0.34, 1.0)
const INNER_DEEP := Color(0.34, 0.18, 0.30, 1.0)
const OUTLINE := Color(0.18, 0.08, 0.10, 1.0)
const SCRUB := Color(0.30, 0.55, 0.26, 1.0)

var gap_left: float
var gap_right: float
var floor_top: float

var _sky_fill: Polygon2D
var _sky_deep: Polygon2D
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
	if _sky_fill == null or _band_root == null:
		return false
	# Interior must read as sky/open air, not the same warm orange as the rims.
	var sky := _sky_fill.color
	var is_skyish := sky.b > sky.r and sky.b > 0.55 and sky.g > 0.45
	return (
		is_skyish
		and _band_root.get_child_count() >= 2
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
	return left_right_edge <= gap_left + 14.0 and right_left_edge >= gap_right - 14.0


func _ensure_parts() -> void:
	if _sky_fill != null:
		return

	_sky_fill = _make_poly("BackFill", SKY, 0)
	_sky_deep = _make_poly("SkyDeep", SKY_DEEP, 0)

	_band_root = Node2D.new()
	_band_root.name = "StrataBands"
	_band_root.z_index = 1
	add_child(_band_root)

	_floor_band = _make_poly("CanyonFloor", FAR_FLOOR, 2)
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

	# Open sky through the canyon mouth — clearly different from warm rim rock.
	_sky_fill.polygon = PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
	_sky_fill.color = SKY

	# Soft deeper sky toward the bottom so the gorge reads as open air, not rock fill.
	var sky_mid := top + DEPTH * 0.42
	_sky_deep.polygon = PackedVector2Array([
		Vector2(left, sky_mid),
		Vector2(right, sky_mid),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])
	_sky_deep.color = SKY_DEEP

	_clear_children(_band_root)
	# Only a couple of cool distant haze shelves — not full-width orange strata
	# that would look like more rim rock.
	var bands := [
		{"y": 150.0, "h": 28.0, "inset": 0.28, "color": Color(DEPTH_PURPLE, 0.55)},
		{"y": 210.0, "h": 34.0, "inset": 0.36, "color": Color(DEPTH_SHADOW, 0.70)},
	]
	for i in range(bands.size()):
		var band: Dictionary = bands[i]
		var inset: float = width * float(band["inset"])
		var y0: float = top + float(band["y"])
		var y1: float = y0 + float(band["h"])
		var fill := Polygon2D.new()
		fill.name = "Band%d" % i
		fill.color = band["color"]
		fill.polygon = PackedVector2Array([
			Vector2(left + inset, y0),
			Vector2(right - inset, y0),
			Vector2(right - inset - 10.0, y1),
			Vector2(left + inset + 10.0, y1),
		])
		_band_root.add_child(fill)

	var inset := minf(width * 0.22, 100.0)
	_floor_band.polygon = PackedVector2Array([
		Vector2(left + inset * 0.35, bottom - 78.0),
		Vector2(right - inset * 0.35, bottom - 78.0),
		Vector2(right - inset, bottom - 6.0),
		Vector2(left + inset, bottom - 6.0),
	])
	_floor_band.color = FAR_FLOOR

	var mid := (left + right) * 0.5
	var river_w := clampf(width * 0.10, 14.0, 40.0)
	_river.polygon = PackedVector2Array([
		Vector2(mid - river_w * 0.2, bottom - 74.0),
		Vector2(mid + river_w * 0.5, bottom - 74.0),
		Vector2(mid + river_w * 0.2, bottom - 42.0),
		Vector2(mid + river_w * 0.85, bottom - 10.0),
		Vector2(mid - river_w * 0.35, bottom - 10.0),
		Vector2(mid - river_w * 0.65, bottom - 42.0),
	])
	_river.color = RIVER


func _layout_inner_walls() -> void:
	_clear_children(_left_walls)
	_clear_children(_right_walls)
	var top := floor_top + 1.0
	var width := gap_right - gap_left
	# Cooler, narrower cliff shelves INSIDE the gap — distinct from warm outer rims.
	var ledge_w := clampf(width * 0.14, 14.0, 52.0)
	if width < 200.0:
		ledge_w = minf(ledge_w, width * 0.20)
	var bands := [
		{"y": 6.0, "h": 40.0, "inset": 0.0, "color": INNER_LIT},
		{"y": 44.0, "h": 44.0, "inset": 8.0, "color": INNER_MID},
		{"y": 86.0, "h": 48.0, "inset": 16.0, "color": INNER_DEEP},
		{"y": 132.0, "h": 52.0, "inset": 26.0, "color": DEPTH_PURPLE},
		{"y": 182.0, "h": 58.0, "inset": 36.0, "color": DEPTH_SHADOW},
	]
	for i in range(bands.size()):
		var band: Dictionary = bands[i]
		var y0: float = top + float(band["y"])
		var y1: float = y0 + float(band["h"])
		var inset: float = float(band["inset"])
		var color: Color = band["color"]
		var jag := 3.5 + float(i % 3) * 1.8

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

		var right_poly := Polygon2D.new()
		right_poly.name = "RightStrata%d" % i
		right_poly.color = color.darkened(0.06)
		right_poly.polygon = PackedVector2Array([
			Vector2(gap_right, y0),
			Vector2(gap_right - (ledge_w - inset + jag), y0 + 2.0),
			Vector2(gap_right - (ledge_w - inset - jag * 0.3), y1),
			Vector2(gap_right, y1),
		])
		_right_walls.add_child(right_poly)


func _layout_details() -> void:
	_clear_children(_detail_root)
	var top := floor_top + 1.0
	var bottom := top + DEPTH
	var width := gap_right - gap_left
	var mid := (gap_left + gap_right) * 0.5

	# Soft sky cloud wisps in the open center (helps sell "air", not rock).
	if width >= 120.0:
		for i in range(2):
			var wisp := Polygon2D.new()
			wisp.name = "SkyWisp%d" % i
			wisp.color = Color(0.92, 0.96, 1.0, 0.35)
			var wy := top + 36.0 + float(i) * 48.0
			var wx := mid + float(i * 2 - 1) * width * 0.12
			var ww := clampf(width * 0.10, 18.0, 42.0)
			wisp.polygon = PackedVector2Array([
				Vector2(wx - ww, wy),
				Vector2(wx - ww * 0.3, wy - 8.0),
				Vector2(wx + ww * 0.6, wy - 5.0),
				Vector2(wx + ww, wy + 2.0),
				Vector2(wx + ww * 0.2, wy + 7.0),
				Vector2(wx - ww * 0.5, wy + 5.0),
			])
			_detail_root.add_child(wisp)

	if width >= 90.0:
		for side_i in [-1, 1]:
			var side := float(side_i)
			var scrub := Polygon2D.new()
			scrub.name = "Scrub%s" % ("L" if side < 0.0 else "R")
			scrub.color = SCRUB
			var edge_x: float = mid + side * width * 0.18
			scrub.polygon = PackedVector2Array([
				Vector2(edge_x - 4.0, top + 14.0),
				Vector2(edge_x, top + 3.0),
				Vector2(edge_x + 4.0, top + 14.0),
				Vector2(edge_x + 1.0, top + 14.0),
				Vector2(edge_x, top + 9.0),
				Vector2(edge_x - 1.0, top + 14.0),
			])
			_detail_root.add_child(scrub)

	for i in range(3):
		var tick := Line2D.new()
		tick.name = "FloorTick%d" % i
		tick.width = 2.0
		tick.default_color = Color(0.40, 0.22, 0.28, 1.0)
		var tx := mid + float(i - 1) * clampf(width * 0.10, 16.0, 42.0)
		tick.points = PackedVector2Array([
			Vector2(tx, bottom - 62.0),
			Vector2(tx + 7.0, bottom - 14.0),
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
