class_name BullEnemy
extends AnimatableBody2D

## Trail bull: charges the cowboy, ties on lasso or head stomp like bandits.

signal hurt_player(player: Player)
signal captured(bull: BullEnemy)

const BULL_TEX := preload("res://assets/world/trail_bull.png")
const BULL_TIED_TEX := preload("res://assets/world/boss_stampede_bull_tied_legs.png")
const BULL_DOWN_TEX := preload("res://assets/world/boss_stampede_bull_down.png")
const BULL_RUN_TEX: Array[Texture2D] = [
	preload("res://assets/world/trail_bull_run_0.png"),
	preload("res://assets/world/trail_bull_run_1.png"),
	preload("res://assets/world/trail_bull_run_2.png"),
	preload("res://assets/world/trail_bull_run_3.png"),
]
const LIZARD_TEX := preload("res://assets/world/cave_lizard.png")
const LIZARD_TIED_TEX := preload("res://assets/world/cave_lizard_tied_legs.png")
const LIZARD_DOWN_TEX := preload("res://assets/world/cave_lizard_down.png")

## Same on-screen height for standing and leg-bound poses so the bull does not shrink when tied.
const STAND_TARGET_HEIGHT := 92.0
## Lying pose uses a shorter texture; keep body mass similar to the standing bull.
const DOWN_TARGET_HEIGHT := 72.0
const CHARGE_SPEED := 150.0
const CHARGE_RANGE := 560.0
const CHARGE_Y_BAND := 180.0
const GRAVITY := 1400.0
## Look this far up/down from the hooves for the trail crust when grounding.
const GROUND_PROBE_UP := 48.0
const GROUND_PROBE_DOWN := 64.0
## Once the bull tumbles this far below its post it has cleared into the canyon.
const FALL_DEATH_DEPTH := 1400.0
## About 8 cm on a typical play window — reverse run after a pit/canyon lip.
const EDGE_RETREAT_PX := 300.0
const EDGE_LOOKAHEAD_PX := 32.0
const RUN_FPS := 10.0

var _origin: Vector2
var _facing: float = 1.0
var _area: Area2D
var _label: Label
var _sprite: Sprite2D
var _hint_phase: float = 0.0
var _tied: bool = false
var _charge_bob: float = 0.0
var _run_phase: float = 0.0
var _pose_tween: Tween
var _stand_scale: float = 1.0
var _vel_y: float = 0.0
var _fallen: bool = false
var _was_grounded: bool = false
var _level_style: String = LevelStyle.DESERT
var _retreat_remaining: float = 0.0
var _retreat_dir: float = 0.0


func apply_level_style(style: String) -> void:
	_level_style = LevelStyle.normalize(style)
	if _sprite != null and not _tied:
		_setup_sprite()


func _stand_tex() -> Texture2D:
	return LIZARD_TEX if LevelStyle.is_cave(_level_style) else BULL_TEX


func _tied_tex() -> Texture2D:
	return LIZARD_TIED_TEX if LevelStyle.is_cave(_level_style) else BULL_TIED_TEX


func _down_tex() -> Texture2D:
	return LIZARD_DOWN_TEX if LevelStyle.is_cave(_level_style) else BULL_DOWN_TEX


func _has_run_cycle() -> bool:
	return not LevelStyle.is_cave(_level_style) and not BULL_RUN_TEX.is_empty()


func _play_move_visual(moving: bool, delta: float) -> void:
	if _sprite == null or _tied or _fallen:
		return
	var base_offset := -float(_stand_tex().get_height()) * 0.5
	if moving and _has_run_cycle():
		_run_phase += delta * RUN_FPS
		var idx := int(floor(_run_phase)) % BULL_RUN_TEX.size()
		_sprite.texture = BULL_RUN_TEX[idx]
		_sprite.offset.y = base_offset
		_sprite.rotation = 0.0
	elif moving:
		_charge_bob += delta * 14.0
		_sprite.texture = _stand_tex()
		_sprite.offset.y = base_offset + sin(_charge_bob) * 3.0
		_sprite.rotation = sin(_charge_bob * 0.5) * 0.04 * _facing
	else:
		_run_phase = 0.0
		_sprite.texture = _stand_tex()
		_sprite.offset.y = base_offset
		_sprite.rotation = 0.0


