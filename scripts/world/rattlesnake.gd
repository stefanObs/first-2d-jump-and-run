class_name Rattlesnake
extends Area2D

## Small desert hazard that watches, raises, rattles, and then bites.

signal hurt_player(player: Player)

const IDLE_TEXTURE := preload("res://assets/world/rattlesnake_idle.png")
const BITE_TEXTURE := preload("res://assets/world/rattlesnake_bite.png")

var _sprite: Sprite2D
var _label: Label
var _biting: bool = false
var _phase: float = 0.0
var _raised: bool = false

const WATCH_DISTANCE := 360.0
const RAISE_DISTANCE := 190.0
const REST_POSITION := Vector2(0, -22)
const RAISED_POSITION := Vector2(0, -32)
const REST_SCALE := Vector2(0.54, 0.42)
const RAISED_SCALE := Vector2(0.57, 0.54)


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_label = get_node_or_null("Label") as Label
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_phase += delta
	var player := _find_nearby_player(WATCH_DISTANCE)
	if player != null:
		_face_player(player)
	var should_raise := player != null and global_position.distance_to(player.global_position) <= RAISE_DISTANCE
	if should_raise != _raised and not _biting:
		_set_raised(should_raise)
	if not _biting and _sprite != null:
		var rattle_speed := 19.0 if _raised else 8.0
		var rattle_amount := 0.035 if _raised else 0.012
		_sprite.rotation = sin(_phase * rattle_speed) * rattle_amount
	if _label != null and not _biting:
		_label.visible = _raised
		_label.text = "RATTLE!"


func _find_nearby_player(radius: float) -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Player and global_position.distance_to((node as Player).global_position) <= radius:
			return node as Player
	var root := tree.current_scene
	if root != null:
		var candidate := root.find_child("Player", true, false)
		if candidate is Player and global_position.distance_to((candidate as Player).global_position) <= radius:
			return candidate as Player
	return null


func _face_player(player: Player) -> void:
	if _sprite == null:
		return
	# The painted snake faces right.
	_sprite.flip_h = player.global_position.x < global_position.x


func _set_raised(value: bool) -> void:
	_raised = value
	if _sprite == null:
		return
	var target_scale := RAISED_SCALE if value else REST_SCALE
	var target_position := RAISED_POSITION if value else REST_POSITION
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_sprite, "position", target_position, 0.16)
	tween.tween_property(_sprite, "scale", target_scale, 0.16)


func _on_body_entered(body: Node2D) -> void:
	if _biting or not (body is Player):
		return
	_bite(body as Player)


func _bite(player: Player) -> void:
	_biting = true
	_face_player(player)
	if _sprite != null:
		_sprite.texture = BITE_TEXTURE
		var tween := create_tween()
		tween.tween_property(_sprite, "scale", Vector2(0.64, 0.58), 0.1)
		tween.tween_property(_sprite, "scale", RAISED_SCALE, 0.12)
	if _label != null:
		_label.text = "HISS!"
		_label.visible = true
	await get_tree().create_timer(0.24).timeout
	if is_instance_valid(player) and player in get_overlapping_bodies() and not player.is_invulnerable():
		hurt_player.emit(player)
	await get_tree().create_timer(0.45).timeout
	if _sprite != null:
		_sprite.texture = IDLE_TEXTURE
	if _label != null:
		_label.visible = false
	_biting = false
	var nearby := _find_nearby_player(RAISE_DISTANCE)
	_set_raised(nearby != null)
