class_name Rattlesnake
extends Area2D

## Floor-bound desert hazard. Body stays put; only the head rises to warn, then bites.

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
const BODY_SCALE := Vector2(0.48, 0.38)
const REST_OFFSET := Vector2(0, -18)
const RAISED_OFFSET := Vector2(0, -34)


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_label = get_node_or_null("Label") as Label
	_ensure_shadow()
	_ensure_collision()
	if _sprite != null:
		_sprite.position = REST_OFFSET
		_sprite.scale = BODY_SCALE
		_sprite.modulate = Color(1.06, 1.02, 0.94, 1.0)
	if _label != null:
		_label.position = Vector2(-48, -78)
		_label.add_theme_font_size_override(&"font_size", 16)
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
		# Head rattle only — body scale stays fixed on the floor.
		var rattle_speed := 20.0 if _raised else 8.0
		var rattle_amount := 0.04 if _raised else 0.012
		_sprite.rotation = sin(_phase * rattle_speed) * rattle_amount
		_sprite.scale = BODY_SCALE
	if _shadow != null:
		_shadow.modulate.a = 0.4 if _raised else 0.28
	if _label != null and not _biting:
		_label.visible = _raised
		_label.text = "RATTLE!"
		_label.position.y = -78.0 + sin(_phase * 10.0) * 2.0


func _ensure_shadow() -> void:
	_shadow = get_node_or_null("GroundShadow") as Polygon2D
	if _shadow != null:
		return
	_shadow = Polygon2D.new()
	_shadow.name = "GroundShadow"
	_shadow.z_index = -2
	_shadow.color = Color(0.2, 0.1, 0.05, 0.35)
	_shadow.polygon = PackedVector2Array([
		Vector2(-38, -2), Vector2(38, -2), Vector2(30, 8), Vector2(-30, 8)
	])
	add_child(_shadow)
	move_child(_shadow, 0)


func _ensure_collision() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(88, 28)
	shape_node.shape = rect
	shape_node.position = Vector2(0, -12)


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
	_sprite.flip_h = player.global_position.x < global_position.x


func _set_raised(value: bool) -> void:
	_raised = value
	if _sprite == null:
		return
	var target := RAISED_OFFSET if value else REST_OFFSET
	var tween := create_tween()
	tween.tween_property(_sprite, "position", target, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Keep collision on the floor coil; head rise is visual warning only.
	_sprite.scale = BODY_SCALE


func _on_body_entered(body: Node2D) -> void:
	if _biting or not (body is Player):
		return
	_bite(body as Player)


func _bite(player: Player) -> void:
	_biting = true
	_face_player(player)
	if _sprite != null:
		_sprite.texture = BITE_TEXTURE
		_sprite.scale = BODY_SCALE
		var tween := create_tween()
		tween.tween_property(_sprite, "position", RAISED_OFFSET + Vector2(0, -8), 0.08)
		tween.tween_property(_sprite, "position", RAISED_OFFSET, 0.1)
	if _label != null:
		_label.text = "HISS!"
		_label.visible = true
	await get_tree().create_timer(0.24).timeout
	if is_instance_valid(player) and player in get_overlapping_bodies() and not player.is_invulnerable():
		hurt_player.emit(player)
	await get_tree().create_timer(0.45).timeout
	if _sprite != null:
		_sprite.texture = IDLE_TEXTURE
		_sprite.scale = BODY_SCALE
	if _label != null:
		_label.visible = false
	_biting = false
	var nearby := _find_nearby_player(RAISE_DISTANCE)
	_set_raised(nearby != null)
