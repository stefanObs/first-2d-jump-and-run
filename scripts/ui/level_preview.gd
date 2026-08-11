class_name LevelPreview
extends Control

## Live gameplay preview with an independent horizontal view; hover shows a cursor band only.

signal hover_column_changed(column: int)
signal hover_cell_changed(column: int, row: int)
signal stamp_requested(column: int, row: int)
signal remove_requested(column: int, row: int)
signal canyon_adjust_requested(start_x: int, end_x: int, side: String, grow: bool)

const FRAME_CONTENT_MARGIN := 6.0
const MIN_PREVIEW_SIZE := Vector2(160, 120)
const SKY_PADDING_CELLS := 0.75
const GROUND_PADDING_CELLS := 0.65
## Match WildWestTheme.configure_player_camera so stamp scale matches play mode.
const GAMEPLAY_CAMERA_ZOOM := 0.84
const _GHOST_OUTLINE := Color(1.0, 0.82, 0.12, 0.95)
const _PLACED_OUTLINE := Color(1.0, 0.94, 0.72, 1.0)
const CANYON_HANDLE_SIZE := 36.0
const CANYON_WARNING_SIZE := 40.0
const _ICON_SCROLL_LEFT := "res://assets/ui/menu_icon_scroll_left.png"
const _ICON_SCROLL_RIGHT := "res://assets/ui/menu_icon_scroll_right.png"
const _ICON_CANYON_TOO_WIDE := "res://assets/ui/menu_icon_canyon_too_wide.png"

var _data: Dictionary = {}
var _hover_column: int = -1
var _hover_row: int = -1
var _view_center_x: float = -1.0
var _selected_type: String = "ground"
var _frame: PanelContainer
var _container: SubViewportContainer
var _viewport: SubViewport
var _world: LevelController
var _camera: Camera2D
var _cursor_marker: Node2D
var _ghost_overlay: Control
var _canyon_overlay: Control
var _ghost_root: Node2D
var _rebuild_pending := false
var _last_built_hash := ""
var _ghost_key := ""
var _canyon_handle_key := ""

func _ready() -> void:
	custom_minimum_size = MIN_PREVIEW_SIZE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_viewport()
	_build_ghost_overlay()
	_build_canyon_overlay()
	call_deferred("_fit_preview_to_pane")
	if not _data.is_empty():
		_queue_rebuild()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_preview_to_pane()
		_update_ghost_world()
		_sync_canyon_handles()

func show_level(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_queue_rebuild()

func set_selected_type(type_name: String) -> void:
	_selected_type = type_name
	_update_ghost_world()

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
	_update_cursor_marker()
	_update_ghost_world()
	hover_column_changed.emit(_hover_column)
	hover_cell_changed.emit(_hover_column, _hover_row)

func set_view_center_column(column: int) -> void:
	if _data.is_empty():
		return
	var metrics := _view_metrics()
	var width: int = metrics["width"]
	var grid: float = metrics["grid"]
	var clamped := clampi(column, 0, width - 1)
	_view_center_x = (float(clamped) + 0.5) * grid
	_update_camera()

func pan_view_screen(delta_screen_px: float) -> void:
	if _camera == null or _data.is_empty() or absf(delta_screen_px) <= 0.01:
		return
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var width: int = metrics["width"]
	var zoom: float = metrics["zoom"]
	_ensure_view_center()
	var min_x := grid * 0.5
	var max_x := (float(width) - 0.5) * grid
	_view_center_x = clampf(_view_center_x + delta_screen_px / zoom, min_x, max_x)
	_update_camera()

func get_hover_column() -> int:
	return _hover_column

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
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	_container = SubViewportContainer.new()
	_container.name = "LivePreviewContainer"
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.stretch = true
	_container.stretch_shrink = 1
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_container)

	_viewport = SubViewport.new()
	_viewport.name = "LivePreviewViewport"
	_viewport.size = Vector2i(320, 180)
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.handle_input_locally = false
	_viewport.gui_disable_input = true
	_viewport.physics_object_picking = false
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	_container.add_child(_viewport)

func _build_ghost_overlay() -> void:
	_ghost_overlay = Control.new()
	_ghost_overlay.name = "StampGhostOverlay"
	_ghost_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ghost_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ghost_overlay)


