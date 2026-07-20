class_name Goal
extends Area2D

## Saloon exit that starts the celebration transition when reached.

signal reached(goal: Goal)

var _triggered: bool = false
var _sprite: CanvasItem
var _label: Label
var _arrow: Label
var _phase: float = 0.0
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as CanvasItem
	if _sprite == null:
		_sprite = get_node_or_null("Visual") as CanvasItem
	_label = get_node_or_null("Label") as Label
	if _sprite != null:
		_base_scale = _sprite.scale
	if _label != null:
		_label.text = "SALOON!"
		_label.add_theme_font_size_override(&"font_size", 20)
	_ensure_arrow()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _triggered:
		if _arrow != null:
			_arrow.visible = false
		return

	# Crossing the saloon's place on the trail counts, even when flying high.
	if _player_reached_saloon():
		_trigger()
		return

	_phase += delta * 3.0
	var pulse := 1.0 + sin(_phase) * 0.06
	if _sprite != null:
		_sprite.scale = _base_scale * pulse
		_sprite.modulate = Color(1.0, 0.95 + sin(_phase) * 0.05, 0.7, 1.0)
	if _label != null:
		_label.modulate.a = 0.7 + absf(sin(_phase)) * 0.3
	_update_approach_arrow()


func reset() -> void:
	_triggered = false
	if _sprite != null:
		_sprite.modulate = Color(1, 1, 1, 1)
		_sprite.scale = _base_scale


func is_triggered() -> bool:
	return _triggered


func _ensure_arrow() -> void:
	_arrow = get_node_or_null("ApproachArrow") as Label
	if _arrow != null:
		return
	_arrow = Label.new()
	_arrow.name = "ApproachArrow"
	_arrow.position = Vector2(-90, -260)
	_arrow.size = Vector2(180, 36)
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow.add_theme_color_override(&"font_color", Color(0.95, 0.35, 0.1, 1.0))
	_arrow.add_theme_font_size_override(&"font_size", 22)
	_arrow.text = "THIS WAY!"
	_arrow.visible = false
	add_child(_arrow)


func _update_approach_arrow() -> void:
	if _arrow == null:
		return
	var player := _find_player()
	if player == null:
		_arrow.visible = false
		return
	var dist := global_position.distance_to(player.global_position)
	var near := dist < 900.0 and dist > 80.0 and player.global_position.x < global_position.x
	_arrow.visible = near
	if near:
		_arrow.position.y = -260.0 + sin(_phase * 1.4) * 6.0
		_arrow.modulate.a = 0.65 + absf(sin(_phase * 2.0)) * 0.35


func _find_player() -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Player = null
	var best_dist := INF
	for node in tree.get_nodes_in_group("player"):
		if node is Player:
			var candidate := node as Player
			var dist := global_position.distance_squared_to(candidate.global_position)
			if dist < best_dist:
				best_dist = dist
				best = candidate
	if best != null:
		return best
	var root := tree.current_scene
	if root == null:
		return null
	var found := root.find_child("Player", true, false)
	return found as Player if found is Player else null


func _player_reached_saloon() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	# Same idea as camps: the trail place matters, not touching the doorway.
	# Any cowboy who has crossed the saloon's X counts (including flyovers).
	for node in tree.get_nodes_in_group("player"):
		if node is Player:
			var player := node as Player
			if player.global_position.x >= global_position.x - 64.0:
				return true
	return false


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_trigger()


func _trigger() -> void:
	if _triggered:
		return
	_triggered = true
	if _sprite != null:
		_sprite.modulate = Color(1.0, 0.95, 0.55, 1.0)
		_sprite.scale = _base_scale * 1.15
	if _label != null:
		_label.text = "YEEHAW!"
	if _arrow != null:
		_arrow.visible = false
	reached.emit(self)
