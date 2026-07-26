extends CanvasLayer

## Western-styled game over after Advanced Mode lives reach zero.


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()


func _run() -> void:
	AudioManager.stop_music()
	var view := get_viewport().get_visible_rect().size

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.12, 0.05, 0.02, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var wash := ColorRect.new()
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.55, 0.12, 0.08, 0.0)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var stamp := Label.new()
	stamp.text = tr("GAME OVER")
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp.set_anchors_preset(Control.PRESET_CENTER)
	stamp.offset_left = -320.0
	stamp.offset_top = -72.0
	stamp.offset_right = 320.0
	stamp.offset_bottom = 72.0
	stamp.rotation = -0.08
	stamp.add_theme_font_size_override(&"font_size", 72)
	stamp.add_theme_color_override(&"font_color", Color(0.78, 0.1, 0.12, 1))
	stamp.add_theme_color_override(&"font_outline_color", Color(0.22, 0.06, 0.04, 1))
	stamp.add_theme_constant_override(&"outline_size", 10)
	stamp.modulate.a = 0.0
	stamp.scale = Vector2(1.8, 1.8)
	stamp.pivot_offset = Vector2(320, 36)
	add_child(stamp)

	var subtitle := Label.new()
	subtitle.text = tr("The trail got the better of you...")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -280.0
	subtitle.offset_top = 56.0
	subtitle.offset_right = 280.0
	subtitle.offset_bottom = 96.0
	subtitle.add_theme_font_size_override(&"font_size", 22)
	subtitle.add_theme_color_override(&"font_color", Color(0.94, 0.82, 0.52, 1))
	subtitle.add_theme_color_override(&"font_outline_color", Color(0.22, 0.06, 0.04, 0.75))
	subtitle.add_theme_constant_override(&"outline_size", 3)
	subtitle.modulate.a = 0.0
	add_child(subtitle)

	var fade := create_tween()
	fade.tween_property(dim, "color:a", 0.72, 0.55)
	fade.parallel().tween_property(wash, "color:a", 0.35, 0.55)

	await get_tree().create_timer(0.35).timeout

	var slam := create_tween()
	slam.tween_property(stamp, "modulate:a", 1.0, 0.08)
	slam.parallel().tween_property(stamp, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK)
	var shake := create_tween()
	shake.tween_property(stamp, "rotation", 0.04, 0.06)
	shake.tween_property(stamp, "rotation", -0.06, 0.06)
	shake.tween_property(stamp, "rotation", 0.0, 0.08)

	await get_tree().create_timer(0.28).timeout

	var sub_in := create_tween()
	sub_in.tween_property(subtitle, "modulate:a", 1.0, 0.35)

	await get_tree().create_timer(2.2).timeout

	var out := create_tween()
	out.tween_property(dim, "modulate:a", 0.0, 0.45)
	out.parallel().tween_property(wash, "modulate:a", 0.0, 0.45)
	out.parallel().tween_property(stamp, "modulate:a", 0.0, 0.45)
	out.parallel().tween_property(subtitle, "modulate:a", 0.0, 0.45)
	await out.finished

	GameManager.return_to_save_select()
