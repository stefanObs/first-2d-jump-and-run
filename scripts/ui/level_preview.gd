class_name LevelPreview
extends Control

## Live 3/4-size gameplay preview centered on the editor cursor column.

signal hover_column_changed(column: int)

const GAME_SIZE := Vector2(1280, 720)
const PREVIEW_SCALE := 0.75
const PREVIEW_SIZE := Vector2(960, 540)

var _data: Dictionary = {}
var _hover_column: int = -1
var _container: SubViewportContainer
var _viewport: SubViewport
var _world: LevelController
var _camera: Camera2D
var _cursor_marker: Node2D
var _rebuild_pending := false
var _last_built_hash := ""


func _ready() -> void:
	custom_minimum_size = PREVIEW_SIZE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_viewport()
	if not _data.is_empty():
		_queue_rebuild()


func show_level(data: Dictionary) -> void:
	_data = data.duplicate(true)
	_queue_rebuild()


func set_hover_column(column: int) -> void:
	var width := maxi(int(_data.get("width", 24)), 1)
	var next := clampi(column, -1, width - 1)
	if next == _hover_column:
		return
	_hover_column = next
	_update_camera()
	hover_column_changed.emit(_hover_column)


func get_hover_column() -> int:
	return _hover_column


func _build_viewport() -> void:
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.1, 0.04, 1)
	style.set_border_width_all(4)
	style.border_color = Color(0.45, 0.24, 0.08, 1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	frame.add_theme_stylebox_override(&"panel", style)
	add_child(frame)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(center)

	_container = SubViewportContainer.new()
	_container.name = "LivePreviewContainer"
	_container.custom_minimum_size = PREVIEW_SIZE
	_container.stretch = true
	_container.stretch_shrink = 1
	center.add_child(_container)

	_viewport = SubViewport.new()
	_viewport.name = "LivePreviewViewport"
	_viewport.size = Vector2i(int(GAME_SIZE.x), int(GAME_SIZE.y))
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = false
	_viewport.gui_disable_input = true
	_viewport.physics_object_picking = false
	_container.add_child(_viewport)


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
		return
	_last_built_hash = digest
	for child in _viewport.get_children():
		child.queue_free()
	_world = null
	_camera = null
	_cursor_marker = null
	if _data.is_empty():
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
	marker.size = Vector2(8, 120)
	marker.position = Vector2(-4, -120)
	marker.color = Color(1.0, 0.85, 0.15, 0.85)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_marker.add_child(marker)
	level.add_child(_cursor_marker)

	_world = level
	_update_camera()


func _update_camera() -> void:
	if _camera == null or not is_instance_valid(_camera) or _data.is_empty():
		return
	var grid := float(_data.get("grid", 40))
	var width := maxi(int(_data.get("width", 24)), 1)
	var height := maxi(int(_data.get("height", 8)), 1)
	var trail := CustomLevelStore.trail_row(height)
	var focus_x := _hover_column if _hover_column >= 0 else int((_data.get("spawn", [2, trail]) as Array)[0])
	focus_x = clampi(focus_x, 0, width - 1)
	var world_x := (float(focus_x) + 0.5) * grid
	var world_y := float(trail) * grid - 80.0
	_camera.position = Vector2(world_x, world_y)
	if _cursor_marker != null and is_instance_valid(_cursor_marker):
		_cursor_marker.position = Vector2(world_x, float(trail) * grid)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var local := (event as InputEventMouse).position
		var width := maxi(int(_data.get("width", 24)), 1)
		if size.x <= 1.0:
			return
		var rel := clampf(local.x / size.x, 0.0, 0.999)
		# Map click across the visible window (~half the trail around cursor).
		var window := mini(14, width)
		var start := _window_start(width, window)
		set_hover_column(start + int(floor(rel * float(window))))


func _window_start(width: int, window: int) -> int:
	var focus := _hover_column if _hover_column >= 0 else mini(4, width - 1)
	return clampi(focus - window / 2, 0, maxi(width - window, 0))
