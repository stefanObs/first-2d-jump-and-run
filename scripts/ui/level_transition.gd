class_name LevelTransition
extends CanvasLayer

## Simple celebration overlay shown after the goal is reached.

var _veil: ColorRect
var _banner: Label


func _ready() -> void:
	_veil = get_node_or_null("Veil") as ColorRect
	_banner = get_node_or_null("Banner") as Label
	visible = false
	layer = 100


func play_celebration(message: String = "Great job!") -> void:
	visible = true
	if _veil != null:
		_veil.color = Color(0.2, 0.55, 1.0, 0.0)
	if _banner != null:
		_banner.text = message
		_banner.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	if _veil != null:
		tween.tween_property(_veil, "color:a", 0.55, 0.45)
	if _banner != null:
		tween.tween_property(_banner, "modulate:a", 1.0, 0.35)


func set_progress(progress: float) -> void:
	if not visible or _veil == null:
		return
	_veil.color = Color(
		lerpf(0.2, 0.95, progress),
		lerpf(0.55, 0.45, progress),
		lerpf(1.0, 0.75, progress),
		lerpf(0.55, 0.85, progress)
	)
