class_name LevelLayoutRules
extends RefCounted

## Structural and mathematical QA for safe, forward-solvable, styled levels.

const BASE_JUMP_HEIGHT := 90.0
const ASSISTED_JUMP_HEIGHT := 190.0
const SPRING_JUMP_HEIGHT := 250.0
const BASE_HORIZONTAL_GAP := 230.0
const ASSISTED_HORIZONTAL_GAP := 340.0
const CACTUS_CANYON_CLEAR_PX := 120.0  ## Past thin hand-painted rim face (RIM_SIZE.x + margin).
## Timed doors stay clear of the gap and the rim band (tall gates must not sit above mouths).
const TIMED_DOOR_CANYON_CLEAR_PX := 140.0
const TIMED_DOOR_HALF_WIDTH := 45.0
## Conveyor push path must hit a timed door (or clear solid ground) before a canyon.
const CONVEYOR_HALF_WIDTH := 80.0
const CONVEYOR_CANYON_PROBE_PX := 720.0
const CONVEYOR_DOOR_CATCH_PX := 55.0
const SPRING_APPROACH_PX := 350.0
const RATTLESNAKE_CANYON_CLEAR_PX := 120.0
const CANYON_HEIGHT_STEP_PX := 10.0
const CONTINUOUS_HEIGHT_STEP_PX := 10.0
const LATE_LEVEL_HEIGHT_DIFF_MIN := 2
const LATE_LEVEL_HEIGHT_DIFF_MAX := 10
const CARRION_MAX_SCALE := 0.65
const CARRION_VISUAL_HALF := Vector2(74.0, 46.0)
const PLAYER_BODY_HEIGHT := 44.0
const WALK_CLEAR_PX := 28.0
const FLIGHT_CEILING_Y := -40.0
const CORRIDOR_GAP_MIN := 50.0
const CORRIDOR_GAP_MAX := 120.0
const CORRIDOR_X_OVERLAP := 80.0


