extends BossLassoTarget

## One coach door handle — must be lassoed in order.


func _ready() -> void:
	super._ready()
	lassoed.connect(_on_lassoed)


func _on_lassoed() -> void:
	var index := 0
	if String(name).begins_with("Door"):
		index = int(String(name).trim_prefix("Door"))
	elif has_meta("door_index"):
		index = int(get_meta("door_index"))
	var arena := get_tree().current_scene
	if arena != null and arena.has_method("on_door_lassoed"):
		arena.call("on_door_lassoed", index)
