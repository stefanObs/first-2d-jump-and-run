class_name Player
extends CharacterBody2D

## Child-friendly wild-west cowboy controller with movement animation.

signal landed
signal respawned(position: Vector2)
signal mode_changed(mode_name: String, remaining: float)
signal star_collected(total: int)

@export var move_speed: float = 270.0
@export var acceleration: float = 1900.0
@export var air_acceleration: float = 1300.0
@export var friction: float = 2000.0
@export var air_friction: float = 400.0
@export var jump_velocity: float = -500.0
@export var gravity: float = 1350.0
@export var fall_gravity_multiplier: float = 1.25
@export var jump_cut_multiplier: float = 0.5
@export var coyote_time: float = 0.16
@export var jump_buffer_time: float = 0.15
@export var max_fall_speed: float = 820.0
@export var respawn_invulnerability_time: float = 0.85
@export var fly_rise_speed: float = 240.0
@export var fly_fall_speed: float = 150.0
@export var start_mounted: bool = false

const HORSE_SPEED_MULTIPLIER := 1.45
const HORSE_JUMP_DISTANCE_MULTIPLIER := 1.2
const HORSE_VISUAL_SCALE := 0.48
const WING_BASE_SCALE := 1.05
const PLAYER_DISPLAY_SCALE := 1.5
## Idle uses one frame plus a gentle breathe — idle_0/idle_1 were mismatched poses and flickered.
const RUN_SPEED_ENTER := 34.0
const RUN_SPEED_EXIT := 14.0
const JUMP_ANIM_AIR_TIME := 0.07
const CLIMB_SPEED := 160.0
## Near climb_top, Space is a jump so the cowboy can hop onto a nearby ledge or mover.
const LADDER_TOP_JUMP_SLACK := 22.0

var input_enabled: bool = true
var stars_collected: int = 0
var external_velocity: Vector2 = Vector2.ZERO

var _jump_assist: JumpAssist
var _modes: ModeController
var _was_on_floor: bool = false
var _jump_cut_applied: bool = false
var _invulnerable_remaining: float = 0.0
var _sprite: AnimatedSprite2D
var _facing: float = 1.0
var _shield_bubble: BubbleForceField
var _land_squash: float = 0.0
var _wing_sprite: Sprite2D
var _celebrating: bool = false
var _using_magic_boots_art: bool = false
var _bounce_cooldown: float = 0.0
var _lasso_cooldown: float = 0.0
var _is_canyon_falling: bool = false
var _mounted: bool = false
var _mounted_sprite: Sprite2D
var _body_shape: CollisionShape2D
var _normal_shape: Shape2D
var _normal_shape_position: Vector2
var _player_character: String = GameManager.PLAYER_COWBOY
var _air_time: float = 0.0
var _ground_time: float = 0.0
var _showing_run: bool = false
var _showing_jump: bool = false
var _nearby_ladders: Array[Ladder] = []
var _active_ladder: Ladder = null
var _climbing: bool = false
var _climb_anim_phase: float = 0.0
## Jump was used to climb; ignore that hold until Space is released (no re-grab / auto-jump).
var _climb_up_latched: bool = false


func _ready() -> void:
	add_to_group("player")
	_ensure_jump_assist()
	_ensure_modes()
	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_body_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _body_shape != null:
		_normal_shape = _body_shape.shape
		_normal_shape_position = _body_shape.position
	_setup_sprite_frames(false)
	_ensure_mounted_sprite()
	if start_mounted:
		mount_horse()
	_ensure_shield_bubble()
	_ensure_wings()
	if _sprite != null:
		_sprite.play(&"idle")
	landed.connect(_on_landed)
	if not GameManager.settings_changed.is_connected(_on_player_settings_changed):
		GameManager.settings_changed.connect(_on_player_settings_changed)


