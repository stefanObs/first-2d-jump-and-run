extends Control

## Kid-first title screen: giant numbered save doors, icon chrome, F1 debug strip.
## Matches chibi cowboy/cowgirl art — thick outlines, warm wood, bandana-red focus.

const TITLE_CREAM := Color(0.96, 0.86, 0.48, 1.0)
const TITLE_CREAM_HOVER := Color(1.0, 0.92, 0.62, 1.0)
const WOOD := Color(0.78, 0.48, 0.22, 0.96)
const WOOD_HOVER := Color(0.90, 0.62, 0.30, 1.0)
const STAR_TEX := preload("res://assets/world/star_badge.png")
const PORTRAIT_EMPTY := preload("res://assets/ui/menu_portrait_empty.png")
const PORTRAIT_COWBOY := preload("res://assets/ui/menu_portrait_cowboy.png")
const PORTRAIT_COWGIRL := preload("res://assets/ui/menu_portrait_cowgirl.png")
const ELEMENT_REFERENCE_PATH := "res://docs/element_name_reference.png"
const SHEET_ZOOM_MIN := 1.0
const SHEET_ZOOM_MAX := 4.0
const SHEET_ZOOM_STEP := 0.25
const MAX_STAR_DOTS := 3

var _cards: Array[Button] = []
var _index: int = 0
var _status_hint: Label
var _delete_dialog: ConfirmationDialog
var _settings: SettingsPanel
var _settings_dim: ColorRect
var _debug_strip: Control
var _element_ref_button: Button
var _translation_editor_button: Button
var _element_ref_overlay: Control
var _sheet: TextureRect
var _sheet_scroll: ScrollContainer
var _sheet_zoom_label: Label
var _sheet_zoom: float = 1.0
var _sheet_base_size: Vector2 = Vector2.ZERO
var _sheet_panning: bool = false
var _sheet_pan_last: Vector2 = Vector2.ZERO
var _hearts_button: Button
var _settings_button: Button
var _workshop_button: Button
var _exit_button: Button
var _cowboy_button: Button
var _cowgirl_button: Button
var _character_hint: Label
var _creation_credit: Label


func _ready() -> void:
	_status_hint = get_node_or_null("StatusHint") as Label
	_delete_dialog = get_node_or_null("DeleteConfirmation") as ConfirmationDialog
	_settings = get_node_or_null("SettingsPanel") as SettingsPanel
	_settings_dim = get_node_or_null("SettingsDim") as ColorRect
	_debug_strip = get_node_or_null("DebugStrip") as Control
	_element_ref_button = get_node_or_null("DebugStrip/ElementReferenceButton") as Button
	_translation_editor_button = get_node_or_null("DebugStrip/TranslationEditorButton") as Button
	_element_ref_overlay = get_node_or_null("ElementReferenceOverlay") as Control
	_hearts_button = get_node_or_null("HeartsButton") as Button
	_settings_button = get_node_or_null("SettingsButton") as Button
	_workshop_button = get_node_or_null("BuildTrailButton") as Button
	_exit_button = get_node_or_null("ExitGameButton") as Button
	_cowboy_button = get_node_or_null("Mascots/Cowboy") as Button
	_cowgirl_button = get_node_or_null("Mascots/Cowgirl") as Button
	_character_hint = get_node_or_null("CharacterHint") as Label
	_creation_credit = get_node_or_null("CreationCredit") as Label
	_localize_static_labels()
	_style_screen()
	_setup_element_reference()
	_setup_chrome_buttons()
	_setup_character_pickers()
	if _delete_dialog != null:
		_delete_dialog.confirmed.connect(_confirm_delete)
		_style_delete_dialog()
	if _settings != null:
		_settings.process_mode = Node.PROCESS_MODE_ALWAYS
		_settings.visible = false
		_settings.closed.connect(_close_settings)
	if _settings_dim != null:
		_settings_dim.visible = false
		_settings_dim.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
				_close_settings()
		)
	for i in range(3):
		var card := get_node_or_null("Slots/Slot%d" % (i + 1)) as Button
		if card == null:
			continue
		_cards.append(card)
		_style_door_button(card)
		_ensure_star_dots(card)
		var captured := i
		card.pressed.connect(func() -> void:
			if _settings_open() or _element_reference_open():
				return
			_select_slot(captured)
		)
		card.gui_input.connect(func(event: InputEvent) -> void:
			if _settings_open() or _element_reference_open():
				return
			if (
				event is InputEventMouseButton
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT
				and (event as InputEventMouseButton).pressed
			):
				_index = captured
				_highlight()
				_request_delete()
		)
		card.mouse_entered.connect(func() -> void:
			if _settings_open() or _element_reference_open():
				return
			_index = captured
			_highlight()
			_sync_play_settings_from_focused_slot()
		)
		card.focus_entered.connect(func() -> void:
			if _settings_open() or _element_reference_open():
				return
			_index = captured
			_highlight()
			_sync_play_settings_from_focused_slot()
		)
	GameManager.saves_changed.connect(_refresh)
	GameManager.settings_changed.connect(_on_settings_changed)
	InputManager.device_changed.connect(_on_input_device_changed)
	GameManager.reset_trail_mode_to_classic()
	_refresh()
	_refresh_hearts_button()
	_refresh_character_pickers()
	_refresh_status_hint()
	_highlight()
	_sync_play_settings_from_focused_slot()
	_bob_title()
	_breathe_mascots()
	MenuChrome.bind_menu_buttons(self)


