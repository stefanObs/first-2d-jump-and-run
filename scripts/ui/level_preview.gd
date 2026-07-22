class_name LevelPreview
extends Control

## Game-like trail preview. Prefer a large hover magnifier; keep a small overview strip.

signal hover_column_changed(column: int)

var _data: Dictionary = {}
var _hover_column: int = -1
var _magnifier := true
var _overview_height := 56.0


func _ready() -> void:
	custom_minimum_size = Vector2(0, 220)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW


func show_level(data: Dictionary) -> void:
	_data = data.duplicate(true)
	queue_redraw()


func set_hover_column(column: int) -> void:
	var width := maxi(int(_data.get("width", 24)), 1)
	var next := clampi(column, -1, width - 1)
	if next == _hover_column:
		return
	_hover_column = next
	queue_redraw()
	hover_column_changed.emit(_hover_column)


func get_hover_column() -> int:
	return _hover_column


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var local := (event as InputEventMouse).position
		var width := maxi(int(_data.get("width", 24)), 1)
		var area := _magnifier_area()
		if area.has_point(local) or local.y < size.y:
			var overview := _overview_area()
			if overview.has_point(local):
				var rel := (local.x - overview.position.x) / maxf(overview.size.x, 1.0)
				set_hover_column(int(floor(rel * float(width))))
			elif area.has_point(local):
				var window := _window_columns()
				var start := _window_start(width, window)
				var rel := (local.x - area.position.x) / maxf(area.size.x, 1.0)
				set_hover_column(start + int(floor(rel * float(window))))


func _draw() -> void:
	if _data.is_empty():
		return
	_draw_magnifier()
	_draw_overview()


func _magnifier_area() -> Rect2:
	return Rect2(Vector2(8, 4), Vector2(maxf(size.x - 16.0, 10.0), maxf(size.y - _overview_height - 10.0, 80.0)))


func _overview_area() -> Rect2:
	return Rect2(
		Vector2(8, size.y - _overview_height + 2.0),
		Vector2(maxf(size.x - 16.0, 10.0), maxf(_overview_height - 8.0, 24.0))
	)


func _window_columns() -> int:
	return 10


func _window_start(width: int, window: int) -> int:
	var focus := _hover_column if _hover_column >= 0 else mini(4, width - 1)
	return clampi(focus - window / 2, 0, maxi(width - window, 0))


func _draw_magnifier() -> void:
	var width := maxi(int(_data.get("width", 24)), 1)
	var height := maxi(int(_data.get("height", 8)), 1)
	var trail := CustomLevelStore.trail_row(height)
	var area := _magnifier_area()
	draw_rect(area, Color(0.52, 0.80, 0.96, 1.0), true)
	# Desert wash under the trail line.
	var trail_band_y := area.position.y + area.size.y * (float(trail) + 0.15) / float(height)
	draw_rect(
		Rect2(Vector2(area.position.x, trail_band_y), Vector2(area.size.x, area.end.y - trail_band_y)),
		Color(0.91, 0.68, 0.36, 1.0),
		true
	)
	var window := mini(_window_columns(), width)
	var start := _window_start(width, window)
	var cell := minf(area.size.x / float(window), area.size.y / float(height))
	var origin := Vector2(
		area.position.x + (area.size.x - float(window) * cell) * 0.5,
		area.end.y - float(height) * cell
	)
	_draw_objects(origin, cell, start, start + window - 1, true)
	# Focus frame around the hovered column.
	if _hover_column >= start and _hover_column < start + window:
		var focus := Rect2(origin + Vector2(float(_hover_column - start) * cell, 0.0), Vector2(cell, float(height) * cell))
		draw_rect(focus, Color(1.0, 0.92, 0.45, 0.18), true)
		draw_rect(focus, Color(0.95, 0.72, 0.18, 0.95), false, 2.0)
	draw_rect(area, Color(0.30, 0.13, 0.04), false, 3.0)
	var label := "Hover preview" if _hover_column < 0 else "Column %d" % (_hover_column + 1)
	draw_string(
		ThemeDB.fallback_font,
		area.position + Vector2(10, 22),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.28, 0.12, 0.04, 0.9)
	)


func _draw_overview() -> void:
	var width := maxi(int(_data.get("width", 24)), 1)
	var height := maxi(int(_data.get("height", 8)), 1)
	var area := _overview_area()
	draw_rect(area, Color(0.48, 0.76, 0.94, 1.0), true)
	draw_rect(
		Rect2(area.position + Vector2(0, area.size.y * 0.55), Vector2(area.size.x, area.size.y * 0.45)),
		Color(0.90, 0.66, 0.34, 1.0),
		true
	)
	var cell := minf(area.size.x / float(width), area.size.y / float(height))
	var origin := Vector2(area.position.x, area.end.y - float(height) * cell)
	_draw_objects(origin, cell, 0, width - 1, false)
	if _hover_column >= 0:
		var marker := Rect2(origin + Vector2(float(_hover_column) * cell, 0.0), Vector2(maxf(cell, 2.0), float(height) * cell))
		draw_rect(marker, Color(1.0, 0.85, 0.2, 0.35), true)
	draw_rect(area, Color(0.30, 0.13, 0.04), false, 2.0)


