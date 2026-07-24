class_name ScalableCanyonArt
extends Node2D

## Hand-painted full-height cliff ridges outside the desert floor, framing an
## open canyon mouth. Sky shows through naturally (no fill column) — no depth
## shelves, floor wash, or mountain scenery inside. Rims stay warm and
## trail-matched from the desert top down the full canyon face.

const RIM_TEXTURE: Texture2D = preload("res://assets/world/canyon_rim_left.png")

## World size of one ridge: wide enough to cover the bank cut, tall enough to
## reach the bottom of the trail dirt / view (not a short surface lip).
const RIM_SIZE := Vector2(200.0, 900.0)
## Pixel row of the painted desert sand crust on canyon_rim_left.png.
## Keep locked to the top plateau so ridge lips meet the trail surface.
const RIM_SURFACE_TEX_Y := 4.0
## Texture X of the canyon-facing lip (opaque right edge of the top crust).
## Positioning uses this — not the full padded texture width — so the ridge
## terminates the desert cleanly and lower strata do not float in the mouth.
const RIM_LIP_TEX_X := 353.0
## Draw above TrailFloor surface tiles (z 1) so ridge lips sit on the desert edge.
const CANYON_DRAW_Z := 2
## How far below the desert top the ridge must reach (matches FloorAbyss depth).
const RIM_DEPTH_PX := 880.0


var gap_left: float
var gap_right: float
var floor_top: float
var left_floor_top: float
var right_floor_top: float

var _left_rim: Sprite2D
var _right_rim: Sprite2D


func _ready() -> void:
	top_level = true
	z_index = CANYON_DRAW_Z
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
	z_index = CANYON_DRAW_Z
	z_as_relative = false
	left_floor_top = new_floor_top if is_nan(new_left_floor_top) else new_left_floor_top
	right_floor_top = new_floor_top if is_nan(new_right_floor_top) else new_right_floor_top
	# Interior starts at the higher bank lip so raised sides stay covered.
	floor_top = minf(left_floor_top, right_floor_top)
	gap_left = minf(new_gap_left, new_gap_right)
	gap_right = maxf(new_gap_left, new_gap_right)
	_ensure_parts()
	global_position = Vector2.ZERO
	_layout_rims()


func opening_width() -> float:
	return gap_right - gap_left


func center_is_illustrated() -> bool:
	## Open mouth: rims only — no sky-fill column, depth shelves, or inner walls.
	if _left_rim == null or _right_rim == null:
		return false
	if get_node_or_null("SkyWash") != null:
		return false
	if get_node_or_null("DepthTiles") != null:
		return false
	if get_node_or_null("FloorWash") != null:
		return false
	if get_node_or_null("LeftInnerWalls") != null:
		return false
	return _left_rim.texture == RIM_TEXTURE and _right_rim.texture == RIM_TEXTURE


func rims_outside_floor() -> bool:
	## Left rim lip sits at the left bank; right rim lip at the right bank.
	if _left_rim == null or _right_rim == null:
		return false
	return (
		absf(_rim_lip_world_x(_left_rim, false) - gap_left) <= 14.0
		and absf(_rim_lip_world_x(_right_rim, true) - gap_right) <= 14.0
	)


func rim_surface_world_y(rim: Sprite2D) -> float:
	## World Y of the painted desert top on a rim sprite.
	if rim == null or rim.texture == null:
		return floor_top
	var tex_h := float(rim.texture.get_size().y)
	return rim.position.y + (RIM_SURFACE_TEX_Y - tex_h * 0.5) * rim.scale.y


func rim_bottom_world_y(rim: Sprite2D) -> float:
	## World Y of the bottom of the full-height ridge art.
	if rim == null or rim.texture == null:
		return floor_top
	var tex_h := float(rim.texture.get_size().y)
	return rim.position.y + (tex_h * 0.5) * rim.scale.y


func rims_match_desert_height(tolerance: float = 4.0) -> bool:
	## Ridge tops sit 1px under the trail crust by design.
	if _left_rim == null or _right_rim == null:
		return false
	return (
		absf(rim_surface_world_y(_left_rim) - (left_floor_top + 1.0)) <= tolerance
		and absf(rim_surface_world_y(_right_rim) - (right_floor_top + 1.0)) <= tolerance
	)


func rims_reach_canyon_bottom(tolerance: float = 40.0) -> bool:
	## Full-height ridges — not a short surface lip — cover the canyon face.
	if _left_rim == null or _right_rim == null:
		return false
	var left_target := left_floor_top + RIM_DEPTH_PX
	var right_target := right_floor_top + RIM_DEPTH_PX
	return (
		rim_bottom_world_y(_left_rim) >= left_target - tolerance
		and rim_bottom_world_y(_right_rim) >= right_target - tolerance
	)


func interior_stays_inside_gap(tolerance: float = 0.5) -> bool:
	## No sky-fill column — mouth is open; always true when SkyWash is absent.
	if get_node_or_null("SkyWash") != null:
		return false
	return opening_width() > tolerance


func _rim_lip_world_x(rim: Sprite2D, flip: bool) -> float:
	if rim == null or rim.texture == null:
		return gap_left if not flip else gap_right
	var tex_w := float(rim.texture.get_size().x)
	var lip_from_center := (RIM_LIP_TEX_X - tex_w * 0.5) * rim.scale.x
	if flip:
		# Mirrored: lip is on the left side of the sprite.
		return rim.position.x - lip_from_center
	return rim.position.x + lip_from_center


func _ensure_parts() -> void:
	# Drop any legacy sky-fill column from older builds.
	var legacy_sky := get_node_or_null("SkyWash")
	if legacy_sky != null:
		legacy_sky.free()
	if _left_rim != null:
		return

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
	rim.z_index = 1
	return rim


func _layout_rims() -> void:
	var tex_size := RIM_TEXTURE.get_size()
	var base_scale := RIM_SIZE / tex_size
	# Narrow gaps shrink ridge WIDTH only — keep full cliff height.
	var width := opening_width()
	var fit_x := 1.0
	if width < 200.0:
		fit_x = clampf(width / 200.0, 0.45, 1.0)
	var rim_scale := Vector2(base_scale.x * fit_x, base_scale.y)
	_left_rim.scale = rim_scale
	_right_rim.scale = rim_scale
	_right_rim.flip_h = true
	_left_rim.z_as_relative = true
	_right_rim.z_as_relative = true
	_left_rim.z_index = 1
	_right_rim.z_index = 1

	# Place rims OUTSIDE the desert floor gap: painted lip at the bank edge,
	# rock body under the trail bank, drawn in front of desert tiles.
	var surface_from_center := (RIM_SURFACE_TEX_Y - tex_size.y * 0.5) * rim_scale.y
	var lip_from_center := (RIM_LIP_TEX_X - tex_size.x * 0.5) * rim_scale.x
	# +1px under the trail crust so the ridge top reads continuous with desert.
	var surface_y := left_floor_top + 1.0
	_left_rim.position = Vector2(gap_left - lip_from_center, surface_y - surface_from_center)
	surface_y = right_floor_top + 1.0
	_right_rim.position = Vector2(gap_right + lip_from_center, surface_y - surface_from_center)
