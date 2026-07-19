class_name WildWestTheme
extends RefCounted

## Applies cheerful hand-drawn wild-west art across levels.


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
	_dress_mesas_and_fences(level)
	_dress_grounds_and_platforms(level)


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


static func _dress_mesas_and_fences(level: Node) -> void:
	for node in level.find_children("*", "ColorRect", true, false):
		var rect := node as ColorRect
		var rect_name := String(rect.name)
		if rect_name == "Sun" or rect.get_parent() != level:
			continue
		var texture_path := ""
		if rect_name.begins_with("Mesa"):
			var digits := String(rect_name).trim_prefix("Mesa")
			var mesa_index := int(digits) if digits.is_valid_int() else 0
			texture_path = (
				"res://assets/world/mesa_near.png"
				if mesa_index % 2 == 0
				else "res://assets/world/mesa.png"
			)
		elif rect_name.begins_with("Fence"):
			texture_path = "res://assets/world/fence.png"
		else:
			continue
		rect.visible = false
		var art_name := "%sArt" % rect_name
		if level.get_node_or_null(art_name) != null:
			continue
		var sprite := Sprite2D.new()
		sprite.name = art_name
		sprite.texture = load(texture_path)
		sprite.centered = true
		sprite.position = rect.position + rect.size * 0.5
		var tex_size := sprite.texture.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			sprite.scale = Vector2(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
		sprite.z_index = rect.z_index
		sprite.modulate = rect.modulate
		level.add_child(sprite)


static func _dress_grounds_and_platforms(level: Node) -> void:
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		var parent_name := String(node.name)
		if parent_name.begins_with("Ground"):
			_replace_block_art(node, "res://assets/world/ground_tile.png", true)
		elif (
			parent_name.begins_with("Platform")
			or parent_name.begins_with("SpringLedge")
			or parent_name.begins_with("WindLedge")
			or parent_name.begins_with("StarPlatform")
			or parent_name.begins_with("High")
		):
			_replace_block_art(node, "res://assets/world/wood_plank.png", false)


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
		# Ground tiles stretch to the segment; planks keep a slightly thicker look.
		var target_h := height if is_ground else maxf(height, 28.0)
		sprite.scale = Vector2(width / tex_size.x, target_h / tex_size.y)
	sprite.z_index = 1
	body.add_child(sprite)


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