func _physics_process(delta: float) -> void:
	_ensure_jump_assist()
	_ensure_modes()
	_modes.tick(delta)
	if _is_canyon_falling:
		velocity = Vector2.ZERO
		external_velocity = Vector2.ZERO
		return
	if _invulnerable_remaining > 0.0:
		_invulnerable_remaining = maxf(_invulnerable_remaining - delta, 0.0)
	if _bounce_cooldown > 0.0:
		_bounce_cooldown = maxf(_bounce_cooldown - delta, 0.0)
	if _lasso_cooldown > 0.0:
		_lasso_cooldown = maxf(_lasso_cooldown - delta, 0.0)

	var on_floor := is_on_floor()
	_jump_assist.notify_grounded(on_floor)
	_jump_assist.tick(delta)

	if input_enabled and not Input.is_action_pressed(&"jump"):
		_climb_up_latched = false
	if input_enabled and Input.is_action_just_pressed(&"jump"):
		_jump_assist.notify_jump_pressed()
	if input_enabled and Input.is_action_just_pressed(&"lasso"):
		throw_lasso()

	if _climbing or _try_begin_climb():
		_apply_climb(delta)
	elif _modes.is_flying() and input_enabled:
		_apply_flight(delta)
	else:
		_apply_gravity(delta, on_floor)
		if input_enabled:
			_apply_horizontal_movement(delta, on_floor)
			_try_jump(on_floor)
			_cut_jump_if_released()
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	velocity += external_velocity
	move_and_slide()
	external_velocity = Vector2.ZERO

	on_floor = is_on_floor()
	if on_floor:
		_air_time = 0.0
		_ground_time += delta
	else:
		_ground_time = 0.0
		_air_time += delta
	if on_floor and not _was_on_floor:
		landed.emit()
		_spawn_dust_puff()
	_was_on_floor = on_floor
	_update_animation(on_floor)
	_update_mode_visual()


func register_ladder(ladder: Ladder) -> void:
	if ladder == null:
		return
	if ladder not in _nearby_ladders:
		_nearby_ladders.append(ladder)


func unregister_ladder(ladder: Ladder) -> void:
	_nearby_ladders.erase(ladder)
	if _active_ladder == ladder:
		_end_climb()



func _best_ladder() -> Ladder:
	var best: Ladder = null
	var best_dx := INF
	for ladder in _nearby_ladders:
		if ladder == null or not is_instance_valid(ladder):
			continue
		if not ladder.contains_player_y(global_position.y, 20.0):
			continue
		var dx := absf(ladder.center_x() - global_position.x)
		if dx < best_dx:
			best_dx = dx
			best = ladder
	return best


func _try_begin_climb() -> bool:
	if not input_enabled or _mounted or _modes.is_flying():
		return false
	if _climbing:
		return true
	var want_up := Input.is_action_pressed(&"jump")
	var want_down := Input.is_action_pressed(&"move_down")
	if not want_up and not want_down:
		return false
	var ladder := _best_ladder()
	if ladder == null:
		return false
	# From the floor, only Space/Up starts a climb. Down grabs a ladder when
	# standing near the top (drop onto the upper path's ladder mouth).
	if want_down and not want_up and is_on_floor():
		if global_position.y < ladder.climb_top_y() + 28.0:
			_start_climb(ladder)
			return true
		return false
	if want_up:
		if _climb_up_latched:
			return false
		## At the top, Space jumps onto a nearby object instead of grabbing the rungs again.
		if _is_at_ladder_top(ladder) and not want_down:
			return false
		_start_climb(ladder)
		_climb_up_latched = true
		return true
	return false


func _is_at_ladder_top(ladder: Ladder) -> bool:
	if ladder == null or not is_instance_valid(ladder):
		return false
	return global_position.y <= ladder.climb_top_y() + LADDER_TOP_JUMP_SLACK


func _start_climb(ladder: Ladder) -> void:
	_climbing = true
	_active_ladder = ladder
	_jump_assist.reset()
	_jump_cut_applied = true
	global_position.x = ladder.center_x()
	velocity = Vector2.ZERO
	_showing_jump = false
	_showing_run = false
	# Pass through solid ledges while climbing; one-way planks catch the exit step.
	collision_mask = 0


func _end_climb() -> void:
	_climbing = false
	_active_ladder = null
	_climb_anim_phase = 0.0
	collision_mask = 1


