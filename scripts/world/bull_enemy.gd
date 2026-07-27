class_name BullEnemy
extends AnimatableBody2D

## Trail bull: charges the cowboy, ties on lasso or head stomp like bandits.

signal hurt_player(player: Player)
signal captured(bull: BullEnemy)

const BULL_TEX := preload("res://assets/world/boss_stampede_bull.png")
const BULL_TIED_TEX := preload("res://assets/world/boss_stampede_bull_tied_legs.png")

const STAND_TARGET_HEIGHT := 92.0
const TIED_TARGET_HEIGHT := 78.0
const STOMP_BOUNCE := -420.0
const STOMP_MIN_FALL_SPEED := 80.0
const CHARGE_SPEED := 150.0
const CHARGE_RANGE := 560.0
const CHARGE_Y_BAND := 180.0

var _origin: Vector2
var _facing: float = 1.0
var _area: Area2D
var _label: Label
var _sprite: Sprite2D
var _hint_phase: float = 0.0
var _tied: bool = false
var _charge_bob: float = 0.0
var _pose_tween: Tween
var _stand_scale: float = 1.0


func _ready() -> void:
	_origin = global_position
	_area = get_node_or_null("HurtArea") as Area2D
	_label = get_node_or_null("Label") as Label
	if _label != null:
		_label.visible = false
	_setup_sprite()
	if _area != null:
		_area.body_entered.connect(_on_body_entered)


func _setup_sprite() -> void:
	var existing := get_node_or_null("BullSprite") as Sprite2D
	if existing != null:
		existing.queue_free()
	var old := get_node_or_null("Sprite2D") as Node
	_sprite = Sprite2D.new()
	_sprite.name = "BullSprite"
	_sprite.texture = BULL_TEX
	_sprite.centered = true
	_stand_scale = _scale_for(BULL_TEX, STAND_TARGET_HEIGHT)
	_sprite.scale = Vector2(_stand_scale, _stand_scale)
	_sprite.offset = Vector2(0.0, -float(BULL_TEX.get_height()) * 0.5)
	_apply_facing(_facing)
	add_child(_sprite)
	if old != null:
		old.visible = false


func _scale_for(texture: Texture2D, target_height: float) -> float:
	var tex_h := float(texture.get_height()) if texture != null else target_height
	return target_height / maxf(tex_h, 1.0)


func _process(delta: float) -> void:
	_hint_phase += delta * 4.0
	if _tied:
		return
	_update_nearby_hint()


func _physics_process(delta: float) -> void:
	if _tied:
		return
	_resolve_player_overlap()
	if _tied:
		return
	var player := _find_nearby_player(CHARGE_RANGE)
	if player != null and absf(player.global_position.y - global_position.y) <= CHARGE_Y_BAND:
		var toward := 1.0 if player.global_position.x >= global_position.x else -1.0
		if _has_floor_ahead(toward):
			_facing = toward
			_apply_facing(_facing)
			_charge_bob += delta * 14.0
			if _sprite != null:
				_sprite.offset.y = -float(BULL_TEX.get_height()) * 0.5 + sin(_charge_bob) * 3.0
				_sprite.rotation = sin(_charge_bob * 0.5) * 0.04 * _facing
			global_position.x += _facing * CHARGE_SPEED * delta
		elif _sprite != null:
			_sprite.offset.y = -float(BULL_TEX.get_height()) * 0.5
			_sprite.rotation = 0.0
	else:
		if _sprite != null:
			_sprite.offset.y = -float(BULL_TEX.get_height()) * 0.5
			_sprite.rotation = 0.0


func _has_floor_ahead(direction: float) -> bool:
	var world := get_world_2d()
	if world == null:
		return true
	var ahead := global_position + Vector2(direction * 28.0, -4.0)
	var query := PhysicsRayQueryParameters2D.create(
		ahead,
		ahead + Vector2(0.0, 80.0),
		1
	)
	query.exclude = [get_rid()]
	return not world.direct_space_state.intersect_ray(query).is_empty()


func _apply_facing(direction: float) -> void:
	if _sprite == null:
		return
	_sprite.flip_h = direction < 0.0


func is_tied() -> bool:
	return _tied


func get_stand_scale() -> float:
	return _stand_scale


func tie_up(_award_bounty: bool = true) -> void:
	if _tied:
		return
	_tied = true
	collision_layer = 0
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", false)
		_area.set_deferred("monitorable", false)
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", true)
	_show_tied_pose()
	if get_node_or_null("TiedRopes") == null:
		var ropes := TiedBanditOverlay.new()
		ropes.name = "TiedRopes"
		ropes.z_index = 0
		add_child(ropes)
		_animate_rope_coils(ropes)
	z_index = -1
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.55, 0.25, 0.06, 1.0)
		_label.position.y = -98.0
	_play_tying_flourish()
	captured.emit(self)


