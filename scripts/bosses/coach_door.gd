extends BossLassoTarget

## One coach door handle — must be lassoed in order. Opens when tied.

var _panel: Node2D
var _interior: Polygon2D
var _handle: Node2D
var _opened: bool = false


func _ready() -> void:
	super._ready()
	lassoed.connect(_on_lassoed)
	_handle = get_node_or_null("Handle")
	_build_door_visual()


func is_open() -> bool:
	return _opened


func set_lasso_active(value: bool) -> void:
	if _opened:
		active = false
		set_deferred("monitorable", false)
		return
	super.set_lasso_active(value)


func _build_door_visual() -> void:
	_interior = Polygon2D.new()
	_interior.name = "Interior"
	_interior.z_index = -1
	_interior.color = Color(0.08, 0.06, 0.05, 1)
	_interior.polygon = PackedVector2Array([
		Vector2(-22, -42), Vector2(22, -42), Vector2(22, 42), Vector2(-22, 42)
	])
	_interior.visible = false
	add_child(_interior)

	_panel = Node2D.new()
	_panel.name = "DoorPanel"
	_panel.position = Vector2(-22, 0)
	_panel.z_index = 0
	add_child(_panel)

	var wood := Polygon2D.new()
	wood.name = "Wood"
	wood.color = Color(0.45, 0.28, 0.14, 1)
	wood.polygon = PackedVector2Array([
		Vector2(0, -42), Vector2(44, -42), Vector2(44, 42), Vector2(0, 42)
	])
	_panel.add_child(wood)

	var trim := Line2D.new()
	trim.width = 2.0
	trim.default_color = Color(0.25, 0.14, 0.06, 1)
	trim.points = PackedVector2Array([
		Vector2(0, -42), Vector2(44, -42), Vector2(44, 42), Vector2(0, 42), Vector2(0, -42)
	])
	_panel.add_child(trim)

	var window := Polygon2D.new()
	window.color = Color(0.55, 0.75, 0.9, 0.85)
	window.polygon = PackedVector2Array([
		Vector2(10, -34), Vector2(34, -34), Vector2(34, -10), Vector2(10, -10)
	])
	_panel.add_child(window)

	var hinge := Polygon2D.new()
	hinge.color = Color(0.7, 0.55, 0.2, 1)
	hinge.polygon = PackedVector2Array([
		Vector2(-3, -12), Vector2(3, -12), Vector2(3, -6), Vector2(-3, -6)
	])
	_panel.add_child(hinge)
	var hinge2 := hinge.duplicate() as Polygon2D
	hinge2.position = Vector2(0, 18)
	_panel.add_child(hinge2)


func play_open() -> void:
	if _opened:
		return
	_opened = true
	active = false
	set_deferred("monitorable", false)
	modulate = Color.WHITE
	if _glow != null:
		_glow.visible = false
	if _interior != null:
		_interior.visible = true
	if _handle != null:
		_handle.visible = false
	if _panel == null:
		return
	var wood := _panel.get_node_or_null("Wood") as Polygon2D
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "rotation_degrees", -78.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if wood != null:
		tween.tween_property(wood, "color", Color(0.55, 0.38, 0.18, 1), 0.28)
	tween.chain().tween_property(_panel, "rotation_degrees", -68.0, 0.12).set_trans(Tween.TRANS_SINE)


func _on_lassoed() -> void:
	var index := 0
	if String(name).begins_with("Door"):
		index = int(String(name).trim_prefix("Door"))
	elif has_meta("door_index"):
		index = int(get_meta("door_index"))
	var arena := get_tree().current_scene
	if arena != null and arena.has_method("on_door_lassoed"):
		arena.call("on_door_lassoed", index)