func _draw_objects(origin: Vector2, cell: float, first_x: int, last_x: int, detailed: bool) -> void:
	var height := maxi(int(_data.get("height", 8)), 1)
	var trail := CustomLevelStore.trail_row(height)
	var ground_by_x: Dictionary = {}
	for value in _data.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		var x := int(object.get("x", 0))
		if x < first_x or x > last_x:
			continue
		if str(object.get("type", "")) == "ground":
			var y := int(object.get("y", trail))
			if not ground_by_x.has(x):
				ground_by_x[x] = []
			(ground_by_x[x] as Array).append(y)

	# Dirt columns with stacked steps first so props sit on top.
	for x in ground_by_x.keys():
		var ys: Array = ground_by_x[x]
		ys.sort()
		var top_y: int = int(ys[0])
		var bottom_y: int = int(ys[ys.size() - 1])
		var top_rect := Rect2(
			origin + Vector2(float(x - first_x), float(top_y)) * cell,
			Vector2(maxf(cell, 1.0), maxf(cell * float(bottom_y - top_y + 1), cell))
		)
		# Dirt body.
		draw_rect(top_rect, Color(0.58, 0.32, 0.14), true)
		# Desert surface only on the highest step.
		var surface := Rect2(top_rect.position, Vector2(top_rect.size.x, maxf(2.0, cell * 0.28)))
		draw_rect(surface, Color(0.91, 0.68, 0.36), true)
		draw_line(
			surface.position,
			surface.position + Vector2(surface.size.x, 0),
			Color(0.35, 0.62, 0.24),
			maxf(1.0, cell * 0.12)
		)
		# Step ledge when stacked.
		if bottom_y > top_y and detailed:
			for step_y in ys:
				if int(step_y) == top_y:
					continue
				var ledge_y := origin.y + float(step_y) * cell
				draw_line(
					Vector2(top_rect.position.x, ledge_y),
					Vector2(top_rect.end.x, ledge_y),
					Color(0.42, 0.22, 0.10),
					maxf(1.0, cell * 0.1)
				)

	for value in _data.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		var x := int(object.get("x", 0))
		if x < first_x or x > last_x:
			continue
		var y := float(object.get("y", 0))
		var rect := Rect2(origin + Vector2(float(x - first_x), y) * cell, Vector2(maxf(cell, 1.0), maxf(cell, 1.0)))
		var type_name := str(object.get("type", ""))
		match type_name:
			"ground":
				pass
			"platform":
				draw_rect(
					Rect2(rect.position + Vector2(0, cell * 0.35), Vector2(cell * (1.6 if detailed else 1.2), maxf(2.0, cell * 0.28))),
					Color(0.42, 0.22, 0.08),
					true
				)
			"pit", "canyon":
				var open := Rect2(rect.position + Vector2(cell * 0.08, cell * 0.2), Vector2(cell * 0.84, cell * 1.6))
				draw_rect(Rect2(rect.position, Vector2(cell, cell * 1.8)), Color(0.78, 0.48, 0.22), true)
				draw_rect(open, Color(0.45, 0.62, 0.88, 1.0), true)
				draw_rect(open.grow(-cell * 0.08), Color(0.55, 0.28, 0.16, 0.85), true)
			"star":
				draw_circle(rect.get_center(), maxf(2.0, cell * 0.28), Color(1.0, 0.82, 0.12))
			"cactus":
				draw_line(
					rect.get_center() + Vector2(0, cell * 0.35),
					rect.get_center() - Vector2(0, cell * 0.35),
					Color(0.18, 0.55, 0.2),
					maxf(2.0, cell * 0.22)
				)
			"checkpoint":
				draw_line(
					rect.position + Vector2(cell * 0.5, cell * 0.9),
					rect.position + Vector2(cell * 0.5, cell * 0.1),
					Color(0.35, 0.16, 0.05),
					maxf(1.0, cell * 0.12)
				)
				draw_circle(rect.position + Vector2(cell * 0.72, cell * 0.22), maxf(2.0, cell * 0.18), Color(0.95, 0.28, 0.14))
			"spring":
				draw_rect(Rect2(rect.position + Vector2(0, cell * 0.6), Vector2(cell, cell * 0.28)), Color(0.2, 0.75, 0.35), true)
			"bandit":
				draw_circle(rect.get_center(), maxf(2.0, cell * 0.3), Color(0.28, 0.12, 0.05))
			"goal":
				draw_rect(
					Rect2(rect.position - Vector2(cell * 0.15, cell * 0.7), Vector2(cell * 1.3, cell * 1.6)),
					Color(0.58, 0.28, 0.08),
					true
				)
	var spawn: Array = _data.get("spawn", [2, trail])
	if spawn.size() >= 2:
		var sx := int(spawn[0])
		if sx >= first_x and sx <= last_x:
			var spawn_pos := origin + Vector2(float(sx - first_x) + 0.5, float(spawn[1]) + 0.5) * cell
			draw_circle(spawn_pos, maxf(3.0, cell * 0.32), Color(0.1, 0.35, 0.8))
