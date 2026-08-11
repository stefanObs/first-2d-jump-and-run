class_name PlayerLookup
extends RefCounted

## Shared "find the cowboy" helpers used by enemies, camps, and hazards.


static func find_in_tree(from: Node, radius: float = -1.0) -> Player:
	var tree := from.get_tree() if from != null else null
	if tree == null:
		return null
	var origin := from as Node2D
	var best: Player = null
	var best_dist := INF
	for node in tree.get_nodes_in_group("player"):
		if not (node is Player):
			continue
		var candidate := node as Player
		if not _is_live_player(from, candidate):
			continue
		if origin != null and radius >= 0.0:
			var dist := origin.global_position.distance_to(candidate.global_position)
			if dist > radius:
				continue
			if dist < best_dist:
				best_dist = dist
				best = candidate
		else:
			return candidate
	if best != null:
		return best
	var root := tree.current_scene
	if root == null:
		return null
	var found := root.find_child("Player", true, false)
	if found is Player:
		var fallback := found as Player
		if not _is_live_player(from, fallback):
			return null
		if origin != null and radius >= 0.0:
			if origin.global_position.distance_to(fallback.global_position) > radius:
				return null
		return fallback
	return null


static func any_in_radius(from: Node2D, radius: float) -> bool:
	return find_in_tree(from, radius) != null


static func any_past_x(from: Node, min_x: float) -> bool:
	var tree := from.get_tree() if from != null else null
	if tree == null:
		return false
	for node in tree.get_nodes_in_group("player"):
		if not (node is Player):
			continue
		var candidate := node as Player
		if _is_live_player(from, candidate) and candidate.global_position.x >= min_x:
			return true
	return false


static func _is_live_player(from: Node, player: Player) -> bool:
	if player == null or not is_instance_valid(player) or not player.is_inside_tree():
		return false
	if from != null and from.get_viewport() != player.get_viewport():
		return false
	var node: Node = player
	while node != null:
		if node is LevelController and (node as LevelController).skip_auto_setup:
			return false
		node = node.get_parent()
	return true
