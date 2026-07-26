extends Control

## Grid/stamp editor: typed stamp dropdowns + scrollable trail grid above a live preview.

const TOOL_CATEGORIES: Array = [
	{
		"id": "trail",
		"label": "Trail",
		"tools": [
			["ground", "Dirt", "res://assets/world/trail_desert_tile.png"],
			["canyon", "Canyon", "res://assets/ui/editor_canyon_stamp_icon.png"],
			["platform", "Plank", "res://assets/world/trail_dirt_tile.png"],
		],
	},
	{
		"id": "pickups",
		"label": "Pickups",
		"tools": [
			["star", "Badge", "res://assets/world/star_badge.png"],
			["chest", "Treasure Chest", "res://assets/world/treasure_chest_stamp.png"],
			["checkpoint", "Camp", "res://assets/world/checkpoint_active.png"],
		],
	},
	{
		"id": "hazards",
		"label": "Hazards",
		"tools": [
			["cactus", "Cactus", "res://assets/world/cactus.png"],
			["pit", "Pit", "res://assets/world/pit.png"],
			["spring", "Spring", "res://assets/world/spring.png"],
		],
	},
	{
		"id": "enemies",
		"label": "Enemies",
		"tools": [
			["bandit", "Bandit", "res://assets/world/bandit.png"],
			["bounty_bandit", "Bounty Bandit", "res://assets/world/bandit_red.png"],
			["rattlesnake", "Rattlesnake", "res://assets/world/rattlesnake_idle.png"],
			["carrion", "Carrion Bird", "res://assets/world/carrion_bird.png"],
		],
	},
	{
		"id": "powerups",
		"label": "Power-ups",
		"tools": [
			["wings", "Wings", "res://assets/world/modes/wings.png"],
			["boots", "Magic Boots", "res://assets/world/modes/magic_boots.png"],
			["speed", "Speed Star", "res://assets/world/modes/speed_badge.png"],
			["shield", "Bubble Shield", "res://assets/world/modes/bubble_shield.png"],
		],
	},
	{
		"id": "goal",
		"label": "Goal",
		"tools": [
			["goal", "Saloon", "res://assets/world/goal_saloon.png"],
		],
	},
	{
		"id": "tools",
		"label": "Tools",
		"tools": [
			["erase", "Erase", ""],
		],
	},
]

var _data: Dictionary
var _selected_type: String = "ground"
var _cells: Array[Button] = []
var _category_dropdown: OptionButton
var _tool_dropdown: OptionButton
var _trail_tool_bar: HBoxContainer
var _trail_tool_buttons: Dictionary = {}
var _category_example: TextureRect
var _tool_label: Label
var _tool_icon: TextureRect
var _syncing_tool_ui := false
var _status: Label
var _title_edit: LineEdit
var _preview: LevelPreview
var _save_button: Button
var _reset_button: Button
var _reset_dialog: ConfirmationDialog
var _saved_data: Dictionary
var _initial_data: Dictionary
var _has_saved_state := false
var _dirty := false
var _grid: GridContainer
var _grid_scroll: ScrollContainer
var _editor_pane: VBoxContainer
var _h_scroll: HScrollBar
var _length_minus: Button
var _length_plus: Button
const _CELL_WIDTH := 42.0
const _MIN_CELL_HEIGHT := 12.0
const _COMFORT_CELL_HEIGHT := 22.0
const _MAX_CELL_HEIGHT := 40.0
const _MIN_GRID_HEIGHT := 96.0
const _PREVIEW_MIN_SIZE := Vector2(320, 180)
const _TRAIL_CATEGORY_ID := "trail"
var _hover_column: int = -1
var _hover_row: int = -1
var _syncing_scroll := false
var _export_dialog: FileDialog
var _import_dialog: FileDialog
const _EDGE_SCROLL_ZONE := 28.0
const _EDGE_SCROLL_SPEED := 320.0
const _DROPDOWN_FONT_SIZE := 10
const _DROPDOWN_HEIGHT := 18.0
const _PALETTE_ICON_SIZE := 16.0
const _DROPDOWN_INK := Color(0.28, 0.12, 0.04, 1.0)
const _DROPDOWN_INK_HOVER := Color(0.45, 0.2, 0.06, 1.0)
const _DROPDOWN_INK_DISABLED := Color(0.45, 0.35, 0.28, 1.0)
const _DROPDOWN_PANEL := Color(1.0, 0.93, 0.78, 1.0)
const _DROPDOWN_PANEL_HOVER := Color(1.0, 0.86, 0.5, 1.0)
const _DROPDOWN_BORDER := Color(0.45, 0.24, 0.08, 1.0)

const TRAIL_PACK_FILTER := "*.cowboytrail ; Cowboy Trail Pack"


