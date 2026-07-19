extends BossLassoTarget

## Kingpin torso — lasso only counts while telegraphing after guards fall.


func _ready() -> void:
	active = false
	super._ready()
	lassoed.connect(_on_lassoed)


func _on_lassoed() -> void:
	var arena := get_tree().current_scene
	if arena != null and arena.has_method("lasso_kingpin"):
		arena.call("lasso_kingpin")
