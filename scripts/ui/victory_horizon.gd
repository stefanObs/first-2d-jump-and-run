extends CanvasLayer

## Cowboy rides into the sunset after the final boss.


func _ready() -> void:
	layer = 120
	_run()


func _run() -> void:
	var view := get_viewport().get_visible_rect().size
	var sky := ColorRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.color = Color(0.98, 0.55, 0.28, 1)
	add_child(sky)
	var band := ColorRect.new()
	band.set_anchors_preset(Control.PRESET_FULL_RECT)
	band.offset_top = view.y * 0.45
	band.color = Color(0.95, 0.35, 0.15, 1)
	add_child(band)
	var sun := ColorRect.new()
	sun.size = Vector2(120, 120)
	sun.position = Vector2(view.x * 0.7, view.y * 0.28)
	sun.color = Color(1.0, 0.92, 0.35, 1)
	add_child(sun)
	var title := Label.new()
	title.text = "Trail complete!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 48
	title.offset_bottom = 110
	title.add_theme_font_size_override(&"font_size", 42)
	title.add_theme_color_override(&"font_color", Color(0.35, 0.12, 0.05, 1))
	add_child(title)
	var sub := Label.new()
	sub.text = "The cowboy rides into the horizon..."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top = 110
	sub.offset_bottom = 150
	sub.add_theme_font_size_override(&"font_size", 22)
	sub.add_theme_color_override(&"font_color", Color(0.45, 0.18, 0.08, 1))
	add_child(sub)
	var rider := Sprite2D.new()
	rider.texture = preload("res://assets/world/cowboy_horse_ride_0.png")
	rider.scale = Vector2(0.9, 0.9)
	rider.position = Vector2(-200, view.y * 0.62)
	add_child(rider)
	var phase := {"t": 0.0}
	var blink := Timer.new()
	blink.wait_time = 0.14
	blink.timeout.connect(func() -> void:
		phase["t"] = float(phase["t"]) + 1.0
		rider.texture = (
			preload("res://assets/world/cowboy_horse_ride_0.png")
			if int(phase["t"]) % 2 == 0
			else preload("res://assets/world/cowboy_horse_ride_1.png")
		)
	)
	add_child(blink)
	blink.start()
	var tween := create_tween()
	tween.tween_property(rider, "position:x", view.x + 240.0, 4.2).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	blink.stop()
	await get_tree().create_timer(0.6).timeout
	GameManager.return_to_save_select()