func _exit_tree() -> void:
	if GameManager.saves_changed.is_connected(_refresh):
		GameManager.saves_changed.disconnect(_refresh)
	if GameManager.settings_changed.is_connected(_on_settings_changed):
		GameManager.settings_changed.disconnect(_on_settings_changed)
	if InputManager.device_changed.is_connected(_on_input_device_changed):
		InputManager.device_changed.disconnect(_on_input_device_changed)


func _on_input_device_changed(_device: Variant) -> void:
	_refresh_status_hint()


func _localize_static_labels() -> void:
	var title := get_node_or_null("Title") as Label
	if title != null:
		title.text = tr("Cowboy Trail")
	var title_logo := get_node_or_null("TitleLogo") as TextureRect
	if title_logo != null:
		title_logo.tooltip_text = tr("Cowboy Trail")
	if _character_hint != null:
		# Concrete chosen rider is filled by _refresh_character_pickers().
		_character_hint.text = tr("Pick Cowboy or Cowgirl")
	if _creation_credit != null:
		_creation_credit.text = tr("Created with AI assistance from human instructions.")
	if _cowboy_button != null:
		_cowboy_button.tooltip_text = tr("Cowboy")
		var cowboy_name := _cowboy_button.get_node_or_null("Name") as Label
		if cowboy_name != null:
			cowboy_name.text = tr("Cowboy")
	if _cowgirl_button != null:
		_cowgirl_button.tooltip_text = tr("Cowgirl")
		var cowgirl_name := _cowgirl_button.get_node_or_null("Name") as Label
		if cowgirl_name != null:
			cowgirl_name.text = tr("Cowgirl")
	if _settings_button != null:
		_settings_button.tooltip_text = tr("Settings")
	if _workshop_button != null:
		_workshop_button.tooltip_text = tr("Campaign Workshop")
	if _hearts_button != null:
		_hearts_button.tooltip_text = tr("Trail mode")
	if _exit_button != null:
		_exit_button.text = tr("Exit Game")
		_exit_button.tooltip_text = tr("Exit Game")
	if _translation_editor_button != null:
		_translation_editor_button.text = tr("Translation Editor")
	if _element_ref_button != null:
		_element_ref_button.text = tr("Element Names")
	var overlay_title := get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/Title") as Label
	if overlay_title != null:
		overlay_title.text = tr("Element name sheet")
	var zoom_out := get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/ZoomBar/ZoomOutButton") as Button
	if zoom_out != null:
		zoom_out.tooltip_text = tr("Zoom out")
	var zoom_in := get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/ZoomBar/ZoomInButton") as Button
	if zoom_in != null:
		zoom_in.tooltip_text = tr("Zoom in")
	var zoom_hint := get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/ZoomBar/ZoomHint") as Label
	if zoom_hint != null:
		zoom_hint.text = tr("Mouse wheel zooms · drag to pan")
	var overlay_close := get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/CloseButton") as Button
	if overlay_close != null:
		overlay_close.text = tr("Back")
	if _delete_dialog != null:
		_delete_dialog.title = tr("Delete save?")
		_delete_dialog.dialog_text = tr("Delete the selected save? This cannot be undone.")
		_delete_dialog.ok_button_text = tr("Delete")
		_delete_dialog.cancel_button_text = tr("Keep it")


