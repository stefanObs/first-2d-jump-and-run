class_name WildWestTheme
extends RefCounted

## Applies a cheerful wild-west look to level and menu visuals.


static func desert_sky_color() -> Color:
	# Cool mid-horizon so warm dirt floors stay readable.
	return Color(0.62, 0.84, 0.96, 1.0)


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
		sky.color = Color(0.42, 0.74, 0.98, 1.0)

	for node in level.find_children("*", "ColorRect", true, false):
		var rect := node as ColorRect
		var rect_name := String(rect.name)
		var parent_name := String(rect.get_parent().name)

		# Keep decorative accents painted in the level scenes.
		if rect_name in ["Nail", "Sun", "Mesa", "Fence"]:
			continue
		if rect_name.begins_with("Mesa") or rect_name.begins_with("Fence"):
			continue

		if parent_name.begins_with("Ground"):
			if rect_name == "Visual":
				rect.color = sand_color()
			elif rect_name == "TopStripe":
				rect.color = grass_color()
				# Thicker grass rim so kids can spot the walkable top.
				rect.offset_bottom = rect.offset_top + 20.0
			elif rect_name == "DirtEdge":
				rect.color = dirt_edge_color()
		elif (
			parent_name.begins_with("Platform")
			or parent_name.begins_with("SpringLedge")
			or parent_name.begins_with("WindLedge")
			or parent_name.begins_with("StarPlatform")
			or parent_name.begins_with("High")
		):
			if rect_name == "Visual":
				rect.color = wood_color()
		elif parent_name.begins_with("Gap") or parent_name.begins_with("Cloud"):
			rect.color = Color(0.95, 0.92, 0.82, 1.0)

	_ensure_ground_edges(level)


static func _ensure_ground_edges(level: Node) -> void:
	for node in level.find_children("*", "StaticBody2D", true, false):
		if not String(node.name).begins_with("Ground"):
			continue
		var visual := node.get_node_or_null("Visual") as ColorRect
		if visual == null:
			continue
		var edge := node.get_node_or_null("DirtEdge") as ColorRect
		if edge == null:
			edge = ColorRect.new()
			edge.name = "DirtEdge"
			edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.add_child(edge)
		edge.offset_left = visual.offset_left
		edge.offset_right = visual.offset_right
		edge.offset_top = visual.offset_bottom - 8.0
		edge.offset_bottom = visual.offset_bottom
		edge.color = dirt_edge_color()
		edge.z_index = 1


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
