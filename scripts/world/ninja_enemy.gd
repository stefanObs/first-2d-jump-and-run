class_name NinjaEnemy
extends AnimatableBody2D

## Ambush foe: pops in ahead of the cowboy, charges with a sword, throws stars at flyers.

signal hurt_player(player: Player)
signal captured(ninja: NinjaEnemy)

enum State { DORMANT, APPEAR, CHASE, ATTACK, THROW, TIED }

const STAND_SCALE := 1.15
## Tied art is the same 64×80 frame as idle — keep standing size so he does not shrink.
const STAND_FOOT_OFFSET := Vector2(0, -40)
const SPAWN_AHEAD := 480.0
const TRIGGER_RANGE := 1040.0
const CHASE_SPEED := 170.0
const MELEE_RANGE := 34.0
const SHURIKEN_RANGE := 640.0
const SHURIKEN_COOLDOWN := 1.35

var _anchor: Vector2
var _facing: float = 1.0
var _area: Area2D
var _label: Label
var _sprite: AnimatedSprite2D
var _hint_phase: float = 0.0
var _tied: bool = false
var _state: State = State.DORMANT
var _activated: bool = false
var _attack_token: int = 0
var _throw_token: int = 0
var _throw_timer: float = 0.0
var _pose_tween: Tween


func _ready() -> void:
	_anchor = global_position
	_area = get_node_or_null("HurtArea") as Area2D
	_label = get_node_or_null("Label") as Label
	if _label != null:
		_label.visible = false
	_setup_sprite()
	_set_dormant(true)
	if _area != null:
		_area.body_entered.connect(_on_body_entered)


func _setup_sprite() -> void:
	var existing := get_node_or_null("NinjaSprite") as AnimatedSprite2D
	if existing != null:
		existing.queue_free()
	var old := get_node_or_null("Sprite2D") as Node
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "NinjaSprite"
	_sprite.sprite_frames = _make_sprite_frames()
	_sprite.centered = true
	_sprite.offset = STAND_FOOT_OFFSET
	_sprite.scale = Vector2(STAND_SCALE, STAND_SCALE)
	_apply_facing(1.0)
	_sprite.play(&"idle")
	add_child(_sprite)
	if old != null:
		old.visible = false


func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for anim_data in [
		[&"idle", 1.0, true, ["res://assets/world/ninja_idle.png"]],
		[&"run", 10.0, true, [
			"res://assets/world/ninja_run_0.png",
			"res://assets/world/ninja_idle.png",
			"res://assets/world/ninja_run_1.png",
			"res://assets/world/ninja_idle.png",
		]],
		[&"sword", 12.0, false, [
			"res://assets/world/ninja_sword_0.png",
			"res://assets/world/ninja_sword_1.png",
		]],
		[&"throw", 10.0, false, [
			"res://assets/world/ninja_throw_0.png",
			"res://assets/world/ninja_throw_1.png",
		]],
		[&"tied", 1.0, false, ["res://assets/world/ninja_tied.png"]],
	]:
		var anim: StringName = anim_data[0]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, anim_data[1])
		frames.set_animation_loop(anim, anim_data[2])
		for path in anim_data[3]:
			var tex: Texture2D = load(str(path))
			if tex != null:
				frames.add_frame(anim, tex)
	return frames


func _set_dormant(hidden: bool) -> void:
	if hidden:
		_state = State.DORMANT
		modulate.a = 0.0
		if _area != null:
			_area.set_deferred("monitoring", false)
			_area.set_deferred("monitorable", false)
	else:
		modulate.a = 1.0
		if _area != null:
			_area.set_deferred("monitoring", true)
			_area.set_deferred("monitorable", true)


func _process(delta: float) -> void:
	_hint_phase += delta * 4.0
	if _tied or _state == State.DORMANT:
		return
	_update_nearby_hint()


func _physics_process(delta: float) -> void:
	if _tied:
		return
	if _state == State.DORMANT:
		_try_activate()
		return
	if _state == State.ATTACK or _state == State.THROW or _state == State.APPEAR:
		return
	_resolve_player_overlap()
	if _tied:
		return
	var player := _find_player()
	if player == null:
		if _state == State.CHASE:
			_set_move_animation(false)
		return
	if player.get_modes().is_flying():
		_handle_flying_player(player, delta)
	else:
		_handle_ground_player(player, delta)


func _try_activate() -> void:
	if _activated:
		return
	var player := _find_player()
	if player == null:
		return
	if global_position.distance_to(player.global_position) > TRIGGER_RANGE:
		return
	if global_position.distance_to(_anchor) > TRIGGER_RANGE + 40.0:
		return
	_activated = true
	_appear_in_front_of(player)