func _setup_chrome_buttons() -> void:
	if _workshop_button != null:
		_style_circle_chrome(_workshop_button)
		_workshop_button.pressed.connect(func() -> void:
			if _settings_open() or _element_reference_open():
				return
			AudioManager.ensure_gameplay_music()
			GameManager.open_custom_level_hub()
		)
	if _settings_button != null:
		_style_circle_chrome(_settings_button)
		_settings_button.pressed.connect(_open_settings)
	if _hearts_button != null:
		_style_circle_chrome(_hearts_button)
		_hearts_button.pressed.connect(_toggle_trail_mode)
	if _exit_button != null:
		_style_exit_button(_exit_button)
		_exit_button.pressed.connect(_exit_game)
	if _translation_editor_button != null:
		_style_action_button(_translation_editor_button)
		_translation_editor_button.pressed.connect(func() -> void:
			if _settings_open() or _element_reference_open():
				return
			if not DebugLabels.is_enabled():
				return
			get_tree().change_scene_to_file("res://scenes/ui/translation_editor.tscn")
		)


func _toggle_trail_mode() -> void:
	if _settings_open() or _element_reference_open():
		return
	var next := GameManager.cycle_badges_per_life(GameManager.get_badges_per_life_setting())
	GameManager.set_badges_per_life_setting(next)
	_refresh_hearts_button()
	_commit_play_settings_to_focused_slot()
	_flash_status(GameManager.trail_mode_label(next))


func _on_settings_changed() -> void:
	_localize_static_labels()
	_refresh_hearts_button()
	_refresh_character_pickers()
	_refresh()
	## Only push rider/mode onto a filled door when the player edits Settings.
	if _settings_open():
		_commit_play_settings_to_focused_slot()


func _setup_character_pickers() -> void:
	for button in [_cowboy_button, _cowgirl_button]:
		if button == null:
			continue
		var empty := StyleBoxEmpty.new()
		_apply_button_styles(button, empty, empty)
	if _cowboy_button != null:
		_cowboy_button.pressed.connect(func() -> void:
			_pick_character(GameManager.PLAYER_COWBOY)
		)
	if _cowgirl_button != null:
		_cowgirl_button.pressed.connect(func() -> void:
			_pick_character(GameManager.PLAYER_COWGIRL)
		)


func _pick_character(character: String) -> void:
	if _settings_open() or _element_reference_open():
		return
	if GameManager.get_player_character() == character:
		_refresh_character_pickers()
		return
	GameManager.set_setting("player_character", character)
	_commit_play_settings_to_focused_slot()
	_refresh_character_pickers()
	_refresh()
	_flash_status(tr("Cowboy") if character == GameManager.PLAYER_COWBOY else tr("Cowgirl"))


func _refresh_character_pickers() -> void:
	var is_cowgirl := GameManager.get_player_character() == GameManager.PLAYER_COWGIRL
	_style_character_picker(_cowboy_button, not is_cowgirl, tr("Cowboy"))
	_style_character_picker(_cowgirl_button, is_cowgirl, tr("Cowgirl"))
	if _character_hint != null:
		var chosen := tr("Cowgirl") if is_cowgirl else tr("Cowboy")
		_character_hint.text = tr("Playing as %s") % chosen