func _apply_climb(delta: float) -> void:
	if not _climbing:
		return
	if _active_ladder == null or not is_instance_valid(_active_ladder):
		_end_climb()
		return
	if not input_enabled:
		velocity = Vector2.ZERO
		return

	var climb_dir := 0.0
	if Input.is_action_pressed(&"jump"):
		climb_dir -= 1.0
		_climb_up_latched = true
	if Input.is_action_pressed(&"move_down"):
		climb_dir += 1.0

	var top := _active_ladder.climb_top_y()
	var bottom := _active_ladder.climb_bottom_y()
	var at_top := global_position.y <= top + LADDER_TOP_JUMP_SLACK
	var side := Input.get_axis(&"move_left", &"move_right")
	# Fresh Space at the top hops off the rungs onto a nearby ledge, mover, or badge.
	if at_top and Input.is_action_just_pressed(&"jump"):
		_jump_from_ladder(side)
		return

	# Left/right while climbing detaches (drop or step off).
	if absf(side) > 0.55 and absf(climb_dir) < 0.1:
		_end_climb()
		velocity.x = side * move_speed * 0.45
		velocity.y = 40.0
		return

	global_position.x = _active_ladder.center_x()
	velocity.x = 0.0
	velocity.y = climb_dir * CLIMB_SPEED

	if global_position.y <= top and climb_dir < 0.0:
		# Feet origin; land above the 24px one-way plank centered on climb_top.
		global_position.y = top - 14.0
		velocity.y = 0.0
		_end_climb()
		velocity.y = -80.0
		_climb_up_latched = true
		_jump_assist.notify_grounded(true)
		return
	if global_position.y >= bottom and climb_dir > 0.0:
		global_position.y = bottom
		velocity.y = 0.0
		_end_climb()
		return

	if absf(climb_dir) > 0.1:
		_climb_anim_phase += delta * 8.0
	_jump_assist.reset()
	_jump_cut_applied = true


func _jump_from_ladder(side: float) -> void:
	_ensure_jump_assist()
	_ensure_modes()
	_end_climb()
	_climb_up_latched = true
	if absf(side) > 0.2:
		velocity.x = signf(side) * get_run_speed()
	else:
		velocity.x = 0.0
	velocity.y = jump_velocity * _modes.jump_multiplier()
	_jump_cut_applied = false
	_showing_jump = true
	_jump_assist.consume_jump()
	AudioManager.play_sfx(&"jump")



func set_input_enabled(enabled: bool) -> void:
	_ensure_jump_assist()
	input_enabled = enabled
	if not enabled:
		velocity.x = 0.0
		_jump_assist.reset()


func mount_horse() -> void:
	_mounted = true
	_ensure_mounted_sprite()
	if _sprite != null:
		_sprite.visible = false
	if _mounted_sprite != null:
		_mounted_sprite.visible = true
	if _body_shape != null:
		var horse_shape := RectangleShape2D.new()
		horse_shape.size = Vector2(94.0, 58.0)
		_body_shape.shape = horse_shape
		_body_shape.position = Vector2(8.0, -29.0)



func is_mounted() -> bool:
	return _mounted


func get_run_speed() -> float:
	_ensure_modes()
	var mount_multiplier := HORSE_SPEED_MULTIPLIER if _mounted else 1.0
	return move_speed * _modes.move_speed_multiplier() * mount_multiplier


func get_jump_distance_multiplier() -> float:
	return HORSE_JUMP_DISTANCE_MULTIPLIER if _mounted else 1.0


func celebrate() -> void:
	_celebrating = true
	velocity = Vector2.ZERO
	if _sprite != null:
		_sprite.play(&"celebrate")


func throw_lasso() -> void:
	if not input_enabled or _lasso_cooldown > 0.0 or _celebrating:
		return
	_lasso_cooldown = 0.55
	AudioManager.play_sfx(&"lasso")
	var lasso := LassoCast.new()
	lasso.name = "LassoCast"
	lasso.position = (
		Vector2(52.0 * _facing, -76.0)
		if _mounted
		else Vector2(10.0 * _facing, -38.0)
	)
	lasso.z_index = 4
	lasso.setup(_facing)
	add_child(lasso)
	if _sprite != null:
		var tween := create_tween()
		tween.tween_property(_sprite, "rotation", -0.1 * _facing, 0.08)
		tween.tween_property(_sprite, "rotation", 0.06 * _facing, 0.12)
		tween.tween_property(_sprite, "rotation", 0.0, 0.1)