func _ready() -> void:
	var draft: Dictionary = GameManager.custom_level_draft
	if (
		not draft.is_empty()
		and int(draft.get("slot", -1)) == GameManager.active_custom_slot
	):
		_data = draft.duplicate(true)
		GameManager.custom_level_draft = {}
	else:
		_data = CustomLevelStore.load_level(GameManager.active_custom_slot)
	_data = CustomLevelStore.sanitize(_data, GameManager.active_custom_slot)
	_initial_data = _data.duplicate(true)
	_has_saved_state = CustomLevelStore.exists(GameManager.active_custom_slot)
	_saved_data = (
		CustomLevelStore.load_level(GameManager.active_custom_slot)
		if _has_saved_state
		else _initial_data.duplicate(true)
	)
	_dirty = not _has_saved_state
	_build_ui()
	_refresh_grid()
	_update_action_state()
	_sync_tool_dropdowns()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.55, 0.8, 0.98)
	add_child(background)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	root.add_theme_constant_override(&"separation", 4)
	add_child(root)

	var heading := HBoxContainer.new()
	root.add_child(heading)
	var title := Label.new()
	title.text = (
		tr("Edit Campaign Level")
		if str(_data.get("kind", "")) == "override"
		else tr("Add Campaign Level")
	)
	title.add_theme_font_size_override(&"font_size", 18)
	title.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	title.custom_minimum_size.x = 220
	heading.add_child(title)
	_title_edit = LineEdit.new()
	_title_edit.text = str(_data.get("title", "Family Trail"))
	_title_edit.placeholder_text = tr("Trail name")
	_title_edit.custom_minimum_size = Vector2(240, 30)
	_title_edit.text_changed.connect(_on_title_changed)
	heading.add_child(_title_edit)
	var length_box := HBoxContainer.new()
	length_box.add_theme_constant_override(&"separation", 4)
	heading.add_child(length_box)
	_length_minus = Button.new()
	_length_minus.name = "LengthMinusButton"
	_length_minus.text = tr("− Length")
	_length_minus.custom_minimum_size = Vector2(92, 30)
	_length_minus.add_theme_font_size_override(&"font_size", 12)
	_length_minus.pressed.connect(func() -> void: _change_length(-CustomLevelStore.WIDTH_STEP))
	length_box.add_child(_length_minus)
	_length_plus = Button.new()
	_length_plus.name = "LengthPlusButton"
	_length_plus.text = tr("+ Length")
	_length_plus.custom_minimum_size = Vector2(92, 30)
	_length_plus.add_theme_font_size_override(&"font_size", 12)
	_length_plus.pressed.connect(func() -> void: _change_length(CustomLevelStore.WIDTH_STEP))
	length_box.add_child(_length_plus)
	_update_length_buttons()

	var instructions := Label.new()
	instructions.text = tr("1. Pick a stamp   2. Pick a square   3. Save or Play Test")
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override(&"font_size", 13)
	root.add_child(instructions)

	var trail_help := Label.new()
	trail_help.text = tr(
		"Bottom row is dirt/canyon. Ground props stamp one row above dirt so they stand on the trail."
	)
	trail_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	trail_help.add_theme_font_size_override(&"font_size", 12)
	trail_help.add_theme_color_override(&"font_color", Color(0.4, 0.2, 0.08))
	root.add_child(trail_help)

	var palette := HBoxContainer.new()
	palette.name = "Palette"
	palette.alignment = BoxContainer.ALIGNMENT_CENTER
	palette.add_theme_constant_override(&"separation", 4)
	root.add_child(palette)
	var category_label := Label.new()
	category_label.text = tr("Stamp category")
	category_label.add_theme_font_size_override(&"font_size", _DROPDOWN_FONT_SIZE)
	category_label.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	palette.add_child(category_label)
	_category_example = TextureRect.new()
	_category_example.name = "CategoryExample"
	_category_example.custom_minimum_size = Vector2(_PALETTE_ICON_SIZE, _PALETTE_ICON_SIZE)
	_category_example.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_category_example.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	palette.add_child(_category_example)
	_category_dropdown = OptionButton.new()
	_category_dropdown.name = "StampCategory"
	_category_dropdown.custom_minimum_size = Vector2(132, _DROPDOWN_HEIGHT)
	_category_dropdown.add_theme_font_size_override(&"font_size", _DROPDOWN_FONT_SIZE)
	_category_dropdown.item_selected.connect(_on_category_selected)
	palette.add_child(_category_dropdown)
	var tool_label := Label.new()
	tool_label.name = "StampToolLabel"
	tool_label.text = tr("Stamp tool")
	tool_label.add_theme_font_size_override(&"font_size", _DROPDOWN_FONT_SIZE)
	tool_label.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	palette.add_child(tool_label)
	_tool_label = tool_label
	_tool_dropdown = OptionButton.new()
	_tool_dropdown.name = "StampTool"
	_tool_dropdown.custom_minimum_size = Vector2(148, _DROPDOWN_HEIGHT)
	_tool_dropdown.add_theme_font_size_override(&"font_size", _DROPDOWN_FONT_SIZE)
	_tool_dropdown.item_selected.connect(_on_tool_selected)
	palette.add_child(_tool_dropdown)
	_trail_tool_bar = HBoxContainer.new()
	_trail_tool_bar.name = "TrailPathTools"
	_trail_tool_bar.add_theme_constant_override(&"separation", 4)
	_trail_tool_bar.visible = false
	palette.add_child(_trail_tool_bar)
	_build_trail_tool_bar()
	_tool_icon = TextureRect.new()
	_tool_icon.name = "StampToolIcon"
	_tool_icon.custom_minimum_size = Vector2(_PALETTE_ICON_SIZE, _PALETTE_ICON_SIZE)
	_tool_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_tool_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	palette.add_child(_tool_icon)
	_style_dropdown(_category_dropdown)
	_style_dropdown(_tool_dropdown)
	_populate_category_dropdown()

	_editor_pane = VBoxContainer.new()
	_editor_pane.name = "EditorPane"
	_editor_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor_pane.size_flags_stretch_ratio = 0.85
	_editor_pane.custom_minimum_size = Vector2(0, _MIN_GRID_HEIGHT + 20.0)
	_editor_pane.add_theme_constant_override(&"separation", 4)
	_editor_pane.resized.connect(_fit_grid_layout)
	root.add_child(_editor_pane)

	_grid_scroll = ScrollContainer.new()
	_grid_scroll.name = "GridScroll"
	_grid_scroll.custom_minimum_size = Vector2(0, _MIN_GRID_HEIGHT)
	_grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_grid_scroll.gui_input.connect(_on_grid_scroll_gui)
	_grid_scroll.resized.connect(_fit_grid_layout)
	_editor_pane.add_child(_grid_scroll)
	_grid = GridContainer.new()
	_grid.name = "StampGrid"
	_grid.columns = int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	_grid.add_theme_constant_override(&"h_separation", 2)
	_grid.add_theme_constant_override(&"v_separation", 2)
	_grid_scroll.add_child(_grid)
	var width := int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	var height := int(_data.get("height", 8))
	for y in range(height):
		for x in range(width):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(_CELL_WIDTH, _COMFORT_CELL_HEIGHT)
			cell.add_theme_font_size_override(&"font_size", 9)
			var cell_x := x
			var cell_y := y
			cell.pressed.connect(func() -> void: _place(cell_x, cell_y))
			cell.mouse_entered.connect(func() -> void: _set_hover_cell(cell_x, cell_y))
			_grid.add_child(cell)
			_cells.append(cell)

	_h_scroll = HScrollBar.new()
	_h_scroll.name = "TrailScrollBar"
	_h_scroll.custom_minimum_size = Vector2(0, 16)
	_h_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_h_scroll.value_changed.connect(_on_h_scroll_changed)
	_editor_pane.add_child(_h_scroll)
	call_deferred("_sync_scroll_range")
	set_process(true)

	_status = Label.new()
	_status.text = tr("Stamp: Dirt — keep a dirt path under the cowboy and saloon.")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override(&"font_size", 13)
	root.add_child(_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override(&"separation", 10)
	root.add_child(actions)
	_save_button = _add_action(actions, tr("Save Trail"), _save, "SaveButton")
	_reset_button = _add_action(actions, tr("Reset Changes"), _request_reset, "ResetButton")
	_add_action(actions, tr("Export Trail"), _open_export_dialog, "ExportTrailButton")
	_add_action(actions, tr("Import Trail"), _open_import_dialog, "ImportTrailButton")
	_add_action(actions, tr("Play Test"), _play_test, "PlayTestButton")
	_add_action(
		actions,
		tr("Back to Campaign Workshop"),
		GameManager.open_custom_level_hub,
		"BackButton"
	)

	var preview_label := Label.new()
	preview_label.text = tr("Live preview — full height, follows stamp cursor")
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_size_override(&"font_size", 13)
	preview_label.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	root.add_child(preview_label)

	_preview = LevelPreview.new()
	_preview.name = "LevelPreview"
	_preview.hover_column_changed.connect(_on_preview_hover_column)
	_preview.hover_cell_changed.connect(_on_preview_hover_cell)
	_preview.stamp_requested.connect(_on_preview_stamp)
	root.add_child(_preview)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview.size_flags_stretch_ratio = 1.45
	_preview.custom_minimum_size = _PREVIEW_MIN_SIZE

	_reset_dialog = ConfirmationDialog.new()
	_reset_dialog.name = "ResetConfirmation"
	_reset_dialog.title = tr("Reset trail?")
	_reset_dialog.dialog_text = tr("Discard unsaved changes and return to the last saved trail?")
	_reset_dialog.ok_button_text = tr("Reset")
	_reset_dialog.cancel_button_text = tr("Keep editing")
	_reset_dialog.confirmed.connect(_reset)
	add_child(_reset_dialog)

	_export_dialog = FileDialog.new()
	_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_dialog.filters = PackedStringArray([TRAIL_PACK_FILTER])
	_export_dialog.title = tr("Export Trail")
	_export_dialog.file_selected.connect(_on_export_selected)
	add_child(_export_dialog)

	_import_dialog = FileDialog.new()
	_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_import_dialog.filters = PackedStringArray([TRAIL_PACK_FILTER])
	_import_dialog.title = tr("Import Trail")
	_import_dialog.file_selected.connect(_on_import_selected)
	add_child(_import_dialog)


func _style_dropdown(dropdown: OptionButton) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = _DROPDOWN_PANEL
	normal.set_border_width_all(1)
	normal.border_color = _DROPDOWN_BORDER
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 6
	normal.content_margin_top = 2
	normal.content_margin_right = 6
	normal.content_margin_bottom = 2
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = _DROPDOWN_PANEL_HOVER
	dropdown.add_theme_stylebox_override(&"normal", normal)
	dropdown.add_theme_stylebox_override(&"hover", hover)
	dropdown.add_theme_stylebox_override(&"pressed", hover)
	dropdown.add_theme_stylebox_override(&"focus", hover)
	dropdown.add_theme_color_override(&"font_color", _DROPDOWN_INK)
	dropdown.add_theme_color_override(&"font_hover_color", _DROPDOWN_INK_HOVER)
	dropdown.add_theme_color_override(&"font_pressed_color", _DROPDOWN_INK)
	dropdown.add_theme_color_override(&"font_focus_color", _DROPDOWN_INK)
	dropdown.add_theme_color_override(&"font_disabled_color", _DROPDOWN_INK_DISABLED)
	dropdown.add_theme_constant_override(&"icon_max_width", int(_PALETTE_ICON_SIZE))
	var popup := dropdown.get_popup()
	popup.add_theme_font_size_override(&"font_size", _DROPDOWN_FONT_SIZE)
	popup.add_theme_constant_override(&"icon_max_width", int(_PALETTE_ICON_SIZE))
	popup.add_theme_constant_override(&"v_separation", 2)
	popup.add_theme_color_override(&"font_color", _DROPDOWN_INK)
	popup.add_theme_color_override(&"font_hover_color", _DROPDOWN_INK_HOVER)
	popup.add_theme_color_override(&"font_disabled_color", _DROPDOWN_INK_DISABLED)
	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = _DROPDOWN_PANEL
	popup_panel.set_border_width_all(1)
	popup_panel.border_color = _DROPDOWN_BORDER
	popup_panel.set_corner_radius_all(4)
	popup_panel.content_margin_left = 4
	popup_panel.content_margin_top = 4
	popup_panel.content_margin_right = 4
	popup_panel.content_margin_bottom = 4
	popup.add_theme_stylebox_override(&"panel", popup_panel)
	var item_hover := StyleBoxFlat.new()
	item_hover.bg_color = _DROPDOWN_PANEL_HOVER
	item_hover.set_corner_radius_all(2)
	popup.add_theme_stylebox_override(&"hover", item_hover)


func _populate_category_dropdown() -> void:
	_category_dropdown.clear()
	for i in range(TOOL_CATEGORIES.size()):
		var category := TOOL_CATEGORIES[i] as Dictionary
		_category_dropdown.add_item(tr(str(category.get("label", ""))), i)
		var icon := _category_icon(category)
		if icon != null:
			_category_dropdown.set_item_icon(i, icon)


func _category_icon(category: Dictionary) -> Texture2D:
	for tool in category.get("tools", []) as Array:
		var texture_path := str((tool as Array)[2])
		if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
			continue
		return load(texture_path) as Texture2D
	return null


func _build_trail_tool_bar() -> void:
	for child in _trail_tool_bar.get_children():
		child.queue_free()
	_trail_tool_buttons.clear()
	for category in TOOL_CATEGORIES:
		if str((category as Dictionary).get("id", "")) != _TRAIL_CATEGORY_ID:
			continue
		for tool in (category as Dictionary).get("tools", []) as Array:
			var entry := tool as Array
			var type_id := str(entry[0])
			var label_key := str(entry[1])
			var texture_path := str(entry[2])
			var button := Button.new()
			button.name = "TrailTool_%s" % type_id
			button.tooltip_text = tr(label_key)
			button.custom_minimum_size = Vector2(22, _DROPDOWN_HEIGHT)
			button.focus_mode = Control.FOCUS_NONE
			if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
				button.icon = load(texture_path) as Texture2D
				button.expand_icon = true
				button.text = ""
			else:
				button.text = tr(label_key)
			button.pressed.connect(func() -> void: _select_tool(type_id))
			_trail_tool_bar.add_child(button)
			_trail_tool_buttons[type_id] = button
		break


func _is_trail_category(category_index: int) -> bool:
	if category_index < 0 or category_index >= TOOL_CATEGORIES.size():
		return false
	return str((TOOL_CATEGORIES[category_index] as Dictionary).get("id", "")) == _TRAIL_CATEGORY_ID


func _update_tool_picker_visibility(category_index: int) -> void:
	var trail := _is_trail_category(category_index)
	_tool_dropdown.visible = not trail
	if _trail_tool_bar != null:
		_trail_tool_bar.visible = trail
	var tool_label := _tool_label
	if tool_label != null:
		tool_label.text = tr("Path stamp") if trail else tr("Stamp tool")


func _populate_tool_dropdown(category_index: int) -> void:
	_tool_dropdown.clear()
	if category_index < 0 or category_index >= TOOL_CATEGORIES.size():
		return
	var category := TOOL_CATEGORIES[category_index] as Dictionary
	for tool in category.get("tools", []) as Array:
		var entry := tool as Array
		var type_id := str(entry[0])
		var label_key := str(entry[1])
		var texture_path := str(entry[2])
		var item_index := _tool_dropdown.item_count
		_tool_dropdown.add_item(tr(label_key))
		_tool_dropdown.set_item_metadata(item_index, type_id)
		if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
			_tool_dropdown.set_item_icon(item_index, load(texture_path) as Texture2D)


func _tool_entry(type_id: String) -> Array:
	for category in TOOL_CATEGORIES:
		for tool in (category as Dictionary).get("tools", []) as Array:
			if str((tool as Array)[0]) == type_id:
				return tool as Array
	return ["ground", "Dirt", "res://assets/world/trail_desert_tile.png"]


func _category_index_for_type(type_id: String) -> int:
	for i in range(TOOL_CATEGORIES.size()):
		for tool in (TOOL_CATEGORIES[i] as Dictionary).get("tools", []) as Array:
			if str((tool as Array)[0]) == type_id:
				return i
	return 0


func _tool_index_for_type(category_index: int, type_id: String) -> int:
	if category_index < 0 or category_index >= TOOL_CATEGORIES.size():
		return 0
	var tools := (TOOL_CATEGORIES[category_index] as Dictionary).get("tools", []) as Array
	for i in range(tools.size()):
		if str((tools[i] as Array)[0]) == type_id:
			return i
	return 0


func _sync_tool_dropdowns() -> void:
	if _category_dropdown == null or _tool_dropdown == null:
		return
	_syncing_tool_ui = true
	var category_index := _category_index_for_type(_selected_type)
	_category_dropdown.select(category_index)
	_update_tool_picker_visibility(category_index)
	_update_category_example(category_index)
	if _is_trail_category(category_index):
		for type_id in _trail_tool_buttons.keys():
			var button := _trail_tool_buttons[type_id] as Button
			var selected: bool = type_id == _selected_type
			button.self_modulate = Color(1.15, 1.08, 0.82) if selected else Color.WHITE
	else:
		_populate_tool_dropdown(category_index)
		var tool_index := _tool_index_for_type(category_index, _selected_type)
		if tool_index >= 0 and tool_index < _tool_dropdown.item_count:
			_tool_dropdown.select(tool_index)
	_update_tool_icon()
	_syncing_tool_ui = false


func _update_category_example(category_index: int) -> void:
	if _category_example == null:
		return
	if category_index < 0 or category_index >= TOOL_CATEGORIES.size():
		_category_example.texture = null
		return
	var icon := _category_icon(TOOL_CATEGORIES[category_index] as Dictionary)
	_category_example.texture = icon


func _update_tool_icon() -> void:
	if _tool_icon == null:
		return
	var entry := _tool_entry(_selected_type)
	var texture_path := str(entry[2])
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		_tool_icon.texture = null
		return
	_tool_icon.texture = load(texture_path) as Texture2D


func _select_tool(type_id: String) -> void:
	_selected_type = type_id
	var entry := _tool_entry(type_id)
	_status.text = "%s: %s" % [tr("Stamp"), tr(str(entry[1]))]
	if _preview != null:
		_preview.set_selected_type(type_id)
	_sync_tool_dropdowns()


func _on_category_selected(index: int) -> void:
	if _syncing_tool_ui:
		return
	_update_tool_picker_visibility(index)
	_update_category_example(index)
	if _is_trail_category(index):
		var tools := (TOOL_CATEGORIES[index] as Dictionary).get("tools", []) as Array
		if not tools.is_empty():
			_select_tool(str((tools[0] as Array)[0]))
		return
	_populate_tool_dropdown(index)
	if _tool_dropdown.item_count > 0:
		_on_tool_selected(0)


func _on_tool_selected(index: int) -> void:
	if _syncing_tool_ui or _tool_dropdown == null:
		return
	var type_id := str(_tool_dropdown.get_item_metadata(index))
	if type_id.is_empty():
		return
	_select_tool(type_id)


func _fit_grid_layout() -> void:
	if _grid_scroll == null or _cells.is_empty() or _grid == null:
		return
	var height := maxi(int(_data.get("height", 8)), 1)
	var separation := float(_grid.get_theme_constant(&"v_separation", "GridContainer"))
	var needed_at_min := float(height) * _MIN_CELL_HEIGHT + separation * float(height - 1)
	_grid_scroll.custom_minimum_size.y = maxf(_MIN_GRID_HEIGHT, needed_at_min)
	if _editor_pane != null:
		_editor_pane.custom_minimum_size.y = _grid_scroll.custom_minimum_size.y + 20.0

	var available := maxf(_grid_scroll.size.y, _grid_scroll.custom_minimum_size.y)
	var cell_h := floorf((available - separation * float(height - 1)) / float(height))
	cell_h = clampf(cell_h, _MIN_CELL_HEIGHT, _MAX_CELL_HEIGHT)
	var total := cell_h * float(height) + separation * float(height - 1)
	if total > available + 0.5:
		cell_h = _COMFORT_CELL_HEIGHT
		total = cell_h * float(height) + separation * float(height - 1)
		_grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	else:
		_grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	for cell in _cells:
		cell.custom_minimum_size = Vector2(_CELL_WIDTH, cell_h)


func _add_action(
	parent: Control, text: String, action: Callable, node_name: String
) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(150, 36)
	button.add_theme_font_size_override(&"font_size", 14)
	button.add_theme_color_override(&"font_color", Color(0.35, 0.16, 0.05))
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _trail_y() -> int:
	return CustomLevelStore.trail_row(int(_data.get("height", 8)))


func _change_length(delta_columns: int) -> void:
	var width := int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	var next_width := width + delta_columns
	if next_width < CustomLevelStore.MIN_WIDTH or next_width > CustomLevelStore.MAX_WIDTH:
		return
	_data = CustomLevelStore.resize_width(_data, next_width, GameManager.active_custom_slot)
	_rebuild_stamp_grid()
	_refresh_grid()
	_mark_dirty()
	_update_length_buttons()
	if _preview != null:
		_preview.show_level(_data)
	call_deferred("_sync_scroll_range")
	_status.text = tr("Trail length: %d columns") % int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))


