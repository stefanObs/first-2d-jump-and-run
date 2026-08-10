class_name WildWestTheme
extends RefCounted

## Applies cheerful hand-drawn wild-west sky, hills, and trail floor art.

## Clear Mesa/backdrop art just past canyon lips so buttes never silhouette
## inside the open mouth column (sky / Background only between the ridges).
## Keep pad modest so bank-side mesas are not hard-clipped far inland of the lip.
const CANYON_BACKDROP_PAD := 40.0
## Match hand-placed campaign cacti (desert top + small sand sink).
const CACTUS_DESERT_SINK := 10.0
const CACTUS_MAX_TILT := 0.22
const CACTUS_TILT_BLEND := 0.35
const CHEST_FOOT_SINK := 0.0
const CHEST_MAX_TILT := 0.12
const CHEST_TILT_BLEND := 0.2


static func desert_sky_color() -> Color:
	return Color(0.58, 0.82, 0.96, 1.0)


static func sand_color() -> Color:
	return Color(0.91, 0.67, 0.37, 1.0)


static func apply_to_level(level: Node) -> void:
	var style := LevelStyle.from_level(level)
	_dress_sky(level, style)
	_dress_cave_ceiling(level, style)
	_dress_sun(level, style)
	_hide_fences(level)
	_make_endless_hills(level, style)
	_dress_platforms(level, style)
	_disable_ground_fill_collision(level)
	_make_contiguous_floors(level, style)
	# Floor tops are final after TrailFloor — pull the cave wash under the crust.
	_retuck_cave_sky_to_floor(level, style)
	_align_cacti(level)
	_align_chests(level)
	_align_ground_foes(level)
	_apply_actor_styles(level, style)
	# After actor styles: Hazard.apply_level_style would otherwise overwrite
	# per-bank ridge tops with a temporary single-height canyon align.
	_align_pits(level)
	_carve_ground_lips_for_canyons(level)


static func _apply_actor_styles(level: Node, style: String) -> void:
	for node in level.find_children("*", "Node", true, false):
		if node.has_method("apply_level_style"):
			node.call("apply_level_style", style)


static func _dress_sky(level: Node, style: String = LevelStyle.DESERT) -> void:
	var background := level.get_node_or_null("Background") as ColorRect
	if background != null:
		background.color = LevelStyle.sky_color(style)
	var sky_band := level.get_node_or_null("SkyBand") as ColorRect
	if sky_band != null:
		sky_band.visible = false

	var existing := level.get_node_or_null("SkyArt") as Node2D
	if existing != null:
		if LevelStyle.is_cave(style):
			_stamp_cave_sky_floor_meta(existing, level)
		return

	var width := _level_width(level)
	var root := Node2D.new()
	root.name = "SkyArt"
	root.z_index = -19
	level.add_child(root)

	var tex: Texture2D = load(LevelStyle.sky_path(style))
	if tex == null:
		root.queue_free()
		return
	# Continuous trail sky — punch only Mesa hills out of canyon columns so the
	# opening does not get a mismatched Background-blue sky seam.
	var sky_y := -520.0
	var sky_h := 700.0
	if LevelStyle.is_cave(style):
		# Drop the cave wash so its bottom tucks under the trail crust — no gap.
		var floor_top := _typical_floor_top(level)
		sky_y = -620.0
		const FLOOR_OVERLAP := 72.0
		sky_h = maxf(floor_top + FLOOR_OVERLAP - sky_y, 400.0)
		# Stretch the solid Background behind the wash so a soft edge can't open a seam.
		if background != null:
			var bg_bottom := background.position.y + background.size.y
			var need_bottom := floor_top + FLOOR_OVERLAP + 40.0
			if bg_bottom < need_bottom:
				background.size.y = need_bottom - background.position.y
	_tile_backdrop(root, tex, "SkyTile", width, sky_y, sky_h, 8.0, Color.WHITE)
	if LevelStyle.is_cave(style):
		_stamp_cave_sky_floor_meta(root, level, sky_y + sky_h)


static func _stamp_cave_sky_floor_meta(
	sky_root: Node2D, level: Node, sky_bottom_override: float = NAN
) -> void:
	var floor_top := _typical_floor_top(level)
	var sky_bottom := sky_bottom_override
	if is_nan(sky_bottom):
		sky_bottom = -INF
		for child in sky_root.get_children():
			if not (child is Sprite2D):
				continue
			if not String(child.name).begins_with("SkyTile"):
				continue
			var spr := child as Sprite2D
			var tex := spr.texture
			if tex == null:
				continue
			sky_bottom = maxf(sky_bottom, spr.position.y + tex.get_size().y * spr.scale.y)
	sky_root.set_meta("sky_bottom_y", sky_bottom)
	sky_root.set_meta("floor_top_y", floor_top)


static func _retuck_cave_sky_to_floor(level: Node, style: String) -> void:
	## After TrailFloor exists, stretch cave wash so it always overlaps the crust.
	if not LevelStyle.is_cave(style):
		return
	var sky := level.get_node_or_null("SkyArt") as Node2D
	if sky == null:
		return
	var floor_top := _typical_floor_top(level)
	const FLOOR_OVERLAP := 96.0
	var want_bottom := floor_top + FLOOR_OVERLAP
	var sky_y := INF
	for child in sky.get_children():
		if child is Sprite2D and String(child.name).begins_with("SkyTile"):
			sky_y = minf(sky_y, (child as Sprite2D).position.y)
	if sky_y == INF:
		sky_y = -620.0
	var want_h := maxf(want_bottom - sky_y, 400.0)
	for child in sky.get_children():
		if not (child is Sprite2D):
			continue
		if not String(child.name).begins_with("SkyTile"):
			continue
		var spr := child as Sprite2D
		var tex := spr.texture
		if tex == null:
			continue
		var tex_h := tex.get_size().y
		if tex_h <= 0.0:
			continue
		spr.position.y = sky_y
		spr.scale.y = want_h / tex_h
	var background := level.get_node_or_null("Background") as ColorRect
	if background != null:
		var need_bottom := want_bottom + 40.0
		if background.position.y + background.size.y < need_bottom:
			background.size.y = need_bottom - background.position.y
	_stamp_cave_sky_floor_meta(sky, level, want_bottom)


