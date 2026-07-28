class_name CaveCeilingHazard
extends Area2D

## Solid cave rock ceiling: blocks Wings flight and respawns on touch while flying.

signal hurt(player: Player)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var player := body as Player
	if player.get_modes().is_flying():
		hurt.emit(player)
