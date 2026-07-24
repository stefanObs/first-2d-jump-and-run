class_name ScalableCanyonArt
extends Node2D

## Hand-painted cliff rims outside the desert floor, framing an open canyon
## mouth. Only sky blue fills the gap — no depth shelves, floor wash, or
## mountain scenery inside. Rims stay warm and trail-matched.

const RIM_TEXTURE: Texture2D = preload("res://assets/world/canyon_rim_left.png")
const SKY_TEXTURE: Texture2D = preload("res://assets/world/canyon_sky_wash.png")

const RIM_SIZE := Vector2(220.0, 260.0)
const DEPTH := 320.0
## Pixel row of the painted desert top in canyon_rim_left.png (sand crust under scrub).
## Cliff-lip columns first go opaque around y=16; keep this matched to that lip.
const RIM_SURFACE_TEX_Y := 16.0
## Keep sky inset under the rim lips so blue never paints desert banks.
const INTERIOR_INSET := 3.0
## Drop the sky wash just under the desert crust / rim lip.
const INTERIOR_TOP_PAD := 3.0


var gap_left: float
var gap_right: float
var floor_top: float
var left_floor_top: float
var right_floor_top: float

var _sky: Sprite2D
var _left_rim: Sprite2D
var _right_rim: Sprite2D


func _ready() -> void:
	top_level = true
	# Absolute draw order: above FloorAbyss (-2), below trail dirt/surface (0/1).
	z_index = -1
	z_as_relative = false
	_ensure_parts()


func configure(
	new_floor_top: float,
	new_gap_left: float,
	new_gap_right: float,
	new_left_floor_top: float = NAN,
	new_right_floor_top: float = NAN
) -> void:
	top_level = true
	z_index = -1
	z_as_relative = false
	left_floor_top = new_floor_top if is_nan(new_left_floor_top) else new_left_floor_top
	right_floor_top = new_floor_top if is_nan(new_right_floor_top) else new_right_floor_top
	# Interior starts at the higher bank lip so raised sides stay covered.
	floor_top = minf(left_floor_top, right_floor_top)
	gap_left = minf(new_gap_left, new_gap_right)
	gap_right = maxf(new_gap_left, new_gap_right)
	_ensure_parts()
	global_position = Vector2.ZERO
	_layout_sky()
	_layout_rims()


func opening_width() -> float:
	return gap_right - gap_left


func center_is_illustrated() -> bool:
	## Open sky blue between the ridges — no dark void, no mountain fill.
	if _sky == null:
		return false
	return _sky.texture == SKY_TEXTURE and _sky_reads_blue()


func rims_outside_floor() -> bool:
	## Left rim body sits left of the gap; right rim body sits right of the gap.
	if _left_rim == null or _right_rim == null:
		return false
	var half_w := absf(_left_rim.scale.x) * RIM_TEXTURE.get_size().x * 0.5
	var left_right_edge := _left_rim.position.x + half_w
	var right_left_edge := _right_rim.position.x - half_w
	return left_right_edge <= gap_left + 14.0 and right_left_edge >= gap_right - 14.0


func rim_surface_world_y(rim: Sprite2D) -> float:
	## World Y of the painted desert top on a rim sprite.
	if rim == null or rim.texture == null:
		return floor_top
	var tex_h := float(rim.texture.get_size().y)
	return rim.position.y + (RIM_SURFACE_TEX_Y - tex_h * 0.5) * rim.scale.y


func rims_match_desert_height(tolerance: float = 3.0) -> bool:
	if _left_rim == null or _right_rim == null:
		return false
	return (
		absf(rim_surface_world_y(_left_rim) - left_floor_top) <= tolerance
		and absf(rim_surface_world_y(_right_rim) - right_floor_top) <= tolerance
	)


func interior_stays_inside_gap(tolerance: float = 0.5) -> bool:
	## Sky must not paint over desert banks beside the mouth.
	if _sky == null:
		return false
	return _sprite_inside_x(_sky, gap_left - tolerance, gap_right + tolerance)


func _sprite_inside_x(sprite: Sprite2D, left: float, right: float) -> bool:
	if sprite == null or sprite.texture == null:
		return false
	var tex_w := float(sprite.texture.get_size().x)
	var x0: float
	var x1: float
	if sprite.centered:
		var half := tex_w * absf(sprite.scale.x) * 0.5
		x0 = sprite.position.x - half
		x1 = sprite.position.x + half
	else:
		x0 = sprite.position.x
		x1 = sprite.position.x + tex_w * absf(sprite.scale.x)
	return x0 >= left and x1 <= right


func _ensure_parts() -> void:
	if _sky != null:
		return

	_sky = Sprite2D.new()
	_sky.name = "SkyWash"
	_sky.texture = SKY_TEXTURE
	_sky.centered = false
	_sky.z_index = 0
	add_child(_sky)

	# Rims last at the same relative z so tree order covers any seam, still under desert (z 1).
	_left_rim = _make_rim("LeftRim", false)
	_right_rim = _make_rim("RightRim", true)
	add_child(_left_rim)
	add_child(_right_rim)


func _make_rim(rim_name: String, flip: bool) -> Sprite2D:
	var rim := Sprite2D.new()
	rim.name = rim_name
	rim.texture = RIM_TEXTURE
	rim.centered = true
	rim.flip_h = flip
	rim.z_as_relative = true
	rim.z_index = 0
	return rim


func _sky_reads_blue() -> bool:
	var img: Image = SKY_TEXTURE.get_image()
	if img == null:
		return true
	var sample: Color = img.get_pixel(img.get_width() / 2, maxi(1, img.get_height() / 5))
	return sample.b > sample.r and sample.b > 0.45 and sample.g > 0.40


func _interior_bounds() -> Dictionary:
	var inset := minf(INTERIOR_INSET, opening_width() * 0.08)
	var left := gap_left + inset
	var right := gap_right - inset
	if right - left < 8.0:
		left = gap_left
		right = gap_right
	var top := floor_top + INTERIOR_TOP_PAD
	return {"left": left, "right": right, "top": top, "bottom": top + DEPTH}


func _layout_sky() -> void:
	var bounds := _interior_bounds()
	var top: float = bounds["top"]
	var left: float = bounds["left"]
	var right: float = bounds["right"]
	var width := right - left
	var sky_size: Vector2 = SKY_TEXTURE.get_size()
	_sky.position = Vector2(left, top)
	_sky.scale = Vector2(width / sky_size.x, DEPTH / sky_size.y)
	_sky.modulate = Color(1, 1, 1, 1)


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
	_left_rim.z_as_relative = true
	_right_rim.z_as_relative = true
	_left_rim.z_index = 0
	_right_rim.z_index = 0

	# Place rims OUTSIDE the desert floor gap: cliff lip at the bank edge,
	# rock body under the trail bank (covered by floor tiles), never over sand.
	# Align the painted desert top in the rim texture to each adjacent bank.
	var half_w := RIM_SIZE.x * 0.5 * fit
	var surface_from_center := (RIM_SURFACE_TEX_Y - tex_size.y * 0.5) * rim_scale.y
	_left_rim.position = Vector2(gap_left - half_w - 2.0 * fit, left_floor_top - surface_from_center)
	_right_rim.position = Vector2(gap_right + half_w + 2.0 * fit, right_floor_top - surface_from_center)
