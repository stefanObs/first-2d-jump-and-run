class_name LevelPreview
extends Control

## Live gameplay preview centered on the editor cursor column.

signal hover_column_changed(column: int)
signal hover_cell_changed(column: int, row: int)
signal stamp_requested(column: int, row: int)

const FRAME_CONTENT_MARGIN := 6.0
const MIN_PREVIEW_SIZE := Vector2(160, 120)
const SKY_PADDING_CELLS := 0.75
const GROUND_PADDING_CELLS := 0.65
## Match WildWestTheme.configure_player_camera so stamp scale matches play mode.
const GAMEPLAY_CAMERA_ZOOM := 0.84

var _data: Dictionary = {}
var _hover_column: int = -1
var _hover_row: int = -1
var _selected_type: String = "ground"
var _frame: PanelContainer
var _container: SubViewportContainer
var _viewport: SubViewport
var _world: LevelController
var _camera: Camera2D
var _cursor_marker: Node2D
var _ghost_overlay: Control
var _rebuild_pending := false
var _last_built_hash := ""


func _ready() -> void:
	custom_minimum_size = MIN_PREVIEW_SIZE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_viewport()
	_build_ghost_overlay()
	call_deferred("_fit_preview_to_pane")
	if not _data.is_empty():
		_queue_rebuild()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_preview_to_pane()
		_update_ghost_overlay()


func show_level(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_queue_rebuild()


func set_selected_type(type_name: String) -> void:
	_selected_type = type_name
	_update_ghost_overlay()


func set_hover_column(column: int) -> void:
	set_hover_cell(column, _hover_row)


func set_hover_cell(column: int, row: int) -> void:
	var width := maxi(int(_data.get("width", 24)), 1)
	var height := maxi(int(_data.get("height", 8)), 1)
	var next_col := clampi(column, -1, width - 1)
	var next_row := clampi(row, -1, height - 1)
	if next_col == _hover_column and next_row == _hover_row:
		return
	_hover_column = next_col
	_hover_row = next_row
	_update_camera()
	_update_ghost_overlay()
	hover_column_changed.emit(_hover_column)
	hover_cell_changed.emit(_hover_column, _hover_row)


func get_hover_column() -> int:
	return _hover_column


func get_hover_row() -> int:
	return _hover_row


func _build_viewport() -> void:
	_frame = PanelContainer.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.1, 0.04, 1)
	style.set_border_width_all(4)
	style.border_color = Color(0.45, 0.24, 0.08, 1)
	style.set_corner_radius_all(10)
	style.content_margin_left = FRAME_CONTENT_MARGIN
	style.content_margin_top = FRAME_CONTENT_MARGIN
	style.content_margin_right = FRAME_CONTENT_MARGIN
	style.content_margin_bottom = FRAME_CONTENT_MARGIN
	_frame.add_theme_stylebox_override(&"panel", style)
	add_child(_frame)

	_container = SubViewportContainer.new()
	_container.name = "LivePreviewContainer"
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.stretch = false
	_frame.add_child(_container)

	_viewport = SubViewport.new()
	_viewport.name = "LivePreviewViewport"
	_viewport.size = Vector2i(320, 180)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = false
	_viewport.gui_disable_input = true
	_viewport.physics_object_picking = false
	_container.add_child(_viewport)


func _build_ghost_overlay() -> void:
	_ghost_overlay = Control.new()
	_ghost_overlay.name = "StampGhostOverlay"
	_ghost_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ghost_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ghost_overlay)


func _queue_rebuild() -> void:
	if _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_rebuild_world")


func _rebuild_world() -> void:
	_rebuild_pending = false
	if _viewport == null:
		return
	var digest := JSON.stringify(_data)
	if digest == _last_built_hash and _world != null and is_instance_valid(_world):
		_update_camera()
		_update_ghost_overlay()
		return
	_last_built_hash = digest
	for child in _viewport.get_children():
		child.queue_free()
	_world = null
	_camera = null
	_cursor_marker = null
	if _data.is_empty():
		_update_ghost_overlay()
		return

	var level := LevelController.new()
	level.name = "PreviewLevel"
	level.is_custom_level = true
	level.skip_auto_setup = true
	level.level_title = str(_data.get("title", "Family Trail"))
	_viewport.add_child(level)
	CustomLevelBuilder.build(level, _data, true)
	# Theme + camera like play, without HUD / celebration flow.
	WildWestTheme.apply_to_level(level)
	for node in level.find_children("*", "AnimatableBody2D", true, false):
		node.set_physics_process(false)
		node.set_process(false)
	var player := level.get_node_or_null("Player") as Player
	if player != null:
		player.set_input_enabled(false)
		player.set_physics_process(false)
		player.set_process(false)
		var player_cam := player.get_node_or_null("Camera2D") as Camera2D
		if player_cam != null:
			player_cam.enabled = false

	_camera = Camera2D.new()
	_camera.name = "PreviewCamera"
	_camera.enabled = true
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	level.add_child(_camera)
	_camera.make_current()

	_cursor_marker = Node2D.new()
	_cursor_marker.name = "EditorCursor"
	var marker := ColorRect.new()
	marker.name = "CursorBand"
	marker.size = Vector2(8, 120)
	marker.position = Vector2(-4, -120)
	marker.color = Color(1.0, 0.85, 0.15, 0.85)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_marker.add_child(marker)
	level.add_child(_cursor_marker)

	_world = level
	_update_camera()
	_update_ghost_overlay()


