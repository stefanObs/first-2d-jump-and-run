class_name LevelLayoutRules
extends RefCounted

## Structural and mathematical QA for safe, forward-solvable, styled levels.

const BASE_JUMP_HEIGHT := 90.0
const ASSISTED_JUMP_HEIGHT := 190.0
const SPRING_JUMP_HEIGHT := 250.0
const BASE_HORIZONTAL_GAP := 230.0
const ASSISTED_HORIZONTAL_GAP := 340.0


static func validate_level_node(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	errors.append_array(_validate_forward_route(level))
	errors.append_array(_validate_stars(level))
	errors.append_array(_validate_platforms(level))
	errors.append_array(_validate_checkpoints(level))
	errors.append_array(_validate_no_plank_highway(level))
	errors.append_array(_validate_ground_props_clear_of_raised_platforms(level))
	errors.append_array(_validate_cactus_clear_of_springs(level))
	errors.append_array(_validate_mode_item_spacing(level))
	errors.append_array(_validate_visuals(level))
	return errors


static func _validate_forward_route(level: Node) -> PackedStringArray:
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
		errors.append("Goal should be clearly ahead of the spawn.")
	if checkpoint != null:
		var checkpoint_x := checkpoint.global_position.x
		if checkpoint_x <= spawn_x + 40.0:
			errors.append("Checkpoint should be ahead of the spawn.")
		if goal_x <= checkpoint_x + 40.0:
			errors.append("Goal should be ahead of the checkpoint.")

	var ground := level.find_child("Ground", true, false) as Node2D
	if ground == null:
		ground = level.find_child("GroundLeft", true, false) as Node2D
	if ground == null:
		errors.append("No styled ground route exists between spawn and goal.")
	return errors


static func _validate_stars(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var spawn := level.get_node_or_null("SpawnPoint") as Node2D
	var checkpoint := level.find_child("Checkpoint", true, false) as Node2D
	if spawn == null:
		return errors

	var hazards: Array[Rect2] = []
	for node in level.find_children("*", "Area2D", true, false):
		if node is Hazard:
			hazards.append(_approx_rect(node as Node2D, Vector2(64, 32)))
	for node in level.find_children("*", "AnimatableBody2D", true, false):
		if node is Opponent:
			hazards.append(_approx_rect(node as Node2D, Vector2(48, 48)))

	var spawn_x := spawn.global_position.x
	var checkpoint_x := checkpoint.global_position.x if checkpoint != null else spawn_x
	var surfaces: Array[Dictionary] = []
	for surface_node in level.find_children("*", "PhysicsBody2D", true, false):
		if _is_platform(surface_node):
			var surface := _surface_for(surface_node as Node2D)
			if not surface.is_empty():
				surfaces.append(surface)
	var jump_height := BASE_JUMP_HEIGHT
	if _has_mode(level, ModeController.Mode.MAGIC_BOOTS):
		jump_height = ASSISTED_JUMP_HEIGHT
	if _has_spring(level):
		jump_height = maxf(jump_height, SPRING_JUMP_HEIGHT)
	var has_wings := _has_mode(level, ModeController.Mode.WINGS)
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Star):
			continue
		var star := node as Node2D
		var star_pos := star.global_position
		var star_rect := _approx_rect(star, Vector2(28, 28))
		if star_pos.x < spawn_x - 40.0:
			errors.append("Star %s is behind the spawn." % star.name)
		if checkpoint != null and star_pos.x < checkpoint_x and star_pos.x < spawn_x + 20.0:
			errors.append("Star %s is not on the forward path to the checkpoint." % star.name)
		for hazard_rect in hazards:
			if hazard_rect.grow(18.0).intersects(star_rect):
				errors.append("Star %s is unsafe to collect." % star.name)
				break
		if not has_wings and not _star_has_reachable_surface(star_pos, surfaces, jump_height):
			errors.append("Star %s has no reachable supporting surface." % star.name)
	return errors


static func _star_has_reachable_surface(
	star_position: Vector2,
	surfaces: Array[Dictionary],
	jump_height: float
) -> bool:
	for surface in surfaces:
		var left := float(surface["left"]) - 48.0
		var right := float(surface["right"]) + 48.0
		if star_position.x < left or star_position.x > right:
			continue
		if StarReachability.is_star_reachable_from_surface(
			float(surface["top"]),
			star_position.y,
			jump_height,
			12.0
		):
			return true
	return false


static func _validate_platforms(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var surfaces: Array[Dictionary] = []
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if _is_platform(node):
			var surface := _surface_for(node as Node2D)
			if not surface.is_empty():
				surfaces.append(surface)
	if surfaces.is_empty():
		errors.append("Level has no standable, styled surfaces.")
		return errors

	var has_wings := _has_mode(level, ModeController.Mode.WINGS)
	var has_boots := _has_mode(level, ModeController.Mode.MAGIC_BOOTS)
	var has_spring := _has_spring(level)
	var jump_height := BASE_JUMP_HEIGHT
	var horizontal_gap := BASE_HORIZONTAL_GAP
	if has_boots:
		jump_height = ASSISTED_JUMP_HEIGHT
		horizontal_gap = ASSISTED_HORIZONTAL_GAP
	if has_spring:
		jump_height = maxf(jump_height, SPRING_JUMP_HEIGHT)
		horizontal_gap = ASSISTED_HORIZONTAL_GAP

	var reachable: Array[int] = []
	for index in range(surfaces.size()):
		if bool(surfaces[index]["is_ground"]):
			reachable.append(index)
	if reachable.is_empty():
		errors.append("No reachable ground surface starts the level.")
		return errors

	if not has_wings:
		var changed := true
		while changed:
			changed = false
			for target_index in range(surfaces.size()):
				if target_index in reachable:
					continue
				for source_index in reachable:
					if _can_reach_surface(
						surfaces[source_index],
						surfaces[target_index],
						jump_height,
						horizontal_gap
					):
						reachable.append(target_index)
						changed = true
						break

	for index in range(surfaces.size()):
		if has_wings or index in reachable:
			continue
		errors.append("Platform %s is not reachable from the forward route." % surfaces[index]["name"])
	return errors


static func _validate_checkpoints(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var grounds: Array[Dictionary] = []
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if String(node.name).begins_with("Ground"):
			var surface := _surface_for(node as Node2D)
			if not surface.is_empty():
				grounds.append(surface)
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Checkpoint):
			continue
		var checkpoint := node as Node2D
		var supported := false
		for ground in grounds:
			if (
				checkpoint.global_position.x >= float(ground["left"]) + 32.0
				and checkpoint.global_position.x <= float(ground["right"]) - 32.0
			):
				supported = true
				break
		if not supported:
			errors.append("Checkpoint %s is not safely supported by ground." % checkpoint.name)
	return errors


static func _validate_no_plank_highway(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var numbered_planks := 0
	for node in level.find_children("*", "StaticBody2D", true, false):
		if String(node.name).match("Platform*") and String(node.name).trim_prefix("Platform").is_valid_int():
			numbered_planks += 1
	if numbered_planks > 12:
		errors.append("Generic plank highway blocks hazards and ground interactions.")
	return errors


static func _validate_visuals(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var background := level.get_node_or_null("Background") as ColorRect
	if background == null or not background.visible or background.color.a < 0.8:
		errors.append("Environment needs a clearly visible styled background.")

	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if _is_platform(node) and not _has_visible_art(node):
			if String(node.name).begins_with("Ground") and level.get_node_or_null("TrailFloor") != null:
				continue
			errors.append("Platform %s has no visible styling." % node.name)
	for node in level.find_children("*", "Area2D", true, false):
		if (
			node is Star
			or node is Hazard
			or node is Goal
			or node is Checkpoint
			or node is ModeItem
			or node is SpringPad
			or node is WindZone
		):
			if not _has_visible_art(node):
				errors.append("Gameplay object %s has no clearly visible effect/art." % node.name)
	for node in level.find_children("*", "AnimatableBody2D", true, false):
		if (node is Opponent or node is MovingPlatform) and not _has_visible_art(node):
			errors.append("Moving object %s has no visible styling." % node.name)

	var transition := level.find_child("LevelTransition", true, false)
	if transition == null or transition.get_node_or_null("Veil") == null or transition.get_node_or_null("Banner") == null:
		errors.append("Completion effect is missing its visible veil or banner.")
	return errors


static func _validate_ground_props_clear_of_raised_platforms(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var raised: Array[Dictionary] = []
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if not _is_platform(node):
			continue
		var surface := _surface_for(node as Node2D)
		if not surface.is_empty() and float(surface["top"]) < 290.0:
			raised.append(surface)
	for node in level.find_children("*", "Area2D", true, false):
		var is_ground_prop := node is SpringPad or node is Rattlesnake
		if node is Hazard:
			is_ground_prop = (node as Hazard).is_cactus()
		if not is_ground_prop:
			continue
		var rect := _approx_rect(node as Node2D, Vector2(64, 40))
		for surface in raised:
			if rect.end.x > float(surface["left"]) and rect.position.x < float(surface["right"]):
				errors.append(
					"%s must not sit below raised platform %s."
					% [node.name, String(surface["name"])]
				)
				break
	return errors


static func _validate_cactus_clear_of_springs(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var cacti: Array[Node2D] = []
	var springs: Array[Node2D] = []
	for node in level.find_children("*", "Area2D", true, false):
		if node is Hazard and (node as Hazard).is_cactus():
			cacti.append(node as Node2D)
		elif node is SpringPad:
			springs.append(node as Node2D)
	for cactus in cacti:
		var cactus_rect := _approx_rect(cactus, Vector2(40, 48)).grow(10.0)
		for spring in springs:
			var spring_rect := _approx_rect(spring, Vector2(64, 24)).grow(10.0)
			if cactus_rect.intersects(spring_rect):
				errors.append(
					"Cactus %s must never overlap spring %s."
					% [cactus.name, spring.name]
				)
	return errors


static func _validate_mode_item_spacing(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var items: Array[ModeItem] = []
	for node in level.find_children("*", "Area2D", true, false):
		if node is ModeItem:
			items.append(node as ModeItem)
	for left_index in range(items.size()):
		for right_index in range(left_index + 1, items.size()):
			var left := items[left_index]
			var right := items[right_index]
			if left.global_position.distance_to(right.global_position) < 220.0:
				errors.append("Mode items %s and %s are too close." % [left.name, right.name])
	return errors


static func _is_platform(node: Node) -> bool:
	if node is Opponent or node is TimedDoor:
		return false
	var name_text := String(node.name)
	return (
		name_text.begins_with("Ground")
		or name_text.contains("Platform")
		or name_text.begins_with("Moving")
		or name_text.begins_with("Cloud")
		or name_text.begins_with("Conveyor")
		or name_text.contains("Ledge")
	)


static func _surface_for(node: Node2D) -> Dictionary:
	var shape_node := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return {}
	var size := (shape_node.shape as RectangleShape2D).size * node.scale.abs()
	var center := shape_node.global_position
	var left := center.x - size.x * 0.5
	var right := center.x + size.x * 0.5
	if node is MovingPlatform:
		var moving := node as MovingPlatform
		left += minf(moving.point_a.x, moving.point_b.x)
		right += maxf(moving.point_a.x, moving.point_b.x)
	return {
		"name": String(node.name),
		"left": left,
		"right": right,
		"top": center.y - size.y * 0.5,
		"is_ground": String(node.name).begins_with("Ground"),
	}


static func _can_reach_surface(
	source: Dictionary,
	target: Dictionary,
	jump_height: float,
	horizontal_gap: float
) -> bool:
	var rise: float = float(source["top"]) - float(target["top"])
	if rise > jump_height + 12.0:
		return false
	var gap := 0.0
	if float(target["left"]) > float(source["right"]):
		gap = float(target["left"]) - float(source["right"])
	elif float(source["left"]) > float(target["right"]):
		gap = float(source["left"]) - float(target["right"])
	return gap <= horizontal_gap


static func _has_mode(level: Node, mode: ModeController.Mode) -> bool:
	for node in level.find_children("*", "Area2D", true, false):
		if node is ModeItem and (node as ModeItem).mode == mode:
			return true
	return false


static func _has_spring(level: Node) -> bool:
	for node in level.find_children("*", "Area2D", true, false):
		if node is SpringPad:
			return true
	return false


static func _has_visible_art(node: Node) -> bool:
	for child in node.get_children():
		if child is CanvasItem:
			var canvas := child as CanvasItem
			if not canvas.visible or canvas.modulate.a < 0.25:
				continue
			if child is ColorRect and (child as ColorRect).color.a >= 0.25:
				return true
			if child is Sprite2D and (child as Sprite2D).texture != null:
				return true
			if child is AnimatedSprite2D:
				return true
		if _has_visible_art(child):
			return true
	return false


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