static func _dress_cave_ceiling(level: Node, style: String = LevelStyle.DESERT) -> void:
	## Cowboy-style rock panels with fixed low/high side heights. Adjacent panels
	## only pair when the shared edge heights match. Fill stays above segment tops.
	## Stalactites fuse into seats until their release animation starts.
	if not LevelStyle.is_cave(style):
		return
	if level.get_node_or_null("CaveCeiling") != null:
		return
	var catalog := _load_ceiling_segment_catalog(style)
	if catalog.is_empty():
		return
	var segments: Array = catalog.get("segments", [])
	if segments.is_empty():
		return
	var fill_path := LevelStyle.ceiling_fill_path(style)
	var fill_tex: Texture2D = null
	if not fill_path.is_empty() and ResourceLoader.exists(fill_path):
		fill_tex = load(fill_path)
	var width := _level_width(level)
	var root := Node2D.new()
	root.name = "CaveCeiling"
	root.z_index = -17
	level.add_child(root)

	const CAMERA_TOP := -280.0
	const SEGMENT_TOP := -168.0
	var fill_top := CAMERA_TOP - 100.0

	if fill_tex != null:
		_tile_strip_row(
			root,
			fill_tex,
			-200.0,
			width + 200.0,
			fill_top,
			maxf(8.0, SEGMENT_TOP - fill_top),
			0,
			"CeilingFill"
		)

	var by_start: Dictionary = catalog.get("by_start", {})
	var attach_points: Array = []
	var min_underside := INF
	var max_underside := SEGMENT_TOP
	var x := -200.0
	var seg_i := 0
	var overlap := 8.0
	var need_start := "low"
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	while x < width + 200.0:
		var entry := _pick_ceiling_segment(segments, by_start, need_start, rng)
		if entry.is_empty():
			break
		var file_name := str(entry.get("file", ""))
		var path := "res://assets/world/%s" % file_name
		if file_name.is_empty() or not ResourceLoader.exists(path):
			break
		var tex: Texture2D = load(path)
		if tex == null:
			break
		var sprite := Sprite2D.new()
		sprite.name = "CeilingRock_%d" % seg_i
		sprite.texture = tex
		sprite.centered = false
		sprite.position = Vector2(x, SEGMENT_TOP)
		sprite.z_index = 1
		sprite.set_meta("start", str(entry.get("start", "low")))
		sprite.set_meta("end", str(entry.get("end", "low")))
		root.add_child(sprite)
		var seats: Array = entry.get("attach", [])
		for seat_v in seats:
			if not (seat_v is Dictionary):
				continue
			var seat := seat_v as Dictionary
			var ax := x + float(seat.get("x", 0.0))
			var ay := SEGMENT_TOP + float(seat.get("y", 120.0))
			attach_points.append({"x": ax, "y": ay})
			min_underside = minf(min_underside, ay)
			max_underside = maxf(max_underside, ay)
		need_start = str(entry.get("end", need_start))
		x += float(tex.get_width()) - overlap
		seg_i += 1
		if seg_i > 400:
			break

	if attach_points.is_empty():
		min_underside = SEGMENT_TOP + float(catalog.get("low_y", 108.0))
		max_underside = SEGMENT_TOP + float(catalog.get("high_y", 156.0))
	var mid_underside := (min_underside + max_underside) * 0.5
	root.set_meta("underside_y", mid_underside)
	root.set_meta("attach_points", attach_points)
	root.set_meta("segment_top_y", SEGMENT_TOP)
	_add_cave_flight_ceiling(root, width, fill_top, max_underside + 6.0)
	_snap_ceiling_hangings(level, attach_points, mid_underside)

	if _is_dragon_cave_level(level):
		return

	var existing: Array = level.find_children("*", "StalactiteHazard", true, false)
	var index := 0
	var last_x := -9999.0
	for i in range(attach_points.size()):
		var seat: Dictionary = attach_points[i]
		var sx := float(seat.get("x", 0.0))
		var sy := float(seat.get("y", mid_underside))
		if sx < 120.0 or sx > width - 80.0:
			continue
		if sx - last_x < 280.0:
			continue
		var too_close := false
		for node in existing:
			if absf((node as Node2D).global_position.x - sx) < 120.0:
				too_close = true
				break
		if too_close:
			continue
		var spike := StalactiteHazard.new()
		spike.name = "CeilingStalactite%d" % index
		# Mix droppable teeth with shorter fake décor so the lip stays varied.
		spike.drops = (index % 3) != 1
		spike.fuse_with_ceiling = true
		# Sit on the shelf; fused look covers the painted nub until release.
		spike.position = Vector2(sx, sy - 2.0)
		spike.z_index = 1
		root.add_child(spike)
		var scale := randf_range(0.92, 1.06) if spike.drops else randf_range(0.78, 0.92)
		var spr := spike.get_node_or_null("Sprite2D") as Sprite2D
		if spr != null:
			spr.scale = Vector2(scale, scale)
		existing.append(spike)
		last_x = sx
		index += 1
		if index > 16:
			break


static func _pick_ceiling_segment(
	segments: Array, by_start: Dictionary, need_start: String, rng: RandomNumberGenerator
) -> Dictionary:
	var indices: Array = by_start.get(need_start, [])
	if indices.is_empty():
		# Fallback: any segment that happens to start correctly.
		for entry_v in segments:
			if entry_v is Dictionary and str((entry_v as Dictionary).get("start", "")) == need_start:
				return entry_v as Dictionary
		return segments[0] as Dictionary if segments[0] is Dictionary else {}
	var pick: int = int(indices[rng.randi_range(0, indices.size() - 1)])
	if pick < 0 or pick >= segments.size():
		return {}
	var chosen: Variant = segments[pick]
	return chosen as Dictionary if chosen is Dictionary else {}


static func _load_ceiling_segment_catalog(style: String) -> Dictionary:
	var path := LevelStyle.ceiling_segments_catalog_path(style)
	if path.is_empty() or not ResourceLoader.exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}


static func _snap_ceiling_hangings(level: Node, attach_points: Array, fallback_y: float) -> void:
	## Snap stamped hangings onto the nearest ceiling attach seat.
	for node in level.find_children("*", "StalactiteHazard", true, false):
		var spike := node as StalactiteHazard
		if spike.get_parent() != null and String(spike.get_parent().name) == "CaveCeiling":
			continue
		spike.fuse_with_ceiling = true
		spike.global_position.y = _nearest_ceiling_attach_y(attach_points, spike.global_position.x, fallback_y) - 6.0
		spike.call("_apply_hang_look", true)
		if spike.has_method("sync_ceiling_origin"):
			spike.call("sync_ceiling_origin")
	for node in level.find_children("*", "AcidDrip", true, false):
		var drip := node as Node2D
		drip.global_position.y = _nearest_ceiling_attach_y(attach_points, drip.global_position.x, fallback_y) + 2.0
		if drip.has_method("sync_ceiling_origin"):
			drip.call("sync_ceiling_origin")


static func _nearest_ceiling_attach_y(attach_points: Array, world_x: float, fallback_y: float) -> float:
	if attach_points.is_empty():
		return fallback_y
	var best_y := fallback_y
	var best_d := INF
	for seat_v in attach_points:
		if not (seat_v is Dictionary):
			continue
		var seat := seat_v as Dictionary
		var d := absf(float(seat.get("x", 0.0)) - world_x)
		if d < best_d:
			best_d = d
			best_y = float(seat.get("y", fallback_y))
	return best_y


static func _is_dragon_cave_level(level: Node) -> bool:
	if level is BossArena and int(level.get("source_level")) == 16:
		return true
	var level_number := int(level.get("level_number"))
	var campaign_source := int(level.get("campaign_source_level"))
	var source := campaign_source if campaign_source > 0 else level_number
	return source == 16 or level_number == 16


static func _add_cave_flight_ceiling(
	root: Node2D, width: float, ceiling_y: float, underside: float
) -> void:
	## Solid band so Wings cannot leave through the rock; Area2D respawns on touch.
	var solid := StaticBody2D.new()
	solid.name = "FlightCeilingCave"
	solid.collision_layer = 1
	solid.collision_mask = 0
	solid.position = Vector2(width * 0.5, (ceiling_y + underside) * 0.5)
	var solid_shape := CollisionShape2D.new()
	var solid_rect := RectangleShape2D.new()
	solid_rect.size = Vector2(width + 400.0, maxf(underside - ceiling_y, 40.0))
	solid_shape.shape = solid_rect
	solid.add_child(solid_shape)
	root.add_child(solid)

	var hazard := CaveCeilingHazard.new()
	hazard.name = "CaveCeilingHazard"
	hazard.position = Vector2(width * 0.5, underside - 8.0)
	var hurt_shape := CollisionShape2D.new()
	var hurt_rect := RectangleShape2D.new()
	hurt_rect.size = Vector2(width + 400.0, 36.0)
	hurt_shape.shape = hurt_rect
	hazard.add_child(hurt_shape)
	root.add_child(hazard)