func _update_length_buttons() -> void:
	var width := int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	if _length_minus != null:
		_length_minus.disabled = width <= CustomLevelStore.MIN_WIDTH
	if _length_plus != null:
		_length_plus.disabled = width >= CustomLevelStore.MAX_WIDTH


func _set_hover_cell(column: int, row: int) -> void:
	_hover_column = column
	_hover_row = row
	if _preview != null:
		_preview.set_hover_cell(column, row)
	_refresh_grid_highlights()


func _set_hover_column(column: int) -> void:
	_set_hover_cell(column, _hover_row if _hover_row >= 0 else _trail_y())


func _on_preview_hover_column(column: int) -> void:
	_hover_column = column
	_refresh_grid_highlights()


func _on_preview_hover_cell(column: int, row: int) -> void:
	_hover_column = column
	_hover_row = row
	_refresh_grid_highlights()


func _on_preview_stamp(column: int, row: int) -> void:
	_place(column, row)


func _horizontal_scroll_max() -> float:
	if _grid_scroll == null or _grid == null:
		return 0.0
	var content_w := _grid.size.x
	if content_w <= 0.0:
		var width := int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
		var h_sep := float(_grid.get_theme_constant(&"h_separation", "GridContainer"))
		content_w = _CELL_WIDTH * float(width) + h_sep * float(maxi(width - 1, 0))
	return maxf(content_w - _grid_scroll.size.x, 0.0)


