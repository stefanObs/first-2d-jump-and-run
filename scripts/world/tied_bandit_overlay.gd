class_name TiedBanditOverlay
extends Node2D

## Marker for a captured bandit/ninja. Rope coils live in the tied floor sprite.


func _ready() -> void:
	# Keep a named child so tests and restores can detect the tied state.
	pass


static func ensure_attached(host: Node2D, tween_host: Node) -> TiedBanditOverlay:
	var existing := host.get_node_or_null("TiedRopes")
	if existing is TiedBanditOverlay:
		return existing as TiedBanditOverlay
	var ropes := TiedBanditOverlay.new()
	ropes.name = "TiedRopes"
	ropes.z_index = 0
	host.add_child(ropes)
	animate_settle_coils(ropes, tween_host)
	return ropes


static func remove_from(host: Node) -> void:
	var ropes := host.get_node_or_null("TiedRopes")
	if ropes != null:
		ropes.queue_free()


static func animate_settle_coils(ropes: Node2D, tween_host: Node) -> void:
	# Temporary rope loops that settle onto the tied enemy.
	for i in range(3):
		var loop := Line2D.new()
		loop.width = 4.0
		loop.default_color = Color(0.72, 0.5, 0.22, 1.0)
		loop.z_index = 2
		var radius := 28.0 + float(i) * 8.0
		var points := PackedVector2Array()
		for step in range(10):
			var ang := TAU * float(step) / 9.0
			points.append(Vector2(
				cos(ang) * radius * 0.55,
				-38.0 - float(i) * 10.0 + sin(ang) * radius * 0.28
			))
		loop.points = points
		loop.modulate.a = 0.0
		ropes.add_child(loop)
		var tween := tween_host.create_tween()
		tween.tween_property(loop, "modulate:a", 1.0, 0.08).set_delay(0.05 * float(i))
		tween.tween_property(loop, "modulate:a", 0.0, 0.35).set_delay(0.22)
		tween.tween_callback(loop.queue_free)