func _build_canyon_overlay() -> void:
	_canyon_overlay = Control.new()
	_canyon_overlay.name = "CanyonHandleOverlay"
	_canyon_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canyon_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canyon_overlay)

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
		_update_ghost_world()
		_sync_canyon_handles()
		return
	_last_built_hash = digest
	var preserved_center := _view_center_x
	_clear_ghost_root()
	for child in _viewport.get_children():
		child.queue_free()
	_world = null
	_camera = null
	_cursor_marker = null
	if _data.is_empty():
		_update_ghost_world()
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
	## Editor rebuilds replace the camera; smoothing from origin makes the view
	## slide after every stamp or dirt-height change.
	_camera.position_smoothing_enabled = false
	level.add_child(_camera)

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
	if preserved_center >= 0.0:
		var metrics := _view_metrics()
		var grid: float = metrics["grid"]
		var width: int = metrics["width"]
		var min_x := grid * 0.5
		var max_x := (float(width) - 0.5) * grid
		_view_center_x = clampf(preserved_center, min_x, max_x)
	else:
		_view_center_x = -1.0
	_ensure_view_center()
	var snap := _view_metrics()
	_camera.zoom = Vector2(snap["zoom"], snap["zoom"])
	_camera.position = Vector2(_view_center_x, snap["center_y"])
	_camera.make_current()
	_update_camera()
	_update_ghost_world()
	_sync_canyon_handles()
	_request_preview_redraw()

func _ensure_view_center() -> void:
	if _view_center_x >= 0.0 or _data.is_empty():
		return
	var metrics := _view_metrics()
	var width: int = metrics["width"]
	var trail: int = metrics["trail"]
	var grid: float = metrics["grid"]
	var spawn_col := int((_data.get("spawn", [2, trail]) as Array)[0])
	spawn_col = clampi(spawn_col, 0, width - 1)
	_view_center_x = (float(spawn_col) + 0.5) * grid

func _update_camera() -> void:
	if _camera == null or not is_instance_valid(_camera) or _data.is_empty():
		return
	_ensure_view_center()
	var metrics := _view_metrics()
	_camera.zoom = Vector2(metrics["zoom"], metrics["zoom"])
	_camera.position = Vector2(_view_center_x, metrics["center_y"])
	_request_preview_redraw()
	_update_cursor_marker()
	_sync_canyon_handles()

func _update_cursor_marker() -> void:
	if _cursor_marker == null or not is_instance_valid(_cursor_marker) or _data.is_empty():
		return
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var width: int = metrics["width"]
	var trail: int = metrics["trail"]
	var focus_x := _hover_column if _hover_column >= 0 else int((_data.get("spawn", [2, trail]) as Array)[0])
	focus_x = clampi(focus_x, 0, width - 1)
	var world_x := (float(focus_x) + 0.5) * grid
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
	_update_ghost_world()

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
	if display.size.x <= 1.0 or not display.has_point(local) or _camera == null:
		return Vector2i(-1, -1)
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var zoom: float = metrics["zoom"]
	var vp_size := Vector2(_viewport.size)
	var norm := (local - display.position) / display.size
	var vp_pixel := Vector2(
		clampf(norm.x, 0.0, 1.0) * vp_size.x,
		clampf(norm.y, 0.0, 1.0) * vp_size.y
	)
	var world := _camera.position + (vp_pixel - vp_size * 0.5) / zoom
	var width: int = metrics["width"]
	var height: int = metrics["height"]
	return Vector2i(
		clampi(int(floor(world.x / grid)), 0, width - 1),
		clampi(int(floor(world.y / grid)), 0, height - 1)
	)

func occupying_stamp() -> Dictionary:
	if _hover_column < 0 or _hover_row < 0 or _data.is_empty():
		return {}
	var metrics := _view_metrics()
	return CustomLevelStore.object_occupying_cell(
		_data.get("objects", []) as Array,
		_hover_column,
		_hover_row,
		int(metrics["trail"]),
		int(metrics["width"])
	)


func occupying_stamp_cells() -> Array[Vector2i]:
	if _hover_column < 0 or _hover_row < 0 or _data.is_empty():
		return []
	var metrics := _view_metrics()
	return CustomLevelStore.occupying_stamp_cells(
		_data.get("objects", []) as Array,
		_hover_column,
		_hover_row,
		int(metrics["trail"]),
		int(metrics["width"])
	)


func _ghost_rect_screen() -> Rect2:
	return _world_rect_to_screen(_aligned_ghost_world_rect())


func _placed_stamp_rect_screen() -> Rect2:
	return _world_rect_to_screen(_aligned_placed_world_rect())


