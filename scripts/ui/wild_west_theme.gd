class_name WildWestTheme
extends RefCounted

## Applies cheerful hand-drawn wild-west sky, hills, and trail floor art.


static func desert_sky_color() -> Color:
	return Color(0.58, 0.82, 0.96, 1.0)


static func sand_color() -> Color:
	return Color(0.91, 0.67, 0.37, 1.0)


static func apply_to_level(level: Node) -> void:
	_dress_sky(level)
	_dress_sun(level)
	_hide_fences(level)
	_make_endless_hills(level)
	_dress_platforms(level)
	_make_contiguous_floors(level)
	_align_pits(level)


static func _dress_sky(level: Node) -> void:
	var background := level.get_node_or_null("Background") as ColorRect
	if background != null:
		background.color = desert_sky_color()
	var sky_band := level.get_node_or_null("SkyBand") as ColorRect
	if sky_band != null:
		sky_band.visible = false

	if level.get_node_or_null("SkyArt") != null:
		return

	var width := _level_width(level)
	var root := Node2D.new()
	root.name = "SkyArt"
	root.z_index = -19
	level.add_child(root)

	var tex: Texture2D = load("res://assets/world/sky_handdrawn.png")
	if tex == null:
		return
	# Lower the sky wash so more blue sits behind the trail.
	_tile_backdrop(root, tex, "SkyTile", width, -520.0, 700.0, 8.0, Color.WHITE)


static func _dress_sun(level: Node) -> void:
	var sun := level.get_node_or_null("Sun") as ColorRect
	if sun == null:
		return
	sun.visible = false
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
	for node in level.find_children("*", "CanvasItem", true, false):
		var name_text := String(node.name)
		if name_text.begins_with("Fence") or name_text.begins_with("FenceArt"):
			(node as CanvasItem).visible = false


static func _make_endless_hills(level: Node) -> void:
	for node in level.find_children("*", "CanvasItem", true, false):
		var name_text := String(node.name)
		if name_text.begins_with("Mesa"):
			(node as CanvasItem).visible = false

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
	_tile_backdrop(
		root,
		tex,
		"HillTile",
		width,
		hill_y,
		520.0,
		220.0,
		Color(1, 1, 1, 0.98)
	)
	# Open sky through canyon mouths — no mountain silhouette over the gaps.
	_clear_hills_over_canyons(level, root, hill_y, 540.0)


static func _canyon_gap_ranges(level: Node) -> Array[Vector2]:
	var gaps: Array[Vector2] = []
	var merged := _merge_segments(_collect_ground_segments(level))
	for i in range(merged.size() - 1):
		var left := float(merged[i]["right"])
		var right := float(merged[i + 1]["left"])
		if right - left > 8.0:
			gaps.append(Vector2(left, right))
	return gaps


static func _clear_hills_over_canyons(
	level: Node,
	hills_root: Node2D,
	hill_y: float,
	hill_h: float
) -> void:
	var gaps := _canyon_gap_ranges(level)
	var sky_tex: Texture2D = load("res://assets/world/sky_handdrawn.png")
	for i in range(gaps.size()):
		var gap: Vector2 = gaps[i]
		var cover_root := Node2D.new()
		cover_root.name = "CanyonSkyGap%d" % i
		cover_root.z_index = 1
		hills_root.add_child(cover_root)
		var left := gap.x - 6.0
		var width := gap.y - gap.x + 12.0
		if sky_tex != null:
			# Hand-drawn sky strip over the mountain silhouette in the canyon mouth.
			var sprite := Sprite2D.new()
			sprite.name = "SkyPatch"
			sprite.texture = sky_tex
			sprite.centered = false
			sprite.position = Vector2(left, hill_y - 8.0)
			var tex_size := sky_tex.get_size()
			sprite.scale = Vector2(width / tex_size.x, hill_h / tex_size.y)
			sprite.modulate = Color(1, 1, 1, 1)
			cover_root.add_child(sprite)
		else:
			var cover := ColorRect.new()
			cover.name = "SkyFlat"
			cover.position = Vector2(left, hill_y - 8.0)
			cover.size = Vector2(width, hill_h)
			cover.color = desert_sky_color()
			cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cover_root.add_child(cover)


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
	var tex_size := tex.get_size()
	var tile_w := tex_size.x * 1.35
	var x := -500.0
	var index := 0
	while x < level_width + 600.0:
		var sprite := Sprite2D.new()
		sprite.name = "%s%d" % [name_prefix, index]
		sprite.texture = tex
		sprite.centered = false
		sprite.position = Vector2(x, y)
		sprite.scale = Vector2(tile_w / tex_size.x, tile_h / tex_size.y)
		sprite.modulate = modulate
		parent.add_child(sprite)
		x += tile_w - overlap
		index += 1


static func _dress_platforms(level: Node) -> void:
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
			_replace_block_art(node, "res://assets/world/wood_plank.png")