static func _dress_sun(level: Node, style: String = LevelStyle.DESERT) -> void:
	var sun := level.get_node_or_null("Sun") as ColorRect
	if sun == null:
		return
	sun.visible = false
	if LevelStyle.is_cave(style):
		return
	if level.get_node_or_null("SunArt") != null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "SunArt"
	sprite.texture = load("res://assets/world/sun.png")
	sprite.centered = true
	sprite.position = sun.position + sun.size * 0.5 + Vector2(0, 20)
	sprite.z_index = sun.z_index
	level.add_child(sprite)


static func _hide_fences(level: Node) -> void:
	## Hide legacy ColorRect fence placeholders from desert scene templates.
	## Keep stamped FenceDecor sprites (and any Sprite2D FenceArt) visible.
	for node in level.find_children("*", "ColorRect", true, false):
		var name_text := String(node.name)
		if name_text.begins_with("Fence") or name_text.begins_with("FenceArt"):
			(node as CanvasItem).visible = false


static func _make_endless_hills(level: Node, style: String = LevelStyle.DESERT) -> void:
	for node in level.find_children("*", "CanvasItem", true, false):
		var name_text := String(node.name)
		if name_text.begins_with("Mesa"):
			(node as CanvasItem).visible = false

	if LevelStyle.is_cave(style):
		return
	if level.get_node_or_null("HorizonHills") != null:
		return

	var width := _level_width(level)
	var floor_top := _typical_floor_top(level)
	var root := Node2D.new()
	root.name = "HorizonHills"
	root.z_index = -16
	level.add_child(root)

	var tex: Texture2D = load("res://assets/world/horizon_hills_strip.png")
	if tex == null:
		return
	var hill_y := floor_top - 520.0 + 10.0
	# Tile hills only beside canyon mouths so Background sky shows through the
	# gaps — pad far enough that Mesa buttes never sit in the opening column.
	var gaps := _canyon_gap_ranges(level)
	var spans := _spans_excluding_gaps(-500.0, width + 600.0, gaps, CANYON_BACKDROP_PAD)
	var index := 0
	for span in spans:
		index = _tile_backdrop_span(
			root,
			tex,
			"HillTile",
			float(span["left"]),
			float(span["right"]),
			hill_y,
			520.0,
			220.0,
			Color(1, 1, 1, 0.98),
			index
		)
	# Marker nodes so tests can confirm mouths open to sky (no mountain cover).
	for i in range(gaps.size()):
		var marker := Node2D.new()
		marker.name = "CanyonSkyGap%d" % i
		marker.position = Vector2((gaps[i].x + gaps[i].y) * 0.5, hill_y)
		root.add_child(marker)


static func _canyon_gap_ranges(level: Node) -> Array[Vector2]:
	var gaps: Array[Vector2] = []
	var merged := _cached_merged_segments(level)
	for i in range(merged.size() - 1):
		var left := float(merged[i]["right"])
		var right := float(merged[i + 1]["left"])
		if right - left > 8.0:
			gaps.append(Vector2(left, right))
	return gaps


static func _spans_excluding_gaps(
	span_left: float,
	span_right: float,
	gaps: Array[Vector2],
	pad: float
) -> Array[Dictionary]:
	var cuts: Array[Vector2] = []
	for gap in gaps:
		var left := gap.x - pad
		var right := gap.y + pad
		if right <= span_left or left >= span_right:
			continue
		cuts.append(Vector2(maxf(left, span_left), minf(right, span_right)))
	cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var spans: Array[Dictionary] = []
	var cursor := span_left
	for cut in cuts:
		if cut.x > cursor + 1.0:
			spans.append({"left": cursor, "right": cut.x})
		cursor = maxf(cursor, cut.y)
	if span_right > cursor + 1.0:
		spans.append({"left": cursor, "right": span_right})
	return spans


static func _tile_backdrop(
	parent: Node,
	tex: Texture2D,
	name_prefix: String,
	level_width: float,
	y: float,
	tile_h: float,
	overlap: float,
	modulate: Color
) -> void:
	_tile_backdrop_span(
		parent, tex, name_prefix, -500.0, level_width + 600.0, y, tile_h, overlap, modulate, 0
	)


static func _tile_backdrop_span(
	parent: Node,
	tex: Texture2D,
	name_prefix: String,
	span_left: float,
	span_right: float,
	y: float,
	tile_h: float,
	overlap: float,
	modulate: Color,
	start_index: int
) -> int:
	var tex_size := tex.get_size()
	var tile_w := tex_size.x * 1.35
	# Keep world-aligned tiling so spans share the same UV phase as a full strip.
	var step := tile_w - overlap
	var x := -500.0
	while x + tile_w <= span_left:
		x += step
	var index := start_index
	while x < span_right - 0.5:
		var draw_left := maxf(x, span_left)
		var draw_right := minf(x + tile_w, span_right)
		if draw_right - draw_left > 1.0:
			var sprite := Sprite2D.new()
			sprite.name = "%s%d" % [name_prefix, index]
			sprite.texture = tex
			sprite.centered = false
			sprite.position = Vector2(draw_left, y)
			var use_w := draw_right - draw_left
			# Region-crop when the span clips a tile so UVs stay aligned.
			if absf(use_w - tile_w) > 0.5:
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				var u0 := (draw_left - x) / tile_w * tex_size.x
				var uw := use_w / tile_w * tex_size.x
				atlas.region = Rect2(u0, 0.0, uw, tex_size.y)
				sprite.texture = atlas
				sprite.scale = Vector2(use_w / maxf(uw, 1.0), tile_h / tex_size.y)
			else:
				sprite.scale = Vector2(tile_w / tex_size.x, tile_h / tex_size.y)
			sprite.modulate = modulate
			parent.add_child(sprite)
			index += 1
		x += step
		if index > 400:
			break
	return index


static func _dress_platforms(level: Node, style: String = LevelStyle.DESERT) -> void:
	var plank_path := LevelStyle.plank_path(style)
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		var parent_name := String(node.name)
		if (
			parent_name.begins_with("Platform")
			or parent_name.begins_with("SpringLedge")
			or parent_name.begins_with("JumpPlank")
			or parent_name.begins_with("BoostPlank")
			or parent_name.begins_with("WindLedge")
			or parent_name.begins_with("StarPlatform")
			or parent_name.begins_with("High")
			or parent_name.begins_with("FerryStep")
			or parent_name.begins_with("FerryIsle")
			or parent_name.begins_with("PlankStep")
			or parent_name.begins_with("PlankIsle")
			or parent_name.contains("Ledge")
			or parent_name.begins_with("Boots")
		):
			_replace_block_art(node, plank_path)