func _placed_cell_rects_screen() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	for cell in occupying_stamp_cells():
		rects.append(
			_world_rect_to_screen(Rect2(float(cell.x) * grid, float(cell.y) * grid, grid, grid))
		)
	return rects

func _ghost_cell_rects_screen() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var trail: int = metrics["trail"]
	var width: int = metrics["width"]
	for cell in CustomLevelStore.stamp_hover_cells(
		_selected_type, _hover_column, _hover_row, trail, width
	):
		rects.append(
			_world_rect_to_screen(Rect2(float(cell.x) * grid, float(cell.y) * grid, grid, grid))
		)
	return rects

func _ghost_placement_object() -> Dictionary:
	if _hover_column < 0 or _hover_row < 0 or _data.is_empty():
		return {}
	var metrics := _view_metrics()
	var trail: int = metrics["trail"]
	var width: int = metrics["width"]
	var place_row := CustomLevelStore.placement_row(_selected_type, _hover_row, trail)
	var col := _hover_column
	var cells := CustomLevelStore.stamp_hover_cells(
		_selected_type, _hover_column, _hover_row, trail, width
	)
	if not cells.is_empty():
		col = cells[0].x
		place_row = cells[0].y
	return {"type": _selected_type, "x": col, "y": place_row}

func _aligned_ghost_world_rect() -> Rect2:
	if _hover_column < 0 or _hover_row < 0 or _data.is_empty():
		return Rect2()
	if _selected_type in ["erase", "ground", "canyon"]:
		return Rect2()
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var trail: int = metrics["trail"]
	var width: int = metrics["width"]
	var rect := CustomLevelStore.stamp_visual_world_rect(
		_selected_type,
		_hover_column,
		_hover_row,
		trail,
		width,
		grid,
		str(_data.get("style", CustomLevelStore.STYLE_DESERT))
	)
	if rect.size.x <= 0.0:
		return Rect2()
	if _world == null or not is_instance_valid(_world):
		return rect
	var center_x := rect.position.x + rect.size.x * 0.5
	var surface := WildWestTheme.walk_surface_at(_world, center_x)
	var floor_y := float(surface["y"])
	if CustomLevelStore.is_ground_standing(_selected_type):
		rect.position.y = floor_y + WildWestTheme.CACTUS_DESERT_SINK - rect.size.y
	elif _selected_type == "star":
		rect.position.y = floor_y - rect.size.y
	return rect


func _aligned_placed_world_rect() -> Rect2:
	var object := occupying_stamp()
	if object.is_empty():
		return Rect2()
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var trail: int = metrics["trail"]
	var width: int = metrics["width"]
	var style := str(_data.get("style", CustomLevelStore.STYLE_DESERT))
	var type_name := str(object.get("type", ""))
	if type_name == "canyon":
		var cells := occupying_stamp_cells()
		if cells.is_empty():
			return Rect2()
		var left := cells[0].x
		var right := cells[0].x
		for cell in cells:
			left = mini(left, cell.x)
			right = maxi(right, cell.x)
		return Rect2(
			float(left) * grid,
			float(trail) * grid,
			float(right - left + 1) * grid,
			grid
		)
	var rect := CustomLevelStore.stamp_visual_world_rect_for_object(
		object, trail, width, grid, style
	)
	if rect.size.x <= 0.0:
		return Rect2()
	if _world == null or not is_instance_valid(_world):
		return rect
	if type_name == "ground" or type_name == "pit":
		return rect
	var center_x := rect.position.x + rect.size.x * 0.5
	var surface := WildWestTheme.walk_surface_at(_world, center_x)
	var floor_y := float(surface["y"])
	if CustomLevelStore.is_ground_standing(type_name):
		rect.position.y = floor_y + WildWestTheme.CACTUS_DESERT_SINK - rect.size.y
	elif type_name == "star":
		rect.position.y = floor_y - rect.size.y
	return rect

func _request_preview_redraw() -> void:
	if _viewport == null:
		return
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _clear_ghost_root() -> void:
	if _ghost_root != null and is_instance_valid(_ghost_root):
		_ghost_root.queue_free()
	_ghost_root = null
	_ghost_key = ""