func _ready() -> void:
	_origin = global_position
	_area = get_node_or_null("HurtArea") as Area2D
	_label = get_node_or_null("Label") as Label
	if _label != null:
		_label.visible = false
	_setup_sprite()
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
	set_physics_process(true)
	set_process(true)
	# Snap hooves to the trail on the first physics tick when a floor exists.
	call_deferred("_snap_to_floor_once")


func _setup_sprite() -> void:
	# Free every leftover sprite so cave lizards never stack on the desert bull art.
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	_sprite = Sprite2D.new()
	_sprite.name = "BullSprite"
	_sprite.texture = _stand_tex()
	_sprite.centered = true
	_stand_scale = _scale_for(_stand_tex(), STAND_TARGET_HEIGHT)
	_sprite.scale = Vector2(_stand_scale, _stand_scale)
	_sprite.offset = Vector2(0.0, -float(_stand_tex().get_height()) * 0.5)
	_apply_facing(_facing)
	add_child(_sprite)


func _scale_for(texture: Texture2D, target_height: float) -> float:
	var tex_h := float(texture.get_height()) if texture != null else target_height
	return target_height / maxf(tex_h, 1.0)


func _process(delta: float) -> void:
	_hint_phase += delta * 4.0
	if _tied:
		return
	_update_nearby_hint()


func _snap_to_floor_once() -> void:
	var hit_y := _probe_floor_y(GROUND_PROBE_DOWN + 120.0)
	if not is_nan(hit_y):
		global_position.y = hit_y
		_origin.y = global_position.y
		_was_grounded = true
		_vel_y = 0.0


func _physics_process(delta: float) -> void:
	if _tied:
		return
	_resolve_player_overlap()
	if _tied:
		return
	var player := _find_nearby_player(99999.0)
	var retreating := _retreat_remaining > 0.0
	if not retreating and player != null:
		# Always turn to glare at the cowpoke, even before the charge begins.
		_facing = 1.0 if player.global_position.x >= global_position.x else -1.0
		_apply_facing(_facing)
	var charging := (
		not retreating
		and player != null
		and global_position.distance_to(player.global_position) <= CHARGE_RANGE
		and absf(player.global_position.y - global_position.y) <= CHARGE_Y_BAND
	)
	# AnimatableBody2D defers transform writes — combine charge + gravity into one
	# assignment so the X shove is not wiped by the floor snap.
	var next := global_position
	if retreating:
		if _edge_ahead(_retreat_dir):
			_retreat_remaining = 0.0
		else:
			var step := _retreat_dir * CHARGE_SPEED * delta
			next.x += step
			_retreat_remaining = maxf(_retreat_remaining - absf(step), 0.0)
			_facing = _retreat_dir
			_apply_facing(_facing)
	elif charging:
		if _edge_ahead(_facing):
			_begin_edge_retreat()
		else:
			next.x += _facing * CHARGE_SPEED * delta
	next = _integrate_gravity(next, delta)
	global_position = next
	_play_move_visual((charging or retreating) and not _fallen, delta)


func _edge_ahead(direction: float) -> bool:
	## True at a pit or canyon lip in the given facing.
	var dir := signf(direction)
	if is_zero_approx(dir):
		return false
	if not FloorProbe.has_floor_ahead(self, dir):
		return true
	var probe := global_position + Vector2(dir * EDGE_LOOKAHEAD_PX, 0.0)
	return is_nan(_probe_floor_y_at(probe, GROUND_PROBE_DOWN))


