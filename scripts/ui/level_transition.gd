class_name LevelTransition
extends CanvasLayer

## Cheerful celebration overlay shown after the goal is reached.

var _veil: ColorRect
var _banner: Label
var _subtitle: Label


func _ready() -> void:
	_veil = get_node_or_null("Veil") as ColorRect
	_banner = get_node_or_null("Banner") as Label
	_subtitle = get_node_or_null("Subtitle") as Label
	visible = false
	layer = 100


func play_celebration(message: String = "Yeehaw!") -> void:
	visible = true
	if _veil != null:
		_veil.color = Color(1.0, 0.72, 0.28, 0.0)
	if _banner != null:
		_banner.text = message
		_banner.modulate.a = 0.0
	if _subtitle != null:
		_subtitle.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	if _veil != null:
		tween.tween_property(_veil, "color:a", 0.62, 0.45)
	if _banner != null:
		tween.tween_property(_banner, "modulate:a", 1.0, 0.35)
	if _subtitle != null:
		tween.tween_property(_subtitle, "modulate:a", 1.0, 0.5)


func set_progress(progress: float) -> void:
	if not visible or _veil == null:
		return
	_veil.color = Color(
		lerpf(1.0, 0.98, progress),
		lerpf(0.72, 0.55, progress),
		lerpf(0.28, 0.85, progress),
		lerpf(0.62, 0.88, progress)
	)
