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
	var query := PhysicsRayQueryParameters2D.create(from, to, mask)
	query.collide_with_areas = false
	if not exclude.is_empty():
		query.exclude = exclude
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return fallback
	return float(hit["position"].y)


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
