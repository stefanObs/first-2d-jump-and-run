class_name Hazard
extends Area2D

## Harmful cactus or canyon gap. Always returns the player to a checkpoint,
## even while a Bubble Shield is active.

signal hurt(player: Player)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_configure_visual()


func _configure_visual() -> void:
	var sprite := get_node_or_null("Sprite2D") as CanvasItem
	var pit := get_node_or_null("PitVisual") as CanvasItem
	var rim := get_node_or_null("PitRim") as CanvasItem
	var label := get_node_or_null("PitLabel") as Label
	var wide := maxf(absf(scale.x), absf(scale.y)) > 1.35
	if sprite != null:
		sprite.visible = not wide
	if pit != null:
		pit.visible = false
	if rim != null:
		rim.visible = false
	if label != null:
		label.visible = true
		label.text = "CANYON!" if wide else "OUCH!"
		label.add_theme_font_size_override(&"font_size", 18 if wide else 15)
		if not wide:
			label.add_theme_color_override(&"font_color", Color(0.15, 0.5, 0.18, 1.0))
		else:
			label.add_theme_color_override(&"font_color", Color(0.95, 0.45, 0.18, 1.0))
	if wide:
		align_pit_to_floor(global_position.y - 80.0)


func align_pit_to_floor(floor_top_y: float) -> void:
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
	# Wide canyon mouth flush with the desert trail top.
	var world_w := maxf(parent_sx * 42.0, 220.0)
	var world_h := maxf(parent_sy * 95.0, 160.0)
	mouth.centered = true
	mouth.scale = Vector2(world_w / (tex_w * parent_sx), world_h / (tex_h * parent_sy))
	var half_local_h := (tex_h * 0.5) * mouth.scale.y
	mouth.position = Vector2(
		0.0,
		(floor_top_y - global_position.y) / parent_sy + half_local_h
	)
	mouth.visible = true

	var label := get_node_or_null("PitLabel") as Label
	if label != null:
		label.position = Vector2(-58.0, (floor_top_y - global_position.y) / parent_sy - 38.0)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		hurt.emit(body as Player)
