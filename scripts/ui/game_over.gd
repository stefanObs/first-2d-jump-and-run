extends CanvasLayer

## Advanced Mode game over — same desert / saloon look as the start screen.

const BACKDROP := preload("res://assets/ui/menu_backdrop_desert.png")
const TITLE_BOARD := preload("res://assets/ui/saloon_title_board.png")
const HEART := preload("res://assets/ui/menu_icon_heart.png")
const INK := Color(0.35, 0.16, 0.05, 1.0)
const INK_SOFT := Color(0.42, 0.22, 0.08, 1.0)


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()


func _run() -> void:
	AudioManager.stop_music()

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.modulate.a = 0.0
	add_child(root)

	var backdrop := TextureRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = BACKDROP
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)

	## Soft dusk veil so the saloon board reads clearly without a flat blackout.
	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.45, 0.18, 0.06, 0.22)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(veil)

	var board := TextureRect.new()
	board.name = "TitleBoard"
	board.texture = TITLE_BOARD
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	board.custom_minimum_size = Vector2(720, 220)
	board.set_anchors_preset(Control.PRESET_CENTER)
	board.offset_left = -360.0
	board.offset_top = -150.0
	board.offset_right = 360.0
	board.offset_bottom = 70.0
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.pivot_offset = Vector2(360, 110)
	board.scale = Vector2(0.92, 0.92)
	root.add_child(board)

	var stamp := Label.new()
	stamp.name = "Stamp"
	stamp.text = tr("GAME OVER")
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stamp.offset_top = -18.0
	stamp.offset_bottom = -18.0
	stamp.add_theme_font_size_override(&"font_size", 64)
	stamp.add_theme_color_override(&"font_color", INK)
	stamp.add_theme_color_override(&"font_outline_color", Color(1.0, 0.92, 0.72, 0.85))
	stamp.add_theme_constant_override(&"outline_size", 8)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(stamp)

	var hearts := HBoxContainer.new()
	hearts.name = "BrokenHearts"
	hearts.alignment = BoxContainer.ALIGNMENT_CENTER
	hearts.add_theme_constant_override(&"separation", 10)
	hearts.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hearts.offset_left = -90.0
	hearts.offset_top = 78.0
	hearts.offset_right = 90.0
	hearts.offset_bottom = 122.0
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hearts)
	for _i in range(3):
		var heart := TextureRect.new()
		heart.custom_minimum_size = Vector2(36, 36)
		heart.texture = HEART
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.modulate = Color(0.55, 0.45, 0.4, 0.55)
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts.add_child(heart)

	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = tr("The trail got the better of you...")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.offset_left = -340.0
	subtitle.offset_top = 96.0
	subtitle.offset_right = 340.0
	subtitle.offset_bottom = 140.0
	subtitle.add_theme_font_size_override(&"font_size", 24)
	subtitle.add_theme_color_override(&"font_color", INK_SOFT)
	subtitle.add_theme_color_override(&"font_outline_color", Color(1.0, 0.94, 0.78, 0.7))
	subtitle.add_theme_constant_override(&"outline_size", 4)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	subtitle.modulate.a = 0.0
	root.add_child(subtitle)

	var fade_in := create_tween()
	fade_in.tween_property(root, "modulate:a", 1.0, 0.45)
	fade_in.parallel().tween_property(board, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree():
		return
	var sub_in := create_tween()
	sub_in.tween_property(subtitle, "modulate:a", 1.0, 0.4)

	await get_tree().create_timer(2.2).timeout
	if not is_inside_tree():
		return

	var out := create_tween()
	out.tween_property(root, "modulate:a", 0.0, 0.45)
	await out.finished
	if not is_inside_tree():
		return

	GameManager.return_to_save_select()