func _begin_edge_retreat() -> void:
	## Spin away from the gap and run inland ~8 cm instead of tumbling in.
	_retreat_dir = -_facing
	if is_zero_approx(_retreat_dir):
		_retreat_dir = -1.0
	_facing = _retreat_dir
	_apply_facing(_facing)
	_retreat_remaining = EDGE_RETREAT_PX


func _probe_floor_y_at(world_pos: Vector2, down_reach: float) -> float:
	var world := get_world_2d()
	if world == null:
		return NAN
	var from := world_pos + Vector2(0.0, -GROUND_PROBE_UP)
	var query := PhysicsRayQueryParameters2D.create(
		from,
		world_pos + Vector2(0.0, down_reach),
		1
	)
	query.exclude = [get_rid()]
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return NAN
	return float((hit["position"] as Vector2).y)


func _probe_floor_y(down_reach: float) -> float:
	return _probe_floor_y_at(global_position, down_reach)


func _integrate_gravity(next: Vector2, delta: float) -> Vector2:
	if _fallen:
		_vel_y += GRAVITY * delta
		next.y += _vel_y * delta
		return next
	var reach := GROUND_PROBE_DOWN + maxf(_vel_y, 0.0) * delta
	var hit_y := _probe_floor_y_at(next, reach)
	if not is_nan(hit_y):
		next.y = hit_y
		_vel_y = 0.0
		_was_grounded = true
		return next
	# Only tumble after leaving a real trail crust (canyon rim / pit). Fixtures
	# without a floor under the spawn post stay put so unit tests stay stable.
	if not _was_grounded:
		_vel_y = 0.0
		return next
	_vel_y += GRAVITY * delta
	next.y += _vel_y * delta
	if next.y > _origin.y + FALL_DEATH_DEPTH:
		_begin_fallen()
	return next



func _begin_fallen() -> void:
	if _fallen:
		return
	_fallen = true
	_was_grounded = false
	collision_layer = 0
	if _area != null:
		_area.set_deferred("monitoring", false)
		_area.set_deferred("monitorable", false)
	visible = false


func restore_for_respawn() -> void:
	## Bulls that charged into a canyon (or wandered off) return to their post
	## when the cowboy respawns at a camp.
	if _tied:
		return
	_fallen = false
	_vel_y = 0.0
	_was_grounded = false
	_retreat_remaining = 0.0
	_retreat_dir = 0.0
	global_position = _origin
	_facing = 1.0
	visible = true
	if _area != null:
		_area.set_deferred("monitoring", true)
		_area.set_deferred("monitorable", true)
	_apply_facing(_facing)
	call_deferred("_snap_to_floor_once")


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
	_fallen = false
	_vel_y = 0.0
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
	z_index = -1
	captured.emit(self)
	# Camp restore / load snaps straight to the floor pose; live captures play the full tip-over.
	if _award_bounty:
		_play_tie_sequence()
	else:
		_snap_to_down_pose()