static func validate_level_node(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	errors.append_array(_validate_forward_route(level))
	errors.append_array(_validate_stars(level))
	errors.append_array(_validate_platforms(level))
	errors.append_array(_validate_goal_reachable_without_items(level))
	errors.append_array(_validate_checkpoints(level))
	errors.append_array(_validate_no_plank_highway(level))
	errors.append_array(_validate_ground_props_clear_of_raised_platforms(level))
	errors.append_array(_validate_cactus_clear_of_springs(level))
	errors.append_array(_validate_cactus_clear_of_canyons(level))
	errors.append_array(_validate_rattlesnakes_clear_of_canyons(level))
	errors.append_array(_validate_bulls_clear_of_pits_and_canyons(level))
	errors.append_array(_validate_ground_standing_clear_of_gaps(level))
	errors.append_array(_validate_canyon_up_needs_spring(level))
	errors.append_array(_validate_timed_doors_clear_of_canyons(level))
	errors.append_array(_validate_no_doors_in_caves(level))
	errors.append_array(_validate_conveyors_not_pushing_into_canyons(level))
	errors.append_array(_validate_no_slopes_across_canyons(level))
	errors.append_array(_validate_late_level_height_differences(level))
	errors.append_array(_validate_carrion_flight_paths(level))
	errors.append_array(_validate_mode_item_spacing(level))
	errors.append_array(_validate_ladder_tops(level))
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
		ground = level.find_child("Ground0", true, false) as Node2D
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

	var has_spring := _has_spring(level)
	var jump_height := BASE_JUMP_HEIGHT
	var horizontal_gap := BASE_HORIZONTAL_GAP
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

	if not _has_mode(level, ModeController.Mode.WINGS):
		var changed := true
		while changed:
			changed = false
			for target_index in range(surfaces.size()):
				if target_index in reachable:
					continue
				if _is_optional_platform(String(surfaces[target_index]["name"])):
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
		if _has_mode(level, ModeController.Mode.WINGS):
			continue
		if _is_optional_platform(String(surfaces[index]["name"])):
			continue
		if index in reachable:
			continue
		errors.append("Platform %s is not reachable from the forward route." % surfaces[index]["name"])
	return errors


static func _validate_goal_reachable_without_items(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	if _has_mode(level, ModeController.Mode.WINGS):
		return errors
	var goal := level.find_child("Goal", true, false) as Node2D
	if goal == null:
		return errors
	var surfaces: Array[Dictionary] = []
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if not _is_platform(node):
			continue
		if _is_optional_platform(String(node.name)):
			continue
		var surface := _surface_for(node as Node2D)
		if not surface.is_empty():
			surfaces.append(surface)
	if surfaces.is_empty():
		errors.append("Goal route needs standable ground surfaces.")
		return errors

	var has_spring := _has_spring(level)
	var jump_height := BASE_JUMP_HEIGHT
	var horizontal_gap := BASE_HORIZONTAL_GAP
	if has_spring:
		jump_height = maxf(jump_height, SPRING_JUMP_HEIGHT)
		horizontal_gap = ASSISTED_HORIZONTAL_GAP

	var reachable: Array[int] = []
	for index in range(surfaces.size()):
		if bool(surfaces[index].get("is_ground", false)):
			reachable.append(index)
	if reachable.is_empty():
		errors.append("Goal route needs reachable ground at the level start.")
		return errors

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

	var goal_pos := goal.global_position
	var goal_supported := false
	for index in reachable:
		var surface := surfaces[index]
		if (
			goal_pos.x >= float(surface["left"]) - 48.0
			and goal_pos.x <= float(surface["right"]) + 48.0
			and float(surface["top"]) - goal_pos.y <= jump_height + 24.0
		):
			goal_supported = true
			break
	if not goal_supported:
		errors.append(
			"Goal is not reachable without power-up items (springs are allowed)."
		)
	return errors


static func _validate_checkpoints(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var camps: Array[Node2D] = []
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Checkpoint):
			continue
		var checkpoint := node as Node2D
		camps.append(checkpoint)
		var pos := checkpoint.global_position
		var surface := WildWestTheme.walk_surface_at(level, pos.x)
		var floor_y := float(surface["y"])
		if pos.y > floor_y + 16.0 or pos.y < floor_y - 96.0:
			errors.append("Checkpoint %s is not safely supported by ground." % checkpoint.name)
	if camps.size() < 3:
		errors.append("Need at least 3 camps (found %d)." % camps.size())
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
			var node_name := String(node.name)
			if node_name.begins_with("Ground") and level.get_node_or_null("TrailFloor") != null:
				continue
			if node_name.begins_with("FloorSlopeBody"):
				# Dune collision is styled by FloorSlope* sprites on TrailFloor.
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
		if String(node.name).begins_with("FloorSlopeBody"):
			continue
		if _is_optional_platform(String(node.name)):
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


static func _validate_cactus_clear_of_canyons(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var gaps := _ground_canyon_gaps(level)
	if gaps.is_empty():
		return errors
	var springs: Array[Node2D] = []
	var cacti: Array[Node2D] = []
	for node in level.find_children("*", "Area2D", true, false):
		if node is Hazard and (node as Hazard).is_cactus():
			cacti.append(node as Node2D)
		elif node is SpringPad:
			springs.append(node as Node2D)
	for cactus in cacti:
		# Use the sprite body, not only the origin — a centered cactus can hang
		# over the mouth while its position still sits on the bank.
		var cactus_rect := _approx_rect(cactus, Vector2(52, 64))
		var cactus_left := cactus_rect.position.x
		var cactus_right := cactus_rect.end.x
		for gap in gaps:
			var gap_left := float(gap["left"])
			var gap_right := float(gap["right"])
			# Body overlapping the open mouth is always illegal (incl. overhang).
			if cactus_right > gap_left and cactus_left < gap_right:
				errors.append(
					"Cactus %s sits inside canyon gap %.0f..%.0f; remove it."
					% [cactus.name, gap_left, gap_right]
				)
				break
			# Also reject bodies that sit on the hand-painted ridge band.
			var rim_band := CACTUS_CANYON_CLEAR_PX * 0.45
			if cactus_right > gap_left - rim_band and cactus_left < gap_left:
				errors.append(
					"Cactus %s overlaps the left canyon ridge band at gap %.0f..%.0f."
					% [cactus.name, gap_left, gap_right]
				)
				break
			if cactus_left < gap_right + rim_band and cactus_right > gap_right:
				errors.append(
					"Cactus %s overlaps the right canyon ridge band at gap %.0f..%.0f."
					% [cactus.name, gap_left, gap_right]
				)
				break
			var side := ""
			var edge_dist := INF
			if cactus_right <= gap_left:
				side = "before"
				edge_dist = gap_left - cactus_right
			elif cactus_left >= gap_right:
				side = "after"
				edge_dist = cactus_left - gap_right
			if edge_dist >= CACTUS_CANYON_CLEAR_PX:
				continue
			var spring_ok := false
			for spring in springs:
				var sx := spring.global_position.x
				if side == "before" and gap_left - SPRING_APPROACH_PX <= sx and sx <= gap_left + 40.0:
					spring_ok = true
				elif side == "after" and gap_right - 40.0 <= sx and sx <= gap_right + SPRING_APPROACH_PX:
					spring_ok = true
			if spring_ok:
				continue
			errors.append(
				"Cactus %s is directly %s canyon gap %.0f..%.0f without a launch spring."
				% [cactus.name, side, gap_left, gap_right]
			)
			break
	return errors


static func _validate_timed_doors_clear_of_canyons(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var gaps := _ground_canyon_gaps(level)
	if gaps.is_empty():
		return errors
	for node in level.find_children("*", "StaticBody2D", true, false):
		if not (node is TimedDoor):
			continue
		var door := node as Node2D
		var door_left := door.global_position.x - TIMED_DOOR_HALF_WIDTH
		var door_right := door.global_position.x + TIMED_DOOR_HALF_WIDTH
		for gap in gaps:
			var gap_left := float(gap["left"]) - TIMED_DOOR_CANYON_CLEAR_PX
			var gap_right := float(gap["right"]) + TIMED_DOOR_CANYON_CLEAR_PX
			var overlap := minf(door_right, gap_right) - maxf(door_left, gap_left)
			if overlap <= 0.0:
				continue
			errors.append(
				"TimedDoor %s sits over/above canyon gap %.0f..%.0f; remove it."
				% [door.name, float(gap["left"]), float(gap["right"])]
			)
			break
	return errors


static func _validate_no_doors_in_caves(level: Node) -> PackedStringArray:
	## Ranch gates belong to the desert; cave trails use belts, ladders and ledges.
	var errors: PackedStringArray = []
	if not LevelStyle.is_cave(str(level.get_meta("level_style", LevelStyle.DESERT))):
		return errors
	for node in level.find_children("*", "StaticBody2D", true, false):
		if node is TimedDoor:
			errors.append("TimedDoor %s sits in a cave trail; caves carry no ranch gates." % node.name)
	return errors


static func _validate_conveyors_not_pushing_into_canyons(level: Node) -> PackedStringArray:
	## Belts may push into a timed door on solid ground, never into an open canyon.
	var errors: PackedStringArray = []
	var gaps := _ground_canyon_gaps(level)
	if gaps.is_empty():
		return errors
	var doors: Array[Node2D] = []
	for node in level.find_children("*", "StaticBody2D", true, false):
		if node is TimedDoor:
			doors.append(node as Node2D)
	for node in level.find_children("*", "StaticBody2D", true, false):
		if not (node is ConveyorBelt):
			continue
		var belt := node as ConveyorBelt
		var direction := 1.0 if belt.push_right else -1.0
		# Prefer global X; fall back to local when transforms are not flushed yet.
		var belt_x := belt.global_position.x
		if is_zero_approx(belt_x) and not is_zero_approx(belt.position.x):
			belt_x = belt.position.x
		var cursor := belt_x + CONVEYOR_HALF_WIDTH * direction
		var blocked_by_door := false
		var step := 0.0
		while step <= CONVEYOR_CANYON_PROBE_PX:
			for door in doors:
				var door_x := door.global_position.x
				if is_zero_approx(door_x) and not is_zero_approx(door.position.x):
					door_x = door.position.x
				if absf(door_x - cursor) <= CONVEYOR_DOOR_CATCH_PX:
					blocked_by_door = true
					break
			if blocked_by_door:
				break
			for gap in gaps:
				var gap_left := float(gap["left"])
				var gap_right := float(gap["right"])
				if cursor >= gap_left and cursor <= gap_right:
					errors.append(
						"Conveyor %s pushes into canyon gap %.0f..%.0f; reposition belt/door onto solid ground."
						% [belt.name, gap_left, gap_right]
					)
					blocked_by_door = true
					break
			if blocked_by_door:
				break
			cursor += direction * 10.0
			step += 10.0
	return errors


static func _validate_rattlesnakes_clear_of_canyons(level: Node) -> PackedStringArray:
	## Snakes must not sit on the approach (near) bank right in front of a canyon mouth.
	var errors: PackedStringArray = []
	var gaps := _ground_canyon_gaps(level)
	if gaps.is_empty():
		return errors
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Rattlesnake):
			continue
		var snake := node as Node2D
		var snake_rect := _approx_rect(snake, Vector2(88, 28))
		var snake_right := snake_rect.end.x
		for gap in gaps:
			var gap_left := float(gap["left"])
			var gap_right := float(gap["right"])
			if snake_right > gap_left and snake_rect.position.x < gap_right:
				errors.append(
					"Rattlesnake %s sits inside canyon gap %.0f..%.0f; remove it."
					% [snake.name, gap_left, gap_right]
				)
				break
			# Approaching from the left (campaign runs rightward).
			if snake_right > gap_left:
				continue
			var edge_dist := gap_left - snake_right
			if edge_dist >= RATTLESNAKE_CANYON_CLEAR_PX:
				continue
			errors.append(
				"Rattlesnake %s is directly in front of canyon gap %.0f..%.0f."
				% [snake.name, gap_left, gap_right]
			)
			break
	return errors


static func _validate_bulls_clear_of_pits_and_canyons(level: Node) -> PackedStringArray:
	## Trail bulls / cave lizards must stand on solid dirt — never over a pit or canyon mouth.
	return _validate_actors_clear_of_gaps(level, "bull", Vector2(72, 64), "Bull")


static func _validate_ground_standing_clear_of_gaps(level: Node) -> PackedStringArray:
	## Bandits, ninjas, springs, camps, goals, items, belts, and doors never sit in a mouth.
	var errors: PackedStringArray = []
	errors.append_array(_validate_actors_clear_of_gaps(level, "foe", Vector2(48, 64), "Ground foe"))
	errors.append_array(_validate_actors_clear_of_gaps(level, "prop", Vector2(56, 64), "Ground prop"))
	return errors


static func _actor_matches_gap_kind(node: Node, kind: String) -> bool:
	match kind:
		"bull":
			return node is BullEnemy
		"foe":
			return node is Opponent or node is NinjaEnemy
		"prop":
			return (
				node is SpringPad
				or node is Checkpoint
				or node is TreasureChest
				or node is ModeItem
				or node is Goal
				or node is ConveyorBelt
				or node is TimedDoor
				or node is Ladder
			)
		_:
			return false


static func _validate_actors_clear_of_gaps(
	level: Node,
	kind: String,
	fallback_size: Vector2,
	label: String
) -> PackedStringArray:
	var errors: PackedStringArray = []
	var actors: Array[Node2D] = []
	for node in level.find_children("*", "Node2D", true, false):
		if _actor_matches_gap_kind(node, kind):
			actors.append(node as Node2D)
	if actors.is_empty():
		return errors

	var gaps := _ground_canyon_gaps(level)
	var pit_spans: Array[Dictionary] = []
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Hazard):
			continue
		var hazard := node as Hazard
		if not hazard.is_pit():
			continue
		var center := (node as Node2D).global_position.x
		pit_spans.append({
			"left": center - CustomLevelStore.PIT_PIXEL_SIZE.x * 0.5,
			"right": center + CustomLevelStore.PIT_PIXEL_SIZE.x * 0.5,
			"name": node.name,
		})

	for actor in actors:
		var actor_rect := _approx_rect(actor, fallback_size)
		var actor_left := actor_rect.position.x
		var actor_right := actor_rect.end.x
		for gap in gaps:
			var gap_left := float(gap["left"])
			var gap_right := float(gap["right"])
			if actor_right > gap_left and actor_left < gap_right:
				errors.append(
					"%s %s sits inside canyon gap %.0f..%.0f; move it onto solid dirt."
					% [label, actor.name, gap_left, gap_right]
				)
				break
		for pit in pit_spans:
			var pit_left := float(pit["left"])
			var pit_right := float(pit["right"])
			if actor_right > pit_left and actor_left < pit_right:
				errors.append(
					"%s %s sits over pit %s; move it onto solid dirt."
					% [label, actor.name, str(pit["name"])]
				)
				break
	return errors


static func _validate_canyon_up_needs_spring(level: Node) -> PackedStringArray:
	## Far bank higher than near bank requires a spring on the approach side.
	var errors: PackedStringArray = []
	var gaps := _ground_canyon_gaps(level)
	if gaps.is_empty():
		return errors
	var springs: Array[Node2D] = []
	for node in level.find_children("*", "Area2D", true, false):
		if node is SpringPad:
			springs.append(node as Node2D)
	for gap in gaps:
		var left_end := float(gap["left"])
		var right_start := float(gap["right"])
		var near_top := float(gap["near_top"])
		var far_top := float(gap["far_top"])
		var rise := near_top - far_top
		if rise < CANYON_HEIGHT_STEP_PX:
			continue
		var spring_ok := false
		for spring in springs:
			var sx := spring.global_position.x
			if left_end - SPRING_APPROACH_PX <= sx and sx <= left_end + 40.0:
				spring_ok = true
				break
		if spring_ok:
			continue
		errors.append(
			"Canyon gap %.0f..%.0f ends higher (rise %.0f) without an approach spring."
			% [left_end, right_start, rise]
		)
	return errors


static func _validate_late_level_height_differences(level: Node) -> PackedStringArray:
	## Levels 7–10 need a modest amount of continuous bank height steps (not canyon-only).
	var errors: PackedStringArray = []
	var level_number := 0
	if level is LevelController:
		level_number = (level as LevelController).level_number
	elif level.get("level_number") != null:
		level_number = int(level.get("level_number"))
	if level_number < 7 or level_number > 10:
		return errors
	var count := count_continuous_height_differences(level)
	if count < LATE_LEVEL_HEIGHT_DIFF_MIN or count > LATE_LEVEL_HEIGHT_DIFF_MAX:
		errors.append(
			"Level %d needs %d–%d continuous height differences (found %d)."
			% [level_number, LATE_LEVEL_HEIGHT_DIFF_MIN, LATE_LEVEL_HEIGHT_DIFF_MAX, count]
		)
	return errors


static func count_continuous_height_differences(level: Node) -> int:
	## Distinct walk-surface Y changes along continuous ground (excludes canyon transitions).
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	var count := 0
	for index in range(merged.size() - 1):
		if WildWestTheme._is_canyon_between(merged[index], merged[index + 1]):
			continue
		var step := absf(float(merged[index]["top"]) - float(merged[index + 1]["top"]))
		if step >= CONTINUOUS_HEIGHT_STEP_PX:
			count += 1
	return count


static func _validate_no_slopes_across_canyons(level: Node) -> PackedStringArray:
	## Height changes across a canyon use the canyon itself — never a painted slope.
	var errors: PackedStringArray = []
	var gaps := _ground_canyon_gaps(level)
	if gaps.is_empty():
		return errors
	for body in level.find_children("FloorSlopeBody*", "StaticBody2D", true, false):
		var col := body.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		if col == null or col.polygon.size() < 2:
			continue
		var min_x := INF
		var max_x := -INF
		for point in col.polygon:
			var local_point: Vector2 = point
			var world_x: float = body.to_global(local_point).x
			min_x = minf(min_x, world_x)
			max_x = maxf(max_x, world_x)
		for gap in gaps:
			var gap_left := float(gap["left"])
			var gap_right := float(gap["right"])
			var overlap := minf(max_x, gap_right) - maxf(min_x, gap_left)
			if overlap > 16.0:
				errors.append(
					"Desert slope %s crosses canyon gap %.0f..%.0f; canyon is the height transition."
					% [body.name, gap_left, gap_right]
				)
				break
	return errors


static func _validate_carrion_flight_paths(level: Node) -> PackedStringArray:
	var errors: PackedStringArray = []
	var carrions: Array[Carrion] = []
	for node in level.find_children("*", "Area2D", true, false):
		if node is Carrion:
			carrions.append(node as Carrion)
	if carrions.is_empty():
		return errors

	var flight_span_left := INF
	var flight_span_right := -INF
	var has_flight_corridor := false
	for carrion in carrions:
		var sprite := carrion.get_node_or_null("Sprite2D") as Node2D
		var scale_x := absf(sprite.scale.x) if sprite != null else absf(carrion.scale.x)
		var scale_y := absf(sprite.scale.y) if sprite != null else absf(carrion.scale.y)
		if maxf(scale_x, scale_y) > CARRION_MAX_SCALE + 0.001:
			errors.append("Carrion %s is too large (scale %.2f)." % [carrion.name, maxf(scale_x, scale_y)])
		var half := Vector2(CARRION_VISUAL_HALF.x * scale_x / 0.58, CARRION_VISUAL_HALF.y * scale_y / 0.58)
		var bird_rect := Rect2(carrion.global_position - half, half * 2.0)
		bird_rect.position.x -= carrion.patrol_width
		bird_rect.size.x += carrion.patrol_width * 2.0
		bird_rect.position.y -= carrion.bob_height
		bird_rect.size.y += carrion.bob_height * 2.0
		var solid_rect := bird_rect.grow(12.0)
		flight_span_left = minf(flight_span_left, bird_rect.position.x)
		flight_span_right = maxf(flight_span_right, bird_rect.end.x)

		for body in level.find_children("*", "PhysicsBody2D", true, false):
			if body is Player or body is Opponent:
				continue
			var body_name := String(body.name)
			if body_name.begins_with("FlightCeiling") or body_name.begins_with("Ground"):
				continue
			var body_rect := _solid_rect_for(body as Node2D)
			if body_rect.size == Vector2.ZERO:
				continue
			if solid_rect.intersects(body_rect):
				errors.append(
					"Carrion %s patrols through solid obstacle %s."
					% [carrion.name, body.name]
				)
				break

		var floor_top := INF
		for body in level.find_children("Ground*", "StaticBody2D", true, false):
			var surface := _surface_for(body as Node2D)
			if surface.is_empty():
				continue
			if (
				carrion.global_position.x >= float(surface["left"])
				and carrion.global_position.x <= float(surface["right"])
			):
				floor_top = minf(floor_top, float(surface["top"]))
		if floor_top < INF:
			var max_bottom := floor_top - PLAYER_BODY_HEIGHT - WALK_CLEAR_PX
			if bird_rect.end.y > max_bottom:
				errors.append("Carrion %s flies too low for the cowboy to walk under." % carrion.name)

	for left_index in range(carrions.size()):
		for right_index in range(left_index + 1, carrions.size()):
			var a := carrions[left_index]
			var b := carrions[right_index]
			var a_left := a.global_position.x - a.patrol_width
			var a_right := a.global_position.x + a.patrol_width
			var b_left := b.global_position.x - b.patrol_width
			var b_right := b.global_position.x + b.patrol_width
			var overlap := minf(a_right, b_right) - maxf(a_left, b_left)
			if overlap < CORRIDOR_X_OVERLAP:
				continue
			var upper: Carrion = a if a.global_position.y < b.global_position.y else b
			var lower: Carrion = b if upper == a else a
			var upper_bottom := upper.global_position.y + upper.bob_height + CARRION_VISUAL_HALF.y
			var lower_top := lower.global_position.y - lower.bob_height - CARRION_VISUAL_HALF.y
			var gap := lower_top - upper_bottom
			if gap >= CORRIDOR_GAP_MIN and gap <= CORRIDOR_GAP_MAX:
				has_flight_corridor = true

	if _has_mode(level, ModeController.Mode.WINGS):
		var ceiling_coverage := 0.0
		var span := maxf(flight_span_right - flight_span_left, 1.0)
		for body in level.find_children("*", "StaticBody2D", true, false):
			if not String(body.name).begins_with("FlightCeiling"):
				continue
			var ceiling_rect := _solid_rect_for(body as Node2D)
			if ceiling_rect.size == Vector2.ZERO:
				continue
			if ceiling_rect.position.y > FLIGHT_CEILING_Y:
				errors.append("Flight ceiling %s is too low to block leaving the window." % body.name)
				continue
			var covered := minf(ceiling_rect.end.x, flight_span_right) - maxf(ceiling_rect.position.x, flight_span_left)
			ceiling_coverage += maxf(covered, 0.0)
		if ceiling_coverage / span < 0.7:
			errors.append("Wings route needs FlightCeiling solids covering the carrion flight band.")
		if not has_flight_corridor:
			errors.append("Wings route needs a paired carrion corridor to fly between.")
	return errors


static func _ground_surface_spans(level: Node) -> Array[Dictionary]:
	var spans: Array[Dictionary] = []
	for body in level.find_children("Ground*", "StaticBody2D", true, false):
		# Fill blocks only pad under raised banks — walk top comes from the non-Fill ground.
		if String(body.name).ends_with("Fill"):
			continue
		var surface := _surface_for(body as Node2D)
		if surface.is_empty():
			continue
		spans.append(surface)
	spans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["left"]) < float(b["left"]))
	return spans


