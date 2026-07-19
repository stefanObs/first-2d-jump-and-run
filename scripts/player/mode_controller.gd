class_name ModeController
extends RefCounted

## Timed player power-ups collected from mode items.

enum Mode { NONE, WINGS, MAGIC_BOOTS, SPEED_STAR, BUBBLE_SHIELD }

signal mode_changed(mode: Mode, remaining: float)

var active_mode: Mode = Mode.NONE
var remaining: float = 0.0

var wings_duration: float = 12.0
var boots_duration: float = 10.0
var speed_duration: float = 8.0
var shield_duration: float = 8.0


func activate(mode: Mode) -> void:
	active_mode = mode
	match mode:
		Mode.WINGS:
			remaining = wings_duration
		Mode.MAGIC_BOOTS:
			remaining = boots_duration
		Mode.SPEED_STAR:
			remaining = speed_duration
		Mode.BUBBLE_SHIELD:
			remaining = shield_duration
		_:
			remaining = 0.0
	mode_changed.emit(active_mode, remaining)


func clear() -> void:
	active_mode = Mode.NONE
	remaining = 0.0
	mode_changed.emit(active_mode, remaining)


func tick(delta: float) -> void:
	if active_mode == Mode.NONE:
		return
	remaining = maxf(remaining - delta, 0.0)
	if remaining <= 0.0:
		clear()
	else:
		mode_changed.emit(active_mode, remaining)


func has_shield() -> bool:
	return active_mode == Mode.BUBBLE_SHIELD


func move_speed_multiplier() -> float:
	return 1.45 if active_mode == Mode.SPEED_STAR else 1.0


func jump_multiplier() -> float:
	return 1.45 if active_mode == Mode.MAGIC_BOOTS else 1.0


func is_flying() -> bool:
	return active_mode == Mode.WINGS


static func mode_name(mode: Mode) -> String:
	match mode:
		Mode.WINGS:
			return "Wings"
		Mode.MAGIC_BOOTS:
			return "Magic Boots"
		Mode.SPEED_STAR:
			return "Speed Star"
		Mode.BUBBLE_SHIELD:
			return "Bubble Shield"
		_:
			return "None"


static func mode_name_kid(mode: Mode) -> String:
	match mode:
		Mode.WINGS:
			return "Fly high!"
		Mode.MAGIC_BOOTS:
			return "Super jump!"
		Mode.SPEED_STAR:
			return "Zoom!"
		Mode.BUBBLE_SHIELD:
			return "Safe bubble!"
		_:
			return ""


static func mode_toast(mode: Mode) -> String:
	return mode_name_kid(mode)
