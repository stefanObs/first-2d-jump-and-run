class_name Opponent
extends AnimatableBody2D

## Slow predictable foe. Touching it hurts unless the player has a shield.

signal hurt_player(player: Player)

@export var point_a: Vector2 = Vector2(-80, 0)
@export var point_b: Vector2 = Vector2(80, 0)
@export var move_speed: float = 40.0
@export var vertical_patrol: bool = false

var _origin: Vector2
var _going_to_b: bool = true
var _area: Area2D
var _label: Label
var _hint_phase: float = 0.0


func _ready() -> void:
	_origin = global_position
	_area = get_node_or_null("HurtArea") as Area2D
	_label = get_node_or_null("Label") as Label
	if _area != null:
		_area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_hint_phase += delta * 4.0
	_update_nearby_hint()


func _physics_process(delta: float) -> void:
	var target := _origin + (point_b if _going_to_b else point_a)
	global_position = global_position.move_toward(target, move_speed * delta)
	if global_position.distance_to(target) < 2.0:
		_going_to_b = not _going_to_b


func _update_nearby_hint() -> void:
	if _label == null:
		return
	var player := _find_nearby_player(160.0)
	if player != null:
		_label.text = "JUMP!"
		_label.modulate = Color(1.0, 0.85 + sin(_hint_phase) * 0.15, 0.2, 1.0)
		_label.add_theme_font_size_override(&"font_size", 16)
	else:
		_label.text = "BANDIT"
		_label.modulate = Color(1, 1, 1, 1)
		_label.add_theme_font_size_override(&"font_size", 13)


func _find_nearby_player(radius: float) -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Player and global_position.distance_to((node as Node2D).global_position) <= radius:
			return node as Player
	var root := tree.current_scene
	if root == null:
		return null
	var player_node := root.find_child("Player", true, false)
	if player_node is Player and global_position.distance_to((player_node as Node2D).global_position) <= radius:
		return player_node as Player
	return null


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		if player.is_invulnerable():
			return
		hurt_player.emit(player)