func is_invulnerable() -> bool:
	_ensure_modes()
	return _invulnerable_remaining > 0.0 or _modes.has_shield()


func has_timed_invulnerability() -> bool:
	## Respawn blink only — Bubble Shield does not count (canyon falls still apply).
	return _invulnerable_remaining > 0.0


func is_canyon_falling() -> bool:
	return _is_canyon_falling


func respawn_at(world_position: Vector2) -> void:
	_ensure_jump_assist()
	_ensure_modes()
	global_position = world_position
	velocity = Vector2.ZERO
	_is_canyon_falling = false
	input_enabled = true
	collision_layer = 2
	if _sprite != null:
		_sprite.rotation = 0.0
		_sprite.scale = Vector2(PLAYER_DISPLAY_SCALE, PLAYER_DISPLAY_SCALE)
		_sprite.modulate = Color.WHITE
	if _mounted_sprite != null:
		_mounted_sprite.rotation = 0.0
		_mounted_sprite.scale = Vector2.ONE * HORSE_VISUAL_SCALE
		_mounted_sprite.modulate = Color.WHITE
	_jump_assist.reset()
	_jump_cut_applied = false
	_air_time = 0.0
	_ground_time = 0.0
	_showing_run = false
	_showing_jump = false
	_end_climb()
	_climb_up_latched = false
	_nearby_ladders.clear()
	_invulnerable_remaining = respawn_invulnerability_time
	respawned.emit(world_position)


## Slow drop-back after losing a boss heart: float in from above with a long blink.
func play_boss_heart_recovery(world_position: Vector2, duration: float = 1.15) -> void:
	_ensure_jump_assist()
	_ensure_modes()
	input_enabled = false
	_is_canyon_falling = false
	collision_layer = 0
	velocity = Vector2.ZERO
	_jump_assist.reset()
	_jump_cut_applied = false
	var start := world_position + Vector2(0.0, -90.0)
	global_position = start
	if _sprite != null:
		_sprite.rotation = 0.0
		_sprite.scale = Vector2(PLAYER_DISPLAY_SCALE, PLAYER_DISPLAY_SCALE)
		_sprite.modulate = Color(1, 1, 1, 0.35)
	if _mounted_sprite != null and _mounted:
		_mounted_sprite.rotation = 0.0
		_mounted_sprite.scale = Vector2.ONE * HORSE_VISUAL_SCALE
		_mounted_sprite.modulate = Color(1, 1, 1, 0.35)
	var tween := create_tween()
	tween.tween_property(self, "global_position", world_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var blink: Tween = null
	var recovery_visual := _active_visual()
	if recovery_visual != null:
		# Slower blink than normal respawn.
		blink = create_tween()
		blink.set_loops(maxi(int(duration / 0.2), 5))
		blink.tween_property(recovery_visual, "modulate:a", 0.18, 0.1)
		blink.tween_property(recovery_visual, "modulate:a", 0.9, 0.1)
	await tween.finished
	if blink != null and blink.is_valid():
		blink.kill()
	collision_layer = 2
	if _sprite != null:
		_sprite.modulate = Color.WHITE
	if _mounted_sprite != null:
		_mounted_sprite.modulate = Color.WHITE
	_invulnerable_remaining = maxf(respawn_invulnerability_time, 1.15)
	input_enabled = true
	respawned.emit(world_position)


func play_canyon_fall() -> void:
	if _is_canyon_falling:
		return
	_is_canyon_falling = true
	input_enabled = false
	collision_layer = 0
	velocity = Vector2.ZERO
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y + 135.0, 0.55).set_trans(Tween.TRANS_QUAD)
	var visual := _active_visual()
	if visual != null:
		tween.tween_property(visual, "rotation", visual.rotation + TAU * 1.5, 0.55)
		tween.tween_property(visual, "scale", visual.scale * 0.15, 0.55)
		tween.tween_property(visual, "modulate:a", 0.25, 0.55)
	await tween.finished


func activate_mode(mode: ModeController.Mode, duration_override: float = 0.0, make_infinite: bool = false) -> void:
	_ensure_modes()
	_modes.activate(mode, duration_override, make_infinite)
	mode_changed.emit(ModeController.mode_name(mode), _modes.remaining)