func _update_camera() -> void:
	if _camera == null or not is_instance_valid(_camera) or _data.is_empty():
		return
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var width: int = metrics["width"]
	var trail: int = metrics["trail"]
	var focus_x := _hover_column if _hover_column >= 0 else int((_data.get("spawn", [2, trail]) as Array)[0])
	focus_x = clampi(focus_x, 0, width - 1)
	var world_x := (float(focus_x) + 0.5) * grid
	_camera.zoom = Vector2(metrics["zoom"], metrics["zoom"])
	_camera.position = Vector2(world_x, metrics["center_y"])
	if _cursor_marker != null and is_instance_valid(_cursor_marker):
		_cursor_marker.position = Vector2(world_x, float(trail) * grid)
		var marker := _cursor_marker.get_node_or_null("CursorBand") as ColorRect
		if marker != null:
			var top_y: float = metrics["top_y"]
			var bottom_y: float = metrics["bottom_y"]
			marker.position = Vector2(-4.0, top_y - float(trail) * grid)
			marker.size = Vector2(8.0, bottom_y - top_y)


func _frame_insets() -> Vector2:
	return Vector2(FRAME_CONTENT_MARGIN * 2.0, FRAME_CONTENT_MARGIN * 2.0)


func _preview_display_rect() -> Rect2:
	var insets := _frame_insets()
	var available := size - insets
	if available.x <= 1.0 or available.y <= 1.0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	return Rect2(Vector2(FRAME_CONTENT_MARGIN, FRAME_CONTENT_MARGIN), available)


func _fit_preview_to_pane() -> void:
	if _container == null or _viewport == null:
		return
	var display := _preview_display_rect()
	if display.size.x <= 1.0 or display.size.y <= 1.0:
		return
	var viewport_size := Vector2i(
		maxi(int(round(display.size.x)), 1),
		maxi(int(round(display.size.y)), 1)
	)
	var viewport_changed := _viewport.size != viewport_size
	if viewport_changed:
		_viewport.size = viewport_size
	_update_camera()
	_update_ghost_overlay()


func _view_metrics() -> Dictionary:
	var grid := float(_data.get("grid", 40))
	var width := maxi(int(_data.get("width", 24)), 1)
	var height := maxi(int(_data.get("height", 8)), 1)
	var trail := CustomLevelStore.trail_row(height)
	var top_y := grid * 0.5 - grid * SKY_PADDING_CELLS
	var bottom_y := float(trail) * grid + grid * GROUND_PADDING_CELLS
	var world_height := bottom_y - top_y
	var viewport_height := float(_viewport.size.y) if _viewport != null else 180.0
	var fit_zoom := viewport_height / maxf(world_height, grid)
	var zoom := minf(GAMEPLAY_CAMERA_ZOOM, fit_zoom)
	return {
		"grid": grid,
		"width": width,
		"height": height,
		"trail": trail,
		"top_y": top_y,
		"bottom_y": bottom_y,
		"world_height": world_height,
		"viewport_height": viewport_height,
		"center_y": (top_y + bottom_y) * 0.5,
		"zoom": zoom,
	}


func _mouse_to_cell(local: Vector2) -> Vector2i:
	var display := _preview_display_rect()
	if display.size.x <= 1.0 or display.size.y <= 1.0 or _camera == null:
		return Vector2i(-1, -1)
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var zoom: float = metrics["zoom"]
	var rel := local - display.position - display.size * 0.5
	var world := _camera.position + Vector2(rel.x / zoom, rel.y / zoom)
	var width: int = metrics["width"]
	var height: int = metrics["height"]
	return Vector2i(
		clampi(int(floor(world.x / grid)), 0, width - 1),
		clampi(int(floor(world.y / grid)), 0, height - 1)
	)


