extends BossArena

## Midnight Coach: lasso three door handles in order.

const COACH_TEX := preload("res://assets/world/boss_midnight_coach.png")

var _coach: Node2D
var _doors: Array[BossLassoTarget] = []
var _doors_done: int = 0
var _next_door: int = 0
var _dir: float = 1.0
var _speed: float = 150.0


func _ready() -> void:
	source_level = 7
	boss_title = "Midnight Coach — tie the doors in order!"
	super._ready()
	_coach = $Coach as Node2D
	var spr := $Coach/Sprite2D as Sprite2D
	if spr != null:
		spr.texture = COACH_TEX
	_doors.clear()
	for i in range(3):
		var door := get_node_or_null("Coach/Door%d" % i) as BossLassoTarget
		if door != null:
			door.set_meta("door_index", i)
			door.set_lasso_active(i == 0)
			_doors.append(door)
	_refresh_door_hints()


func _physics_process(delta: float) -> void:
	if _won or _coach == null:
		return
	_coach.position.x += _dir * _speed * delta
	if _coach.position.x > 1100.0:
		_dir = -1.0
	elif _coach.position.x < 500.0:
		_dir = 1.0


func on_door_lassoed(index: int) -> void:
	if _won:
		return
	if index != _next_door:
		report_progress("Wrong door — start with door %d!" % (_next_door + 1))
		return
	_doors_done += 1
	_next_door += 1
	report_progress("Door %d tied! (%d/3)" % [index + 1, _doors_done])
	if index < _doors.size() and _doors[index] != null:
		_doors[index].set_lasso_active(false)
		_doors[index].modulate = Color(0.4, 0.85, 0.35, 1)
	_refresh_door_hints()
	if _doors_done >= 3:
		win_boss()


func _refresh_door_hints() -> void:
	for i in range(_doors.size()):
		var door := _doors[i]
		if door == null:
			continue
		var is_next := i == _next_door and not _won
		door.set_lasso_active(is_next)
		if is_next:
			door.modulate = Color(1.2, 1.05, 0.4, 1)
		elif i < _next_door:
			door.modulate = Color(0.4, 0.85, 0.35, 1)
		else:
			door.modulate = Color(0.75, 0.75, 0.75, 0.9)