func restore_mode(mode: ModeController.Mode, remaining: float, minimum_remaining: float = 20.0) -> void:
	_ensure_modes()
	_modes.restore(mode, remaining, minimum_remaining)


func clear_modes() -> void:
	_ensure_modes()
	_modes.clear()
	mode_changed.emit("None", 0.0)


func collect_star() -> void:
	collect_badges(1)


func collect_badges(amount: int) -> void:
	if amount <= 0:
		return
	stars_collected += amount
	_ensure_modes()
	for index in range(amount):
		_modes.extend_from_badge()
	star_collected.emit(stars_collected)


func bounce_from_hazard(from_world: Vector2, strength: float = 420.0) -> void:
	if _bounce_cooldown > 0.0:
		return
	_bounce_cooldown = 0.35
	var away := global_position - from_world
	if away.length_squared() < 0.01:
		away = Vector2(-_facing, 0.0)
	away.y = minf(away.y, -0.35)
	var dir := away.normalized()
	velocity = Vector2(dir.x * strength, minf(dir.y * strength * 0.85, -280.0))
	_invulnerable_remaining = maxf(_invulnerable_remaining, 0.45)



func get_modes() -> ModeController:
	_ensure_modes()
	return _modes


func _ensure_jump_assist() -> void:
	if _jump_assist == null:
		_jump_assist = JumpAssist.new(coyote_time, jump_buffer_time)


func _ensure_modes() -> void:
	if _modes == null:
		_modes = ModeController.new()
		_modes.mode_changed.connect(_on_mode_changed)


func _on_mode_changed(mode: ModeController.Mode, remaining: float) -> void:
	mode_changed.emit(ModeController.mode_name(mode), remaining)
	_refresh_mode_sprites()


func _on_player_settings_changed() -> void:
	var want_boots := _modes != null and _modes.active_mode == ModeController.Mode.MAGIC_BOOTS
	_setup_sprite_frames(want_boots)
	_refresh_mounted_horse_textures()


func _player_asset_folder() -> String:
	return GameManager.get_player_asset_folder()


func _setup_sprite_frames(use_magic_boots: bool) -> void:
	if _sprite == null:
		return
	var folder := _player_asset_folder()
	_player_character = GameManager.get_player_character()
	var frames := SpriteFrames.new()
	var suffix := "_boots" if use_magic_boots else ""
	_add_anim(frames, &"idle", ["idle_0%s.png" % suffix], 1.0, true, folder)
	_add_anim(
		frames,
		&"run",
		[
			"run_0%s.png" % suffix,
			"run_1%s.png" % suffix,
			"run_2%s.png" % suffix,
			"run_3%s.png" % suffix,
		],
		8.0,
		true,
		folder
	)
	_add_anim(frames, &"jump", ["jump%s.png" % suffix], 5.0, false, folder)
	_add_anim(
		frames,
		&"climb",
		["climb_0%s.png" % suffix, "climb_1%s.png" % suffix],
		8.0,
		true,
		folder
	)
	_add_anim(frames, &"celebrate", ["celebrate%s.png" % suffix], 5.0, true, folder)
	var previous := _sprite.animation
	_sprite.sprite_frames = frames
	_sprite.centered = true
	# Boots sit near the frame bottom. Offset is scaled with the sprite, so
	# -30 (not -46) plants soles on the collision floor at 1.5x scale.
	_sprite.offset = Vector2(0, -30)
	_sprite.scale = Vector2(PLAYER_DISPLAY_SCALE, PLAYER_DISPLAY_SCALE)
	_using_magic_boots_art = use_magic_boots
	if previous != StringName() and frames.has_animation(previous):
		_sprite.play(previous)
	else:
		_sprite.play(&"idle")


func _refresh_mode_sprites() -> void:
	var want_boots := _modes != null and _modes.active_mode == ModeController.Mode.MAGIC_BOOTS
	if want_boots != _using_magic_boots_art:
		_setup_sprite_frames(want_boots)