static func _make_contiguous_floors(level: Node) -> void:
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

	var floor_root := Node2D.new()
	floor_root.name = "TrailFloor"
	floor_root.z_index = 0
	level.add_child(floor_root)

	var surface: Texture2D = load("res://assets/world/trail_desert_tile.png")
	var dirt: Texture2D = load("res://assets/world/trail_dirt_tile.png")
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
	# FloorAbyss must start at or below every walk surface. Using the highest bank
	# top (min y) paints a dark band over lower desert strips (Level 2 bug).
	var abyss_top := float(merged[0]["top"])
	for strip in merged:
		abyss_top = maxf(abyss_top, float(strip["top"]))

	# Deep underworld safety fill only — canyon art must paint over canyon openings.
	var abyss := ColorRect.new()
	abyss.name = "FloorAbyss"
	abyss.position = Vector2(level_left, abyss_top)
	abyss.size = Vector2(level_right - level_left, 900.0)
	abyss.color = Color(0.22, 0.10, 0.12, 1.0)
	abyss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	abyss.z_index = -2
	floor_root.add_child(abyss)

	# Stretch first/last walkable strips to the level edges.
	if not merged.is_empty():
		merged[0]["left"] = minf(float(merged[0]["left"]), level_left)
		merged[merged.size() - 1]["right"] = maxf(
			float(merged[merged.size() - 1]["right"]),
			level_right
		)

	for i in range(merged.size()):
		var strip: Dictionary = merged[i]
		var left := float(strip["left"])
		var right := float(strip["right"])
		var top := float(strip["top"])
		var bottom := float(strip["bottom"])
		var height := bottom - top
		var deep_bottom := top + 880.0
		# Keep a thin desert crust on top; tall stacked banks stay dirt underneath.
		var surface_thickness := minf(maxf(height, 36.0), 56.0)

		# Surface row only — never overhang into canyon gaps.
		if surface != null:
			_tile_strip_row(floor_root, surface, left, right, top, surface_thickness, 1, "FloorSurface%d" % i)

		# Below: continue brown dirt under the bank, stopping a few pixels before the
		# canyon lip so cliff walls sit outside the desert brown face.
		if dirt != null:
			var dirt_h := dirt.get_size().y * (surface_thickness / maxf(dirt.get_size().y, 1.0))
			var y := top + surface_thickness - 2.0
			var dirt_left := left
			var dirt_right := right
			if i + 1 < merged.size():
				dirt_right = minf(dirt_right, right - 10.0)
			if i > 0:
				dirt_left = maxf(dirt_left, left + 10.0)
			var row := 0
			while y < deep_bottom - 1.0:
				_tile_strip_row(floor_root, dirt, dirt_left, dirt_right, y, dirt_h, 0, "FloorDirt%d_%d" % [i, row])
				y += dirt_h - 2.0
				row += 1
				if row > 40:
					break

		# Soft desert slopes where neighboring banks sit at different heights.
		if i + 1 < merged.size():
			_draw_bank_slope(floor_root, surface, dirt, merged[i], merged[i + 1], i)


static func _draw_bank_slope(
	parent: Node,
	surface: Texture2D,
	dirt: Texture2D,
	left_strip: Dictionary,
	right_strip: Dictionary,
	index: int
) -> void:
	var left_top := float(left_strip["top"])
	var right_top := float(right_strip["top"])
	var step := absf(left_top - right_top)
	if step < 10.0:
		return
	var seam_x := (float(left_strip["right"]) + float(right_strip["left"])) * 0.5
	# Gentle kid-friendly grade (~2.5–3:1 run:rise), capped so it stays local.
	var run := clampf(step * 2.75, 56.0, 150.0)
	var left_is_high := left_top < right_top
	var x_high: float
	var y_high: float
	var x_low: float
	var y_low: float
	if left_is_high:
		x_high = seam_x - 6.0
		y_high = left_top
		x_low = seam_x + run
		y_low = right_top
	else:
		x_high = seam_x + 6.0
		y_high = right_top
		x_low = seam_x - run
		y_low = left_top

	_paint_slope_fill(parent, dirt, x_high, y_high, x_low, y_low, index)
	_paint_slope_crust(parent, surface, x_high, y_high, x_low, y_low, index)
	_add_slope_collision(parent, x_high, y_high, x_low, y_low, index)


static func _paint_slope_crust(
	parent: Node,
	surface: Texture2D,
	x_high: float,
	y_high: float,
	x_low: float,
	y_low: float,
	index: int
) -> void:
	if surface == null:
		return
	var dx := x_low - x_high
	var dy := y_low - y_high
	var length := maxf(sqrt(dx * dx + dy * dy), 1.0)
	var angle := atan2(dy, dx)
	var tex_size := surface.get_size()
	var crust_h := 42.0
	var scale_y := crust_h / tex_size.y
	var tile_w := tex_size.x * scale_y * 0.92
	var along := 0.0
	var tile_i := 0
	while along < length - 1.0:
		var use := minf(tile_w, length - along)
		var t := (along + use * 0.5) / length
		var mid := Vector2(lerpf(x_high, x_low, t), lerpf(y_high, y_low, t))
		var sprite := Sprite2D.new()
		sprite.name = "FloorSlope%d_%d" % [index, tile_i]
		sprite.texture = surface
		sprite.centered = true
		sprite.position = mid + Vector2(0, crust_h * 0.28).rotated(angle)
		sprite.rotation = angle
		sprite.scale = Vector2(use / tex_size.x, scale_y)
		sprite.z_index = 3
		parent.add_child(sprite)
		along += use * 0.78
		tile_i += 1
		if tile_i > 40:
			break


