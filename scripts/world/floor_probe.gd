class_name FloorProbe
extends RefCounted

## Shared downward ray probes for hazards and ground enemies.

## How far ahead walkers look before taking a step.
const FLOOR_AHEAD := 24.0
## Floor this far below the boots still counts as the same bank/plank.
## Deeper dirt or canyon floor must not count, or walkers step off ledges.
const SAME_BANK_DROP := 36.0


static func hit_y(
	host: Node2D,
	from: Vector2,
	to: Vector2,
	fallback: float,
	mask: int = 1,
	exclude: Array = []
) -> float:
	var world := host.get_world_2d()
	if world == null:
		return fallback
	var skip: Array = exclude.duplicate()
	if host != null:
		skip.append(host.get_rid())
	var space := world.direct_space_state
	## Skip cave flight-ceiling solids so drops reach trail/planks below.
	for _attempt in range(8):
		var query := PhysicsRayQueryParameters2D.create(from, to, mask)
		query.collide_with_areas = false
		query.exclude = skip
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return fallback
		var collider: Object = hit.get("collider")
		if collider is Node and _is_flight_ceiling(collider as Node):
			skip.append((collider as CollisionObject2D).get_rid())
			continue
		return float(hit["position"].y)
	return fallback


static func _is_flight_ceiling(node: Node) -> bool:
	var cursor: Node = node
	while cursor != null:
		if String(cursor.name).begins_with("FlightCeiling"):
			return true
		cursor = cursor.get_parent()
	return false


static func has_floor_ahead(body: CollisionObject2D, direction: float) -> bool:
	## True when the same bank or plank continues under the next step.
	## Starts well above the boots so one-way ledges are hit from outside,
	## and ignores crusts deeper than SAME_BANK_DROP so walkers do not
	## treat dirt under a plank as a reason to walk off the lip.
	var dir := signf(direction)
	if is_zero_approx(dir):
		return true
	if body.get_world_2d() == null:
		return true
	var ahead := body.global_position + Vector2(dir * FLOOR_AHEAD, 0.0)
	var floor_y := nearest_floor_y(body, ahead, 48.0, 80.0, SAME_BANK_DROP)
	return not is_nan(floor_y)


static func nearest_floor_y(
	host: Node2D,
	world_pos: Vector2,
	up: float,
	down: float,
	max_drop: float = INF,
	mask: int = 1
) -> float:
	## First solid surface at/below the actor, skipping flight ceilings. When
	## `max_drop` is finite, ignore crusts that would teleport more than that
	## distance downward (keeps walkers on their current bank/plank).
	var world := host.get_world_2d()
	if world == null:
		return NAN
	var skip: Array = [host.get_rid()]
	var space := world.direct_space_state
	var from := world_pos + Vector2(0.0, -up)
	var to := world_pos + Vector2(0.0, down)
	for _attempt in range(8):
		var query := PhysicsRayQueryParameters2D.create(from, to, mask)
		query.collide_with_areas = false
		query.exclude = skip
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return NAN
		var collider: Object = hit.get("collider")
		if collider is Node and _is_flight_ceiling(collider as Node):
			skip.append((collider as CollisionObject2D).get_rid())
			continue
		var hit_y := float((hit["position"] as Vector2).y)
		if hit_y > world_pos.y + max_drop:
			skip.append((collider as CollisionObject2D).get_rid())
			continue
		return hit_y
	return NAN


static func crust_y_above(
	host: Node2D,
	world_pos: Vector2,
	up_reach: float = 200.0,
	mask: int = 1
) -> float:
	## Cast from above through every solid and return the lowest crust that is still
	## at/above the actor (the dirt roof when feet are buried). Ignores higher
	## movers so trail bandits are not yanked onto planks overhead.
	var world := host.get_world_2d()
	if world == null:
		return NAN
	var skip: Array = [host.get_rid()]
	var space := world.direct_space_state
	var from := world_pos + Vector2(0.0, -up_reach)
	var to := world_pos + Vector2(0.0, 4.0)
	var best := NAN
	for _attempt in range(16):
		var query := PhysicsRayQueryParameters2D.create(from, to, mask)
		query.collide_with_areas = false
		query.exclude = skip
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			break
		var collider: Object = hit.get("collider")
		if collider is CollisionObject2D:
			skip.append((collider as CollisionObject2D).get_rid())
		if collider is Node and _is_flight_ceiling(collider as Node):
			continue
		var hit_y := float((hit["position"] as Vector2).y)
		if hit_y <= world_pos.y + 1.0:
			if is_nan(best) or hit_y > best:
				best = hit_y
	return best