func _play_tie_sequence() -> void:
	if _sprite == null:
		_snap_to_down_pose()
		return
	_kill_pose_tween()
	var face_left := _sprite.flip_h
	var stand_s := _stand_scale
	var tied_s := _scale_for(_tied_tex(), STAND_TARGET_HEIGHT)
	var down_s := _scale_for(_down_tex(), DOWN_TARGET_HEIGHT)

	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.25, 0.75, 0.3, 1.0)
		_label.position.y = -98.0

	# Rope coils whip around the standing bull's legs (same flourish as the boss).
	var ropes := BullTieFx.spawn_win_ropes(self, self)

	_pose_tween = create_tween()
	_pose_tween.tween_property(_sprite, "scale", Vector2(stand_s * 1.12, stand_s * 0.82), 0.12)
	_pose_tween.tween_property(_sprite, "scale", Vector2(stand_s * 0.92, stand_s * 1.08), 0.1)
	_pose_tween.tween_property(_sprite, "scale", Vector2(stand_s, stand_s), 0.1)
	await get_tree().create_timer(0.55).timeout
	if not is_instance_valid(self) or not _tied:
		return

	if is_instance_valid(ropes):
		ropes.queue_free()
	# Standing pose with legs bound — same on-screen height as the charging bull.
	_sprite.texture = _tied_tex()
	_sprite.flip_h = face_left
	_sprite.rotation = 0.0
	_sprite.scale = Vector2(tied_s, tied_s)
	_sprite.offset = Vector2(0.0, -float(_tied_tex().get_height()) * 0.5)
	var wobble := BullTieFx.wobble_sprite(_sprite, self, face_left)
	await wobble.finished
	if not is_instance_valid(self) or not _tied:
		return
	await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(self) or not _tied:
		return

	# Tip over onto its side, then land on the floor pose.
	if _label != null:
		_label.text = "DOWN!"
		_label.modulate = Color(0.55, 0.3, 0.1, 1.0)
	var tip_dir := -1.0 if face_left else 1.0
	var tip := create_tween()
	tip.set_parallel(true)
	tip.tween_property(_sprite, "rotation", tip_dir * PI * 0.5, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tip.tween_property(_sprite, "offset:y", -float(_tied_tex().get_height()) * 0.22, 0.45)
	await tip.finished
	if not is_instance_valid(self) or not _tied:
		return

	_show_down_pose(face_left, down_s)
	_puff_dust()
	var settle := create_tween()
	settle.tween_property(_sprite, "scale", Vector2(down_s * 1.08, down_s * 0.9), 0.1)
	settle.tween_property(_sprite, "scale", Vector2(down_s, down_s), 0.16)
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.2, 0.7, 0.3, 1.0)
		_label.position.y = -58.0


func _snap_to_down_pose() -> void:
	_kill_pose_tween()
	var face_left := _sprite != null and _sprite.flip_h
	var down_s := _scale_for(_down_tex(), DOWN_TARGET_HEIGHT)
	_show_down_pose(face_left, down_s)
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.2, 0.7, 0.3, 1.0)
		_label.position.y = -58.0


func _show_down_pose(face_left: bool, down_s: float) -> void:
	if _sprite == null:
		return
	_sprite.texture = _down_tex()
	_sprite.flip_h = face_left
	_sprite.rotation = 0.0
	_sprite.scale = Vector2(down_s, down_s)
	# Belly sits on the trail crust (node origin is the walk surface).
	_sprite.offset = Vector2(0.0, -float(_down_tex().get_height()) * 0.5)


func _puff_dust() -> void:
	BullTieFx.puff_dust(
		self,
		self,
		PackedVector2Array([
			Vector2(-42, 0), Vector2(-8, -14), Vector2(24, -6), Vector2(46, 5), Vector2(8, 11), Vector2(-28, 8)
		]),
		Vector2(0, 4)
	)


func untie_for_respawn() -> void:
	if not _tied:
		return
	_tied = false
	_fallen = false
	_vel_y = 0.0
	_kill_pose_tween()
	collision_layer = 0
	z_index = 0
	global_position = _origin
	visible = true
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", true)
		_area.set_deferred("monitorable", true)
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", false)
	TiedBanditOverlay.remove_from(self)
	var win_ropes := get_node_or_null("WinRopes")
	if win_ropes != null:
		win_ropes.queue_free()
	_setup_sprite()
	if _label != null:
		_label.position.y = 0.0
		_label.text = "BULL"
		_label.modulate = Color.WHITE


func _kill_pose_tween() -> void:
	EnemyContact.kill_tween(_pose_tween)
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
	return PlayerLookup.find_in_tree(self, radius)


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
	if EnemyContact.is_head_stomp(self, player, 28.0):
		tie_up()
		EnemyContact.bounce_after_stomp(player)
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
