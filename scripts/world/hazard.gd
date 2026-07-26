class_name Hazard
extends Area2D

## Harmful cactus, fixed-size pit, or canyon gap. Pits and canyons return the player to a camp.
## A Bubble Shield bounces the player off cacti instead of respawning.

signal hurt(player: Player)

const CANYON_ART := preload("res://scripts/world/scalable_canyon_art.gd")
const PIT_TEXTURE := preload("res://assets/world/pit.png")
const PIT_PIXEL_SIZE := Vector2(128.0, 64.0)


func is_pit() -> bool:
	return has_meta("fixed_pit") and bool(get_meta("fixed_pit"))


func is_canyon() -> bool:
	if is_pit():
		return false
	return maxf(absf(scale.x), absf(scale.y)) > 1.35


func is_cactus() -> bool:
	return not is_canyon() and not is_pit()


func is_fatal_fall() -> bool:
	return is_canyon() or is_pit()


func ground_contact_y() -> float:
	## World Y of the painted cactus base for desert-surface checks.
	if is_canyon() or is_pit():
		return global_position.y
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or not sprite.visible or sprite.texture == null:
		return global_position.y
	var tex_h := float(sprite.texture.get_height())
	var scale_y := absf(sprite.scale.y)
	if sprite.centered:
		return global_position.y + sprite.position.y + tex_h * 0.5 * scale_y
	return global_position.y + sprite.position.y + tex_h * scale_y


func align_to_walk_surface(
	floor_y: float,
	slope_angle: float = 0.0,
	sink: float = 10.0,
	tilt_blend: float = 0.35,
	max_tilt: float = 0.22
) -> void:
	if is_canyon() or is_pit():
		return
	var foot_local := ground_contact_y() - global_position.y
	global_position.y = floor_y + sink - foot_local
	rotation = clampf(slope_angle * tilt_blend, -max_tilt, max_tilt)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_configure_visual()


func _configure_visual() -> void:
	if is_pit():
		_configure_fixed_pit()
		return
	var sprite := get_node_or_null("Sprite2D") as CanvasItem
	var pit := get_node_or_null("PitVisual") as CanvasItem
	var rim := get_node_or_null("PitRim") as CanvasItem
	var label := get_node_or_null("PitLabel") as Label
	var wide := is_canyon()
	if wide:
		# Never leave a scaled cactus (or legacy pit art) floating in the mouth.
		_strip_cactus_visuals()
	elif sprite != null:
		sprite.visible = true
	if pit != null:
		pit.visible = false
	if rim != null:
		rim.visible = false
	if label != null:
		label.visible = false
		if not wide:
			label.text = "OUCH!"
			label.add_theme_font_size_override(&"font_size", 15)
			label.add_theme_color_override(&"font_color", Color(0.15, 0.5, 0.18, 1.0))
	if wide:
		# Temporary until WildWestTheme supplies the real floor gap.
		align_canyon_to_gap(global_position.y - 80.0, global_position.x - 80.0, global_position.x + 80.0)


func _configure_fixed_pit() -> void:
	scale = Vector2.ONE
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.visible = false
		sprite.texture = null
		sprite.modulate = Color(1, 1, 1, 0)
	var pit := get_node_or_null("PitVisual") as Sprite2D
	if pit != null:
		pit.visible = true
		pit.texture = PIT_TEXTURE
		pit.scale = Vector2.ONE
		pit.centered = false
		pit.position = Vector2(-PIT_PIXEL_SIZE.x * 0.5, 0.0)
		pit.modulate = Color.WHITE
	var rim := get_node_or_null("PitRim") as CanvasItem
	if rim != null:
		rim.visible = false
	var label := get_node_or_null("PitLabel") as Label
	if label != null:
		label.visible = false
	for node_name in ["CanyonMouth", "PitMouth"]:
		var canyon_art := get_node_or_null(node_name)
		if canyon_art != null:
			canyon_art.queue_free()
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(72.0, 48.0)
		shape.shape = rect
		shape.position = Vector2(0.0, 24.0)


func _strip_cactus_visuals() -> void:
	## Canyon hazards reuse the cactus scene — remove every cactus/pit sprite so a
	## huge scaled saguaro can never float in the gap (hide alone is not enough if
	## debug overlays or late theme passes re-show children).
	for child_name in ["Sprite2D", "PitVisual", "PitRim"]:
		var node := get_node_or_null(child_name)
		if node == null:
			continue
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		if node is Sprite2D:
			(node as Sprite2D).texture = null
		node.modulate = Color(1, 1, 1, 0)


func align_canyon_to_gap(
	floor_top_y: float,
	gap_left: float,
	gap_right: float,
	left_floor_top_y: float = NAN,
	right_floor_top_y: float = NAN
) -> void:
	var parent_sy := absf(scale.y)
	if parent_sy <= 0.001:
		parent_sy = 1.0
	var parent_sx := absf(scale.x)
	if parent_sx <= 0.001:
		parent_sx = 1.0

	_strip_cactus_visuals()

	var gap_w := maxf(gap_right - gap_left, 40.0)
	var opening_center_x := (gap_left + gap_right) * 0.5
	var canyon_art := get_node_or_null("CanyonMouth") as ScalableCanyonArt
	if canyon_art == null:
		canyon_art = get_node_or_null("PitMouth") as ScalableCanyonArt
	if canyon_art == null:
		canyon_art = CANYON_ART.new() as ScalableCanyonArt
		canyon_art.name = "CanyonMouth"
		add_child(canyon_art)
	else:
		canyon_art.name = "CanyonMouth"
	canyon_art.configure(floor_top_y, gap_left, gap_right, left_floor_top_y, right_floor_top_y)

	# Widen the hurt box to cover the fall gap.
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null and shape.shape is RectangleShape2D:
		var rect := (shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect.size = Vector2(gap_w / parent_sx, maxf(rect.size.y, 56.0))
		shape.shape = rect
		shape.position = Vector2(
			(opening_center_x - global_position.x) / parent_sx,
			(floor_top_y - global_position.y) / parent_sy + 28.0
		)

	var label := get_node_or_null("PitLabel") as Label
	if label != null:
		label.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		if is_fatal_fall():
			# Bubble Shield does not save a canyon/pit fall — only skip if already falling.
			if player.is_canyon_falling():
				return
			hurt.emit(player)
			return
		if player.is_invulnerable():
			return
		hurt.emit(player)
