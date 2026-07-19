extends Node2D

## Gray-box first level used to validate movement and camera follow.


func _ready() -> void:
	var player := $Player as Player
	if player == null:
		push_error("Level01 expects a Player child named Player.")
		return
	player.global_position = $SpawnPoint.global_position