func _style_character_picker(button: Button, selected: bool, display_name: String = "") -> void:
	if button == null:
		return
	button.modulate = Color(1, 1, 1, 1) if selected else Color(0.55, 0.52, 0.48, 0.75)
	## No painted border/fill — selection is scale + ChosenMark (same look as first boot).
	var empty := StyleBoxEmpty.new()
	_apply_button_styles(button, empty, empty)
	MenuChrome.set_button_rest_scale(
		button, Vector2(1.12, 1.12) if selected else Vector2(0.86, 0.86)
	)
	var mark := button.get_node_or_null("ChosenMark") as CanvasItem
	if mark != null:
		mark.visible = selected
	var name_label := button.get_node_or_null("Name") as Label
	if name_label != null:
		if display_name != "":
			name_label.text = display_name
		name_label.add_theme_color_override(
			&"font_color",
			Color(1.0, 0.92, 0.45, 1.0) if selected else Color(0.78, 0.72, 0.62, 0.85)
		)
		name_label.add_theme_font_size_override(&"font_size", 18 if selected else 15)


func _refresh_hearts_button() -> void:
	if _hearts_button == null:
		return
	var badges_per_life := GameManager.get_badges_per_life_setting()
	_hearts_button.tooltip_text = "%s — %s" % [tr("Trail mode"), GameManager.trail_mode_label(badges_per_life)]
	var icons := _hearts_button.get_node_or_null("HeartIcons") as CanvasItem
	if icons != null:
		icons.visible = false
	var art := _hearts_button.get_node_or_null("ModeArt") as TextureRect
	if art == null:
		art = TextureRect.new()
		art.name = "ModeArt"
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		## Fill the plate; a slim inset keeps art off the rivet ring.
		art.offset_left = 6
		art.offset_top = 4
		art.offset_right = -6
		art.offset_bottom = -4
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hearts_button.add_child(art)
	else:
		art.offset_left = 6
		art.offset_top = 4
		art.offset_right = -6
		art.offset_bottom = -4
	var path := GameManager.trail_mode_icon_path(badges_per_life)
	if ResourceLoader.exists(path):
		art.texture = load(path) as Texture2D
	art.modulate = Color(1, 1, 1, 1)


func _setup_element_reference() -> void:
	if _element_ref_button != null:
		_style_action_button(_element_ref_button)
		_element_ref_button.pressed.connect(_open_element_reference)
	if _element_ref_overlay != null:
		_element_ref_overlay.visible = false
		_element_ref_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		var panel := get_node_or_null("ElementReferenceOverlay/Panel") as PanelContainer
		if panel != null:
			panel.add_theme_stylebox_override(&"panel", _wood_style(WOOD, 14, 12))
		_sheet_scroll = get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/SheetScroll") as ScrollContainer
		_sheet = get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/SheetScroll/Sheet") as TextureRect
		_sheet_zoom_label = get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/ZoomBar/ZoomLabel") as Label
		if _sheet != null and ResourceLoader.exists(ELEMENT_REFERENCE_PATH):
			_sheet.texture = load(ELEMENT_REFERENCE_PATH) as Texture2D
			_sheet.gui_input.connect(_on_sheet_gui_input)
		if _sheet_scroll != null:
			_sheet_scroll.resized.connect(_recompute_sheet_base_size)
		var zoom_out := get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/ZoomBar/ZoomOutButton") as Button
		if zoom_out != null:
			_style_action_button(zoom_out)
			zoom_out.pressed.connect(func() -> void: nudge_element_reference_zoom(-SHEET_ZOOM_STEP))
		var zoom_in := get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/ZoomBar/ZoomInButton") as Button
		if zoom_in != null:
			_style_action_button(zoom_in)
			zoom_in.pressed.connect(func() -> void: nudge_element_reference_zoom(SHEET_ZOOM_STEP))
		var close_btn := get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/CloseButton") as Button
		if close_btn != null:
			_style_action_button(close_btn)
			close_btn.pressed.connect(_close_element_reference)
		var dim := get_node_or_null("ElementReferenceOverlay/Dim") as ColorRect
		if dim != null:
			dim.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
					_close_element_reference()
			)
		_refresh_sheet_zoom_label()
	if not DebugLabels.enabled_changed.is_connected(_on_debug_labels_enabled_changed):
		DebugLabels.enabled_changed.connect(_on_debug_labels_enabled_changed)
	_sync_element_reference_visibility(DebugLabels.is_enabled())


