class_name BountyRewardEffect
extends Node2D

## Two sheriff badges pop from a tied bounty bandit and fly to the cowboy.

const BADGE_TEXTURE := preload("res://assets/world/star_badge.png")


func play(from_world: Vector2, to_world: Vector2, amount: int) -> void:
	global_position = Vector2.ZERO
	z_index = 100
	for index in range(amount):
		var badge := Sprite2D.new()
		badge.texture = BADGE_TEXTURE
		badge.global_position = from_world + Vector2((index - (amount - 1) * 0.5) * 22.0, -50.0)
		badge.scale = Vector2(0.35, 0.35)
		add_child(badge)
		var label := Label.new()
		label.text = "+1"
		label.position = Vector2(-12, -38)
		label.add_theme_font_size_override(&"font_size", 18)
		label.add_theme_color_override(&"font_color", Color(1.0, 0.78, 0.08, 1.0))
		label.add_theme_color_override(&"font_outline_color", Color(0.28, 0.12, 0.03, 1.0))
		label.add_theme_constant_override(&"outline_size", 4)
		badge.add_child(label)
		var delay := index * 0.13
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(badge, "scale", Vector2(0.72, 0.72), 0.18).set_trans(Tween.TRANS_BACK)
		tween.parallel().tween_property(badge, "position:y", badge.position.y - 45.0, 0.24)
		tween.tween_property(badge, "global_position", to_world + Vector2(0, -55), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(badge, "scale", Vector2(0.28, 0.28), 0.55)
		tween.tween_callback(badge.queue_free)
	var lifetime := 1.1 + maxf(amount - 1, 0) * 0.13
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
