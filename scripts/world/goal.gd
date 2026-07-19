class_name Goal
extends Area2D

## Level exit that starts the celebration transition when reached.

signal reached(goal: Goal)

var _triggered: bool = false
var _visual: ColorRect


func _ready() -> void:
	_visual = get_node_or_null("Visual") as ColorRect
	body_entered.connect(_on_body_entered)


func reset() -> void:
	_triggered = false
	if _visual != null:
		_visual.color = Color(0.25, 0.85, 0.45, 1.0)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body is Player:
		_triggered = true
		if _visual != null:
			_visual.color = Color(1.0, 0.95, 0.35, 1.0)
		reached.emit(self)