func _appear_in_front_of(player: Player) -> void:
	_state = State.APPEAR
	var facing := _player_facing(player)
	var spawn_x := player.global_position.x + facing * SPAWN_AHEAD
	var spawn_y := _walk_surface_y(spawn_x, player.global_position.y)
	global_position = Vector2(spawn_x, spawn_y)
	_facing = -facing
	_apply_facing(_facing)
	_set_dormant(false)
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	tween.tween_callback(func() -> void:
		if not _tied:
			_state = State.CHASE
			_set_move_animation(true)
	)


func _player_facing(player: Player) -> float:
	if absf(player.velocity.x) > 8.0:
		return 1.0 if player.velocity.x >= 0.0 else -1.0
	var sprite := player.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		return -1.0 if sprite.flip_h else 1.0
	return 1.0 if player.global_position.x >= _anchor.x else -1.0


func _walk_surface_y(world_x: float, fallback_y: float) -> float:
	var level := get_tree().current_scene
	if level != null:
		var surface := WildWestTheme.walk_surface_at(level, world_x)
		if surface.has("y"):
			return float(surface["y"])
	return fallback_y


func _handle_ground_player(player: Player, delta: float) -> void:
	_facing = 1.0 if player.global_position.x >= global_position.x else -1.0
	var dist := global_position.distance_to(player.global_position)
	if dist <= MELEE_RANGE:
		_begin_sword_attack(player)
		return
	if _has_floor_ahead(_facing):
		_apply_facing(_facing)
		global_position.x += _facing * CHASE_SPEED * delta
		_set_move_animation(true)
	else:
		_set_move_animation(false)


func _handle_flying_player(player: Player, delta: float) -> void:
	_facing = 1.0 if player.global_position.x >= global_position.x else -1.0
	_apply_facing(_facing)
	_set_move_animation(false)
	_throw_timer -= delta
	if _throw_timer > 0.0:
		return
	if global_position.distance_to(player.global_position) > SHURIKEN_RANGE:
		return
	if absf(player.global_position.y - global_position.y) > SHURIKEN_RANGE:
		return
	_begin_throw(player)


func _begin_sword_attack(player: Player) -> void:
	if _state == State.ATTACK:
		return
	_state = State.ATTACK
	_attack_token += 1
	var token := _attack_token
	_set_move_animation(false)
	if _sprite != null:
		_sprite.play(&"sword")
	if _label != null:
		_label.text = "SLASH!"
		_label.modulate = Color(0.95, 0.2, 0.12, 1.0)
	await get_tree().create_timer(0.12).timeout
	if token != _attack_token or _tied:
		return
	if player != null and global_position.distance_to(player.global_position) <= MELEE_RANGE + 8.0:
		if not player.is_invulnerable():
			hurt_player.emit(player)
	await get_tree().create_timer(0.18).timeout
	if token != _attack_token or _tied:
		return
	_state = State.CHASE
	if _label != null:
		_label.text = "NINJA"
		_label.modulate = Color.WHITE


func _begin_throw(player: Player) -> void:
	if _state == State.THROW:
		return
	_state = State.THROW
	_throw_token += 1
	var token := _throw_token
	_facing = 1.0 if player.global_position.x >= global_position.x else -1.0
	_apply_facing(_facing)
	if _sprite != null:
		_sprite.play(&"throw")
	if _label != null:
		_label.text = "STARS!"
		_label.modulate = Color(0.85, 0.9, 1.0, 1.0)
	await get_tree().create_timer(0.14).timeout
	if token != _throw_token or _tied:
		return
	_spawn_shuriken(player)
	_throw_timer = SHURIKEN_COOLDOWN
	await get_tree().create_timer(0.16).timeout
	if token != _throw_token or _tied:
		return
	_state = State.CHASE
	if _label != null:
		_label.text = "NINJA"
		_label.modulate = Color.WHITE


func _spawn_shuriken(player: Player) -> void:
	var star := NinjaShuriken.new()
	star.name = "NinjaShuriken"
	star.hurt_player.connect(func(hit_player: Player) -> void: hurt_player.emit(hit_player))
	var parent := get_parent()
	if parent == null:
		star.queue_free()
		return
	parent.add_child(star)
	var from := global_position + Vector2(18.0 * _facing, -36.0)
	var lead := player.velocity * 0.18
	star.global_position = from
	star.setup(player.global_position + lead, from)


func _has_floor_ahead(direction: float) -> bool:
	var world := get_world_2d()
	if world == null:
		return true
	var ahead := global_position + Vector2(direction * 24.0, -4.0)
	var query := PhysicsRayQueryParameters2D.create(
		ahead,
		ahead + Vector2(0.0, 72.0),
		1
	)
	query.exclude = [get_rid()]
	return not world.direct_space_state.intersect_ray(query).is_empty()


