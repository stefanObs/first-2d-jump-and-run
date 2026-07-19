class_name LevelCompletionFlow
extends RefCounted

## Tracks the short celebration that plays before the next level loads.

signal finished

var duration: float
var is_active: bool = false
var elapsed: float = 0.0


func _init(p_duration: float = 3.5) -> void:
	duration = p_duration


func start() -> void:
	is_active = true
	elapsed = 0.0


func tick(delta: float) -> bool:
	if not is_active:
		return false
	elapsed += delta
	if elapsed < duration:
		return false
	is_active = false
	finished.emit()
	return true


func progress() -> float:
	if duration <= 0.0:
		return 1.0
	return clampf(elapsed / duration, 0.0, 1.0)