static func _make_contiguous_floors(level: Node, style: String = LevelStyle.DESERT) -> void:
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if not String(node.name).begins_with("Ground"):
			continue
		for child_name in ["Visual", "TopStripe", "DirtEdge", "Nail", "HandArt"]:
			var child := node.get_node_or_null(child_name) as CanvasItem
			if child != null:
				child.visible = false

	if level.get_node_or_null("TrailFloor") != null:
		return

	var segments := _collect_ground_segments(level)
	if segments.is_empty():
		return
	var merged := _merge_segments(segments)
	var bank_bounds: Array[Dictionary] = []
	for strip in merged:
		bank_bounds.append(strip.duplicate())

	var floor_root := Node2D.new()
	floor_root.name = "TrailFloor"
	floor_root.z_index = 0
	level.add_child(floor_root)

	var surface: Texture2D = load(LevelStyle.floor_path(style))
	var dirt: Texture2D = load(LevelStyle.dirt_path(style))
	if dirt == null:
		dirt = load("res://assets/world/trail_dirt_strip.png")
	if surface == null:
		surface = load("res://assets/world/trail_floor_strip.png")

	var level_left := -480.0
	var level_right := _level_width(level) + 480.0
	var background := level.get_node_or_null("Background") as ColorRect
	if background != null:
		level_left = minf(background.offset_left, background.offset_right)
		level_right = maxf(background.offset_left, background.offset_right)
	# Stretch first/last walkable strips to the level edges.
	if not merged.is_empty():
		merged[0]["left"] = minf(float(merged[0]["left"]), level_left)
		merged[merged.size() - 1]["right"] = maxf(
			float(merged[merged.size() - 1]["right"]),
			level_right
		)

	# Deep underworld fill only under dirt banks — never across canyon mouths —
	# so the real Background sky shows through the gap (no blue fill column).
	# Painted per strip below with the same slope/canyon insets as FloorDirt.

	# Lip inset: desert sand crust stops at the inland edge of the ridge face so
	# FloorSurface never paints over the cliff. Dirt/abyss stay under the opaque
	# bank (not in the sky gap past the ridge lip). Keep this modest — collision
	# is carved by the same amount in `_carve_ground_lips_for_canyons` so feet
	# cannot rest on the blue sky band without bloating jump gaps.
	const CANYON_SURFACE_INSET := 12.0
	const CANYON_DIRT_INSET := 10.0

	for i in range(merged.size()):
		var strip: Dictionary = merged[i]
		var left := float(strip["left"])
		var right := float(strip["right"])
		var top := float(strip["top"])
		var bottom := float(strip["bottom"])
		var height := bottom - top
		var deep_bottom := top + 1200.0
		# Keep a thin desert crust on top; tall stacked banks stay dirt underneath.
		var surface_thickness := minf(maxf(height, 36.0), 56.0)

		var surface_left := left
		var surface_right := right
		var dirt_left := left
		var dirt_right := right
		var abyss_left := left
		var abyss_right := right
		# Only inset at true canyon lips — continuous height steps stay flush.
		if i + 1 < merged.size() and _is_canyon_between(merged[i], merged[i + 1]):
			surface_right = minf(surface_right, right - CANYON_SURFACE_INSET)
			dirt_right = minf(dirt_right, right - CANYON_DIRT_INSET)
			abyss_right = minf(abyss_right, right - CANYON_DIRT_INSET)
		if i > 0 and _is_canyon_between(merged[i - 1], merged[i]):
			surface_left = maxf(surface_left, left + CANYON_SURFACE_INSET)
			dirt_left = maxf(dirt_left, left + CANYON_DIRT_INSET)
			abyss_left = maxf(abyss_left, left + CANYON_DIRT_INSET)
		# Leave the dune column to slope art — flat bank fills must not spill over it.
		if i + 1 < merged.size() and not _is_canyon_between(merged[i], merged[i + 1]):
			var slope_to_right := _slope_span(bank_bounds[i], bank_bounds[i + 1])
			if not slope_to_right.is_empty():
				var x_start := float(slope_to_right["x_start"])
				surface_right = minf(surface_right, x_start)
				dirt_right = minf(dirt_right, x_start)
				abyss_right = minf(abyss_right, x_start)
		if i > 0 and not _is_canyon_between(merged[i - 1], merged[i]):
			var slope_from_left := _slope_span(bank_bounds[i - 1], bank_bounds[i])
			if not slope_from_left.is_empty():
				var x_end := float(slope_from_left["x_end"])
				surface_left = maxf(surface_left, x_end)
				dirt_left = maxf(dirt_left, x_end)
				abyss_left = maxf(abyss_left, x_end)

		# Underworld fill — same horizontal clip as dirt so earth never spills over dunes.
		if abyss_right > abyss_left + 1.0:
			var abyss_name := "FloorAbyss%d" % i if i > 0 else "FloorAbyss"
			_paint_abyss_rect(
				floor_root,
				abyss_left,
				top,
				abyss_right - abyss_left,
				1200.0,
				abyss_name,
				style
			)

		# Surface row only — never overhang into canyon gaps.
		if surface != null and surface_right > surface_left + 1.0:
			_tile_strip_row(
				floor_root,
				surface,
				surface_left,
				surface_right,
				top,
				surface_thickness,
				1,
				"FloorSurface%d" % i
			)

		# Below: continue brown dirt under the bank almost to the canyon lip —
		# the thin transparent-bank rim face draws on top at the edge.
		if dirt != null:
			var dirt_h := dirt.get_size().y * (surface_thickness / maxf(dirt.get_size().y, 1.0))
			var y := top + surface_thickness - 2.0
			var row := 0
			while y < deep_bottom - 1.0:
				_tile_strip_row(floor_root, dirt, dirt_left, dirt_right, y, dirt_h, 0, "FloorDirt%d_%d" % [i, row])
				y += dirt_h - 2.0
				row += 1
				if row > 40:
					break

		# Soft desert slopes only for continuous height steps (no canyon between).
		if i + 1 < merged.size() and not _is_canyon_between(merged[i], merged[i + 1]):
			_draw_bank_slope(floor_root, surface, dirt, bank_bounds[i], bank_bounds[i + 1], i, style)


static func _is_canyon_between(left_strip: Dictionary, right_strip: Dictionary) -> bool:
	## Same threshold as canyon gap detection — canyon is the height transition.
	return float(right_strip["left"]) - float(left_strip["right"]) > 8.0


static func _paint_abyss_rect(
	parent: Node,
	left: float,
	top: float,
	width: float,
	height: float,
	node_name: String,
	style: String = LevelStyle.DESERT
) -> void:
	var abyss := Polygon2D.new()
	abyss.name = node_name
	abyss.color = _earth_underfill_color(style)
	abyss.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(width, 0.0),
		Vector2(width, height),
		Vector2(0.0, height),
	])
	abyss.position = Vector2(left, top)
	abyss.z_index = -2
	parent.add_child(abyss)


static func _earth_underfill_color(style: String = LevelStyle.DESERT) -> Color:
	## Readable packed earth under banks/slopes — never near-black voids.
	if LevelStyle.is_cave(style):
		return Color(0.30, 0.24, 0.34, 1.0)
	return Color(0.42, 0.22, 0.14, 1.0)


## Per-frame cache so many callers (ninjas, loot align, layout) share one ground scan.
static var _merged_cache_id: int = 0
static var _merged_cache_frame: int = -1
static var _merged_cache: Array[Dictionary] = []
## Test counter: how often `_collect_ground_segments` rebuilt the map.
static var ground_collect_calls: int = 0


static func invalidate_walk_surface_cache() -> void:
	_merged_cache_id = 0
	_merged_cache_frame = -1
	_merged_cache.clear()


static func _cached_merged_segments(level: Node) -> Array[Dictionary]:
	if level == null:
		return []
	var id := level.get_instance_id()
	var frame := Engine.get_process_frames()
	if id == _merged_cache_id and frame == _merged_cache_frame:
		return _merged_cache
	_merged_cache = _merge_segments(_collect_ground_segments(level))
	_merged_cache_id = id
	_merged_cache_frame = frame
	return _merged_cache