func _play_tying_flourish() -> void:
	if _sprite == null:
		return
	_kill_pose_tween()
	var face := -1.0 if _sprite.flip_h else 1.0
	var tied_scale := _scale_for(BULL_TIED_TEX, TIED_TARGET_HEIGHT)
	_pose_tween = create_tween()
	_pose_tween.tween_property(_sprite, "scale", Vector2(_stand_scale * 1.08 * face, _stand_scale * 0.72), 0.1)
	_pose_tween.tween_property(_sprite, "scale", Vector2(tied_scale * face, tied_scale), 0.14)
	if _label != null:
		_label.text = "GOTCHA!"
		var label_tween := create_tween()
		label_tween.tween_interval(0.28)
		label_tween.tween_callback(func() -> void:
			if _label != null and _tied:
				_label.text = "TIED!"
		)


func _show_tied_pose() -> void:
	if _sprite == null:
		return
	_kill_pose_tween()
	var face_left := _sprite.flip_h
	_sprite.texture = BULL_TIED_TEX
	_sprite.flip_h = face_left
	_sprite.rotation = 0.0
	var tied_scale := _scale_for(BULL_TIED_TEX, TIED_TARGET_HEIGHT)
	var face := -1.0 if face_left else 1.0
	_sprite.scale = Vector2(tied_scale * face, tied_scale)
	_sprite.offset = Vector2(0.0, -float(BULL_TIED_TEX.get_height()) * 0.5)


func _animate_rope_coils(ropes: Node2D) -> void:
	for i in range(3):
		var loop := Line2D.new()
		loop.width = 4.5
		loop.default_color = Color(0.72, 0.5, 0.22, 1.0)
		loop.z_index = 2
		var radius := 34.0 + float(i) * 10.0
		var points := PackedVector2Array()
		for step in range(10):
			var ang := TAU * float(step) / 9.0
			points.append(Vector2(
				cos(ang) * radius * 0.55,
				-44.0 - float(i) * 12.0 + sin(ang) * radius * 0.28
			))
		loop.points = points
		loop.modulate.a = 0.0
		ropes.add_child(loop)
		var tween := create_tween()
		tween.tween_property(loop, "modulate:a", 1.0, 0.08).set_delay(0.05 * float(i))
		tween.tween_property(loop, "modulate:a", 0.0, 0.35).set_delay(0.22)
		tween.tween_callback(loop.queue_free)


func untie_for_respawn() -> void:
	if not _tied:
		return
	_tied = false
	_kill_pose_tween()
	collision_layer = 0
	z_index = 0
	global_position = _origin
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", true)
		_area.set_deferred("monitorable", true)
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", false)
	var ropes := get_node_or_null("TiedRopes")
	if ropes != null:
		ropes.queue_free()
	_setup_sprite()
	if _label != null:
		_label.position.y = 0.0
		_label.text = "BULL"
		_label.modulate = Color.WHITE


func _kill_pose_tween() -> void:
	if _pose_tween != null:
		_pose_tween.kill()
		_pose_tween = null


func _update_nearby_hint() -> void:
	if _label == null:
		return
	var player := _find_nearby_player(180.0)
	if player != null:
		_label.text = "JUMP!"
		_label.modulate = Color(1.0, 0.85 + sin(_hint_phase) * 0.15, 0.2, 1.0)
		_label.add_theme_font_size_override(&"font_size", 16)
	else:
		_label.text = "BULL"
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


func _is_head_stomp(player: Player) -> bool:
	var chest_y := global_position.y - 28.0
	if player.global_position.y > chest_y:
		return false
	if player.velocity.y < STOMP_MIN_FALL_SPEED:
		return false
	return true


func _bounce_after_stomp(player: Player) -> void:
	player.velocity.y = STOMP_BOUNCE
	if absf(player.velocity.x) < 40.0:
		player.velocity.x = 0.0


func _resolve_player_overlap() -> void:
	if _tied or _area == null:
		return
	for body in _area.get_overlapping_bodies():
		if body is Player:
			if _handle_player_contact(body as Player):
				return


func _handle_player_contact(player: Player) -> bool:
	if _tied:
		return false
	if _is_head_stomp(player):
		tie_up()
		_bounce_after_stomp(player)
		return true
	if player.is_invulnerable():
		return false
	hurt_player.emit(player)
	return true


func _on_body_entered(body: Node2D) -> void:
	if _tied:
		return
	if body is Player:
		_handle_player_contact(body as Player)
