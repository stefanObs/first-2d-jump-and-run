class_name Player
extends CharacterBody2D

## Child-friendly platformer controller with forgiving jump assists and modes.

signal landed
signal respawned(position: Vector2)
signal mode_changed(mode_name: String, remaining: float)
signal star_collected(total: int)

@export var move_speed: float = 260.0
@export var acceleration: float = 1800.0
@export var air_acceleration: float = 1200.0
@export var friction: float = 2000.0
@export var air_friction: float = 400.0
@export var jump_velocity: float = -480.0
@export var gravity: float = 1400.0
@export var fall_gravity_multiplier: float = 1.35
@export var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var max_fall_speed: float = 900.0
@export var respawn_invulnerability_time: float = 0.6
@export var fly_rise_speed: float = 220.0
@export var fly_fall_speed: float = 160.0

var input_enabled: bool = true
var stars_collected: int = 0
var external_velocity: Vector2 = Vector2.ZERO

var _jump_assist: JumpAssist
var _modes: ModeController
var _was_on_floor: bool = false
var _jump_cut_applied: bool = false
var _invulnerable_remaining: float = 0.0
var _body_visual: ColorRect


func _ready() -> void:
	_ensure_jump_assist()
	_ensure_modes()
	_body_visual = get_node_or_null("Body") as ColorRect


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


func _update_mode_visual() -> void:
	if _body_visual == null:
		return
	if _modes.has_shield():
		_body_visual.color = Color(0.45, 0.85, 1.0, 1.0)
	elif _modes.is_flying():
		_body_visual.color = Color(0.75, 0.9, 1.0, 1.0)
	elif _modes.active_mode == ModeController.Mode.SPEED_STAR:
		_body_visual.color = Color(1.0, 0.85, 0.25, 1.0)
	elif _modes.active_mode == ModeController.Mode.MAGIC_BOOTS:
		_body_visual.color = Color(0.7, 0.45, 1.0, 1.0)
	else:
		_body_visual.color = Color(0.95, 0.55, 0.2, 1.0)


func _apply_flight(delta: float) -> void:
	var input_axis := Input.get_axis(&"move_left", &"move_right")
	velocity.x = move_toward(velocity.x, input_axis * move_speed * _modes.move_speed_multiplier(), acceleration * delta)
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