func _add_anim(
	frames: SpriteFrames,
	anim_name: StringName,
	files: Array,
	fps: float,
	loop: bool = true,
	folder: String = "res://assets/player/"
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for file_name in files:
		var texture: Texture2D = load("%s%s" % [folder, file_name])
		if texture != null:
			frames.add_frame(anim_name, texture)


func _refresh_mounted_horse_textures() -> void:
	if _mounted_sprite == null:
		return
	if _mounted and not is_on_floor():
		_mounted_sprite.texture = GameManager.get_mounted_horse_texture("jump")
	elif _mounted:
		_mounted_sprite.texture = GameManager.get_mounted_horse_texture("ride_0")


func _ensure_mounted_sprite() -> void:
	_mounted_sprite = get_node_or_null("MountedHorse") as Sprite2D
	if _mounted_sprite != null:
		return
	_mounted_sprite = Sprite2D.new()
	_mounted_sprite.name = "MountedHorse"
	_mounted_sprite.texture = GameManager.get_mounted_horse_texture("ride_0")
	_mounted_sprite.position = Vector2(0.0, -64.0)
	_mounted_sprite.scale = Vector2.ONE * HORSE_VISUAL_SCALE
	_mounted_sprite.z_index = 1
	_mounted_sprite.visible = false
	add_child(_mounted_sprite)


func _active_visual() -> Node2D:
	if _mounted and _mounted_sprite != null:
		return _mounted_sprite
	return _sprite


func _update_animation(on_floor: bool) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if absf(velocity.x) > 12.0:
		_facing = signf(velocity.x)
	_sprite.flip_h = _facing < 0.0
	if _mounted:
		_ensure_mounted_sprite()
		_sprite.visible = false
		_mounted_sprite.visible = true
		_mounted_sprite.flip_h = _facing < 0.0
		if not on_floor:
			_mounted_sprite.texture = GameManager.get_mounted_horse_texture("jump")
		elif absf(velocity.x) > 20.0:
			var gallop_frame := int(Time.get_ticks_msec() / 140) % 2
			_mounted_sprite.texture = (
				GameManager.get_mounted_horse_texture("ride_0")
				if gallop_frame == 0
				else GameManager.get_mounted_horse_texture("ride_1")
			)
		else:
			_mounted_sprite.texture = GameManager.get_mounted_horse_texture("ride_0")
		return
	_sprite.visible = true

	var next := _resolve_body_animation(on_floor)
	if _sprite.animation != next:
		_sprite.play(next)


func _resolve_body_animation(on_floor: bool) -> StringName:
	if _celebrating:
		return &"celebrate"
	if _climbing:
		_showing_jump = false
		_showing_run = false
		return &"climb"
	if _modes.is_flying():
		_showing_jump = true
		_showing_run = false
		return &"jump"
	if not on_floor:
		if _air_time >= JUMP_ANIM_AIR_TIME or _showing_jump:
			_showing_jump = true
			_showing_run = false
			return &"jump"
		# Brief floor-edge bumps: keep the last grounded pose until air time builds up.
		if _showing_run:
			return &"run"
		return &"idle"
	_showing_jump = false
	if _showing_run:
		if absf(velocity.x) <= RUN_SPEED_EXIT:
			_showing_run = false
	else:
		if absf(velocity.x) >= RUN_SPEED_ENTER and _ground_time >= 0.04:
			_showing_run = true
	return &"run" if _showing_run else &"idle"


func _update_mode_visual() -> void:
	if _sprite == null:
		return
	_refresh_mode_sprites()
	var color := Color(1, 1, 1, 1)
	if _modes.has_shield():
		color = Color(0.85, 0.97, 1.0, 1.0)
	elif _modes.is_flying():
		color = Color(0.92, 0.97, 1.0, 1.0)
	elif _modes.active_mode == ModeController.Mode.SPEED_STAR:
		color = Color(1.0, 0.92, 0.55, 1.0)
	elif _modes.active_mode == ModeController.Mode.MAGIC_BOOTS:
		color = Color(1, 1, 1, 1)
	if _invulnerable_remaining > 0.0:
		var blink := 0.35 + absf(sin(Time.get_ticks_msec() * 0.025)) * 0.65
		color.a = blink
	_sprite.modulate = color
	if _mounted_sprite != null:
		_mounted_sprite.modulate = color
	_update_shield_bubble()
	_update_wings()
	_update_boot_sparks()
	_update_land_squash(get_physics_process_delta_time())


func _on_landed() -> void:
	_land_squash = 0.18


func _update_land_squash(delta: float) -> void:
	if _sprite == null:
		return
	if _mounted and _mounted_sprite != null:
		if _land_squash > 0.0:
			_land_squash = maxf(_land_squash - delta, 0.0)
			var horse_t := 1.0 - (_land_squash / 0.18)
			var horse_y := lerpf(0.88, 1.0, horse_t)
			var horse_x := lerpf(1.10, 1.0, horse_t)
			_mounted_sprite.scale = Vector2(
				HORSE_VISUAL_SCALE * horse_x,
				HORSE_VISUAL_SCALE * horse_y
			)
		else:
			_mounted_sprite.scale = Vector2.ONE * HORSE_VISUAL_SCALE
		return
	if _land_squash > 0.0:
		_land_squash = maxf(_land_squash - delta, 0.0)
		var t := 1.0 - (_land_squash / 0.18)
		var y := lerpf(0.82, 1.0, t)
		var x := lerpf(1.18, 1.0, t)
		_sprite.scale = Vector2(PLAYER_DISPLAY_SCALE * x, PLAYER_DISPLAY_SCALE * y)
	elif _modes.is_flying():
		var flap := 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.04
		_sprite.scale = Vector2(PLAYER_DISPLAY_SCALE, PLAYER_DISPLAY_SCALE * flap)
	elif (
		not _mounted
		and _sprite.animation == &"idle"
		and is_on_floor()
		and absf(velocity.x) < RUN_SPEED_EXIT
	):
		var breathe := 1.0 + sin(Time.get_ticks_msec() * 0.0035) * 0.025
		_sprite.scale = Vector2(PLAYER_DISPLAY_SCALE, PLAYER_DISPLAY_SCALE * breathe)
	else:
		_sprite.scale = Vector2(PLAYER_DISPLAY_SCALE, PLAYER_DISPLAY_SCALE)


func _ensure_wings() -> void:
	_wing_sprite = get_node_or_null("WingArt") as Sprite2D
	if _wing_sprite != null:
		return
	_wing_sprite = Sprite2D.new()
	_wing_sprite.name = "WingArt"
	_wing_sprite.texture = load("res://assets/world/modes/wings.png")
	_wing_sprite.centered = true
	_wing_sprite.position = Vector2(0, -42)
	_wing_sprite.scale = Vector2(WING_BASE_SCALE, WING_BASE_SCALE)
	_wing_sprite.z_index = -1
	_wing_sprite.visible = false
	add_child(_wing_sprite)
	move_child(_wing_sprite, 0)


func _update_wings() -> void:
	_ensure_wings()
	if _wing_sprite == null:
		return
	var flying := _modes.is_flying() and not _mounted
	_wing_sprite.visible = flying
	if flying:
		var flap := 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.08
		_wing_sprite.scale = Vector2(WING_BASE_SCALE * flap, WING_BASE_SCALE / flap)
		_wing_sprite.rotation = sin(Time.get_ticks_msec() * 0.015) * 0.08
		_wing_sprite.flip_h = _facing < 0.0


func _update_boot_sparks() -> void:
	var spark := get_node_or_null("BootSpark") as ColorRect
	if _mounted or _modes.active_mode != ModeController.Mode.MAGIC_BOOTS:
		if spark != null:
			spark.visible = false
		return
	if spark == null:
		spark = ColorRect.new()
		spark.name = "BootSpark"
		spark.size = Vector2(22, 8)
		spark.position = Vector2(-11, -4)
		spark.color = Color(0.85, 0.45, 1.0, 0.8)
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(spark)
	spark.visible = true
	spark.modulate.a = 0.45 + absf(sin(Time.get_ticks_msec() * 0.02)) * 0.55
	spark.position.y = -4.0 + sin(Time.get_ticks_msec() * 0.03) * 2.0


func _ensure_shield_bubble() -> void:
	_shield_bubble = get_node_or_null("ShieldBubble") as BubbleForceField
	if _shield_bubble != null:
		return
	_shield_bubble = BubbleForceField.new()
	_shield_bubble.name = "ShieldBubble"
	_shield_bubble.position = Vector2(0, -34)
	_shield_bubble.scale = Vector2(0.88, 1.12)
	_shield_bubble.z_index = 2
	_shield_bubble.visible = false
	add_child(_shield_bubble)


func _update_shield_bubble() -> void:
	_ensure_shield_bubble()
	if _shield_bubble == null:
		return
	var show_bubble := _modes.has_shield()
	_shield_bubble.visible = show_bubble
	if show_bubble:
		_shield_bubble.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _spawn_dust_puff() -> void:
	var dust := ColorRect.new()
	dust.size = Vector2(28, 10)
	dust.position = Vector2(-14, -6)
	if _modes.active_mode == ModeController.Mode.SPEED_STAR:
		dust.color = Color(1.0, 0.85, 0.25, 0.8)
	elif _modes.active_mode == ModeController.Mode.MAGIC_BOOTS:
		dust.color = Color(0.85, 0.55, 1.0, 0.75)
	else:
		dust.color = Color(0.9, 0.75, 0.45, 0.7)
	dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dust)
	var tween := create_tween()
	tween.tween_property(dust, "modulate:a", 0.0, 0.28)
	tween.parallel().tween_property(dust, "position:y", -18.0, 0.28)
	tween.parallel().tween_property(dust, "size:x", 44.0, 0.28)
	tween.tween_callback(dust.queue_free)



