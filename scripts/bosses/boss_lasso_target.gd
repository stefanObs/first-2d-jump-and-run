class_name BossLassoTarget
extends Area2D

## Monitorable lasso hitbox used by boss arenas (ring, doors, kingpin).

signal lassoed

@export var active: bool = true
@export var glow_when_active: bool = true

var _glow: Polygon2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = active
	add_to_group("lasso_target")
	_ensure_glow()
	_refresh_visual()


func _ensure_glow() -> void:
	if _glow != null or not glow_when_active:
		return
	_glow = Polygon2D.new()
	_glow.name = "Glow"
	_glow.z_index = -1
	_glow.color = Color(0.95, 0.75, 0.2, 0.45)
	_glow.polygon = PackedVector2Array([
		Vector2(-28, -36),
		Vector2(28, -36),
		Vector2(28, 36),
		Vector2(-28, 36),
	])
	add_child(_glow)


func set_lasso_active(value: bool) -> void:
	active = value
	set_deferred("monitorable", value)
	_refresh_visual()


func _refresh_visual() -> void:
	if _glow != null:
		_glow.visible = active and glow_when_active
	modulate = Color(1.15, 1.05, 0.55, 1.0) if active else Color(1, 1, 1, 0.55)


func lasso_hit() -> void:
	if not active:
		return
	lassoed.emit()