static func _ground_canyon_gaps(level: Node) -> Array[Dictionary]:
	var spans := _ground_surface_spans(level)
	var gaps: Array[Dictionary] = []
	for index in range(spans.size() - 1):
		var left_end := float(spans[index]["right"])
		var right_start := float(spans[index + 1]["left"])
		if right_start - left_end > 20.0:
			gaps.append({
				"left": left_end,
				"right": right_start,
				"near_top": float(spans[index]["top"]),
				"far_top": float(spans[index + 1]["top"]),
			})
	# Dune slopes carve Ground cliff faces, leaving a gap that FloorSlopeBody walks.
	# Those carved seams are not canyons — filter them out.
	return _gaps_without_slope_bridges(level, gaps)


static func _gaps_without_slope_bridges(level: Node, gaps: Array[Dictionary]) -> Array[Dictionary]:
	if gaps.is_empty():
		return gaps
	var bridges: Array[Dictionary] = []
	for body in level.find_children("FloorSlopeBody*", "StaticBody2D", true, false):
		var col := body.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		if col == null or col.polygon.size() < 2:
			continue
		var min_x := INF
		var max_x := -INF
		for point in col.polygon:
			var world_x: float = body.to_global(point).x
			min_x = minf(min_x, world_x)
			max_x = maxf(max_x, world_x)
		if max_x > min_x:
			bridges.append({"left": min_x, "right": max_x})
	if bridges.is_empty():
		return gaps
	var real_gaps: Array[Dictionary] = []
	for gap in gaps:
		var gap_left := float(gap["left"])
		var gap_right := float(gap["right"])
		var bridged := false
		for bridge in bridges:
			var overlap := minf(gap_right, float(bridge["right"])) - maxf(gap_left, float(bridge["left"]))
			if overlap > (gap_right - gap_left) * 0.5:
				bridged = true
				break
		if not bridged:
			real_gaps.append(gap)
	return real_gaps