func _apply_flight(delta: float) -> void:
	var input_axis := Input.get_axis(&"move_left", &"move_right")
	velocity.x = move_toward(
		velocity.x,
		input_axis * move_speed * _modes.move_speed_multiplier(),
		acceleration * delta
	)
	var rising := Input.is_action_pressed(&"jump")
	if rising and not is_on_ceiling():
		velocity.y = -fly_rise_speed
	else:
		# Always allow descent — never stay pinned under a flight ceiling.
		velocity.y = move_toward(velocity.y, fly_fall_speed, gravity * delta)
		if is_on_ceiling():
			velocity.y = maxf(velocity.y, fly_fall_speed * 0.85)
	# Soft screen-top clamp so Wings cannot wedge into solids above the camera.
	var min_y := -240.0
	if global_position.y < min_y:
		global_position.y = min_y
		if velocity.y < 0.0:
			velocity.y = 0.0


func _apply_gravity(delta: float, on_floor: bool) -> void:
	if on_floor and velocity.y > 0.0:
		velocity.y = 0.0
		return

	var gravity_force := gravity
	if velocity.y > 0.0:
		gravity_force *= fall_gravity_multiplier
	velocity.y = minf(velocity.y + gravity_force * delta, max_fall_speed)


func _apply_horizontal_movement(delta: float, on_floor: bool) -> void:
	var input_axis := Input.get_axis(&"move_left", &"move_right")
	var target_speed := input_axis * (
		move_speed * HORSE_JUMP_DISTANCE_MULTIPLIER
		if _mounted and not on_floor
		else get_run_speed()
	)

	if absf(input_axis) > 0.01:
		var accel := acceleration if on_floor else air_acceleration
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		if on_floor and _modes.active_mode == ModeController.Mode.SPEED_STAR and absf(velocity.x) > 180.0:
			if Engine.get_physics_frames() % 4 == 0:
				_spawn_dust_puff()
	else:
		var drag := friction if on_floor else air_friction
		velocity.x = move_toward(velocity.x, 0.0, drag * delta)


func _try_jump(on_floor: bool) -> void:
	if not _jump_assist.should_consume_buffered_jump(on_floor):
		return
	if _mounted:
		var jump_speed := move_speed * HORSE_JUMP_DISTANCE_MULTIPLIER
		velocity.x = clampf(velocity.x, -jump_speed, jump_speed)
	velocity.y = jump_velocity * _modes.jump_multiplier()
	AudioManager.play_sfx(&"jump")
	_jump_cut_applied = false
	_jump_assist.consume_jump()


func _cut_jump_if_released() -> void:
	if _jump_cut_applied or velocity.y >= 0.0:
		return
	if Input.is_action_pressed(&"jump"):
		return
	velocity.y *= jump_cut_multiplier
	_jump_cut_applied = true