static func walk_surface_at(level: Node, world_x: float) -> Dictionary:
	## Walkable desert top Y and tangent angle (radians) at world X.
	var merged := _cached_merged_segments(level)
	if merged.is_empty():
		return {"y": 320.0, "angle": 0.0}
	for index in range(merged.size() - 1):
		if _is_canyon_between(merged[index], merged[index + 1]):
			continue
		var span := _slope_span(merged[index], merged[index + 1])
		if span.is_empty():
			continue
		var x_start := float(span["x_start"])
		var x_end := float(span["x_end"])
		if world_x < x_start - 0.5 or world_x > x_end + 0.5:
			continue
		var curved := bool(span.get("curved", true))
		var y_start := float(span["y_start"])
		var y_end := float(span["y_end"])
		return {
			"y": _slope_y_at(world_x, x_start, y_start, x_end, y_end, curved),
			"angle": _slope_tangent_angle(world_x, x_start, y_start, x_end, y_end, curved),
		}
	for strip in merged:
		if world_x >= float(strip["left"]) - 0.5 and world_x <= float(strip["right"]) + 0.5:
			return {"y": float(strip["top"]), "angle": 0.0}
	var best_dist := INF
	var best_y := float(merged[0]["top"])
	for strip in merged:
		var mid := (float(strip["left"]) + float(strip["right"])) * 0.5
		var dist := absf(mid - world_x)
		if dist < best_dist:
			best_dist = dist
			best_y = float(strip["top"])
	return {"y": best_y, "angle": 0.0}


static func _slope_span(left_strip: Dictionary, right_strip: Dictionary) -> Dictionary:
	var left_top := float(left_strip["top"])
	var right_top := float(right_strip["top"])
	var step := absf(left_top - right_top)
	if step < 10.0:
		return {}
	if _is_canyon_between(left_strip, right_strip):
		return {}
	# Kid-walkable dune: keep peak grade under ~floor_max_angle (45°).
	# Smoothstep peaks at ~1.5× average grade, so run ≈ 6.5× rise (and ≥160px).
	var min_run := clampf(maxf(step * 6.5, step / tan(0.55)), 160.0, 420.0)
	# Stay inside these two banks only — never spill into a neighboring canyon.
	var bank_left := float(left_strip["left"]) + 4.0
	var bank_right := float(right_strip["right"]) - 4.0
	var avail := maxf(bank_right - bank_left, 40.0)
	var run := minf(min_run, avail)
	const BANK_OVERLAP := 20.0
	var rising_right := left_top > right_top
	var x_start: float
	var x_end: float
	var y_start := left_top
	var y_end := right_top
	if rising_right:
		# Climb onto the higher right bank; prefer ending on the high lip.
		x_end = clampf(float(right_strip["left"]) + BANK_OVERLAP, bank_left + 20.0, bank_right)
		x_start = clampf(x_end - run, bank_left, x_end - 40.0)
		x_end = minf(x_start + run, bank_right)
	else:
		# Descend from the higher left bank.
		x_start = clampf(float(left_strip["right"]) - BANK_OVERLAP, bank_left, bank_right - 20.0)
		x_end = clampf(x_start + run, x_start + 40.0, bank_right)
		x_start = maxf(x_end - run, bank_left)
	# Final guard: keep the dune strictly between these banks.
	x_start = clampf(x_start, bank_left, bank_right - 40.0)
	x_end = clampf(x_end, x_start + 40.0, bank_right)
	if x_end - x_start < 40.0:
		return {}
	# When the banks are too short for a full smoothstep dune, use a linear
	# collision grade (lower peak angle) so kids can still walk it.
	var curved := (x_end - x_start) >= min_run * 0.85
	return {
		"x_start": x_start,
		"y_start": y_start,
		"x_end": x_end,
		"y_end": y_end,
		"curved": curved,
	}


static func _draw_bank_slope(
	parent: Node,
	surface: Texture2D,
	dirt: Texture2D,
	left_strip: Dictionary,
	right_strip: Dictionary,
	index: int,
	style: String = LevelStyle.DESERT
) -> void:
	var span := _slope_span(left_strip, right_strip)
	if span.is_empty():
		return
	var x_start := float(span["x_start"])
	var y_start := float(span["y_start"])
	var x_end := float(span["x_end"])
	var y_end := float(span["y_end"])
	var curved := bool(span.get("curved", true))

	_paint_slope_underfill(parent, x_start, y_start, x_end, y_end, index, curved, style)
	_paint_slope_fill(parent, dirt, x_start, y_start, x_end, y_end, index, curved, style)
	_paint_slope_crust(parent, surface, x_start, y_start, x_end, y_end, index, curved)
	_add_slope_collision(parent, x_start, y_start, x_end, y_end, index, curved)
	# Remove the vertical cliff faces of Ground* boxes so the dune is walkable.
	var level := parent.get_parent()
	if level != null:
		_carve_ground_walls_for_slope(level, x_start, y_start, x_end, y_end)


static func _carve_ground_walls_for_slope(
	level: Node,
	x_start: float,
	y_start: float,
	x_end: float,
	y_end: float
) -> void:
	## Remove Ground boxes from the dune bridge column so FloorSlopeBody is the only
	## walk surface — leftover vertical cliff faces blocked continuous slope walking.
	const BANK_EXTEND := 56.0
	var bridge_left := minf(x_start, x_end) - BANK_EXTEND
	var bridge_right := maxf(x_start, x_end) + BANK_EXTEND
	var high_y := minf(y_start, y_end)
	var low_y := maxf(y_start, y_end)
	for node in level.find_children("Ground*", "StaticBody2D", true, false):
		if String(node.name).ends_with("Fill"):
			continue
		var body := node as StaticBody2D
		if body == null:
			continue
		var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node == null or not (shape_node.shape is RectangleShape2D):
			continue
		var rect := (shape_node.shape as RectangleShape2D).duplicate() as RectangleShape2D
		var center := shape_node.global_position
		var half := rect.size * 0.5
		var left := center.x - half.x
		var right := center.x + half.x
		var top := center.y - half.y
		if right < bridge_left or left > bridge_right:
			continue
		var on_high := absf(top - high_y) <= 18.0
		var on_low := absf(top - low_y) <= 18.0
		if not on_high and not on_low:
			continue
		if left >= bridge_left - 1.0 and right <= bridge_right + 1.0:
			shape_node.disabled = true
			continue
		var new_left := left
		var new_right := right
		if right > bridge_left and left < bridge_left:
			new_right = minf(new_right, bridge_left)
		if left < bridge_right and right > bridge_right:
			new_left = maxf(new_left, bridge_right)
		var new_w := new_right - new_left
		if new_w < 24.0:
			shape_node.disabled = true
			continue
		if is_equal_approx(new_left, left) and is_equal_approx(new_right, right):
			continue
		rect.size = Vector2(new_w, rect.size.y)
		shape_node.shape = rect
		var new_center := Vector2((new_left + new_right) * 0.5, center.y)
		shape_node.global_position = new_center


static func _slope_ease(t: float) -> float:
	## Smoothstep — flat derivative at both desert ends (gentle dune, not a ramp lip).
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func _slope_y_at(
	x: float, x0: float, y0: float, x1: float, y1: float, curved: bool = true
) -> float:
	var span := x1 - x0
	if absf(span) < 0.1:
		return y0
	var t := (x - x0) / span
	if curved:
		return lerpf(y0, y1, _slope_ease(t))
	return lerpf(y0, y1, clampf(t, 0.0, 1.0))


