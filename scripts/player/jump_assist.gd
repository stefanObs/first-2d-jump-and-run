class_name JumpAssist
extends RefCounted

## Tracks coyote time and jump buffering for forgiving platform jumps.

var coyote_time: float
var jump_buffer_time: float

var _coyote_remaining: float = 0.0
var _buffer_remaining: float = 0.0


func _init(p_coyote_time: float = 0.12, p_jump_buffer_time: float = 0.12) -> void:
	coyote_time = p_coyote_time
	jump_buffer_time = p_jump_buffer_time


func reset() -> void:
	_coyote_remaining = 0.0
	_buffer_remaining = 0.0


func notify_grounded(is_on_floor: bool) -> void:
	if is_on_floor:
		_coyote_remaining = coyote_time


func notify_jump_pressed() -> void:
	_buffer_remaining = jump_buffer_time


func tick(delta: float) -> void:
	_coyote_remaining = maxf(_coyote_remaining - delta, 0.0)
	_buffer_remaining = maxf(_buffer_remaining - delta, 0.0)


func can_start_jump(is_on_floor: bool) -> bool:
	return is_on_floor or _coyote_remaining > 0.0


func should_consume_buffered_jump(is_on_floor: bool) -> bool:
	return _buffer_remaining > 0.0 and can_start_jump(is_on_floor)


func consume_jump() -> void:
	_coyote_remaining = 0.0
	_buffer_remaining = 0.0


func coyote_remaining() -> float:
	return _coyote_remaining


func buffer_remaining() -> float:
	return _buffer_remaining