func _update_ghost_world() -> void:
	if _world == null or not is_instance_valid(_world):
		_clear_ghost_root()
		tooltip_text = ""
		return
	var world_rect := _aligned_ghost_world_rect()
	var placed_rect := _aligned_placed_world_rect()
	var occupying := occupying_stamp()
	var next_key := "%d:%d:%s:%s:%.1f:%.1f:%.1f:%.1f:%.1f:%.1f:%.1f:%.1f" % [
		_hover_column,
		_hover_row,
		_selected_type,
		str(occupying.get("type", "")),
		world_rect.position.x,
		world_rect.position.y,
		world_rect.size.x,
		world_rect.size.y,
		placed_rect.position.x,
		placed_rect.position.y,
		placed_rect.size.x,
		placed_rect.size.y,
	]
	if next_key == _ghost_key and _ghost_root != null and is_instance_valid(_ghost_root):
		return
	_ghost_key = next_key
	_clear_ghost_root()
	_ghost_key = next_key
	if _ghost_overlay != null:
		for child in _ghost_overlay.get_children():
			child.queue_free()
	var removable := not occupying.is_empty() and str(occupying.get("type", "")) != "ground"
	tooltip_text = tr("Right-click to remove") if removable else ""
	if world_rect.size.x <= 0.0 and placed_rect.size.x <= 0.0:
		return

	_ghost_root = Node2D.new()
	_ghost_root.name = "StampGhost"
	_ghost_root.z_index = 120
	_world.add_child(_ghost_root)
	_request_preview_redraw()

	if placed_rect.size.x > 0.0:
		_add_world_fill(placed_rect, Color(1.0, 0.94, 0.72, 0.12))
		_ghost_root.add_child(_make_world_outline(placed_rect, _PLACED_OUTLINE, 3.0))
		var metrics := _view_metrics()
		var grid: float = metrics["grid"]
		for cell in occupying_stamp_cells():
			var cell_rect := Rect2(float(cell.x) * grid, float(cell.y) * grid, grid, grid)
			_ghost_root.add_child(_make_world_outline(cell_rect, _PLACED_OUTLINE, 2.0))

	if world_rect.size.x > 0.0:
		_add_world_fill(world_rect, Color(1.0, 0.92, 0.45, 0.18))
		var style := CustomLevelStore.normalize_style(_data.get("style", "desert")) if not _data.is_empty() else "desert"
		var icon_path := LevelStyle.stamp_icon_path(_selected_type, style)
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			var texture := load(icon_path) as Texture2D
			if texture != null:
				var sprite := Sprite2D.new()
				sprite.name = "GhostIcon"
				sprite.texture = texture
				sprite.centered = false
				sprite.modulate = Color(1, 1, 1, 0.55)
				var tex_size := texture.get_size()
				if tex_size.x > 0.0 and tex_size.y > 0.0:
					sprite.scale = world_rect.size / tex_size
				sprite.position = world_rect.position
				_ghost_root.add_child(sprite)
		var metrics := _view_metrics()
		var grid: float = metrics["grid"]
		var trail: int = metrics["trail"]
		var width: int = metrics["width"]
		for cell in CustomLevelStore.stamp_hover_cells(
			_selected_type, _hover_column, _hover_row, trail, width
		):
			var cell_rect := Rect2(float(cell.x) * grid, float(cell.y) * grid, grid, grid)
			_ghost_root.add_child(_make_world_outline(cell_rect, _GHOST_OUTLINE, 2.0))


func _add_world_fill(world_rect: Rect2, color: Color) -> void:
	if _ghost_root == null:
		return
	var fill := Polygon2D.new()
	fill.color = color
	fill.polygon = PackedVector2Array([
		world_rect.position,
		world_rect.position + Vector2(world_rect.size.x, 0.0),
		world_rect.position + world_rect.size,
		world_rect.position + Vector2(0.0, world_rect.size.y),
	])
	_ghost_root.add_child(fill)


func _make_world_outline(
	world_rect: Rect2,
	color: Color = _GHOST_OUTLINE,
	line_width: float = 2.0
) -> Node2D:
	var root := Node2D.new()
	root.position = world_rect.position
	var w := world_rect.size.x
	var h := world_rect.size.y
	for points in [
		[Vector2(0, 0), Vector2(w, 0)],
		[Vector2(0, h), Vector2(w, h)],
		[Vector2(0, 0), Vector2(0, h)],
		[Vector2(w, 0), Vector2(w, h)],
	]:
		var line := Line2D.new()
		line.width = line_width
		line.default_color = color
		line.points = PackedVector2Array(points)
		root.add_child(line)
	return root