static func _slope_tangent_angle(
	x: float, x0: float, y0: float, x1: float, y1: float, curved: bool = true
) -> float:
	var span := x1 - x0
	if absf(span) < 0.1:
		return 0.0
	var t := clampf((x - x0) / span, 0.0, 1.0)
	var dy_dx: float
	if curved:
		var d_ease := 6.0 * t * (1.0 - t)
		dy_dx = ((y1 - y0) / span) * d_ease
	else:
		dy_dx = (y1 - y0) / span
	return atan(dy_dx)


static func _paint_slope_crust(
	parent: Node,
	surface: Texture2D,
	x_start: float,
	y_start: float,
	x_end: float,
	y_end: float,
	index: int,
	curved: bool = true
) -> void:
	if surface == null:
		return
	var length := maxf(absf(x_end - x_start), 1.0)
	var tex_size := surface.get_size()
	# Match flat FloorSurface thickness so ends seam with the desert crust.
	var crust_h := 48.0
	var scale_y := crust_h / tex_size.y
	var tile_w := tex_size.x * scale_y * 0.92
	var along := 0.0
	var tile_i := 0
	while along < length - 1.0:
		var use := minf(tile_w, length - along)
		var x := lerpf(x_start, x_end, (along + use * 0.5) / length)
		var y := _slope_y_at(x, x_start, y_start, x_end, y_end, curved)
		var angle := _slope_tangent_angle(x, x_start, y_start, x_end, y_end, curved)
		var into_ground := Vector2(-sin(angle), cos(angle))
		var sprite := Sprite2D.new()
		sprite.name = "FloorSlope%d_%d" % [index, tile_i]
		sprite.texture = surface
		sprite.centered = true
		sprite.position = Vector2(x, y) + into_ground * (crust_h * 0.5)
		sprite.rotation = angle
		sprite.scale = Vector2(use / tex_size.x, scale_y)
		sprite.z_index = 3
		parent.add_child(sprite)
		along += use * 0.7
		tile_i += 1
		if tile_i > 60:
			break


static func _paint_slope_underfill(
	parent: Node,
	x_start: float,
	y_start: float,
	x_end: float,
	y_end: float,
	index: int,
	curved: bool = true,
	style: String = LevelStyle.DESERT
) -> void:
	## Solid earth wedge under the dune face — flat FloorAbyss is clipped away here and
	## tiled dirt alone leaves sky gaps under the curved crust. Keep the top of this
	## wedge tight under the crust (not inset by a large pad). Extend far below so
	## camera pans never show a black void under the bank.
	const SAMPLES := 24
	const CRUST_PAD := 3.0
	const DEPTH := 1200.0
	var bottom_y := maxf(y_start, y_end) + DEPTH
	var poly: PackedVector2Array = []
	for i in range(SAMPLES + 1):
		var t := float(i) / float(SAMPLES)
		var x := lerpf(x_start, x_end, t)
		var y := _slope_y_at(x, x_start, y_start, x_end, y_end, curved) + CRUST_PAD
		poly.append(Vector2(x, y))
	poly.append(Vector2(x_end, bottom_y))
	poly.append(Vector2(x_start, bottom_y))
	var underfill := Polygon2D.new()
	underfill.name = "FloorSlopeUnderfill%d" % index
	underfill.color = _earth_underfill_color(style)
	underfill.polygon = poly
	underfill.z_index = 1
	parent.add_child(underfill)


static func _paint_slope_fill(
	parent: Node,
	dirt: Texture2D,
	x_start: float,
	y_start: float,
	x_end: float,
	y_end: float,
	index: int,
	curved: bool = true,
	style: String = LevelStyle.DESERT
) -> void:
	## Dirt under the curved sand crust so the bank reads as one soft dune, not a cliff.
	## Pack the upper wedge densely — empty bands under the crust read as sky/black gaps.
	## Keep tiling deep so far-below views stay earth, not a flat black void.
	var x0 := minf(x_start, x_end)
	var x1 := maxf(x_start, x_end)
	var deep := maxf(y_start, y_end) + 1200.0
	var bank_top := minf(y_start, y_end)
	var dirt_modulate := (
		Color(0.92, 0.88, 0.96, 1.0) if LevelStyle.is_cave(style) else Color(0.96, 0.9, 0.82, 1.0)
	)
	if dirt != null:
		var tex_size := dirt.get_size()
		var row_h_full := 28.0
		var row_h_small := row_h_full / 3.0
		var row_h_micro := row_h_full / 5.0
		var y := bank_top + 2.0
		var row := 0
		while y < deep:
			var near_crust := y < bank_top + 90.0
			var upper_wedge := y < bank_top + 48.0
			var row_h := row_h_full
			if upper_wedge:
				row_h = row_h_micro
			elif near_crust:
				row_h = row_h_small
			var scale_y := row_h / tex_size.y
			var tile_w := tex_size.x * scale_y
			var step_factor := 0.88 if upper_wedge else (0.95 if near_crust else 0.92)
			var x := x0
			var tile_i := 0
			while x < x1 - 0.5:
				var surface_y: float = _slope_y_at(
					x + tile_w * 0.5, x_start, y_start, x_end, y_end, curved
				)
				# Stay just under the crust — do not leave a sky band.
				if y < surface_y + 2.0:
					x += tile_w * step_factor
					continue
				var use_w := minf(tile_w, x1 - x)
				var sprite := Sprite2D.new()
				sprite.name = "FloorSlopeDirt%d_%d_%d" % [index, row, tile_i]
				sprite.texture = dirt
				sprite.centered = false
				sprite.position = Vector2(x, y)
				sprite.scale = Vector2(use_w / tex_size.x, scale_y)
				sprite.z_index = 2
				sprite.modulate = dirt_modulate
				parent.add_child(sprite)
				x += use_w * step_factor
				tile_i += 1
				if tile_i > 120:
					break
			y += row_h * (0.72 if upper_wedge else (0.82 if near_crust else 0.9))
			row += 1
			if row > 200:
				break


static func _add_slope_collision(
	parent: Node,
	x_start: float,
	y_start: float,
	x_end: float,
	y_end: float,
	index: int,
	curved: bool = true
) -> void:
	var body := StaticBody2D.new()
	body.name = "FloorSlopeBody%d" % index
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionPolygon2D.new()
	col.name = "CollisionPolygon2D"
	var thick := 34.0
	var samples := 10
	var top_pts: PackedVector2Array = []
	var bottom_pts: PackedVector2Array = []
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var x := lerpf(x_start, x_end, t)
		var y := _slope_y_at(x, x_start, y_start, x_end, y_end, curved)
		top_pts.append(Vector2(x, y))
		bottom_pts.append(Vector2(x, y + thick))
	# Continue the walk surface onto both flat bank lips so the crest/base seams stay walkable.
	const BANK_EXTEND := 56.0
	top_pts.insert(0, Vector2(x_start - BANK_EXTEND, y_start))
	bottom_pts.insert(0, Vector2(x_start - BANK_EXTEND, y_start + thick))
	top_pts.append(Vector2(x_end + BANK_EXTEND, y_end))
	bottom_pts.append(Vector2(x_end + BANK_EXTEND, y_end + thick))
	# Walkable curved top, then reverse along the underside.
	var poly: PackedVector2Array = []
	for p in top_pts:
		poly.append(p)
	for i in range(bottom_pts.size() - 1, -1, -1):
		poly.append(bottom_pts[i])
	col.polygon = poly
	body.add_child(col)
	parent.add_child(body)


