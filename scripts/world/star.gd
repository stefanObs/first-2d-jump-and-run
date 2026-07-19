class_name Star
extends Area2D

## Optional collectible star.

signal collected

var _taken: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _taken or not (body is Player):
		return
	_taken = true
	(body as Player).collect_star()
	collected.emit()
	queue_free()
