class_name SpringPad
extends Area2D

@export var bounce_velocity: float = -820.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		player.velocity.y = bounce_velocity
