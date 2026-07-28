class_name ScalableCanyonArt
extends Node2D

## Slim hand-painted full-height cliff faces outside the trail floor, framing
## an open canyon mouth. The bank/inland side is opaque packed earth so sky and
## FloorAbyss never peek beside the ridge; the canyon-facing edge is jagged rock.
## Sky shows through the mouth (no fill column). Desert and cave each use their
## own rim texture (warm sandstone vs cool slate).

const DESERT_RIM_TEXTURE: Texture2D = preload("res://assets/world/canyon_rim_left.png")
const CAVE_RIM_TEXTURE: Texture2D = preload("res://assets/world/cave_canyon_rim_left.png")
## Legacy alias — desert rim (tests / older callers).
const RIM_TEXTURE: Texture2D = DESERT_RIM_TEXTURE

## World size of one ridge face: thin canyon lip, tall enough to reach the
## bottom of the trail dirt / view (not a short surface lip).
const RIM_SIZE := Vector2(96.0, 900.0)
## Pixel row of the painted desert/cave crust on the rim texture.
## Top of the sealed sand/stone cap — flush with the trail floor.
const RIM_SURFACE_TEX_Y := 0.0
## Texture X of the outermost canyon-facing sand/lip (shared silhouette).
const RIM_LIP_TEX_X := 366.0
## Sand-crust rows at the top of the rim texture that must stay sealed.
const RIM_CRUST_TEX_ROWS := 14
## Draw above TrailFloor surface tiles (z 1) so ridge lips sit on the desert edge.
const CANYON_DRAW_Z := 2
## How far below the desert top the ridge must reach (matches FloorAbyss depth).
const RIM_DEPTH_PX := 880.0


var gap_left: float
var gap_right: float
var floor_top: float
var left_floor_top: float
var right_floor_top: float
var _style: String = LevelStyle.DESERT
var _rim_texture: Texture2D = DESERT_RIM_TEXTURE

var _left_rim: Sprite2D
var _right_rim: Sprite2D


func _ready() -> void:
	top_level = true
	z_index = CANYON_DRAW_Z
	z_as_relative = false
	_ensure_parts()


func apply_level_style(style: String) -> void:
	_style = LevelStyle.normalize(style)
	_rim_texture = CAVE_RIM_TEXTURE if LevelStyle.is_cave(_style) else DESERT_RIM_TEXTURE
	_ensure_parts()
	if _left_rim != null:
		_left_rim.texture = _rim_texture
		_right_rim.texture = _rim_texture
		_layout_rims()


func configure(
	new_floor_top: float,
	new_gap_left: float,
	new_gap_right: float,
	new_left_floor_top: float = NAN,
	new_right_floor_top: float = NAN,
	style: String = LevelStyle.DESERT
) -> void:
	top_level = true
	z_index = CANYON_DRAW_Z
	z_as_relative = false
	_style = LevelStyle.normalize(style)
	_rim_texture = CAVE_RIM_TEXTURE if LevelStyle.is_cave(_style) else DESERT_RIM_TEXTURE
	left_floor_top = new_floor_top if is_nan(new_left_floor_top) else new_left_floor_top
	right_floor_top = new_floor_top if is_nan(new_right_floor_top) else new_right_floor_top
	# Interior starts at the higher bank lip so raised sides stay covered.
	floor_top = minf(left_floor_top, right_floor_top)
	gap_left = minf(new_gap_left, new_gap_right)
	gap_right = maxf(new_gap_left, new_gap_right)
	_ensure_parts()
	_left_rim.texture = _rim_texture
	_right_rim.texture = _rim_texture
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
	return _is_known_rim(_left_rim.texture) and _is_known_rim(_right_rim.texture)