static func _solid_rect_for(node: Node2D) -> Rect2:
	var rect := _approx_rect(node, Vector2(64, 32))
	if node is MovingPlatform:
		var moving := node as MovingPlatform
		var min_x := minf(moving.point_a.x, moving.point_b.x)
		var max_x := maxf(moving.point_a.x, moving.point_b.x)
		var min_y := minf(moving.point_a.y, moving.point_b.y)
		var max_y := maxf(moving.point_a.y, moving.point_b.y)
		rect.position.x += min_x
		rect.position.y += min_y
		rect.size.x += max_x - min_x
		rect.size.y += max_y - min_y
	return rect


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


static func _validate_ladder_tops(level: Node) -> PackedStringArray:
	## Every ladder must have a standable plank near climb_top so the cowboy can step off.
	var errors: PackedStringArray = []
	var ladders: Array[Ladder] = []
	for node in level.find_children("*", "Area2D", true, false):
		if node is Ladder:
			ladders.append(node as Ladder)
	if ladders.is_empty():
		return errors
	var surfaces: Array[Dictionary] = []
	for node in level.find_children("*", "PhysicsBody2D", true, false):
		if not _is_platform(node):
			continue
		var surface := _surface_for(node as Node2D)
		if not surface.is_empty():
			surfaces.append(surface)
	for ladder in ladders:
		var top_y := ladder.climb_top_y()
		var cx := ladder.center_x()
		var found := false
		for surface in surfaces:
			# Plank top should sit at or slightly above climb_top (24px one-way plank).
			if float(surface["top"]) < top_y - 28.0 or float(surface["top"]) > top_y + 4.0:
				continue
			if float(surface["right"]) < cx - 28.0 or float(surface["left"]) > cx + 28.0:
				continue
			found = true
			break
		if not found:
			errors.append(
				"Ladder %s has no standable ledge at the climb top (player cannot reach the upper path)."
				% ladder.name
			)
	return errors


