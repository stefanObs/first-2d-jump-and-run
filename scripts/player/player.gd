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
var _shield_bubble: ColorRect


func _ready() -> void:
	_ensure_jump_assist()
	_ensure_modes()
	_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_setup_sprite_frames()
	_ensure_shield_bubble()
	if _sprite != null:
		_sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	_ensure_jump_assist()
	_ensure_modes()
	_modes.tick(delta)
	if _invulnerable_remaining > 0.0:
		_invulnerable_remaining = maxf(_invulnerable_remaining - delta, 0.0)

	var on_floor := is_on_floor()
	_jump_assist.notify_grounded(on_floor)
	_jump_assist.tick(delta)

	if input_enabled and Input.is_action_just_pressed(&"jump"):
		_jump_assist.notify_jump_pressed()

	if _modes.is_flying() and input_enabled:
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
	if on_floor and not _was_on_floor:
		landed.emit()
	_was_on_floor = on_floor
	_update_animation(on_floor)
	_update_mode_visual()


func set_input_enabled(enabled: bool) -> void:
	_ensure_jump_assist()
	input_enabled = enabled
	if not enabled:
		velocity.x = 0.0
		_jump_assist.reset()


func is_invulnerable() -> bool:
	_ensure_modes()
	return _invulnerable_remaining > 0.0 or _modes.has_shield()


func respawn_at(world_position: Vector2) -> void:
	_ensure_jump_assist()
	_ensure_modes()
	global_position = world_position
	velocity = Vector2.ZERO
	_jump_assist.reset()
	_jump_cut_applied = false
	_invulnerable_remaining = respawn_invulnerability_time
	respawned.emit(world_position)


func activate_mode(mode: ModeController.Mode) -> void:
	_ensure_modes()
	_modes.activate(mode)
	mode_changed.emit(ModeController.mode_name(mode), _modes.remaining)


func clear_modes() -> void:
	_ensure_modes()
	_modes.clear()
	mode_changed.emit("None", 0.0)


func collect_star() -> void:
	stars_collected += 1
	star_collected.emit(stars_collected)


func get_jump_assist() -> JumpAssist:
	_ensure_jump_assist()
	return _jump_assist


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


func _setup_sprite_frames() -> void:
	if _sprite == null:
		return
	var frames := SpriteFrames.new()
	_add_anim(frames, &"idle", ["idle_0.png", "idle_1.png"], 4.0)
	_add_anim(frames, &"run", ["run_0.png", "run_1.png", "run_2.png", "run_3.png"], 10.0)
	_add_anim(frames, &"jump", ["jump.png"], 5.0, false)
	_sprite.sprite_frames = frames
	_sprite.centered = true
	_sprite.offset = Vector2(0, -32)
	_sprite.scale = Vector2(1.5, 1.5)


func _add_anim(
	frames: SpriteFrames,
	anim_name: StringName,
	files: Array,
	fps: float,
	loop: bool = true
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for file_name in files:
		var texture: Texture2D = load("res://assets/player/%s" % file_name)
		if texture != null:
			frames.add_frame(anim_name, texture)


func _update_animation(on_floor: bool) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if absf(velocity.x) > 12.0:
		_facing = signf(velocity.x)
	_sprite.flip_h = _facing < 0.0

	var next := &"idle"
	if not on_floor or _modes.is_flying():
		next = &"jump"
	elif absf(velocity.x) > 20.0:
		next = &"run"
	if _sprite.animation != next:
		_sprite.play(next)


func _update_mode_visual() -> void:
	if _sprite == null:
		return
	var color := Color(1, 1, 1, 1)
	if _modes.has_shield():
		color = Color(0.7, 0.95, 1.0, 1.0)
	elif _modes.is_flying():
		color = Color(0.85, 0.95, 1.0, 1.0)
	elif _modes.active_mode == ModeController.Mode.SPEED_STAR:
		color = Color(1.0, 0.92, 0.55, 1.0)
	elif _modes.active_mode == ModeController.Mode.MAGIC_BOOTS:
		color = Color(0.9, 0.75, 1.0, 1.0)
	if _invulnerable_remaining > 0.0:
		var blink := 0.35 + absf(sin(Time.get_ticks_msec() * 0.025)) * 0.65
		color.a = blink
	_sprite.modulate = color
	_update_shield_bubble()


func _ensure_shield_bubble() -> void:
	_shield_bubble = get_node_or_null("ShieldBubble") as ColorRect
	if _shield_bubble != null:
		return
	_shield_bubble = ColorRect.new()
	_shield_bubble.name = "ShieldBubble"
	_shield_bubble.size = Vector2(56, 64)
	_shield_bubble.position = Vector2(-28, -60)
	_shield_bubble.color = Color(0.35, 0.9, 1.0, 0.28)
	_shield_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_bubble.visible = false
	add_child(_shield_bubble)
	move_child(_shield_bubble, 0)


func _update_shield_bubble() -> void:
	_ensure_shield_bubble()
	if _shield_bubble == null:
		return
	var show_bubble := _modes.has_shield()
	_shield_bubble.visible = show_bubble
	if show_bubble:
		var pulse := 0.22 + absf(sin(Time.get_ticks_msec() * 0.008)) * 0.18
		_shield_bubble.color = Color(0.35, 0.9, 1.0, pulse)



func _apply_flight(delta: float) -> void:
	var input_axis := Input.get_axis(&"move_left", &"move_right")
	velocity.x = move_toward(
		velocity.x,
		input_axis * move_speed * _modes.move_speed_multiplier(),
		acceleration * delta
	)
	if Input.is_action_pressed(&"jump"):
		velocity.y = -fly_rise_speed
	else:
		velocity.y = move_toward(velocity.y, fly_fall_speed, gravity * delta)


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
	var target_speed := input_axis * move_speed * _modes.move_speed_multiplier()

	if absf(input_axis) > 0.01:
		var accel := acceleration if on_floor else air_acceleration
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		var drag := friction if on_floor else air_friction
		velocity.x = move_toward(velocity.x, 0.0, drag * delta)


func _try_jump(on_floor: bool) -> void:
	if not _jump_assist.should_consume_buffered_jump(on_floor):
		return
	velocity.y = jump_velocity * _modes.jump_multiplier()
	_jump_cut_applied = false
	_jump_assist.consume_jump()


func _cut_jump_if_released() -> void:
	if _jump_cut_applied or velocity.y >= 0.0:
		return
	if Input.is_action_pressed(&"jump"):
		return
	velocity.y *= jump_cut_multiplier
	_jump_cut_applied = true
