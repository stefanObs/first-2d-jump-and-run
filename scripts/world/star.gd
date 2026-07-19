class_name Star
extends Area2D

## Optional collectible star with a gentle bob so kids spot it easily.

signal collected

var _taken: bool = false
var _base_y: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_base_y = position.y
	_phase = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _taken:
		return
	_phase += delta * 3.2
	position.y = _base_y + sin(_phase) * 5.0
	rotation = sin(_phase * 0.5) * 0.12


func _on_body_entered(body: Node2D) -> void:
	if _taken or not (body is Player):
		return
	_taken = true
	(body as Player).collect_star()
	collected.emit()
	queue_free()
