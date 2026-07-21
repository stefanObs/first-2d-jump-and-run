class_name LevelPreview
extends Control

## Always-visible whole-level miniature beneath the editable grid.

var _data: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(0, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_level(data: Dictionary) -> void:
	_data = data.duplicate(true)
	queue_redraw()


func _draw() -> void:
	if _data.is_empty():
		return
	var width := maxi(int(_data.get("width", 24)), 1)
	var height := maxi(int(_data.get("height", 10)), 1)
	var area := Rect2(Vector2(8, 6), Vector2(maxf(size.x - 16.0, 10.0), maxf(size.y - 12.0, 10.0)))
	draw_rect(area, Color(0.53, 0.80, 0.96, 1.0), true)
	draw_rect(Rect2(area.position + Vector2(0, area.size.y * 0.58), Vector2(area.size.x, area.size.y * 0.42)), Color(0.92, 0.68, 0.35, 1.0), true)
	var cell := minf(area.size.x / float(width), area.size.y / float(height))
	var origin := Vector2(area.position.x, area.end.y - float(height) * cell)
	for value in _data.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		var x := float(object.get("x", 0))
		var y := float(object.get("y", 0))
		var rect := Rect2(origin + Vector2(x, y) * cell, Vector2(maxf(cell, 1.0), maxf(cell, 1.0)))
		var type_name := str(object.get("type", ""))
		match type_name:
			"ground":
				draw_rect(rect, Color(0.55, 0.30, 0.12), true)
				draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color(0.25, 0.62, 0.22), maxf(1.0, cell * 0.18))
			"platform":
				draw_rect(Rect2(rect.position, Vector2(cell * 2.0, maxf(2.0, cell * 0.3))), Color(0.38, 0.20, 0.08), true)
			"pit":
				draw_rect(Rect2(rect.position, Vector2(cell, cell * 2.0)), Color(0.08, 0.02, 0.04), true)
			"star":
				draw_circle(rect.get_center(), maxf(2.0, cell * 0.32), Color(1.0, 0.82, 0.12))
			"cactus":
				draw_line(rect.get_center() + Vector2(0, cell * 0.4), rect.get_center() - Vector2(0, cell * 0.4), Color(0.18, 0.55, 0.2), maxf(2.0, cell * 0.25))
			"checkpoint":
				draw_line(rect.position + Vector2(cell * 0.5, cell), rect.position + Vector2(cell * 0.5, 0), Color(0.35, 0.16, 0.05), maxf(1.0, cell * 0.12))
				draw_circle(rect.position + Vector2(cell * 0.72, cell * 0.2), maxf(2.0, cell * 0.2), Color(0.95, 0.28, 0.14))
			"spring":
				draw_rect(Rect2(rect.position + Vector2(0, cell * 0.65), Vector2(cell, cell * 0.25)), Color(0.2, 0.75, 0.35), true)
			"bandit":
				draw_circle(rect.get_center(), maxf(2.0, cell * 0.34), Color(0.28, 0.12, 0.05))
			"goal":
				draw_rect(Rect2(rect.position - Vector2(cell * 0.3, cell), Vector2(cell * 1.6, cell * 2.0)), Color(0.58, 0.28, 0.08), true)
	var spawn: Array = _data.get("spawn", [2, 8])
	if spawn.size() >= 2:
		var spawn_pos := origin + Vector2(float(spawn[0]), float(spawn[1])) * cell
		draw_circle(spawn_pos, maxf(3.0, cell * 0.4), Color(0.1, 0.35, 0.8))
	draw_rect(area, Color(0.30, 0.13, 0.04), false, 3.0)
