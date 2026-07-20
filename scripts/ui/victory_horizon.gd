extends CanvasLayer

## Cowboy rides into a hand-drawn sunset after the final boss.

const BACKDROP := preload("res://assets/world/sunset_backdrop.png")
const RIDER_0 := preload("res://assets/world/sunset_rider_0.png")
const RIDER_1 := preload("res://assets/world/sunset_rider_1.png")
const RIDE_0 := preload("res://assets/world/cowboy_horse_ride_0.png")
const RIDE_1 := preload("res://assets/world/cowboy_horse_ride_1.png")


func _ready() -> void:
	layer = 120
	_run()


func _run() -> void:
	AudioManager.play_finale_theme()
	var view := get_viewport().get_visible_rect().size

	var sky := TextureRect.new()
	sky.texture = BACKDROP
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky)

	# Soft vignette / warm wash over the art.
	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(1.0, 0.45, 0.15, 0.18)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var title := Label.new()
	title.text = "Trail complete!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	title.offset_bottom = 100
	title.add_theme_font_size_override(&"font_size", 44)
	title.add_theme_color_override(&"font_color", Color(0.28, 0.1, 0.04, 1))
	title.modulate.a = 0.0
	add_child(title)

	var sub := Label.new()
	sub.text = "The cowboy rides into the sunset..."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sub.offset_top = 100
	sub.offset_bottom = 140
	sub.add_theme_font_size_override(&"font_size", 22)
	sub.add_theme_color_override(&"font_color", Color(0.4, 0.16, 0.06, 1))
	sub.modulate.a = 0.0
	add_child(sub)

	var ground_y := view.y * 0.72
	var rider := Sprite2D.new()
	# Prefer silhouette sunset rider; fall back to trail horse frames.
	rider.texture = RIDER_0 if RIDER_0 != null else RIDE_0
	rider.centered = true
	# Keep both ride frames at the same on-screen height (textures are padded equally).
	var target_h := view.y * 0.38
	var shrink := {"value": 1.0}
	var apply_rider_scale := func() -> void:
		if rider.texture == null:
			return
		var tex_h := float(rider.texture.get_height())
		var s := (target_h / maxf(tex_h, 1.0)) * float(shrink["value"])
		rider.scale = Vector2(s, s)
	apply_rider_scale.call()
	rider.position = Vector2(-220.0, ground_y)
	rider.z_index = 2
	add_child(rider)

	var dust := Node2D.new()
	dust.z_index = 1
	add_child(dust)

	var phase := {"t": 0.0, "dust": 0.0}
	var blink := Timer.new()
	blink.wait_time = 0.16
	blink.timeout.connect(func() -> void:
		phase["t"] = float(phase["t"]) + 1.0
		var use_a := int(phase["t"]) % 2 == 0
		if RIDER_0 != null and RIDER_1 != null:
			rider.texture = RIDER_0 if use_a else RIDER_1
		else:
			rider.texture = RIDE_0 if use_a else RIDE_1
		apply_rider_scale.call()
		rider.position.y = ground_y + sin(float(phase["t"]) * 0.8) * 4.0
	)
	add_child(blink)
	blink.start()

	var fade_in := create_tween()
	fade_in.tween_property(title, "modulate:a", 1.0, 0.8)
	fade_in.parallel().tween_property(sub, "modulate:a", 1.0, 0.9).set_delay(0.2)

	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(rider, "position:x", view.x * 0.55, 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(rider, "position:x", view.x + 260.0, 3.4).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(rider, "modulate", Color(1, 0.7, 0.35, 0.85), 3.4)
	tween.parallel().tween_method(func(v: float) -> void:
		shrink["value"] = v
		apply_rider_scale.call()
	, 1.0, 0.72, 3.4)

	# Occasional dust puffs under the hooves while riding.
	var dust_timer := Timer.new()
	dust_timer.wait_time = 0.22
	dust_timer.timeout.connect(func() -> void:
		if not is_instance_valid(rider):
			return
		var puff := Polygon2D.new()
		puff.color = Color(0.85, 0.55, 0.3, 0.45)
		puff.polygon = PackedVector2Array([
			Vector2(-10, 0), Vector2(8, -6), Vector2(14, 4), Vector2(-4, 8)
		])
		puff.global_position = rider.global_position + Vector2(-30, 40)
		dust.add_child(puff)
		var pt := create_tween()
		pt.tween_property(puff, "modulate:a", 0.0, 0.45)
		pt.parallel().tween_property(puff, "position", puff.position + Vector2(-20, -10), 0.45)
		pt.tween_callback(puff.queue_free)
	)
	add_child(dust_timer)
	dust_timer.start()

	await tween.finished
	blink.stop()
	dust_timer.stop()

	var end_fade := ColorRect.new()
	end_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_fade.color = Color(0, 0, 0, 0.0)
	end_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(end_fade)

	var dedication := Label.new()
	dedication.text = "VOM PAPI FÜR FINN"
	dedication.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dedication.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dedication.set_anchors_preset(Control.PRESET_FULL_RECT)
	dedication.add_theme_font_size_override(&"font_size", 36)
	dedication.add_theme_color_override(&"font_color", Color(1, 0.92, 0.75, 1))
	dedication.modulate.a = 0.0
	dedication.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dedication)

	var ft := create_tween()
	ft.tween_property(end_fade, "color:a", 1.0, 0.9)
	await ft.finished
	var dt := create_tween()
	dt.tween_property(dedication, "modulate:a", 1.0, 0.8)
	await dt.finished
	# Let the country theme finish if it is still going.
	while AudioManager.is_finale_playing():
		await get_tree().process_frame
	await get_tree().create_timer(1.6).timeout
	AudioManager.play_trail_music()
	await get_tree().create_timer(0.35).timeout
	GameManager.return_to_save_select()