func _world_rect_to_screen(world_rect: Rect2) -> Rect2:
	if world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return Rect2()
	var display := _preview_display_rect()
	if display.size.x <= 1.0 or _camera == null or _viewport == null:
		return Rect2()
	var metrics := _view_metrics()
	var zoom: float = metrics["zoom"]
	var vp_size := Vector2(_viewport.size)
	var screen_scale := display.size / vp_size
	var center := display.position + display.size * 0.5
	var vp_offset := (world_rect.position - _camera.position) * zoom
	var top_left := center + Vector2(vp_offset.x * screen_scale.x, vp_offset.y * screen_scale.y)
	var screen_size := Vector2(
		world_rect.size.x * zoom * screen_scale.x,
		world_rect.size.y * zoom * screen_scale.y
	)
	return Rect2(top_left, screen_size)


func _sync_canyon_handles() -> void:
	if _canyon_overlay == null:
		return
	if _data.is_empty() or _camera == null or _viewport == null:
		_clear_canyon_handles()
		return
	var trail := CustomLevelStore.trail_row(int(_data.get("height", 8)))
	var runs := CustomLevelStore.canyon_column_runs(_data, trail)
	var mounted := (
		bool(_data.get("start_mounted", false)) or int(_data.get("source_level", 0)) == 1
	)
	var width := maxi(int(_data.get("width", 24)), 1)
	var parts: PackedStringArray = ["%d:%d" % [int(mounted), width]]
	for run in runs:
		parts.append("%d-%d" % [int(run["start_x"]), int(run["end_x"])])
	var next_key := "|".join(parts)
	if next_key != _canyon_handle_key:
		_rebuild_canyon_handle_nodes(runs, width, mounted)
		_canyon_handle_key = next_key
	_layout_canyon_handles()


func _clear_canyon_handles() -> void:
	_canyon_handle_key = ""
	_free_canyon_overlay_children()


func _free_canyon_overlay_children() -> void:
	if _canyon_overlay == null:
		return
	for child in _canyon_overlay.get_children():
		_canyon_overlay.remove_child(child)
		child.free()


func _rebuild_canyon_handle_nodes(runs: Array[Dictionary], width: int, mounted: bool) -> void:
	_free_canyon_overlay_children()
	for run in runs:
		var start_x := int(run["start_x"])
		var end_x := int(run["end_x"])
		var group := Control.new()
		group.name = "CanyonRun_%d_%d" % [start_x, end_x]
		group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.set_meta("start_x", start_x)
		group.set_meta("end_x", end_x)
		_canyon_overlay.add_child(group)
		group.add_child(
			_make_canyon_arrow(
				"GrowLeft",
				_ICON_SCROLL_LEFT,
				"Widen canyon left",
				start_x,
				end_x,
				"left",
				true,
				start_x <= 0
			)
		)
		group.add_child(
			_make_canyon_arrow(
				"ShrinkLeft",
				_ICON_SCROLL_RIGHT,
				"Narrow canyon from the left",
				start_x,
				end_x,
				"left",
				false,
				false
			)
		)
		group.add_child(
			_make_canyon_arrow(
				"ShrinkRight",
				_ICON_SCROLL_LEFT,
				"Narrow canyon from the right",
				start_x,
				end_x,
				"right",
				false,
				false
			)
		)
		group.add_child(
			_make_canyon_arrow(
				"GrowRight",
				_ICON_SCROLL_RIGHT,
				"Widen canyon right",
				start_x,
				end_x,
				"right",
				true,
				end_x >= width - 1
			)
		)
		if LevelLayoutRules.canyon_too_wide_for_unassisted_jump(
			CustomLevelStore.canyon_gap_px(start_x, end_x, float(_data.get("grid", 40))),
			mounted
		):
			var warn := TextureRect.new()
			warn.name = "TooWide"
			warn.texture = load(_ICON_CANYON_TOO_WIDE) as Texture2D
			warn.custom_minimum_size = Vector2(CANYON_WARNING_SIZE, CANYON_WARNING_SIZE)
			warn.size = Vector2(CANYON_WARNING_SIZE, CANYON_WARNING_SIZE)
			warn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			warn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			warn.mouse_filter = Control.MOUSE_FILTER_STOP
			warn.tooltip_text = tr("This canyon is too wide to jump")
			warn.mouse_default_cursor_shape = Control.CURSOR_ARROW
			group.add_child(warn)


