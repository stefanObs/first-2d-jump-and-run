extends AnimatableBody2D

## Lasso target for Stampede Bull ring — only counts while parent is stunned.

signal ring_lassoed


func lasso_hit() -> void:
	var arena := get_parent()
	while arena != null and not (arena is BossArena):
		arena = arena.get_parent()
	if arena != null and arena.has_method("_on_ring_lasso"):
		arena.call("_on_ring_lasso")
	ring_lassoed.emit()
