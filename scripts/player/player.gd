class_name Player
extends CharacterBody2D

## Child-friendly platformer controller with forgiving jump assists.

signal landed

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

var _jump_assist: JumpAssist
var _was_on_floor: bool = false
var _jump_cut_applied: bool = false


func _ready() -> void:
	_jump_assist = JumpAssist.new(coyote_time, jump_buffer_time)


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	_jump_assist.notify_grounded(on_floor)
	_jump_assist.tick(delta)

	if Input.is_action_just_pressed(&"jump"):
		_jump_assist.notify_jump_pressed()

	_apply_gravity(delta, on_floor)
	_apply_horizontal_movement(delta, on_floor)
	_try_jump(on_floor)
	_cut_jump_if_released()

	move_and_slide()

	on_floor = is_on_floor()
	if on_floor and not _was_on_floor:
		landed.emit()
	_was_on_floor = on_floor


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
	var target_speed := input_axis * move_speed

	if absf(input_axis) > 0.01:
		var accel := acceleration if on_floor else air_acceleration
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		var drag := friction if on_floor else air_friction
		velocity.x = move_toward(velocity.x, 0.0, drag * delta)


func _try_jump(on_floor: bool) -> void:
	if not _jump_assist.should_consume_buffered_jump(on_floor):
		return
	velocity.y = jump_velocity
	_jump_cut_applied = false
	_jump_assist.consume_jump()


func _cut_jump_if_released() -> void:
	if _jump_cut_applied or velocity.y >= 0.0:
		return
	if Input.is_action_pressed(&"jump"):
		return
	velocity.y *= jump_cut_multiplier
	_jump_cut_applied = true


func get_jump_assist() -> JumpAssist:
	return _jump_assist
