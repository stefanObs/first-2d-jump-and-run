class_name WildWestTheme
extends RefCounted

## Applies cheerful hand-drawn wild-west sky, hills, and trail floor art.


static func desert_sky_color() -> Color:
	return Color(0.58, 0.82, 0.96, 1.0)


static func sand_color() -> Color:
	return Color(0.91, 0.67, 0.37, 1.0)


static func dirt_edge_color() -> Color:
	return Color(0.55, 0.28, 0.14, 1.0)


static func grass_color() -> Color:
	# Kept for older callers; trail top is desert sand now.
	return Color(0.91, 0.67, 0.37, 1.0)


static func rock_color() -> Color:
	return Color(0.78, 0.41, 0.24, 1.0)


static func wood_color() -> Color:
	return Color(0.55, 0.32, 0.14, 1.0)


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
	var tex_size := tex.get_size()
	var tile_w := tex_size.x * 1.35
	var tile_h := 700.0
	var x := -500.0
	var index := 0
	while x < width + 600.0:
		var sprite := Sprite2D.new()
		sprite.name = "SkyTile%d" % index
		sprite.texture = tex
		sprite.centered = false
		# Lower the sky wash so more blue sits behind the trail.
		sprite.position = Vector2(x, -520.0)
		sprite.scale = Vector2(tile_w / tex_size.x, tile_h / tex_size.y)
		root.add_child(sprite)
		x += tile_w - 8.0
		index += 1


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
	var tex_size := tex.get_size()
	var tile_w := tex_size.x * 1.35
	var tile_h := 520.0
	var x := -500.0
	var index := 0
	while x < width + 600.0:
		var sprite := Sprite2D.new()
		sprite.name = "HillTile%d" % index
		sprite.texture = tex
		sprite.centered = false
		sprite.position = Vector2(x, floor_top - tile_h + 10.0)
		sprite.scale = Vector2(tile_w / tex_size.x, tile_h / tex_size.y)
		sprite.modulate = Color(1, 1, 1, 0.98)
		root.add_child(sprite)
		x += tile_w - 220.0
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
		):
			_replace_block_art(node, "res://assets/world/wood_plank.png", false)


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
	var floor_top := float(merged[0]["top"])
	var floor_height := float(merged[0]["bottom"]) - floor_top
	for strip in merged:
		floor_top = minf(floor_top, float(strip["top"]))
		floor_height = maxf(floor_height, float(strip["bottom"]) - float(strip["top"]))

	# Solid black underworld so nothing below the trail shows sky.
	var abyss := ColorRect.new()
	abyss.name = "FloorAbyss"
	abyss.position = Vector2(level_left, floor_top)
	abyss.size = Vector2(level_right - level_left, 900.0)
	abyss.color = Color(0.04, 0.02, 0.01, 1.0)
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

		# Surface row only — never overhang into canyon gaps.
		if surface != null:
			_tile_strip_row(floor_root, surface, left, right, top, height, 1, "FloorSurface%d" % i)

		# Below: continue brown dirt where the surface tile ends, down toward the abyss.
		if dirt != null:
			var surface_h := surface.get_size().y if surface != null else dirt.get_size().y
			var scale_y := height / surface_h
			var dirt_h := dirt.get_size().y * scale_y
			var y := top + height - 2.0
			var row := 0
			while y < deep_bottom - 1.0:
				_tile_strip_row(floor_root, dirt, left, right, y, dirt_h, 0, "FloorDirt%d_%d" % [i, row])
				y += dirt_h - 2.0
				row += 1
				if row > 40:
					break


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
	var floor_top := _typical_floor_top(level)
	var merged := _merge_segments(_collect_ground_segments(level))
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Hazard):
			continue
		var hazard := node as Hazard
		if maxf(absf(hazard.scale.x), absf(hazard.scale.y)) <= 1.35:
			continue
		var gap := _gap_around(hazard.global_position.x, merged)
		hazard.align_canyon_to_gap(floor_top, float(gap["left"]), float(gap["right"]))


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
	var merged: Array[Dictionary] = []
	for segment in segments:
		if merged.is_empty():
			merged.append(segment.duplicate())
			continue
		var last: Dictionary = merged[merged.size() - 1]
		if float(segment["left"]) <= float(last["right"]) + 24.0:
			last["right"] = maxf(float(last["right"]), float(segment["right"]))
			last["top"] = minf(float(last["top"]), float(segment["top"]))
			last["bottom"] = maxf(float(last["bottom"]), float(segment["bottom"]))
		else:
			merged.append(segment.duplicate())
	return merged


static func _replace_block_art(body: Node, texture_path: String, is_ground: bool) -> void:
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
		var target_h := height if is_ground else maxf(height, 28.0)
		# Wood planks have transparent pad above the boards; crop so the walk
		# surface matches the collision top (cowboy no longer floats).
		if not is_ground and texture_path.ends_with("wood_plank.png") and tex_size.y > 16.0:
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