func _on_debug_labels_enabled_changed(is_enabled: bool) -> void:
	_sync_element_reference_visibility(is_enabled)


func _sync_element_reference_visibility(is_enabled: bool) -> void:
	if _debug_strip != null:
		_debug_strip.visible = is_enabled
	if _element_ref_button != null:
		_element_ref_button.visible = is_enabled
	if _translation_editor_button != null:
		_translation_editor_button.visible = is_enabled
	if not is_enabled and _element_reference_open():
		_close_element_reference()


func translation_editor_unlocked() -> bool:
	return DebugLabels.is_enabled()


func element_reference_unlocked() -> bool:
	return DebugLabels.is_enabled()


func element_reference_path() -> String:
	return ELEMENT_REFERENCE_PATH


func element_reference_zoom() -> float:
	return _sheet_zoom


func nudge_element_reference_zoom(delta: float) -> void:
	_apply_sheet_zoom(_sheet_zoom + delta)


func _element_reference_open() -> bool:
	return _element_ref_overlay != null and _element_ref_overlay.visible


func _open_element_reference() -> void:
	if _element_ref_overlay == null or not DebugLabels.is_enabled():
		return
	if _settings_open():
		_close_settings()
	_sheet_zoom = 1.0
	_sheet_panning = false
	_element_ref_overlay.visible = true
	call_deferred("_finish_open_element_reference")


func _finish_open_element_reference() -> void:
	if not _element_reference_open():
		return
	_recompute_sheet_base_size()
	if _sheet_scroll != null:
		_sheet_scroll.scroll_horizontal = 0
		_sheet_scroll.scroll_vertical = 0


func _close_element_reference() -> void:
	_sheet_panning = false
	if _element_ref_overlay != null:
		_element_ref_overlay.visible = false
	_refresh_status_hint()
	_highlight()


func _sheet_viewport_size() -> Vector2:
	if _sheet_scroll == null:
		return Vector2(980, 480)
	var size := _sheet_scroll.size
	if size.x < 2.0 or size.y < 2.0:
		return Vector2(980, 480)
	return size


func _recompute_sheet_base_size() -> void:
	if _sheet == null or _sheet.texture == null:
		return
	var tex_size := _sheet.texture.get_size()
	if tex_size.x < 1.0 or tex_size.y < 1.0:
		return
	var view := _sheet_viewport_size()
	var fit := minf(view.x / tex_size.x, view.y / tex_size.y)
	_sheet_base_size = tex_size * fit
	_apply_sheet_zoom(_sheet_zoom, false)


func _apply_sheet_zoom(zoom: float, keep_center: bool = true) -> void:
	var old_zoom := _sheet_zoom
	_sheet_zoom = clampf(zoom, SHEET_ZOOM_MIN, SHEET_ZOOM_MAX)
	_refresh_sheet_zoom_label()
	if _sheet == null or _sheet_base_size.x < 1.0:
		return
	var center := Vector2.ZERO
	if keep_center and _sheet_scroll != null and old_zoom > 0.0:
		center = Vector2(
			float(_sheet_scroll.scroll_horizontal) + _sheet_scroll.size.x * 0.5,
			float(_sheet_scroll.scroll_vertical) + _sheet_scroll.size.y * 0.5
		)
	var new_size := _sheet_base_size * _sheet_zoom
	_sheet.custom_minimum_size = new_size
	_sheet.size = new_size
	if keep_center and _sheet_scroll != null and old_zoom > 0.0:
		var factor := _sheet_zoom / old_zoom
		_sheet_scroll.scroll_horizontal = int(center.x * factor - _sheet_scroll.size.x * 0.5)
		_sheet_scroll.scroll_vertical = int(center.y * factor - _sheet_scroll.size.y * 0.5)


func _refresh_sheet_zoom_label() -> void:
	if _sheet_zoom_label != null:
		_sheet_zoom_label.text = "%d%%" % int(roundf(_sheet_zoom * 100.0))


