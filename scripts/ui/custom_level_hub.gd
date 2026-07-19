extends Control

## Three local custom-trail slots, separate from campaign saves.


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.98, 0.74, 0.45)
	add_child(background)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-460, -270)
	box.size = Vector2(920, 540)
	box.add_theme_constant_override(&"separation", 18)
	add_child(box)
	var title := Label.new()
	title.text = "Build Your Own Cowboy Trail"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 38)
	title.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	box.add_child(title)
	var help := Label.new()
	help.text = "Pick a family trail slot to edit, then press Play Test!"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override(&"font_size", 20)
	box.add_child(help)
	for slot_index in range(CustomLevelStore.SLOT_COUNT):
		var button := Button.new()
		button.custom_minimum_size = Vector2(900, 90)
		button.add_theme_font_size_override(&"font_size", 24)
		var exists := CustomLevelStore.exists(slot_index)
		var data := CustomLevelStore.load_level(slot_index)
		button.text = "Trail %d — %s%s" % [
			slot_index + 1,
			str(data.get("title", "Family Trail")),
			" (saved)" if exists else " (new)",
		]
		var captured := slot_index
		button.pressed.connect(func() -> void: GameManager.edit_custom_level(captured))
		box.add_child(button)
	var back := Button.new()
	back.custom_minimum_size = Vector2(900, 62)
	back.text = "Back to Cowboy Trail"
	back.add_theme_font_size_override(&"font_size", 20)
	back.pressed.connect(GameManager.return_to_save_select)
	box.add_child(back)
	if box.get_child_count() > 2:
		(box.get_child(2) as Control).grab_focus()
