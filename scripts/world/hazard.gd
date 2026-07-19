class_name Hazard
extends Area2D

## Harmful pit or spikes. Always returns the player to a checkpoint,
## even while a Bubble Shield is active.

signal hurt(player: Player)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		hurt.emit(body as Player)
