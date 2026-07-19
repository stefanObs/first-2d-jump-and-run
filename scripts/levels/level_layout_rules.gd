class_name LevelLayoutRules
extends RefCounted

## Validates safe star pickup and forward-only level solvability.


static func validate_level_node(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var spawn := level.get_node_or_null("SpawnPoint") as Node2D
	var checkpoint := level.find_child("Checkpoint", true, false) as Node2D
	var goal := level.find_child("Goal", true, false) as Node2D
	if spawn == null:
		errors.append("Missing SpawnPoint.")
		return errors
	if goal == null:
		errors.append("Missing Goal.")
		return errors

	var spawn_x := spawn.global_position.x
	var goal_x := goal.global_position.x
	if goal_x <= spawn_x + 80.0:
		errors.append("Goal should be clearly ahead of the spawn for forward play.")

	var checkpoint_x := spawn_x
	if checkpoint != null:
		checkpoint_x = checkpoint.global_position.x
		if checkpoint_x <= spawn_x + 40.0:
			errors.append("Checkpoint should be ahead of the spawn.")
		if goal_x <= checkpoint_x + 40.0:
			errors.append("Goal should be ahead of the checkpoint.")

	var hazards: Array[Rect2] = []
	for node in level.find_children("*", "Area2D", true, false):
		if node is Hazard:
			hazards.append(_approx_rect(node as Node2D, Vector2(64, 32)))
		elif node is Opponent:
			hazards.append(_approx_rect(node as Node2D, Vector2(48, 48)))

	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Star):
			continue
		var star := node as Node2D
		var star_pos := star.global_position
		var star_rect := _approx_rect(star, Vector2(28, 28))
		if star_pos.x < spawn_x - 40.0:
			errors.append("Star %s is behind the spawn." % star.name)
		# Stars before the checkpoint must still be on the forward approach,
		# not stranded far behind spawn after the player has progressed.
		if checkpoint != null and star_pos.x < checkpoint_x:
			if star_pos.x < spawn_x + 20.0:
				errors.append("Star %s is not on the forward path to the checkpoint." % star.name)
		for hazard_rect in hazards:
			var padded := hazard_rect.grow(18.0)
			if padded.intersects(star_rect):
				errors.append("Star %s overlaps a hazard/opponent and is unsafe to collect." % star.name)
				break
	return errors


static func _approx_rect(node: Node2D, fallback_size: Vector2) -> Rect2:
	var size := fallback_size
	var shape_node := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null and shape_node.shape is RectangleShape2D:
		size = (shape_node.shape as RectangleShape2D).size * node.scale.abs()
	elif shape_node != null and shape_node.shape is CircleShape2D:
		var radius := (shape_node.shape as CircleShape2D).radius * maxf(node.scale.x, node.scale.y)
		size = Vector2(radius * 2.0, radius * 2.0)
	var center := node.global_position
	if shape_node != null:
		center = shape_node.global_position
	return Rect2(center - size * 0.5, size)