func _apply_horizontal_scroll(value: float) -> void:
	if _grid_scroll == null:
		return
	var clamped := clampf(value, 0.0, _horizontal_scroll_max())
	_syncing_scroll = true
	_grid_scroll.scroll_horizontal = int(clamped)
	if _h_scroll != null:
		_h_scroll.value = clamped
	_syncing_scroll = false


func _sync_scroll_range() -> void:
	if _grid_scroll == null or _h_scroll == null or _grid == null:
		return
	var max_val := _horizontal_scroll_max()
	_h_scroll.min_value = 0.0
	_h_scroll.max_value = max_val
	_h_scroll.page = _grid_scroll.size.x
	_h_scroll.step = 1.0
	_apply_horizontal_scroll(_grid_scroll.scroll_horizontal)


func _on_h_scroll_changed(value: float) -> void:
	if _syncing_scroll or _grid_scroll == null:
		return
	_apply_horizontal_scroll(value)


func _process(delta: float) -> void:
	if _grid_scroll == null or not _grid_scroll.get_global_rect().has_point(get_global_mouse_position()):
		return
	var max_scroll := _horizontal_scroll_max()
	if max_scroll <= 0.0:
		return
	var local := _grid_scroll.get_local_mouse_position()
	var delta_x := 0.0
	if local.x < _EDGE_SCROLL_ZONE:
		var t := 1.0 - local.x / _EDGE_SCROLL_ZONE
		delta_x = -_EDGE_SCROLL_SPEED * t * delta
	elif local.x > _grid_scroll.size.x - _EDGE_SCROLL_ZONE:
		var dist := local.x - (_grid_scroll.size.x - _EDGE_SCROLL_ZONE)
		delta_x = _EDGE_SCROLL_SPEED * (dist / _EDGE_SCROLL_ZONE) * delta
	if absf(delta_x) > 0.01:
		_apply_horizontal_scroll(_grid_scroll.scroll_horizontal + delta_x)


