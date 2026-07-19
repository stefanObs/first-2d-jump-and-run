extends AnimatableBody2D

## Kingpin body — lasso only counts while telegraphing after guards fall.


func lasso_hit() -> void:
	var arena := get_tree().current_scene
	if arena != null and arena.has_method("lasso_kingpin"):
		arena.call("lasso_kingpin")
