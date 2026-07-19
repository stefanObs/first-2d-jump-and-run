class_name Rattlesnake
extends Area2D

## Desert hazard that watches, rises high like a coiled warning, rattles, and bites.

signal hurt_player(player: Player)

const IDLE_TEXTURE := preload("res://assets/world/rattlesnake_idle.png")
const BITE_TEXTURE := preload("res://assets/world/rattlesnake_bite.png")

var _sprite: Sprite2D
var _label: Label
var _shadow: Polygon2D
var _biting: bool = false
var _phase: float = 0.0
var _raised: bool = false

const WATCH_DISTANCE := 380.0
const RAISE_DISTANCE := 210.0
const REST_POSITION := Vector2(0, -22)
const RAISED_POSITION := Vector2(0, -78)
const REST_SCALE := Vector2(0.52, 0.42)
const RAISED_SCALE := Vector2(0.62, 0.78)


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_label = get_node_or_null("Label") as Label
	_ensure_shadow()
	_ensure_collision()
	if _sprite != null:
		_sprite.position = REST_POSITION
		_sprite.scale = REST_SCALE
		_sprite.modulate = Color(1.08, 1.02, 0.92, 1.0)
	if _label != null:
		_label.position = Vector2(-48, -118)
		_label.add_theme_font_size_override(&"font_size", 18)
		_label.add_theme_color_override(&"font_color", Color(0.75, 0.18, 0.05, 1.0))
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
		var rattle_speed := 22.0 if _raised else 9.0
		var rattle_amount := 0.055 if _raised else 0.018
		_sprite.rotation = sin(_phase * rattle_speed) * rattle_amount
		# Soft pulse so coiled snakes read against desert sand.
		var pulse := 1.0 + (0.04 if _raised else 0.02) * sin(_phase * 6.0)
		_sprite.modulate = Color(1.08 * pulse, 1.02, 0.9, 1.0)
	if _shadow != null:
		_shadow.scale = Vector2(1.15 if _raised else 0.9, 0.7)
		_shadow.modulate.a = 0.45 if _raised else 0.28
	if _label != null and not _biting:
		_label.visible = _raised
		_label.text = "RATTLE!"
		_label.position.y = -118.0 + sin(_phase * 10.0) * 3.0


func _ensure_shadow() -> void:
	_shadow = get_node_or_null("GroundShadow") as Polygon2D
	if _shadow != null:
		return
	_shadow = Polygon2D.new()
	_shadow.name = "GroundShadow"
	_shadow.z_index = -2
	_shadow.color = Color(0.2, 0.1, 0.05, 0.35)
	_shadow.polygon = PackedVector2Array([
		Vector2(-42, -4), Vector2(42, -4), Vector2(34, 10), Vector2(-34, 10)
	])
	add_child(_shadow)
	move_child(_shadow, 0)


func _ensure_collision() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(92, 48)
	shape_node.shape = rect
	shape_node.position = Vector2(0, -22)


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
	tween.tween_property(_sprite, "position", target_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "scale", target_scale, 0.22)
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null:
		var target_y := -52.0 if value else -22.0
		var target_h := 96.0 if value else 48.0
		tween.tween_property(shape_node, "position:y", target_y, 0.22)
		if shape_node.shape is RectangleShape2D:
			var rect := (shape_node.shape as RectangleShape2D).duplicate() as RectangleShape2D
			rect.size = Vector2(92, target_h)
			shape_node.shape = rect


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
		tween.tween_property(_sprite, "scale", Vector2(0.72, 0.88), 0.1)
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
