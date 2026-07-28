class_name EnemyContact
extends RefCounted

## Shared stomp / bounce math for ground enemies (bandit, bull, ninja).

const STOMP_BOUNCE := -420.0
const STOMP_MIN_FALL_SPEED := 80.0


static func is_head_stomp(enemy: Node2D, player: Player, chest_offset_y: float = 24.0) -> bool:
	# Stomp = contact from above while falling downward.
	var chest_y := enemy.global_position.y - chest_offset_y
	if player.global_position.y > chest_y:
		return false
	if player.velocity.y < STOMP_MIN_FALL_SPEED:
		return false
	return true


static func bounce_after_stomp(player: Player) -> void:
	player.velocity.y = STOMP_BOUNCE
	if absf(player.velocity.x) < 40.0:
		player.velocity.x = 0.0


static func kill_tween(tween: Tween) -> void:
	if tween != null:
		tween.kill()
