class_name Checkpoint
extends Area2D

## Safe respawn marker activated when the player touches it.

signal activated(checkpoint: Checkpoint)

@export var is_active: bool = false

var _visual: ColorRect
var _label: Label


func _ready() -> void:
	_visual = get_node_or_null("Visual") as ColorRect
	_label = get_node_or_null("Label") as Label
	body_entered.connect(_on_body_entered)
	_update_visual()


func activate() -> void:
	if is_active:
		return
	is_active = true
	_update_visual()
	activated.emit(self)


func deactivate() -> void:
	is_active = false
	_update_visual()


func get_respawn_position() -> Vector2:
	return global_position


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		activate()


func _update_visual() -> void:
	if _visual == null:
		return
	_visual.color = Color(0.95, 0.85, 0.2, 1.0) if is_active else Color(0.75, 0.75, 0.8, 1.0)
	if _label != null:
		_label.text = "SAVE" if is_active else "FLAG"