func _on_sheet_gui_input(event: InputEvent) -> void:
	if _sheet == null:
		return
	if event is InputEventMagnifyGesture:
		var magnify := event as InputEventMagnifyGesture
		_apply_sheet_zoom(_sheet_zoom * magnify.factor)
		_sheet.accept_event()
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			nudge_element_reference_zoom(SHEET_ZOOM_STEP)
			_sheet.accept_event()
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			nudge_element_reference_zoom(-SHEET_ZOOM_STEP)
			_sheet.accept_event()
		elif mouse.button_index == MOUSE_BUTTON_LEFT:
			_sheet_panning = mouse.pressed
			_sheet_pan_last = mouse.global_position
			if mouse.pressed:
				_sheet.accept_event()
		return
	if event is InputEventMouseMotion and _sheet_panning and _sheet_scroll != null:
		var motion := event as InputEventMouseMotion
		var delta := motion.global_position - _sheet_pan_last
		_sheet_pan_last = motion.global_position
		_sheet_scroll.scroll_horizontal -= int(delta.x)
		_sheet_scroll.scroll_vertical -= int(delta.y)
		_sheet.accept_event()


func _style_screen() -> void:
	var legacy_bg := get_node_or_null("Background") as CanvasItem
	if legacy_bg != null:
		legacy_bg.visible = false
	if _status_hint != null:
		_apply_cream_outline(_status_hint, Color(0.96, 0.9, 0.7, 1.0), Color(0.24, 0.09, 0.04, 0.8), 2)


func _apply_cream_outline(label: Label, fill: Color, outline: Color, outline_size: int) -> void:
	label.add_theme_color_override(&"font_color", fill)
	label.add_theme_color_override(&"font_outline_color", outline)
	if outline_size > 0:
		label.add_theme_constant_override(&"outline_size", outline_size)


func _style_door_button(button: Button, _radius: int = 18, _pad: int = 12) -> void:
	button.text = ""
	button.flat = true
	button.pivot_offset = button.custom_minimum_size * 0.5
	var empty := StyleBoxEmpty.new()
	_apply_button_styles(button, empty, empty)


func _style_exit_button(button: Button) -> void:
	MenuChrome.style_wood_button(button, 18)
	MenuChrome.apply_button_icon(button, "res://assets/ui/menu_icon_exit.png", 40)
	var normal := MenuChrome.wood_style(MenuChrome.WOOD, 10)
	normal.content_margin_left = 10
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := MenuChrome.wood_style(MenuChrome.WOOD_HOVER, 10)
	hover.content_margin_left = 10
	hover.content_margin_right = 14
	hover.content_margin_top = 8
	hover.content_margin_bottom = 8
	MenuChrome.apply_button_styleboxes(button, normal, hover)


func _exit_game() -> void:
	if _settings_open() or _element_reference_open():
		return
	GameManager.flush_save_to_disk()
	get_tree().quit()


func _style_circle_chrome(button: Button) -> void:
	button.text = ""
	button.flat = true
	button.icon = null
	var empty := StyleBoxEmpty.new()
	_apply_button_styles(button, empty, empty)


func _style_action_button(button: Button) -> void:
	_apply_cream_button_fonts(button)
	var normal := _wood_style(WOOD, 10, 8)
	var hover := _wood_style(WOOD_HOVER, 10, 8)
	_apply_button_styles(button, normal, hover)


func _apply_cream_button_fonts(button: Button) -> void:
	button.add_theme_color_override(&"font_color", TITLE_CREAM)
	button.add_theme_color_override(&"font_hover_color", TITLE_CREAM_HOVER)
	button.add_theme_color_override(&"font_pressed_color", MenuChrome.TITLE_CREAM_PRESSED)
	button.add_theme_color_override(&"font_focus_color", TITLE_CREAM)
	button.add_theme_color_override(&"font_outline_color", Color(0.22, 0.08, 0.03, 0.85))
	button.add_theme_constant_override(&"outline_size", 3)


