class_name StarReachability
extends RefCounted

## Heuristic checks that stars sit within a reachable height of a surface.


static func max_jump_height(jump_velocity: float = -480.0, gravity: float = 1400.0) -> float:
	return (jump_velocity * jump_velocity) / (2.0 * gravity)


static func max_boots_jump_height(
	jump_velocity: float = -480.0,
	gravity: float = 1400.0,
	multiplier: float = 1.45
) -> float:
	return max_jump_height(jump_velocity * multiplier, gravity)


static func is_star_reachable_from_surface(
	surface_top_y: float,
	star_y: float,
	jump_height: float,
	margin: float = 8.0
) -> bool:
	var apex_y := surface_top_y - jump_height
	return star_y + margin >= apex_y and star_y <= surface_top_y + 20.0
