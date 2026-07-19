class_name LevelTransition
extends CanvasLayer

## Cheerful celebration overlay shown after the goal is reached.

var _veil: ColorRect
var _banner: Label
var _subtitle: Label
var _confetti: Array[ColorRect] = []


func _ready() -> void:
	_veil = get_node_or_null("Veil") as ColorRect
	_banner = get_node_or_null("Banner") as Label
	_subtitle = get_node_or_null("Subtitle") as Label
	visible = false
	layer = 100


func play_celebration(message: String = "Yeehaw!", stars: int = 0) -> void:
	visible = true
	if _veil != null:
		_veil.color = Color(1.0, 0.72, 0.28, 0.0)
	if _banner != null:
		_banner.text = message
		_banner.modulate.a = 0.0
		_banner.scale = Vector2(0.85, 0.85)
	if _subtitle != null:
		if stars > 0:
			_subtitle.text = "Badges found: %d" % stars
		else:
			_subtitle.text = "On to the next trail!"
		_subtitle.modulate.a = 0.0
	_spawn_confetti()
	var tween := create_tween()
	tween.set_parallel(true)
	if _veil != null:
		tween.tween_property(_veil, "color:a", 0.62, 0.45)
	if _banner != null:
		tween.tween_property(_banner, "modulate:a", 1.0, 0.35)
		tween.tween_property(_banner, "scale", Vector2(1.12, 1.12), 0.35)
	if _subtitle != null:
		tween.tween_property(_subtitle, "modulate:a", 1.0, 0.5)
	if _banner != null:
		tween.chain().tween_property(_banner, "scale", Vector2(1.0, 1.0), 0.2)


func set_progress(progress: float) -> void:
	if not visible or _veil == null:
		return
	_veil.color = Color(
		lerpf(1.0, 0.98, progress),
		lerpf(0.72, 0.55, progress),
		lerpf(0.28, 0.85, progress),
		lerpf(0.62, 0.88, progress)
	)
	_update_confetti(progress)


func _spawn_confetti() -> void:
	for old in _confetti:
		if is_instance_valid(old):
			old.queue_free()
	_confetti.clear()
	var colors := [
		Color(1.0, 0.35, 0.35, 1.0),
		Color(1.0, 0.85, 0.2, 1.0),
		Color(0.35, 0.8, 1.0, 1.0),
		Color(0.45, 0.9, 0.4, 1.0),
		Color(0.85, 0.45, 1.0, 1.0),
	]
	for i in range(18):
		var bit := ColorRect.new()
		bit.size = Vector2(10, 14)
		bit.position = Vector2(80.0 + float(i % 9) * 100.0, -20.0 - float(i % 5) * 18.0)
		bit.color = colors[i % colors.size()]
		bit.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bit.rotation = randf() * 0.8
		add_child(bit)
		_confetti.append(bit)


func _update_confetti(progress: float) -> void:
	for i in range(_confetti.size()):
		var bit := _confetti[i]
		if not is_instance_valid(bit):
			continue
		bit.position.y = -20.0 + progress * (420.0 + float(i % 7) * 35.0)
		bit.rotation += 0.03
		bit.modulate.a = 1.0 - progress * 0.35