func _apply_facing(direction: float) -> void:
	if _sprite == null:
		return
	_sprite.flip_h = direction < 0.0


func _set_move_animation(moving: bool) -> void:
	if _sprite == null or _tied or _state == State.ATTACK or _state == State.THROW:
		return
	if moving:
		if _sprite.animation != &"run" or not _sprite.is_playing():
			_sprite.play(&"run")
	elif _sprite.animation != &"idle" or not _sprite.is_playing():
		_sprite.play(&"idle")


func is_tied() -> bool:
	return _tied


func tie_up(_award_bounty: bool = true) -> void:
	if _tied:
		return
	_tied = true
	_state = State.TIED
	_attack_token += 1
	_throw_token += 1
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
		_label.position.y = -78.0
	_play_tying_flourish()
	captured.emit(self)


func _show_tied_pose() -> void:
	if _sprite == null:
		return
	_kill_pose_tween()
	_sprite.play(&"tied")
	# Same frame size as idle — keep standing scale and foot offset so he sits on the trail.
	_sprite.offset = STAND_FOOT_OFFSET
	_sprite.scale = Vector2(STAND_SCALE, STAND_SCALE)


func _play_tying_flourish() -> void:
	if _sprite == null:
		return
	_kill_pose_tween()
	_pose_tween = create_tween()
	_pose_tween.tween_property(_sprite, "scale", Vector2(STAND_SCALE * 1.08, STAND_SCALE * 0.72), 0.1)
	_pose_tween.tween_property(_sprite, "scale", Vector2(STAND_SCALE, STAND_SCALE), 0.14)


func _animate_rope_coils(ropes: Node2D) -> void:
	for i in range(3):
		var loop := Line2D.new()
		loop.width = 4.0
		loop.default_color = Color(0.72, 0.5, 0.22, 1.0)
		loop.z_index = 2
		var radius := 28.0 + float(i) * 8.0
		var points := PackedVector2Array()
		for step in range(10):
			var ang := TAU * float(step) / 9.0
			points.append(Vector2(cos(ang) * radius * 0.55, -38.0 - float(i) * 10.0 + sin(ang) * radius * 0.28))
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
	_state = State.DORMANT
	_activated = false
	_attack_token += 1
	_throw_token += 1
	_throw_timer = 0.0
	_kill_pose_tween()
	collision_layer = 0
	z_index = 0
	global_position = _anchor
	_set_dormant(true)
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", false)
		_area.set_deferred("monitorable", false)
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", false)
	var ropes := get_node_or_null("TiedRopes")
	if ropes != null:
		ropes.queue_free()
	_setup_sprite()
	if _label != null:
		_label.position.y = 0.0
		_label.text = "NINJA"
		_label.modulate = Color.WHITE


func restore_for_respawn() -> void:
	## Untied ninjas that already ambushed return to their dormant anchor.
	## Shuriken are cleared separately by the level controller.
	if _tied:
		return
	_state = State.DORMANT
	_activated = false
	_attack_token += 1
	_throw_token += 1
	_throw_timer = 0.0
	_kill_pose_tween()
	global_position = _anchor
	_set_dormant(true)
	_setup_sprite()
	if _label != null:
		_label.position.y = 0.0
		_label.text = "NINJA"
		_label.modulate = Color.WHITE


func _kill_pose_tween() -> void:
	if _pose_tween != null:
		_pose_tween.kill()
		_pose_tween = null


func _update_nearby_hint() -> void:
	if _label == null:
		return
	var player := _find_player()
	if player != null and global_position.distance_to(player.global_position) <= 180.0:
		_label.text = "JUMP!"
		_label.modulate = Color(1.0, 0.85 + sin(_hint_phase) * 0.15, 0.2, 1.0)
		_label.add_theme_font_size_override(&"font_size", 16)
	else:
		_label.text = "NINJA"
		_label.modulate = Color(1, 1, 1, 1)
		_label.add_theme_font_size_override(&"font_size", 13)


func _find_player() -> Player:
	return PlayerLookup.find_in_tree(self)


func _resolve_player_overlap() -> void:
	if _tied or _area == null or not _area.monitoring:
		return
	for body in _area.get_overlapping_bodies():
		if body is Player:
			if _handle_player_contact(body as Player):
				return


func _handle_player_contact(player: Player) -> bool:
	if _tied or _state == State.DORMANT:
		return false
	if EnemyContact.is_head_stomp(self, player, 24.0):
		tie_up()
		EnemyContact.bounce_after_stomp(player)
		return true
	if player.is_invulnerable():
		return false
	if _state != State.ATTACK:
		hurt_player.emit(player)
	return true


func _on_body_entered(body: Node2D) -> void:
	if _tied or _state == State.DORMANT:
		return
	if body is Player:
		_handle_player_contact(body as Player)
