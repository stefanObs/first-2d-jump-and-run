class_name BullTieFx
extends RefCounted

## Shared rope-coil and dust flourish for trail bulls and the Stampede Bull boss.


static func spawn_win_ropes(
	parent: Node2D,
	tween_host: Node,
	base_width: float = 4.5,
	width_step: float = 0.25,
	base_radius: float = 16.0,
	radius_step: float = 5.0,
	base_y: float = -10.0,
	y_step: float = 4.5
) -> Node2D:
	var ropes := Node2D.new()
	ropes.name = "WinRopes"
	ropes.z_index = 6
	parent.add_child(ropes)
	for i in range(5):
		var loop := Line2D.new()
		loop.width = base_width - float(i) * width_step
		loop.default_color = Color(0.78, 0.58, 0.28, 1.0)
		var radius := base_radius + float(i) * radius_step
		var points := PackedVector2Array()
		for step in range(14):
			var ang := TAU * float(step) / 13.0 + float(i) * 0.35
			points.append(Vector2(
				cos(ang) * radius * 0.7,
				base_y - float(i) * y_step + sin(ang) * radius * 0.35
			))
		loop.points = points
		loop.modulate.a = 0.0
		ropes.add_child(loop)
		var rt := tween_host.create_tween()
		rt.tween_property(loop, "modulate:a", 1.0, 0.12).set_delay(0.07 * float(i))
		rt.parallel().tween_property(loop, "scale", Vector2(1.05, 1.05), 0.12).from(Vector2(0.4, 0.4)).set_delay(0.07 * float(i))
	return ropes


static func puff_dust(
	parent: Node2D,
	tween_host: Node,
	polygon: PackedVector2Array,
	pos: Vector2
) -> void:
	var dust := Polygon2D.new()
	dust.color = Color(0.82, 0.62, 0.38, 0.55)
	dust.polygon = polygon
	dust.position = pos
	dust.z_index = 2
	parent.add_child(dust)
	var dt := tween_host.create_tween()
	dt.tween_property(dust, "modulate:a", 0.0, 0.55)
	dt.parallel().tween_property(dust, "scale", Vector2(1.4, 0.7), 0.55)
	dt.tween_callback(dust.queue_free)


static func wobble_sprite(sprite: Node2D, tween_host: Node, face_left: bool) -> Tween:
	var wobble := tween_host.create_tween()
	wobble.tween_property(sprite, "rotation", 0.12 if face_left else -0.12, 0.18)
	wobble.tween_property(sprite, "rotation", -0.1 if face_left else 0.1, 0.18)
	wobble.tween_property(sprite, "rotation", 0.0, 0.14)
	return wobble
