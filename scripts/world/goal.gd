class_name Goal
extends Area2D

## Saloon exit that starts the celebration transition when reached.

signal reached(goal: Goal)

var _triggered: bool = false
var _sprite: CanvasItem


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as CanvasItem
	if _sprite == null:
		_sprite = get_node_or_null("Visual") as CanvasItem
	body_entered.connect(_on_body_entered)


func reset() -> void:
	_triggered = false
	if _sprite != null:
		_sprite.modulate = Color(1, 1, 1, 1)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body is Player:
		_triggered = true
		if _sprite != null:
			_sprite.modulate = Color(1.0, 0.95, 0.55, 1.0)
		reached.emit(self)