func _on_grid_scroll_gui(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_grid_scroll.accept_event()
			return
		if mouse.pressed:
			call_deferred("_sync_scroll_range")
	elif event is InputEventPanGesture:
		_grid_scroll.accept_event()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			_grid_scroll.accept_event()


func _place(x: int, y: int) -> void:
	var objects := _objects()
	var before := objects.duplicate(true)
	var trail := _trail_y()
	var place_y := CustomLevelStore.placement_row(_selected_type, y, trail)
	if _selected_type == "erase":
		_erase_at(objects, x, place_y)
	elif _selected_type == "canyon":
		_erase_at(objects, x, trail, true)
		objects.append({"type": "canyon", "x": x, "y": trail})
	elif _selected_type == "pit":
		if y != trail or not CustomLevelStore.pit_fits_on_dirt(objects, x, trail):
			return
		_remove_pit_footprint(objects, x, trail)
		objects.append({"type": "pit", "x": x, "y": trail})
	elif _selected_type == "ground":
		var target_y := y if y <= trail else trail
		if not _has_type_at(objects, x, target_y, "ground"):
			objects.append({"type": "ground", "x": x, "y": target_y})
		if target_y < trail and not _has_type_at(objects, x, trail, "ground"):
			if not _has_type_at(objects, x, trail, "canyon"):
				objects.append({"type": "ground", "x": x, "y": trail})
		if target_y == trail:
			for i in range(objects.size() - 1, -1, -1):
				var object := objects[i] as Dictionary
				if (
					int(object.get("x", -1)) == x
					and int(object.get("y", -1)) == trail
					and str(object.get("type", "")) in ["canyon", "pit"]
				):
					objects.remove_at(i)
	else:
		_remove_foreground_at(objects, x, place_y)
		if _selected_type == "goal":
			for i in range(objects.size() - 1, -1, -1):
				if str(objects[i].get("type", "")) == "goal":
					objects.remove_at(i)
		objects.append({"type": _selected_type, "x": x, "y": place_y})
	if objects == before:
		return
	_data["objects"] = objects
	_mark_dirty()
	_refresh_grid()
	_set_hover_cell(x, y)


func _objects() -> Array:
	return (_data.get("objects", []) as Array).duplicate(true)


func _erase_at(objects: Array, x: int, y: int, include_ground: bool = false) -> void:
	var removed_foreground := false
	for i in range(objects.size() - 1, -1, -1):
		var object := objects[i] as Dictionary
		if int(object.get("x", -1)) != x or int(object.get("y", -1)) != y:
			continue
		if str(object.get("type", "")) != "ground":
			objects.remove_at(i)
			removed_foreground = true
	if include_ground or not removed_foreground:
		for i in range(objects.size() - 1, -1, -1):
			var object := objects[i] as Dictionary
			if (
				int(object.get("x", -1)) == x
				and int(object.get("y", -1)) == y
				and str(object.get("type", "")) == "ground"
			):
				objects.remove_at(i)


func _remove_foreground_at(objects: Array, x: int, y: int) -> void:
	for i in range(objects.size() - 1, -1, -1):
		var object := objects[i] as Dictionary
		if (
			int(object.get("x", -1)) == x
			and int(object.get("y", -1)) == y
			and str(object.get("type", "")) != "ground"
		):
			objects.remove_at(i)


func _remove_pit_footprint(objects: Array, center_x: int, trail: int) -> void:
	var probe := {"type": "pit", "x": center_x, "y": trail}
	var span := CustomLevelStore.pit_column_span(probe)
	for i in range(objects.size() - 1, -1, -1):
		var object := objects[i] as Dictionary
		var ox := int(object.get("x", -1))
		if ox < span.x or ox > span.y:
			continue
		var type_name := str(object.get("type", ""))
		if type_name in ["ground", "pit", "canyon"]:
			objects.remove_at(i)


func _has_type_at(objects: Array, x: int, y: int, type_name: String) -> bool:
	for value in objects:
		var object := value as Dictionary
		if (
			int(object.get("x", -1)) == x
			and int(object.get("y", -1)) == y
			and str(object.get("type", "")) == type_name
		):
			return true
	return false


func _refresh_grid() -> void:
	var width := int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	var height := int(_data.get("height", 8))
	var trail := _trail_y()
	for y in range(height):
		for x in range(width):
			var cell := _cells[y * width + x]
			var type_name := _display_type_at(x, y)
			cell.text = _short_label(type_name)
			if y == trail and type_name.is_empty():
				cell.text = "···"
			cell.modulate = _type_color(type_name)
			if y == trail:
				cell.modulate = cell.modulate.darkened(0.04)
				if type_name.is_empty():
					cell.modulate = Color(0.82, 0.7, 0.5)
	_refresh_grid_highlights()
	call_deferred("_sync_scroll_range")
	call_deferred("_fit_grid_layout")
	if _preview != null:
		_preview.show_level(_data)
		_preview.set_selected_type(_selected_type)
		if _hover_column >= 0:
			_preview.set_hover_cell(_hover_column, _hover_row if _hover_row >= 0 else _trail_y())
	_update_length_buttons()


func _refresh_grid_highlights() -> void:
	var width := int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	var height := int(_data.get("height", 8))
	var trail := _trail_y()
	var ghost_col := -1
	var ghost_row := -1
	if _hover_column >= 0 and _hover_row >= 0 and _selected_type not in ["erase", "ground", "canyon"]:
		ghost_col = _hover_column
		ghost_row = CustomLevelStore.placement_row(_selected_type, _hover_row, trail)
	for y in range(height):
		for x in range(width):
			var cell := _cells[y * width + x]
			var type_name := _display_type_at(x, y)
			cell.text = _short_label(type_name)
			if y == trail and type_name.is_empty():
				cell.text = "···"
			if x == _hover_column:
				cell.self_modulate = Color(1.15, 1.1, 0.85)
			else:
				cell.self_modulate = Color.WHITE
			if x == ghost_col and y == ghost_row:
				cell.self_modulate = Color(1.25, 1.18, 0.65)
				var ghost_label := _short_label(_selected_type)
				if not ghost_label.is_empty():
					cell.text = ghost_label


func _display_type_at(x: int, y: int) -> String:
	var ground := false
	for value in _data.get("objects", []):
		var object := value as Dictionary
		if int(object.get("x", -1)) != x or int(object.get("y", -1)) != y:
			continue
		var type_name := str(object.get("type", ""))
		if type_name != "ground":
			return type_name
		ground = true
	return "ground" if ground else ""


func _short_label(type_name: String) -> String:
	var labels := {
		"ground": "DIRT", "platform": "WOOD", "star": "STAR",
		"cactus": "OUCH", "canyon": "CANYON", "pit": "PIT", "checkpoint": "CAMP",
		"spring": "BOING", "bandit": "BANDIT", "bounty_bandit": "BOUNTY",
		"rattlesnake": "SNAKE", "carrion": "BIRD",
		"wings": "WINGS", "boots": "BOOTS", "speed": "FAST", "shield": "BUBBLE",
		"goal": "END", "chest": "CHEST",
	}
	return str(labels.get(type_name, ""))


func _type_color(type_name: String) -> Color:
	var colors := {
		"": Color(1, 1, 1), "ground": Color(0.86, 0.68, 0.38),
		"platform": Color(0.62, 0.4, 0.22), "star": Color(1, 0.85, 0.2),
		"cactus": Color(0.35, 0.75, 0.3), "canyon": Color(0.55, 0.28, 0.14), "pit": Color(0.55, 0.28, 0.14),
		"checkpoint": Color(0.95, 0.45, 0.2), "spring": Color(0.3, 0.9, 0.45),
		"bandit": Color(0.32, 0.18, 0.08), "bounty_bandit": Color(0.75, 0.12, 0.08),
		"rattlesnake": Color(0.55, 0.4, 0.15), "carrion": Color(0.45, 0.35, 0.55),
		"wings": Color(0.75, 0.85, 1.0), "boots": Color(0.7, 0.45, 0.9),
		"speed": Color(1.0, 0.75, 0.2), "shield": Color(0.45, 0.75, 1.0),
		"goal": Color(0.85, 0.3, 0.2),
	}
	return colors.get(type_name, Color.WHITE)


func _on_title_changed(value: String) -> void:
	_data["title"] = value.strip_edges().left(40) if not value.strip_edges().is_empty() else "Family Trail"
	_mark_dirty()


func _save() -> void:
	var title := _title_edit.text.strip_edges().left(40)
	_data["title"] = title if not title.is_empty() else "Family Trail"
	_title_edit.set_block_signals(true)
	_title_edit.text = str(_data["title"])
	_title_edit.set_block_signals(false)
	if CustomLevelStore.save(GameManager.active_custom_slot, _data):
		_data = CustomLevelStore.load_level(GameManager.active_custom_slot)
		_saved_data = _data.duplicate(true)
		_has_saved_state = true
		_dirty = false
		_status.text = tr("Trail saved!")
		_update_action_state()
		if _preview != null:
			_preview.show_level(_data)
	else:
		_status.text = tr("Could not save the trail.")


func _request_reset() -> void:
	if not _dirty:
		_status.text = tr("No unsaved changes to reset.")
		return
	_reset_dialog.popup_centered(Vector2i(560, 190))


func _reset() -> void:
	_data = (
		_saved_data.duplicate(true)
		if _has_saved_state
		else _initial_data.duplicate(true)
	)
	_title_edit.set_block_signals(true)
	_title_edit.text = str(_data.get("title", "Family Trail"))
	_title_edit.set_block_signals(false)
	_dirty = false
	_refresh_grid()
	_update_action_state()
	_status.text = (
		tr("Trail reset to the last saved version.")
		if _has_saved_state
		else tr("New trail reset to its starting layout.")
	)


func _mark_dirty() -> void:
	_dirty = _data != _saved_data
	_update_action_state()


func _update_action_state() -> void:
	if _save_button != null:
		_save_button.disabled = not _dirty and _has_saved_state
	if _reset_button != null:
		_reset_button.disabled = not _dirty


func _play_test() -> void:
	_save()
	var has_goal := false
	var has_ground := false
	for value in _data.get("objects", []):
		var type_name := str((value as Dictionary).get("type", ""))
		has_goal = has_goal or type_name == "goal"
		has_ground = has_ground or type_name == "ground"
	if not has_goal or not has_ground:
		_status.text = tr("Add Dirt and a Saloon before play-testing.")
		return
	GameManager.play_custom_level(GameManager.active_custom_slot, true)


func _open_export_dialog() -> void:
	_export_dialog.popup_centered(Vector2i(900, 600))


func _open_import_dialog() -> void:
	_import_dialog.popup_centered(Vector2i(900, 600))


func _ensure_pack_extension(path: String) -> String:
	if path.get_extension().is_empty():
		return "%s.cowboytrail" % path
	return path


func _on_export_selected(path: String) -> void:
	var export_path := _ensure_pack_extension(path)
	if CustomLevelStore.write_share_pack(export_path, [_data]):
		_status.text = tr("Trail exported.")
	else:
		_status.text = tr("Could not write trail pack.")


func _on_import_selected(path: String) -> void:
	var result := CustomLevelStore.read_share_pack(path)
	if not bool(result.get("ok", false)):
		_status.text = tr("Could not import trail pack.")
		return
	var trails := result.get("trails", []) as Array
	if trails.is_empty() or not (trails[0] is Dictionary):
		_status.text = tr("Could not import trail pack.")
		return
	var slot := GameManager.active_custom_slot
	_data = CustomLevelStore.merge_imported_trail(_data, trails[0] as Dictionary, slot)
	_title_edit.set_block_signals(true)
	_title_edit.text = str(_data.get("title", "Family Trail"))
	_title_edit.set_block_signals(false)
	_rebuild_stamp_grid_if_needed()
	_refresh_grid()
	_dirty = true
	_update_action_state()
	var trail_count := int(result.get("trail_count", trails.size()))
	if trail_count > 1:
		_status.text = tr("Imported first of %d trails.") % trail_count
	else:
		_status.text = tr("Trail imported.")


func _rebuild_stamp_grid_if_needed() -> void:
	var width := int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	var height := int(_data.get("height", 8))
	if _cells.size() == width * height:
		return
	_rebuild_stamp_grid()


func _rebuild_stamp_grid() -> void:
	if _grid == null:
		return
	for cell in _cells:
		if is_instance_valid(cell):
			cell.queue_free()
	_cells.clear()
	_grid.columns = int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	var width := int(_data.get("width", CustomLevelStore.DEFAULT_WIDTH))
	var height := int(_data.get("height", 8))
	for y in range(height):
		for x in range(width):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(_CELL_WIDTH, _COMFORT_CELL_HEIGHT)
			cell.add_theme_font_size_override(&"font_size", 9)
			var cell_x := x
			var cell_y := y
			cell.pressed.connect(func() -> void: _place(cell_x, cell_y))
			cell.mouse_entered.connect(func() -> void: _set_hover_cell(cell_x, cell_y))
			_grid.add_child(cell)
			_cells.append(cell)
	call_deferred("_fit_grid_layout")
	call_deferred("_sync_scroll_range")
