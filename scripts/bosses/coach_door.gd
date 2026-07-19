extends AnimatableBody2D

## One coach door handle — must be lassoed in order.


func lasso_hit() -> void:
	var index := 0
	if String(name).begins_with("Door"):
		index = int(String(name).trim_prefix("Door"))
	var arena := get_tree().current_scene
	if arena != null and arena.has_method("on_door_lassoed"):
		arena.call("on_door_lassoed", index)