func _apply_button_styles(button: Button, normal: StyleBox, hover: StyleBox) -> void:
	MenuChrome.apply_button_styleboxes(button, normal, hover)


func _wood_style(fill: Color, radius: int, _pad_v: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(4)
	style.border_color = Color(0.58, 0.18, 0.10, 1.0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _style_delete_dialog() -> void:
	if _delete_dialog == null:
		return
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.78, 0.48, 0.22, 0.98)
	panel.set_border_width_all(6)
	panel.border_color = Color(0.45, 0.16, 0.08, 1.0)
	panel.set_corner_radius_all(18)
	panel.content_margin_left = 22
	panel.content_margin_right = 22
	panel.content_margin_top = 18
	panel.content_margin_bottom = 18
	_delete_dialog.add_theme_stylebox_override(&"panel", panel)
	_delete_dialog.add_theme_color_override(&"title_color", Color(0.98, 0.9, 0.55, 1.0))
	_delete_dialog.add_theme_font_size_override(&"title_font_size", 28)
	_delete_dialog.add_theme_color_override(&"font_color", Color(0.98, 0.93, 0.78, 1.0))
	_delete_dialog.add_theme_font_size_override(&"font_size", 22)
	var ok := _delete_dialog.get_ok_button()
	var cancel := _delete_dialog.get_cancel_button()
	for btn in [ok, cancel]:
		if btn == null:
			continue
		_apply_cream_button_fonts(btn)
		var normal := _wood_style(Color(0.62, 0.32, 0.14, 1.0), 12, 10)
		var hover := _wood_style(Color(0.78, 0.42, 0.18, 1.0), 12, 10)
		_apply_button_styles(btn, normal, hover)
		btn.custom_minimum_size = Vector2(140, 48)


func _breathe_mascots() -> void:
	# Selection highlight owns mascot scale; keep a gentle bob on the sprites only.
	for path in ["Mascots/Cowboy/Sprite", "Mascots/Cowgirl/Sprite"]:
		var sprite := get_node_or_null(path) as Control
		if sprite == null:
			continue
		var base := sprite.position.y
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "position:y", base - 3.0, 1.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position:y", base + 2.0, 1.05).set_trans(Tween.TRANS_SINE)


func _ensure_star_dots(card: Button) -> void:
	var stars := card.get_node_or_null("Stars") as HBoxContainer
	if stars == null:
		return
	while stars.get_child_count() < MAX_STAR_DOTS:
		var star := TextureRect.new()
		star.custom_minimum_size = Vector2(28, 28)
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.texture = STAR_TEX
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars.add_child(star)


func _bob_title() -> void:
	var title := get_node_or_null("TitleLogo") as Control
	if title == null:
		title = get_node_or_null("Title") as Control
	if title == null:
		return
	var base := title.position.y
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(title, "position:y", base - 5.0, 0.95).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title, "position:y", base + 3.0, 0.95).set_trans(Tween.TRANS_SINE)


func _settings_open() -> bool:
	return _settings != null and _settings.visible


func _open_settings() -> void:
	if _settings == null:
		return
	if _element_reference_open():
		_close_element_reference()
	if _settings_dim != null:
		_settings_dim.visible = true
	_settings.visible = true
	_settings.focus_first()


func _close_settings() -> void:
	if _settings != null:
		_settings.visible = false
	if _settings_dim != null:
		_settings_dim.visible = false
	_refresh_hearts_button()
	_refresh_character_pickers()
	_refresh_status_hint()
	_highlight()


func _unhandled_input(event: InputEvent) -> void:
	if _element_reference_open():
		if event.is_action_pressed(&"back") or event.is_action_pressed(&"pause"):
			_close_element_reference()
			get_viewport().set_input_as_handled()
		return
	if _settings_open():
		return
	if _delete_dialog != null and _delete_dialog.visible:
		if event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
			_delete_dialog.hide()
			_confirm_delete()
		elif event.is_action_pressed(&"back"):
			_delete_dialog.hide()
		return
	if event.is_action_pressed(&"delete_save"):
		_request_delete()
	elif event.is_action_pressed(&"ui_right") or event.is_action_pressed(&"move_right"):
		_index = wrapi(_index + 1, 0, _cards.size())
		_highlight()
		_sync_play_settings_from_focused_slot()
	elif event.is_action_pressed(&"ui_left") or event.is_action_pressed(&"move_left"):
		_index = wrapi(_index - 1, 0, _cards.size())
		_highlight()
		_sync_play_settings_from_focused_slot()
	elif event.is_action_pressed(&"confirm") or event.is_action_pressed(&"jump"):
		_select_slot(_index)


