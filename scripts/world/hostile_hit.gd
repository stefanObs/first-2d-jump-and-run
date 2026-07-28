class_name HostileHit
extends RefCounted

## Shared “hurt cowboy then caller frees” check for hostile projectiles.


## Returns true when body was the player (hit resolved; caller should queue_free).
static func try_hurt_player(emitter: Object, body: Node2D) -> bool:
	if not (body is Player):
		return false
	var player := body as Player
	if not player.is_invulnerable():
		emitter.emit_signal(&"hurt_player", player)
	return true
