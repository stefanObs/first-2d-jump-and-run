extends BossArena

## Midnight Coach: lasso three door handles in order.

const COACH_TEX := preload("res://assets/world/boss_midnight_coach.png")

var _coach: AnimatableBody2D
var _doors_done: int = 0
var _next_door: int = 0
var _dir: float = 1.0
var _speed: float = 160.0


func _ready() -> void:
	source_level = 7
	boss_title = "Midnight Coach — tie the doors in order!"
	super._ready()
	_coach = $Coach as AnimatableBody2D
	var spr := $Coach/Sprite2D as Sprite2D
	if spr != null:
		spr.texture = COACH_TEX
	for i in range(3):
		var door := get_node_or_null("Coach/Door%d" % i) as AnimatableBody2D
		if door != null:
			door.set_meta("door_index", i)


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
	var door := get_node_or_null("Coach/Door%d" % index) as Node2D
	if door != null:
		door.modulate = Color(0.4, 0.85, 0.35, 1)
	if _doors_done >= 3:
		win_boss()
