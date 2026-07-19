class_name Hazard
extends Area2D

## Harmful cactus or canyon gap. Canyons always return the player to a camp.
## A Bubble Shield bounces the player off cacti instead of respawning.

signal hurt(player: Player)


func is_canyon() -> bool:
	return maxf(absf(scale.x), absf(scale.y)) > 1.35


func is_cactus() -> bool:
	return not is_canyon()

## Fraction of canyon_gap.png that is the open fall space (left..right).
const OPENING_LEFT := 0.0875
const OPENING_RIGHT := 0.9125


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_configure_visual()


func _configure_visual() -> void:
	var sprite := get_node_or_null("Sprite2D") as CanvasItem
	var pit := get_node_or_null("PitVisual") as CanvasItem
	var rim := get_node_or_null("PitRim") as CanvasItem
	var label := get_node_or_null("PitLabel") as Label
	var wide := is_canyon()
	if sprite != null:
		sprite.visible = not wide
	if pit != null:
		pit.visible = false
	if rim != null:
		rim.visible = false
	if label != null:
		# Canyons stay unlabeled; cactus keeps a tiny hint.
		label.visible = not wide
		if not wide:
			label.text = "OUCH!"
			label.add_theme_font_size_override(&"font_size", 15)
			label.add_theme_color_override(&"font_color", Color(0.15, 0.5, 0.18, 1.0))
	if wide:
		# Temporary until WildWestTheme supplies the real floor gap.
		align_canyon_to_gap(global_position.y - 80.0, global_position.x - 80.0, global_position.x + 80.0)


func align_pit_to_floor(floor_top_y: float) -> void:
	align_canyon_to_gap(floor_top_y, global_position.x - 80.0, global_position.x + 80.0)


func align_canyon_to_gap(floor_top_y: float, gap_left: float, gap_right: float) -> void:
	var parent_sy := absf(scale.y)
	if parent_sy <= 0.001:
		parent_sy = 1.0
	var parent_sx := absf(scale.x)
	if parent_sx <= 0.001:
		parent_sx = 1.0

	var old_pit := get_node_or_null("PitVisual") as CanvasItem
	if old_pit != null:
		old_pit.visible = false

	var mouth := get_node_or_null("PitMouth") as Sprite2D
	if mouth == null:
		mouth = Sprite2D.new()
		mouth.name = "PitMouth"
		mouth.z_index = -1
		add_child(mouth)
	mouth.texture = load("res://assets/world/canyon_gap.png")
	if mouth.texture == null:
		mouth.texture = load("res://assets/world/pit_mouth.png")
	if mouth.texture == null:
		return

	var tex_w := float(mouth.texture.get_width())
	var tex_h := float(mouth.texture.get_height())
	var gap_w := maxf(gap_right - gap_left, 40.0)
	var opening_frac := OPENING_RIGHT - OPENING_LEFT
	# Scale so the textured opening matches the real fall gap width.
	var world_w := gap_w / opening_frac
	var world_h := maxf(world_w * (tex_h / tex_w), 150.0)
	mouth.centered = true
	mouth.scale = Vector2(world_w / (tex_w * parent_sx), world_h / (tex_h * parent_sy))

	# Place so opening left edge sits on gap_left and rim top on floor_top.
	var opening_center_x := (gap_left + gap_right) * 0.5
	var tex_center_from_opening := ((OPENING_LEFT + OPENING_RIGHT) * 0.5 - 0.5) * world_w
	var world_center_x := opening_center_x - tex_center_from_opening
	var half_local_h := (tex_h * 0.5) * mouth.scale.y
	mouth.position = Vector2(
		(world_center_x - global_position.x) / parent_sx,
		(floor_top_y - global_position.y) / parent_sy + half_local_h
	)
	mouth.visible = true

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
		if is_canyon():
			# Bubble Shield does not save a canyon fall — only skip if already falling.
			if player.is_canyon_falling():
				return
			hurt.emit(player)
			return
		if player.is_invulnerable():
			return
		hurt.emit(player)