static func _tile_strip_row(
	parent: Node,
	tex: Texture2D,
	left: float,
	right: float,
	y: float,
	target_h: float,
	z: int,
	name_prefix: String
) -> void:
	var tile_size := tex.get_size()
	if tile_size.y <= 0.0:
		return
	var scale_y := target_h / tile_size.y
	var tile_w := tile_size.x * scale_y
	var overlap := minf(24.0, tile_w * 0.18)
	var x := left
	var tile_i := 0
	while x < right - 0.5:
		var remaining := right - x
		var use_w := minf(tile_w, remaining)
		var sprite := Sprite2D.new()
		sprite.name = "%s_%d" % [name_prefix, tile_i]
		sprite.texture = tex
		sprite.centered = false
		sprite.position = Vector2(x, y)
		sprite.scale = Vector2(use_w / tile_size.x, scale_y)
		sprite.z_index = z
		parent.add_child(sprite)
		if remaining <= tile_w:
			break
		x += tile_w - overlap
		tile_i += 1
		if tile_i > 400:
			break


static func _align_cacti(level: Node) -> void:
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Hazard):
			continue
		var hazard := node as Hazard
		if not hazard.is_cactus():
			continue
		var surface := walk_surface_at(level, hazard.global_position.x)
		hazard.align_to_walk_surface(
			float(surface["y"]),
			float(surface["angle"]),
			CACTUS_DESERT_SINK,
			CACTUS_TILT_BLEND,
			CACTUS_MAX_TILT
		)


static func _align_chests(level: Node) -> void:
	for node in level.find_children("*", "TreasureChest", true, false):
		var chest := node as TreasureChest
		if chest == null:
			continue
		var surface := walk_surface_at(level, chest.global_position.x)
		chest.align_to_walk_surface(
			float(surface["y"]),
			float(surface["angle"]),
			CHEST_FOOT_SINK,
			CHEST_TILT_BLEND,
			CHEST_MAX_TILT
		)


static func _align_ground_foes(level: Node) -> void:
	## Bandits stamped inside/under dirt get lifted to the trail crust (not onto
	## movers hovering above the bank).
	for node in level.find_children("*", "AnimatableBody2D", true, false):
		if not (node is Opponent):
			continue
		var bandit := node as Opponent
		if bandit.is_tied() or bandit.vertical_patrol:
			continue
		var surface := walk_surface_at(level, bandit.global_position.x)
		var floor_y := float(surface["y"])
		## Only correct burial or small drift — leave intentional aerial stamps to fall.
		if bandit.global_position.y > floor_y + 6.0 or absf(bandit.global_position.y - floor_y) <= 24.0:
			bandit.snap_feet_to_surface(floor_y)


static func _disable_ground_fill_collision(level: Node) -> void:
	## Stacked dirt fill bodies are visual only — their boxes blocked dune crests.
	for node in level.find_children("*", "StaticBody2D", true, false):
		if not String(node.name).contains("Fill"):
			continue
		if not String(node.name).begins_with("Ground"):
			continue
		var shape_node := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node != null:
			shape_node.disabled = true


static func _align_pits(level: Node) -> void:
	var merged := _cached_merged_segments(level)
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Hazard):
			continue
		var hazard := node as Hazard
		if maxf(absf(hazard.scale.x), absf(hazard.scale.y)) <= 1.35:
			continue
		var gap := _gap_around(hazard.global_position.x, merged)
		var edge_tops := _gap_edge_tops(gap, merged, level)
		hazard.align_canyon_to_gap(
			minf(float(edge_tops["left"]), float(edge_tops["right"])),
			float(gap["left"]),
			float(gap["right"]),
			float(edge_tops["left"]),
			float(edge_tops["right"])
		)


static func _carve_ground_lips_for_canyons(level: Node) -> void:
	## Shrink Ground* collision at canyon mouths so feet cannot rest on the blue
	## sky band past the painted desert crust / ridge lip.
	const LIP_INSET := 12.0
	var merged := _cached_merged_segments(level)
	if merged.size() < 2:
		return
	for i in range(merged.size() - 1):
		if not _is_canyon_between(merged[i], merged[i + 1]):
			continue
		var left_right := float(merged[i]["right"])
		var right_left := float(merged[i + 1]["left"])
		_trim_ground_lip(level, left_right, true, LIP_INSET)
		_trim_ground_lip(level, right_left, false, LIP_INSET)
	# Collision extents changed — drop the walk-surface segment cache.
	invalidate_walk_surface_cache()


static func _trim_ground_lip(
	level: Node, lip_x: float, left_bank: bool, inset: float
) -> void:
	for node in level.find_children("Ground*", "StaticBody2D", true, false):
		if String(node.name).ends_with("Fill"):
			continue
		var body := node as StaticBody2D
		if body == null:
			continue
		var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node == null or shape_node.disabled or not (shape_node.shape is RectangleShape2D):
			continue
		var rect := (shape_node.shape as RectangleShape2D).duplicate() as RectangleShape2D
		var center := shape_node.global_position
		var half := rect.size * 0.5
		var left := center.x - half.x
		var right := center.x + half.x
		if left_bank:
			if absf(right - lip_x) > 3.0:
				continue
			var new_right := right - inset
			var new_w := new_right - left
			if new_w < 24.0:
				shape_node.disabled = true
				continue
			rect.size = Vector2(new_w, rect.size.y)
			shape_node.shape = rect
			shape_node.global_position = Vector2((left + new_right) * 0.5, center.y)
		else:
			if absf(left - lip_x) > 3.0:
				continue
			var new_left := left + inset
			var new_w := right - new_left
			if new_w < 24.0:
				shape_node.disabled = true
				continue
			rect.size = Vector2(new_w, rect.size.y)
			shape_node.shape = rect
			shape_node.global_position = Vector2((new_left + right) * 0.5, center.y)


static func _gap_edge_tops(
	gap: Dictionary, merged: Array[Dictionary], level: Node = null
) -> Dictionary:
	## Per-bank desert tops at the canyon lips. Prefer the highest nearby crust
	## (smallest Y) so a raised plateau beside the mouth is not left with abyss
	## showing above a rim that was snapped to a lower lip shelf.
	var gap_left := float(gap["left"])
	var gap_right := float(gap["right"])
	var left_top := _bank_top_near_lip(level, merged, gap_left, true)
	var right_top := _bank_top_near_lip(level, merged, gap_right, false)
	return {"left": left_top, "right": right_top}


static func _bank_top_near_lip(
	level: Node, merged: Array[Dictionary], lip_x: float, left_bank: bool
) -> float:
	var samples: Array[float] = []
	# Sample just inland of the lip and further back across the ridge band.
	var offsets: Array[float] = [8.0, 24.0, 48.0, 88.0, 120.0]
	for offset in offsets:
		var x := lip_x - offset if left_bank else lip_x + offset
		if level != null:
			samples.append(float(walk_surface_at(level, x)["y"]))
		else:
			samples.append(_strip_top_at_x(merged, x))
	# Exact strip that meets the gap edge (legacy match).
	for strip in merged:
		if left_bank and absf(float(strip["right"]) - lip_x) <= 3.0:
			samples.append(float(strip["top"]))
		elif not left_bank and absf(float(strip["left"]) - lip_x) <= 3.0:
			samples.append(float(strip["top"]))
	if samples.is_empty():
		return 320.0
	# Highest desert bank = smallest world Y.
	var best := samples[0]
	for y in samples:
		best = minf(best, y)
	return best