static func _is_optional_platform(name_text: String) -> bool:
	return (
		name_text.contains("Reward")
		or name_text.begins_with("MovingHop")
		or name_text == "BootsHopLedge"
		or name_text.begins_with("WindLedge")
		or name_text.begins_with("SpringLedge")
		or name_text.begins_with("LadderLedge")
	)


static func _is_platform(node: Node) -> bool:
	if node is Opponent or node is TimedDoor:
		return false
	var name_text := String(node.name)
	return (
		name_text.begins_with("Ground")
		or name_text.begins_with("FloorSlopeBody")
		or name_text.contains("Platform")
		or name_text.begins_with("Moving")
		or name_text.begins_with("Cloud")
		or name_text.begins_with("Ferry")
		or name_text.begins_with("Conveyor")
		or name_text.contains("Ledge")
	)


static func _surface_for(node: Node2D) -> Dictionary:
	var name_text := String(node.name)
	if name_text.begins_with("FloorSlopeBody"):
		var col := node.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		if col == null or col.polygon.size() < 2:
			return {}
		var min_x := INF
		var max_x := -INF
		var min_y := INF
		for point in col.polygon:
			var world: Vector2 = node.to_global(point)
			min_x = minf(min_x, world.x)
			max_x = maxf(max_x, world.x)
			min_y = minf(min_y, world.y)
		if max_x <= min_x:
			return {}
		return {"name": name_text, "left": min_x, "right": max_x, "top": min_y}
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
	elif shape_node != null and shape_node.shape is CapsuleShape2D:
		var capsule := shape_node.shape as CapsuleShape2D
		var scale_abs := node.scale.abs()
		var length := (capsule.height + capsule.radius * 2.0) * scale_abs.y
		var width := capsule.radius * 2.0 * scale_abs.x
		# Carrion capsules are rotated 90°, so length becomes horizontal.
		if absf(shape_node.rotation) > 0.5:
			size = Vector2(length, width)
		else:
			size = Vector2(width, length)
	var center := node.global_position
	if shape_node != null:
		center = shape_node.global_position
	return Rect2(center - size * 0.5, size)