func _is_known_rim(tex: Texture2D) -> bool:
	return tex == DESERT_RIM_TEXTURE or tex == CAVE_RIM_TEXTURE


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
	## Ridge tops sit flush under the trail sand crust (no sky seam).
	if _left_rim == null or _right_rim == null:
		return false
	return (
		absf(rim_surface_world_y(_left_rim) - left_floor_top) <= tolerance
		and absf(rim_surface_world_y(_right_rim) - right_floor_top) <= tolerance
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


func rims_are_thin_faces(tolerance: float = 8.0) -> bool:
	## Handcrafted art stays a slim ridge strip (opaque dirt bank + jagged face).
	if _left_rim == null or _right_rim == null or _left_rim.texture == null:
		return false
	var tex_w := float(_left_rim.texture.get_size().x)
	var world_w := tex_w * absf(_left_rim.scale.x)
	return world_w <= RIM_SIZE.x + tolerance and RIM_SIZE.x <= 96.0


func _rim_source_image() -> Image:
	if _rim_texture == null:
		return null
	var img := _rim_texture.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	return img


func rim_bank_is_opaque_dirt() -> bool:
	## Inland/bank side is packed earth (opaque) so sky/abyss cannot show through.
	var img := _rim_source_image()
	if img == null:
		return false
	var w := img.get_width()
	var h := img.get_height()
	if w < 8 or h < 40:
		return false
	var y := mini(h - 1, maxi(40, int(h * 0.35)))
	var solid := 0
	var samples := mini(12, maxi(4, w / 4))
	for i in range(samples):
		var c := img.get_pixel(i, y)
		# Opaque earth — warm desert or cool cave slate, not sky/near-black void.
		var bri := (c.r + c.g + c.b) / 3.0
		if c.a >= 0.85 and bri > 0.18:
			solid += 1
	return solid >= samples * 3 / 4


func rim_sky_edge_is_irregular(min_spread_px: float = 8.0) -> bool:
	## Canyon-facing edge against sky is jagged — not a ruler-straight cut.
	## Requires non-constant lip X (multiple distinct columns) with enough span.
	var img := _rim_source_image()
	if img == null:
		return false
	var w := img.get_width()
	var h := img.get_height()
	var lo := float(w)
	var hi := -1.0
	var samples := 0
	var distinct := {}
	# Skip the sealed sand crust; measure the cliff face silhouette below it.
	var y0 := mini(RIM_CRUST_TEX_ROWS, h - 1)
	# Dense enough to catch deep notches (not just the outer envelope).
	var step := maxi(1, (h - y0) / 120)
	for y in range(y0, h, step):
		var right := -1
		for x in range(w - 1, -1, -1):
			if img.get_pixel(x, y).a > 0.15:
				right = x
				break
		if right >= 0:
			lo = minf(lo, float(right))
			hi = maxf(hi, float(right))
			distinct[right] = true
			samples += 1
	if samples < 8 or hi < 0.0:
		return false
	return (hi - lo) >= min_spread_px and distinct.size() >= 3


func rim_crust_has_no_sky_slit() -> bool:
	## Opaque sand crust at the top — no transparent cap that shows sky.
	var img := _rim_source_image()
	if img == null:
		return false
	var w := img.get_width()
	var crust_h := mini(RIM_CRUST_TEX_ROWS, img.get_height())
	for y in range(0, crust_h):
		var lip := -1
		for x in range(w - 1, -1, -1):
			if img.get_pixel(x, y).a > 0.15:
				lip = x
				break
		if lip < 8:
			return false
		var inland := clampi(lip - 8, 0, w - 1)
		for x in range(inland, lip + 1):
			if img.get_pixel(x, y).a < 0.85:
				return false
	return true


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
	rim.texture = _rim_texture
	rim.centered = true
	rim.flip_h = flip
	rim.z_as_relative = true
	rim.z_index = 1
	return rim


func _layout_rims() -> void:
	if _rim_texture == null or _left_rim == null:
		return
	var tex_size := _rim_texture.get_size()
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

	# Place rims OUTSIDE the desert floor gap: outermost sky lip at the bank
	# edge, thin rock face under the trail bank, drawn in front of desert tiles.
	# Bank-side texels are opaque packed dirt so sky/abyss cannot peek through.
	var surface_from_center := (RIM_SURFACE_TEX_Y - tex_size.y * 0.5) * rim_scale.y
	var lip_from_center := (RIM_LIP_TEX_X - tex_size.x * 0.5) * rim_scale.x
	# Flush with the desert top so sand crust and ridge meet with no sky slit.
	var surface_y := left_floor_top
	_left_rim.position = Vector2(gap_left - lip_from_center, surface_y - surface_from_center)
	surface_y = right_floor_top
	_right_rim.position = Vector2(gap_right + lip_from_center, surface_y - surface_from_center)
