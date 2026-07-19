extends BossLassoTarget

## Invisible lasso hitbox over one coach door handle.


var _opened: bool = false
var _handle: Node2D


func _ready() -> void:
	super._ready()
	lassoed.connect(_on_lassoed)
	_handle = get_node_or_null("Handle")


func is_open() -> bool:
	return _opened


func set_lasso_active(value: bool) -> void:
	if _opened:
		active = false
		set_deferred("monitorable", false)
		if _glow != null:
			_glow.visible = false
		return
	super.set_lasso_active(value)


func play_open() -> void:
	if _opened:
		return
	_opened = true
	active = false
	set_deferred("monitorable", false)
	modulate = Color.WHITE
	if _glow != null:
		_glow.visible = false
	if _handle != null:
		_handle.visible = false


func _on_lassoed() -> void:
	var index := 0
	if String(name).begins_with("Door"):
		index = int(String(name).trim_prefix("Door"))
	elif has_meta("door_index"):
		index = int(get_meta("door_index"))
	var arena := get_tree().current_scene
	if arena != null and arena.has_method("on_door_lassoed"):
		arena.call("on_door_lassoed", index)
