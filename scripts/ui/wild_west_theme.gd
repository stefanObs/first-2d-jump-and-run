class_name WildWestTheme
extends RefCounted

## Applies cheerful wild-west art with continuous floor and horizon hills.


static func desert_sky_color() -> Color:
	return Color(0.58, 0.82, 0.96, 1.0)


static func sand_color() -> Color:
	return Color(0.72, 0.46, 0.22, 1.0)


static func dirt_edge_color() -> Color:
	return Color(0.48, 0.28, 0.12, 1.0)


static func grass_color() -> Color:
	return Color(0.28, 0.72, 0.22, 1.0)


static func wood_color() -> Color:
	return Color(0.55, 0.32, 0.14, 1.0)


static func apply_to_level(level: Node) -> void:
	var background := level.get_node_or_null("Background") as ColorRect
	if background != null:
		background.color = desert_sky_color()

	var sky := level.get_node_or_null("SkyBand") as ColorRect
	if sky != null:
		sky.color = Color(0.38, 0.72, 0.96, 1.0)

	_dress_sun(level)
	_hide_fences(level)
	_make_endless_hills(level)
	_dress_platforms(level)
	_make_contiguous_floors(level)


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
	sprite.position = sun.position + sun.size * 0.5
	sprite.z_index = sun.z_index
	level.add_child(sprite)


static func _hide_fences(level: Node) -> void:
	for node in level.find_children("*", "CanvasItem", true, false):
		var name_text := String(node.name)
		if name_text.begins_with("Fence") or name_text.begins_with("FenceArt"):
			(node as CanvasItem).visible = false


static func _make_endless_hills(level: Node) -> void:
	# Hide the old scattered mesa boxes / sprites.
	for node in level.find_children("*", "CanvasItem", true, false):
		var name_text := String(node.name)
		if name_text.begins_with("Mesa"):
			(node as CanvasItem).visible = false

	if level.get_node_or_null("HorizonHills") != null:
		return

	var width := _level_width(level)
	var root := Node2D.new()
	root.name = "HorizonHills"
	root.z_index = -16
	level.add_child(root)

	var far := _hill_polygon(
		"FarHills",
		width,
		200.0,
		48.0,
		0.0024,
		Color(0.92, 0.62, 0.38, 0.9)
	)
	far.z_index = -2
	root.add_child(far)

	var near := _hill_polygon(
		"NearHills",
		width,
		245.0,
		34.0,
		0.0036,
		Color(0.78, 0.48, 0.28, 0.95)
	)
	near.z_index = -1
	root.add_child(near)


static func _hill_polygon(
	node_name: String,
	width: float,
	base_y: float,
	amplitude: float,
	frequency: float,
	color: Color
) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = node_name
	poly.color = color
	var points := PackedVector2Array()
	var left := -280.0
	var right := width + 480.0
	var ground_y := 340.0
	points.append(Vector2(left, ground_y))
	var x := left
	while x <= right:
		var y := base_y + sin(x * frequency) * amplitude + cos(x * frequency * 0.55) * (amplitude * 0.45)
		points.append(Vector2(x, y))
		x += 70.0
	points.append(Vector2(right, ground_y))
	poly.polygon = points
	return poly


static func _dress_platforms(level: Node) -> void:
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		var parent_name := String(node.name)
		if (
			parent_name.begins_with("Platform")
			or parent_name.begins_with("SpringLedge")
			or parent_name.begins_with("WindLedge")
			or parent_name.begins_with("StarPlatform")
			or parent_name.begins_with("High")
		):
			_replace_block_art(node, "res://assets/world/wood_plank.png", false)


static func _make_contiguous_floors(level: Node) -> void:
	# Hide every per-segment ground visual, including previously generated HandArt.
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if not String(node.name).begins_with("Ground"):
			continue
		for child_name in ["Visual", "TopStripe", "DirtEdge", "Nail", "HandArt"]:
			var child := node.get_node_or_null(child_name) as CanvasItem
			if child != null:
				child.visible = false

	if level.get_node_or_null("TrailFloor") != null:
		return

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

	if segments.is_empty():
		return
	segments.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["left"]) < float(b["left"]))

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

	var floor_root := Node2D.new()
	floor_root.name = "TrailFloor"
	floor_root.z_index = 0
	level.add_child(floor_root)

	for i in range(merged.size()):
		var strip: Dictionary = merged[i]
		var left := float(strip["left"])
		var right := float(strip["right"])
		var top := float(strip["top"])
		var bottom := float(strip["bottom"])
		var width := right - left
		var height := bottom - top

		var dirt := ColorRect.new()
		dirt.name = "FloorDirt%d" % i
		dirt.position = Vector2(left, top)
		dirt.size = Vector2(width, height)
		dirt.color = sand_color()
		dirt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_root.add_child(dirt)

		var grass := ColorRect.new()
		grass.name = "FloorGrass%d" % i
		grass.position = Vector2(left, top)
		grass.size = Vector2(width, 18.0)
		grass.color = grass_color()
		grass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_root.add_child(grass)

		var edge := ColorRect.new()
		edge.name = "FloorEdge%d" % i
		edge.position = Vector2(left, bottom - 7.0)
		edge.size = Vector2(width, 7.0)
		edge.color = dirt_edge_color()
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		floor_root.add_child(edge)


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