func _select_slot(slot_index: int) -> void:
	AudioManager.ensure_gameplay_music()
	_index = slot_index
	## Commit the title-screen rider / trail-mode picks (Classic unless hearts were chosen).
	GameManager.prepare_slot_for_start(slot_index)
	GameManager.start_or_continue_slot(slot_index)


func _sync_play_settings_from_focused_slot() -> void:
	if _index < 0 or _index >= 3:
		return
	if GameManager.is_slot_empty(_index):
		return
	GameManager.apply_play_settings_from_slot(_index)


func _commit_play_settings_to_focused_slot() -> void:
	if not is_inside_tree():
		return
	if _index < 0 or _index >= 3:
		return
	if GameManager.is_slot_empty(_index):
		return
	GameManager.commit_play_settings_to_slot(_index)


func _request_delete() -> void:
	if GameManager.is_slot_empty(_index):
		_flash_status(tr("Save %d is already empty.") % (_index + 1))
		return
	if _delete_dialog == null:
		return
	_delete_dialog.dialog_text = tr("Delete Save %d? This cannot be undone.") % (_index + 1)
	_style_delete_dialog()
	_delete_dialog.popup_centered(Vector2i(520, 220))


func _confirm_delete() -> void:
	GameManager.erase_slot(_index)
	_refresh()
	_refresh_status_hint()


func _refresh() -> void:
	for i in range(_cards.size()):
		var card := _cards[i]
		var slot := GameManager.get_slot(i)
		var number := card.get_node_or_null("Number") as Label
		if number != null:
			number.text = str(i + 1)
		var portrait := card.get_node_or_null("Portrait") as TextureRect
		var stars := card.get_node_or_null("Stars") as HBoxContainer
		var empty := bool(slot.get("empty", true))
		if portrait != null:
			if empty:
				portrait.texture = PORTRAIT_EMPTY
				portrait.modulate = Color(1, 1, 1, 1)
			else:
				portrait.texture = _portrait_for_character(
					GameManager.slot_player_character(i)
				)
				portrait.modulate = Color(1, 1, 1, 1)
		if stars != null:
			var badge_dots := 0 if empty else clampi(int(slot.get("stars", 0)), 0, MAX_STAR_DOTS)
			if not empty and badge_dots == 0 and int(slot.get("current_level", 1)) > 1:
				badge_dots = 1
			for s in range(stars.get_child_count()):
				var star := stars.get_child(s) as CanvasItem
				if star != null:
					star.visible = s < badge_dots


func _portrait_for_character(character: String) -> Texture2D:
	if character == GameManager.PLAYER_COWGIRL:
		return PORTRAIT_COWGIRL
	return PORTRAIT_COWBOY


func _refresh_status_hint() -> void:
	if _status_hint == null:
		return
	_status_hint.text = ""


func _flash_status(message: String) -> void:
	if _status_hint == null:
		return
	_status_hint.text = message


func _highlight() -> void:
	for i in range(_cards.size()):
		var selected := i == _index
		MenuChrome.set_button_rest_scale(
			_cards[i], Vector2(1.04, 1.04) if selected else Vector2.ONE
		)
		var ring := _cards[i].get_node_or_null("SelectRing") as CanvasItem
		if ring != null:
			ring.visible = selected
		var number := _cards[i].get_node_or_null("Number") as Label
		if number != null:
			number.add_theme_color_override(
				&"font_color",
				Color(1.0, 0.95, 0.75, 1.0) if selected else Color(1, 1, 1, 1)
			)
