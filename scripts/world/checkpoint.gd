class_name Checkpoint
extends Area2D

## Safe respawn marker activated when the player touches it.

signal activated(checkpoint: Checkpoint)

@export var is_active: bool = false

const TEX_INACTIVE := preload("res://assets/world/checkpoint_inactive.png")
const TEX_ACTIVE := preload("res://assets/world/checkpoint_active.png")

var _sprite: Sprite2D
var _label: Label
var _pulse: float = 0.0
var _pop_time: float = 0.0
var _sprite_base_y: float = -40.0


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_label = get_node_or_null("Label") as Label
	if _sprite != null:
		_sprite_base_y = _sprite.position.y
	body_entered.connect(_on_body_entered)
	_update_visual()


func _process(delta: float) -> void:
	_pulse += delta * 4.0
	if is_active:
		if _sprite != null:
			_sprite.position.y = _sprite_base_y + sin(_pulse) * 3.0
		if _pop_time > 0.0:
			_pop_time = maxf(_pop_time - delta, 0.0)
			var t := 1.0 - (_pop_time / 0.35)
			var s := lerpf(1.25, 1.0, t)
			scale = Vector2(s, s)
		return

	var nearby := _player_nearby(220.0)
	if _label != null and nearby:
		_label.text = "CAMP!"
		_label.modulate = Color(1.0, 0.9 + sin(_pulse) * 0.1, 0.3, 1.0)
	elif _label != null:
		_label.text = "CAMP"
		_label.modulate = Color(1, 1, 1, 1)
	if _sprite != null and nearby:
		_sprite.modulate = Color(1.0, 0.85 + absf(sin(_pulse)) * 0.15, 0.7, 1.0)
	elif _sprite != null:
		_sprite.modulate = Color(1, 1, 1, 1)


func _player_nearby(radius: float) -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	for node in tree.get_nodes_in_group("player"):
		if node is Node2D and global_position.distance_to((node as Node2D).global_position) <= radius:
			return true
	return false


func activate() -> void:
	if is_active:
		return
	is_active = true
	_pop_time = 0.35
	_update_visual()
	activated.emit(self)


func deactivate() -> void:
	is_active = false
	scale = Vector2.ONE
	if _sprite != null:
		_sprite.position.y = _sprite_base_y
	_update_visual()


func get_respawn_position() -> Vector2:
	return global_position


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		activate()


func _update_visual() -> void:
	if _sprite != null:
		_sprite.texture = TEX_ACTIVE if is_active else TEX_INACTIVE
	if _label != null:
		_label.text = "SAVED!" if is_active else "CAMP"
		_label.add_theme_color_override(
			&"font_color",
			Color(0.2, 0.45, 0.12, 1.0) if is_active else Color(0.35, 0.18, 0.05, 1.0)
		)