func _make_canyon_arrow(
	name_text: String,
	icon_path: String,
	tooltip_key: String,
	start_x: int,
	end_x: int,
	side: String,
	grow: bool,
	disabled: bool
) -> Button:
	var button := Button.new()
	button.name = name_text
	button.custom_minimum_size = Vector2(CANYON_HANDLE_SIZE, CANYON_HANDLE_SIZE)
	button.size = Vector2(CANYON_HANDLE_SIZE, CANYON_HANDLE_SIZE)
	button.icon = load(icon_path) as Texture2D
	button.expand_icon = true
	button.text = ""
	button.tooltip_text = tr(tooltip_key)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.disabled = disabled
	MenuChrome.style_compact_icon_button(button, 10)
	button.pressed.connect(
		func() -> void: canyon_adjust_requested.emit(start_x, end_x, side, grow)
	)
	return button


func _layout_canyon_handles() -> void:
	if _canyon_overlay == null:
		return
	var display := _preview_display_rect()
	var metrics := _view_metrics()
	var grid: float = metrics["grid"]
	var trail: int = metrics["trail"]
	for group_node in _canyon_overlay.get_children():
		var group := group_node as Control
		if group == null:
			continue
		var start_x := int(group.get_meta("start_x", -1))
		var end_x := int(group.get_meta("end_x", -1))
		if start_x < 0:
			continue
		var gap := _world_rect_to_screen(
			Rect2(
				float(start_x) * grid,
				float(trail) * grid,
				float(end_x - start_x + 1) * grid,
				grid
			)
		)
		var hit := display.grow(CANYON_HANDLE_SIZE)
		var visible := gap.size.x > 0.0 and hit.intersects(gap)
		group.visible = visible
		if not visible:
			continue
		var mid_y := gap.position.y + gap.size.y * 0.5 - CANYON_HANDLE_SIZE * 0.5
		var shrink_y := mid_y
		if gap.size.x < CANYON_HANDLE_SIZE * 2.0 + 8.0:
			shrink_y = gap.position.y - CANYON_HANDLE_SIZE - 2.0
		_place_canyon_handle(
			group.get_node_or_null("GrowLeft") as Control,
			Vector2(gap.position.x - CANYON_HANDLE_SIZE - 2.0, mid_y),
			display
		)
		_place_canyon_handle(
			group.get_node_or_null("ShrinkLeft") as Control,
			Vector2(gap.position.x + 2.0, shrink_y),
			display
		)
		_place_canyon_handle(
			group.get_node_or_null("ShrinkRight") as Control,
			Vector2(gap.end.x - CANYON_HANDLE_SIZE - 2.0, shrink_y),
			display
		)
		_place_canyon_handle(
			group.get_node_or_null("GrowRight") as Control,
			Vector2(gap.end.x + 2.0, mid_y),
			display
		)
		var warn := group.get_node_or_null("TooWide") as Control
		if warn != null:
			var warn_y := minf(shrink_y, gap.position.y) - CANYON_WARNING_SIZE - 4.0
			_place_canyon_handle(
				warn,
				Vector2(
					gap.position.x + gap.size.x * 0.5 - CANYON_WARNING_SIZE * 0.5,
					warn_y
				),
				display
			)


func _place_canyon_handle(handle: Control, desired: Vector2, display: Rect2) -> void:
	if handle == null:
		return
	var size := handle.size
	if size.x < 1.0 or size.y < 1.0:
		size = handle.custom_minimum_size
	handle.size = size
	var max_pos := Vector2(
		display.end.x - size.x,
		display.end.y - size.y
	)
	handle.position = Vector2(
		clampf(desired.x, display.position.x, maxf(max_pos.x, display.position.x)),
		clampf(desired.y, display.position.y, maxf(max_pos.y, display.position.y))
	)
	handle.pivot_offset = size * 0.5


func _point_hits_canyon_handle(local: Vector2) -> bool:
	if _canyon_overlay == null:
		return false
	var global := global_position + local
	for group_node in _canyon_overlay.get_children():
		if not (group_node is Control) or not (group_node as Control).visible:
			continue
		for child in group_node.get_children():
			var handle := child as Control
			if handle == null or not handle.visible:
				continue
			if handle.mouse_filter == Control.MOUSE_FILTER_IGNORE:
				continue
			if handle.get_global_rect().has_point(global):
				return true
	return false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var local := (event as InputEventMouse).position
		if _point_hits_canyon_handle(local):
			return
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
				var placement := _ghost_placement_object()
				var stamp_col := int(placement.get("x", cell.x)) if not placement.is_empty() else cell.x
				stamp_requested.emit(stamp_col, cell.y)
				accept_event()
			elif mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
				remove_requested.emit(cell.x, cell.y)
				accept_event()

