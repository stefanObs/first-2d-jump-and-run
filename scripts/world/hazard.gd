class_name Hazard
extends Area2D

## Harmful zone that returns the player to the latest checkpoint.

signal hurt(player: Player)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		if player.is_invulnerable():
			return
		hurt.emit(player)