static func _strip_top_at_x(merged: Array[Dictionary], world_x: float) -> float:
	for strip in merged:
		if world_x >= float(strip["left"]) - 0.5 and world_x <= float(strip["right"]) + 0.5:
			return float(strip["top"])
	if merged.is_empty():
		return 320.0
	var best_dist := INF
	var best_y := float(merged[0]["top"])
	for strip in merged:
		var mid := (float(strip["left"]) + float(strip["right"])) * 0.5
		var dist := absf(mid - world_x)
		if dist < best_dist:
			best_dist = dist
			best_y = float(strip["top"])
	return best_y


static func _gap_around(x: float, merged: Array[Dictionary]) -> Dictionary:
	if merged.is_empty():
		return {"left": x - 80.0, "right": x + 80.0}
	for i in range(merged.size() - 1):
		var left_edge := float(merged[i]["right"])
		var right_edge := float(merged[i + 1]["left"])
		if left_edge - 8.0 <= x and x <= right_edge + 8.0:
			return {"left": left_edge, "right": right_edge}
	# Fallback: nearest edges.
	var best_left := x - 80.0
	var best_right := x + 80.0
	var best_dist := INF
	for i in range(merged.size() - 1):
		var left_edge := float(merged[i]["right"])
		var right_edge := float(merged[i + 1]["left"])
		var mid := (left_edge + right_edge) * 0.5
		var dist := absf(mid - x)
		if dist < best_dist:
			best_dist = dist
			best_left = left_edge
			best_right = right_edge
	return {"left": best_left, "right": best_right}


static func _typical_floor_top(level: Node) -> float:
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if not String(node.name).begins_with("Ground"):
			continue
		var body := node as Node2D
		var visual := body.get_node_or_null("Visual") as ColorRect
		if visual != null:
			return body.global_position.y + minf(visual.offset_top, visual.offset_bottom)
		var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null and shape.shape is RectangleShape2D:
			var size := (shape.shape as RectangleShape2D).size
			return shape.global_position.y - size.y * 0.5
	return 320.0


static func _collect_ground_segments(level: Node) -> Array[Dictionary]:
	ground_collect_calls += 1
	var segments: Array[Dictionary] = []
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if not String(node.name).begins_with("Ground"):
			continue
		var body := node as Node2D
		var visual := body.get_node_or_null("Visual") as ColorRect
		var shape := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var left := body.global_position.x - 210.0
		var right := body.global_position.x + 210.0
		var top := body.global_position.y - 32.0
		var bottom := body.global_position.y + 32.0
		if visual != null:
			left = body.global_position.x + minf(visual.offset_left, visual.offset_right)
			right = body.global_position.x + maxf(visual.offset_left, visual.offset_right)
			top = body.global_position.y + minf(visual.offset_top, visual.offset_bottom)
			bottom = body.global_position.y + maxf(visual.offset_top, visual.offset_bottom)
		elif shape != null and shape.shape is RectangleShape2D:
			var size := (shape.shape as RectangleShape2D).size
			left = shape.global_position.x - size.x * 0.5
			right = shape.global_position.x + size.x * 0.5
			top = shape.global_position.y - size.y * 0.5
			bottom = shape.global_position.y + size.y * 0.5
		segments.append({"left": left, "right": right, "top": top, "bottom": bottom})
	segments.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["left"]) < float(b["left"]))
	return segments


static func _merge_segments(segments: Array[Dictionary]) -> Array[Dictionary]:
	# First collapse vertically stacked dirt in the same column into one tall bank.
	var columns: Array[Dictionary] = []
	for segment in segments:
		var placed := false
		for column in columns:
			var overlap := (
				minf(float(column["right"]), float(segment["right"]))
				- maxf(float(column["left"]), float(segment["left"]))
			)
			var span := minf(
				float(column["right"]) - float(column["left"]),
				float(segment["right"]) - float(segment["left"])
			)
			if overlap > span * 0.55:
				column["left"] = minf(float(column["left"]), float(segment["left"]))
				column["right"] = maxf(float(column["right"]), float(segment["right"]))
				column["top"] = minf(float(column["top"]), float(segment["top"]))
				column["bottom"] = maxf(float(column["bottom"]), float(segment["bottom"]))
				placed = true
				break
		if not placed:
			columns.append(segment.duplicate())
	columns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["left"]) < float(b["left"]))

	# Then join neighbors only when their walk surfaces match — keep height steps.
	var merged: Array[Dictionary] = []
	for segment in columns:
		if merged.is_empty():
			merged.append(segment.duplicate())
			continue
		var last: Dictionary = merged[merged.size() - 1]
		var same_height := absf(float(segment["top"]) - float(last["top"])) <= 12.0
		if same_height and float(segment["left"]) <= float(last["right"]) + 24.0:
			last["right"] = maxf(float(last["right"]), float(segment["right"]))
			last["top"] = minf(float(last["top"]), float(segment["top"]))
			last["bottom"] = maxf(float(last["bottom"]), float(segment["bottom"]))
		else:
			merged.append(segment.duplicate())
	_snap_adjacent_steps(merged)
	return merged


## Close tiny seams between height-stepped banks so they never read as canyon gaps.
static func _snap_adjacent_steps(merged: Array[Dictionary]) -> void:
	for i in range(merged.size() - 1):
		var left: Dictionary = merged[i]
		var right: Dictionary = merged[i + 1]
		var seam := float(right["left"]) - float(left["right"])
		if seam <= 24.0 and seam >= -4.0:
			var mid := (float(left["right"]) + float(right["left"])) * 0.5
			left["right"] = mid
			right["left"] = mid


static func _replace_block_art(body: Node, texture_path: String) -> void:
	var visual := body.get_node_or_null("Visual") as ColorRect
	if visual == null:
		return
	for child_name in ["TopStripe", "DirtEdge", "Nail"]:
		var child := body.get_node_or_null(child_name) as CanvasItem
		if child != null:
			child.visible = false
	visual.visible = false
	if body.get_node_or_null("HandArt") != null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "HandArt"
	sprite.texture = load(texture_path)
	sprite.centered = true
	var width := absf(visual.offset_right - visual.offset_left)
	var height := absf(visual.offset_bottom - visual.offset_top)
	sprite.position = Vector2(
		(visual.offset_left + visual.offset_right) * 0.5,
		(visual.offset_top + visual.offset_bottom) * 0.5
	)
	var tex_size := sprite.texture.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		var target_h := maxf(height, 28.0)
		# Wood planks have transparent pad above the boards; crop so the walk
		# surface matches the collision top (cowboy no longer floats).
		if texture_path.ends_with("wood_plank.png") and tex_size.y > 16.0:
			var atlas := AtlasTexture.new()
			atlas.atlas = sprite.texture
			atlas.region = Rect2(0, 12, tex_size.x, tex_size.y - 12)
			sprite.texture = atlas
			tex_size = atlas.get_size()
		sprite.scale = Vector2(width / tex_size.x, target_h / tex_size.y)
	sprite.z_index = 1
	body.add_child(sprite)


static func _level_width(level: Node) -> float:
	var background := level.get_node_or_null("Background") as ColorRect
	if background != null:
		return maxf(background.size.x, 7200.0)
	var goal := level.find_child("Goal", true, false) as Node2D
	if goal != null:
		return goal.global_position.x + 500.0
	return 7200.0


static func configure_player_camera(level: Node, player: Player) -> void:
	if player == null:
		return
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2(0.84, 0.84)
	camera.limit_top = -280
	camera.limit_bottom = 560
	camera.limit_left = -80
	var goal := level.find_child("Goal", true, false) as Node2D
	if goal != null:
		camera.limit_right = int(goal.global_position.x + 420.0)
	else:
		camera.limit_right = 8000
