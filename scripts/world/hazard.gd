class_name Hazard
extends Area2D

## Harmful cactus or canyon pit. Always returns the player to a checkpoint,
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
		pit.visible = wide
	if rim != null:
		rim.visible = wide
	if label != null:
		label.visible = true
		label.text = "PIT!" if wide else "OUCH!"
		if not wide:
			label.add_theme_color_override(&"font_color", Color(0.2, 0.45, 0.15, 1.0))


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		hurt.emit(body as Player)
