class_name Checkpoint
extends Area2D

## Safe respawn marker activated when the player touches it.

signal activated(checkpoint: Checkpoint)

@export var is_active: bool = false

const TEX_INACTIVE := preload("res://assets/world/checkpoint_inactive.png")
const TEX_ACTIVE := preload("res://assets/world/checkpoint_active.png")
const TEX_CAVE_INACTIVE := preload("res://assets/world/checkpoint_cave_inactive.png")
const TEX_CAVE_ACTIVE := preload("res://assets/world/checkpoint_cave_active.png")
const REACH_X := 64.0
const NEARBY_X := 220.0

var _sprite: Sprite2D
var _label: Label
var _pulse: float = 0.0
var _pop_time: float = 0.0
var _sprite_base_y: float = -40.0
var _level_style: String = LevelStyle.DESERT
var _cached_player: Player


func apply_level_style(style: String) -> void:
	_level_style = LevelStyle.normalize(style)
	_update_visual()


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

	var player := _player()
	if player == null:
		return
	var dx := absf(player.global_position.x - global_position.x)
	## Activate by reaching the camp's place on the trail (not only flag body).
	if dx <= REACH_X:
		activate()
		return
	## Far camps skip label/modulate work — one cached player, no second tree walk.
	if dx > NEARBY_X:
		if _label != null:
			var idle_text := "LANTERN" if LevelStyle.is_cave(_level_style) else "CAMP"
			if _label.text != idle_text:
				_label.text = idle_text
			_label.modulate = Color(1, 1, 1, 1)
		if _sprite != null:
			_sprite.modulate = Color(1, 1, 1, 1)
		return
	if _label != null:
		_label.text = "CAMP!"
		_label.modulate = Color(1.0, 0.9 + sin(_pulse) * 0.1, 0.3, 1.0)
	if _sprite != null:
		_sprite.modulate = Color(1.0, 0.85 + absf(sin(_pulse)) * 0.15, 0.7, 1.0)


func _player() -> Player:
	if _cached_player != null and is_instance_valid(_cached_player):
		return _cached_player
	_cached_player = PlayerLookup.find_in_tree(self) as Player
	return _cached_player


func activate() -> void:
	if is_active:
		return
	is_active = true
	_pop_time = 0.35
	AudioManager.play_sfx(&"checkpoint")
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
		_cached_player = body as Player
		activate()


func _update_visual() -> void:
	if _sprite != null:
		if LevelStyle.is_cave(_level_style):
			_sprite.texture = TEX_CAVE_ACTIVE if is_active else TEX_CAVE_INACTIVE
		else:
			_sprite.texture = TEX_ACTIVE if is_active else TEX_INACTIVE
	if _label != null:
		_label.text = "SAVED!" if is_active else ("LANTERN" if LevelStyle.is_cave(_level_style) else "CAMP")
		_label.add_theme_color_override(
			&"font_color",
			Color(0.2, 0.45, 0.12, 1.0) if is_active else Color(0.35, 0.18, 0.05, 1.0)
		)
