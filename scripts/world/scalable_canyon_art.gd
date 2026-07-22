class_name ScalableCanyonArt
extends Node2D

## Hand-painted cliff rims outside the desert floor, framing an open canyon
## interior. Sky wash + tiled depth art fill the gap; rims stay warm and
## trail-matched so the opening never blends into the bank walls.

const RIM_TEXTURE: Texture2D = preload("res://assets/world/canyon_rim_left.png")
const SKY_TEXTURE: Texture2D = preload("res://assets/world/canyon_sky_wash.png")
const DEPTH_TEXTURE: Texture2D = preload("res://assets/world/canyon_depth_tile.png")
const INNER_WALL_TEXTURE: Texture2D = preload("res://assets/world/canyon_inner_wall.png")
const FLOOR_TEXTURE: Texture2D = preload("res://assets/world/canyon_floor_wash.png")

const RIM_SIZE := Vector2(220.0, 260.0)
const DEPTH := 320.0


var gap_left: float
var gap_right: float
var floor_top: float

var _sky: Sprite2D
var _depth_root: Node2D
var _floor: Sprite2D
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
	if _sky == null or _depth_root == null or _floor == null:
		return false
	# Interior must read as painted sky/open air, not warm rim rock.
	return (
		_sky.texture == SKY_TEXTURE
		and _sky_reads_blue()
		and _depth_root.get_child_count() >= 1
		and _left_walls != null
		and _left_walls.get_child_count() > 0
		and _floor.texture == FLOOR_TEXTURE
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
	if _sky != null:
		return

	_sky = Sprite2D.new()
	_sky.name = "SkyWash"
	_sky.texture = SKY_TEXTURE
	_sky.centered = false
	_sky.z_index = 0
	add_child(_sky)

	_depth_root = Node2D.new()
	_depth_root.name = "DepthTiles"
	_depth_root.z_index = 1
	add_child(_depth_root)

	_floor = Sprite2D.new()
	_floor.name = "FloorWash"
	_floor.texture = FLOOR_TEXTURE
	_floor.centered = false
	_floor.z_index = 2
	add_child(_floor)

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


func _sky_reads_blue() -> bool:
	var img: Image = SKY_TEXTURE.get_image()
	if img == null:
		return true
	var sample: Color = img.get_pixel(img.get_width() / 2, maxi(1, img.get_height() / 5))
	return sample.b > sample.r and sample.b > 0.45 and sample.g > 0.40


func _layout_center() -> void:
	var top := floor_top + 1.0
	var bottom := top + DEPTH
	var left := gap_left
	var right := gap_right
	var width := right - left

	# Painted sky wash stretched across the open mouth.
	var sky_size: Vector2 = SKY_TEXTURE.get_size()
	_sky.position = Vector2(left, top)
	_sky.scale = Vector2(width / sky_size.x, DEPTH / sky_size.y)
	_sky.modulate = Color(1, 1, 1, 1)

	# Distant handpainted depth tiles (soft shelves / haze), repeated for width.
	_clear_children(_depth_root)
	var depth_size: Vector2 = DEPTH_TEXTURE.get_size()
	var tile_h := DEPTH * 0.92
	var tile_scale_y := tile_h / depth_size.y
	var tile_w := depth_size.x * tile_scale_y
	var tile_y := top + DEPTH * 0.06
	var x := left - tile_w * 0.08
	var tile_i := 0
	while x < right - tile_w * 0.15:
		var tile := Sprite2D.new()
		tile.name = "Depth%d" % tile_i
		tile.texture = DEPTH_TEXTURE
		tile.centered = false
		tile.position = Vector2(x, tile_y)
		tile.scale = Vector2(tile_scale_y, tile_scale_y)
		# Soften so sky wash still reads through the open air.
		tile.modulate = Color(1, 1, 1, 0.88)
		_depth_root.add_child(tile)
		x += tile_w * 0.72
		tile_i += 1
	if tile_i == 0:
		var fallback := Sprite2D.new()
		fallback.name = "Depth0"
		fallback.texture = DEPTH_TEXTURE
		fallback.centered = false
		fallback.position = Vector2(left, tile_y)
		fallback.scale = Vector2(width / depth_size.x, tile_scale_y)
		fallback.modulate = Color(1, 1, 1, 0.88)
		_depth_root.add_child(fallback)

	# Soft painted gorge floor wash near the bottom.
	var floor_size: Vector2 = FLOOR_TEXTURE.get_size()
	var floor_h := 72.0
	var floor_y := bottom - floor_h - 4.0
	_floor.position = Vector2(left + width * 0.08, floor_y)
	_floor.scale = Vector2((width * 0.84) / floor_size.x, floor_h / floor_size.y)


func _layout_inner_walls() -> void:
	_clear_children(_left_walls)
	_clear_children(_right_walls)
	var top := floor_top + 1.0
	var width := gap_right - gap_left
	var wall_size: Vector2 = INNER_WALL_TEXTURE.get_size()
	var ledge_w := clampf(width * 0.16, 28.0, 70.0)
	if width < 200.0:
		ledge_w = minf(ledge_w, width * 0.22)
	var wall_h := DEPTH * 0.95
	var sx: float = ledge_w / wall_size.x
	var sy: float = wall_h / wall_size.y

	var left_wall := Sprite2D.new()
	left_wall.name = "LeftInnerPaint"
	left_wall.texture = INNER_WALL_TEXTURE
	left_wall.centered = false
	left_wall.position = Vector2(gap_left, top + 4.0)
	left_wall.scale = Vector2(sx, sy)
	left_wall.modulate = Color(0.92, 0.88, 0.95, 0.92)
	_left_walls.add_child(left_wall)

	var right_wall := Sprite2D.new()
	right_wall.name = "RightInnerPaint"
	right_wall.texture = INNER_WALL_TEXTURE
	right_wall.centered = false
	right_wall.flip_h = true
	right_wall.position = Vector2(gap_right - ledge_w, top + 4.0)
	right_wall.scale = Vector2(sx, sy)
	right_wall.modulate = Color(0.86, 0.82, 0.90, 0.92)
	_right_walls.add_child(right_wall)


func _layout_details() -> void:
	_clear_children(_detail_root)
	var top := floor_top + 1.0
	var width := gap_right - gap_left
	var mid := (gap_left + gap_right) * 0.5

	# Soft painted scrub accents near the bank lips (tiny polygon dabs only).
	if width >= 90.0:
		for side_i in [-1, 1]:
			var side := float(side_i)
			var scrub := Polygon2D.new()
			scrub.name = "Scrub%s" % ("L" if side < 0.0 else "R")
			scrub.color = Color(0.32, 0.50, 0.28, 0.85)
			var edge_x: float = mid + side * width * 0.22
			scrub.polygon = PackedVector2Array([
				Vector2(edge_x - 3.5, top + 12.0),
				Vector2(edge_x, top + 2.0),
				Vector2(edge_x + 3.5, top + 12.0),
				Vector2(edge_x + 1.0, top + 12.0),
				Vector2(edge_x, top + 7.5),
				Vector2(edge_x - 1.0, top + 12.0),
			])
			_detail_root.add_child(scrub)

	# Extra soft wisp marks so detail root stays populated on narrow gaps.
	if width >= 70.0:
		var wisp := Sprite2D.new()
		wisp.name = "SkyGrainHint"
		wisp.texture = SKY_TEXTURE
		wisp.centered = true
		wisp.modulate = Color(1, 1, 1, 0.18)
		wisp.position = Vector2(mid, top + 48.0)
		var hint_w := clampf(width * 0.28, 40.0, 120.0)
		var tex_size: Vector2 = SKY_TEXTURE.get_size()
		wisp.scale = Vector2(hint_w / tex_size.x, 36.0 / tex_size.y)
		_detail_root.add_child(wisp)


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