func _placement_row(click_row: int) -> int:
	var trail: int = _view_metrics()["trail"]
	return CustomLevelStore.placement_row(_selected_type, click_row, trail)


func _ghost_rect_screen() -> Rect2:
	if _hover_column < 0 or _hover_row < 0 or _selected_type in ["erase", "ground", "canyon", "pit"]:
		return Rect2()
	var display := _preview_display_rect()
	if display.size.x <= 1.0 or _camera == null:
		return Rect2()
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var zoom: float = metrics["zoom"]
	var footprint := CustomLevelStore.stamp_footprint(_selected_type)
	var place_row := _placement_row(_hover_row)
	var start_x := float(_hover_column)
	if footprint.x > 1.0:
		start_x -= floor((footprint.x - 1.0) * 0.5)
	start_x = clampf(start_x, 0.0, float(metrics["width"]) - footprint.x)
	var world_left := start_x * grid
	var world_top := float(place_row) * grid
	var world_size := Vector2(footprint.x * grid, footprint.y * grid)
	var center := display.position + display.size * 0.5
	var top_left := center + (_camera.position + Vector2(world_left, world_top) - _camera.position) * zoom
	var size := world_size * zoom
	return Rect2(top_left, size)


func _update_ghost_overlay() -> void:
	if _ghost_overlay == null:
		return
	for child in _ghost_overlay.get_children():
		child.queue_free()
	var rect := _ghost_rect_screen()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	var fill := ColorRect.new()
	fill.position = rect.position
	fill.size = rect.size
	fill.color = Color(1.0, 0.92, 0.45, 0.22)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost_overlay.add_child(fill)
	var outline := _make_outline(rect, Color(1.0, 0.82, 0.12, 0.92), 2.0)
	_ghost_overlay.add_child(outline)
	var icon_path := _icon_path_for_type(_selected_type)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path) as Texture2D
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color(1, 1, 1, 0.55)
		var icon_side := minf(minf(rect.size.x, rect.size.y) * 0.85, 48.0)
		var icon_size := Vector2(icon_side, icon_side)
		icon.custom_minimum_size = icon_size
		icon.size = icon_size
		icon.position = rect.position + (rect.size - icon_size) * 0.5
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ghost_overlay.add_child(icon)


func _make_outline(rect: Rect2, color: Color, width: float) -> Control:
	var root := Control.new()
	root.position = rect.position
	root.size = rect.size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for edge in [
		Rect2(0, 0, rect.size.x, width),
		Rect2(0, rect.size.y - width, rect.size.x, width),
		Rect2(0, 0, width, rect.size.y),
		Rect2(rect.size.x - width, 0, width, rect.size.y),
	]:
		var line := ColorRect.new()
		line.position = edge.position
		line.size = edge.size
		line.color = color
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(line)
	return root


func _icon_path_for_type(type_name: String) -> String:
	var icons := {
		"ground": "res://assets/world/trail_desert_tile.png",
		"canyon": "res://assets/ui/editor_canyon_stamp_icon.png",
		"platform": "res://assets/world/trail_dirt_tile.png",
		"star": "res://assets/world/star_badge.png",
		"checkpoint": "res://assets/world/checkpoint_active.png",
		"cactus": "res://assets/world/cactus.png",
		"spring": "res://assets/world/spring.png",
		"bandit": "res://assets/world/bandit.png",
		"bounty_bandit": "res://assets/world/bandit_red.png",
		"rattlesnake": "res://assets/world/rattlesnake_idle.png",
		"carrion": "res://assets/world/carrion_bird.png",
		"wings": "res://assets/world/modes/wings.png",
		"boots": "res://assets/world/modes/magic_boots.png",
		"speed": "res://assets/world/modes/speed_badge.png",
		"shield": "res://assets/world/modes/bubble_shield.png",
		"goal": "res://assets/world/goal_saloon.png",
	}
	return str(icons.get(type_name, ""))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var local := (event as InputEventMouse).position
		var preview_rect := _preview_display_rect()
		if preview_rect.size.x <= 1.0 or not preview_rect.has_point(local):
			return
		var cell := _mouse_to_cell(local)
		if cell.x < 0:
			return
		set_hover_cell(cell.x, cell.y)
		if event is InputEventMouseButton:
			var mouse := event as InputEventMouseButton
			if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
				stamp_requested.emit(cell.x, cell.y)
				accept_event()


func _window_start(width: int, window: int) -> int:
	var focus := _hover_column if _hover_column >= 0 else mini(4, width - 1)
	return clampi(focus - window / 2, 0, maxi(width - window, 0))
