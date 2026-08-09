class_name FloorProbe
extends RefCounted

## Shared downward ray probes for hazards and ground enemies.


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
	var world := body.get_world_2d()
	if world == null:
		return true
	var ahead := body.global_position + Vector2(direction * 24.0, -4.0)
	var query := PhysicsRayQueryParameters2D.create(
		ahead,
		ahead + Vector2(0.0, 72.0),
		1
	)
	query.exclude = [body.get_rid()]
	return not world.direct_space_state.intersect_ray(query).is_empty()


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