static func _paint_slope_fill(
	parent: Node,
	dirt: Texture2D,
	x_high: float,
	y_high: float,
	x_low: float,
	y_low: float,
	index: int
) -> void:
	## Dirt wedge under the sand crust so the bank reads as one soft dune, not a cliff.
	var x0 := minf(x_high, x_low)
	var x1 := maxf(x_high, x_low)
	var top_at := func(x: float) -> float:
		if absf(x1 - x0) < 0.1:
			return minf(y_high, y_low)
		var t := (x - x0) / (x1 - x0)
		# Map world x back onto the high→low line.
		var y_at_x0 := y_high if x_high <= x_low else y_low
		var y_at_x1 := y_low if x_high <= x_low else y_high
		return lerpf(y_at_x0, y_at_x1, t)

	var deep := maxf(y_high, y_low) + 96.0
	if dirt != null:
		var tex_size := dirt.get_size()
		var row_h := 28.0
		var scale_y := row_h / tex_size.y
		var tile_w := tex_size.x * scale_y
		var y := minf(y_high, y_low) + 18.0
		var row := 0
		while y < deep:
			var x := x0
			var tile_i := 0
			while x < x1 - 0.5:
				var surface_y: float = top_at.call(x + tile_w * 0.5)
				if y + row_h < surface_y + 8.0:
					x += tile_w * 0.85
					continue
				var use_w := minf(tile_w, x1 - x)
				var sprite := Sprite2D.new()
				sprite.name = "FloorSlopeDirt%d_%d_%d" % [index, row, tile_i]
				sprite.texture = dirt
				sprite.centered = false
				sprite.position = Vector2(x, y)
				sprite.scale = Vector2(use_w / tex_size.x, scale_y)
				sprite.z_index = 2
				sprite.modulate = Color(0.96, 0.9, 0.82, 1.0)
				parent.add_child(sprite)
				x += use_w * 0.85
				tile_i += 1
				if tile_i > 60:
					break
			y += row_h - 3.0
			row += 1
			if row > 12:
				break


static func _add_slope_collision(
	parent: Node,
	x_high: float,
	y_high: float,
	x_low: float,
	y_low: float,
	index: int
) -> void:
	var body := StaticBody2D.new()
	body.name = "FloorSlopeBody%d" % index
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionPolygon2D.new()
	col.name = "CollisionPolygon2D"
	var thick := 34.0
	col.polygon = PackedVector2Array([
		Vector2(x_high, y_high),
		Vector2(x_low, y_low),
		Vector2(x_low, y_low + thick),
		Vector2(x_high, y_high + thick),
	])
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


static func _align_pits(level: Node) -> void:
	var merged := _merge_segments(_collect_ground_segments(level))
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Hazard):
			continue
		var hazard := node as Hazard
		if maxf(absf(hazard.scale.x), absf(hazard.scale.y)) <= 1.35:
			continue
		var gap := _gap_around(hazard.global_position.x, merged)
		var edge_tops := _gap_edge_tops(gap, merged)
		hazard.align_canyon_to_gap(
			minf(float(edge_tops["left"]), float(edge_tops["right"])),
			float(gap["left"]),
			float(gap["right"]),
			float(edge_tops["left"]),
			float(edge_tops["right"])
		)


static func _gap_edge_tops(gap: Dictionary, merged: Array[Dictionary]) -> Dictionary:
	var gap_left := float(gap["left"])
	var gap_right := float(gap["right"])
	var left_top := 320.0
	var right_top := 320.0
	var found_left := false
	var found_right := false
	for strip in merged:
		if absf(float(strip["right"]) - gap_left) <= 2.0:
			left_top = float(strip["top"])
			found_left = true
		if absf(float(strip["left"]) - gap_right) <= 2.0:
			right_top = float(strip["top"])
			found_right = true
	if not found_left:
		for strip in merged:
			if float(strip["right"]) <= gap_left + 2.0:
				left_top = float(strip["top"])
				found_left = true
	if not found_right:
		for strip in merged:
			if float(strip["left"]) >= gap_right - 2.0:
				right_top = float(strip["top"])
				found_right = true
				break
	if not found_left and not merged.is_empty():
		left_top = float(merged[0]["top"])
	if not found_right and not merged.is_empty():
		right_top = float(merged[merged.size() - 1]["top"])
	return {"left": left_top, "right": right_top}


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
