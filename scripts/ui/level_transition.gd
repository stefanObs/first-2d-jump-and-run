class_name LevelTransition
extends CanvasLayer

## Cowboy mounts his horse, rides out, then dismounts in the next level.

signal arrival_finished

const HORSE_TEXTURE := preload("res://assets/world/trail_horse.png")
const RIDE_TEXTURE_0 := preload("res://assets/world/cowboy_horse_ride_0.png")
const RIDE_TEXTURE_1 := preload("res://assets/world/cowboy_horse_ride_1.png")

var _veil: ColorRect
var _banner: Label
var _subtitle: Label
var _horse: Sprite2D
var _rider: Sprite2D
var _ride_phase: float = 0.0
var _arrival_active: bool = false


func _ready() -> void:
	_veil = get_node_or_null("Veil") as ColorRect
	_banner = get_node_or_null("Banner") as Label
	_subtitle = get_node_or_null("Subtitle") as Label
	_ensure_horse_art()
	_place_badge_labels()
	visible = false
	layer = 100


func _process(delta: float) -> void:
	if not visible or _rider == null or not _rider.visible:
		return
	_ride_phase += delta
	_rider.texture = RIDE_TEXTURE_0 if int(_ride_phase / 0.14) % 2 == 0 else RIDE_TEXTURE_1


func play_celebration(message: String = "Yeehaw!", stars: int = 0) -> void:
	_arrival_active = false
	visible = true
	_ensure_horse_art()
	var view_size := get_viewport().get_visible_rect().size
	if _veil != null:
		_veil.color = Color(1.0, 0.82, 0.48, 0.38)
	if _banner != null:
		_banner.text = message
		_banner.modulate.a = 1.0
	if _subtitle != null:
		_subtitle.text = "Badges found: %d" % stars
		_subtitle.modulate.a = 1.0
	_horse.visible = true
	_horse.modulate.a = 1.0
	_horse.position = Vector2(view_size.x + 180.0, view_size.y * 0.58)
	_rider.visible = false
	_rider.modulate.a = 0.0


func set_progress(progress: float) -> void:
	if not visible or _arrival_active:
		return
	_ensure_horse_art()
	var view_size := get_viewport().get_visible_rect().size
	var center := Vector2(view_size.x * 0.5, view_size.y * 0.58)
	if progress < 0.24:
		var arrival_ratio := progress / 0.24
		_horse.visible = true
		_horse.modulate.a = 1.0
		_horse.position = Vector2(lerpf(view_size.x + 180.0, center.x, arrival_ratio), center.y)
		_rider.visible = false
	elif progress < 0.38:
		var mount_ratio := (progress - 0.24) / 0.14
		_horse.visible = true
		_horse.position = center
		_horse.modulate.a = 1.0 - mount_ratio
		_rider.visible = true
		_rider.position = center
		_rider.modulate.a = mount_ratio
	else:
		var ride_ratio := (progress - 0.38) / 0.62
		_horse.visible = false
		_rider.visible = true
		_rider.modulate.a = 1.0
		_rider.position = Vector2(lerpf(center.x, view_size.x + 220.0, ride_ratio), center.y)
	if _veil != null:
		_veil.color.a = lerpf(0.38, 0.72, progress)


func play_arrival() -> void:
	_arrival_active = true
	visible = true
	_ensure_horse_art()
	_run_arrival()


func _run_arrival() -> void:
	var view_size := get_viewport().get_visible_rect().size
	var center := Vector2(view_size.x * 0.5, view_size.y * 0.58)
	if _veil != null:
		_veil.color = Color(1.0, 0.82, 0.48, 0.62)
	if _banner != null:
		_banner.text = "Next trail!"
		_banner.modulate.a = 1.0
	if _subtitle != null:
		_subtitle.text = "The cowboy rides in..."
		_subtitle.modulate.a = 1.0
	_horse.visible = false
	_rider.visible = true
	_rider.modulate.a = 1.0
	_rider.position = Vector2(-220.0, center.y)
	var ride_in := create_tween()
	ride_in.tween_property(_rider, "position", center, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await ride_in.finished
	_horse.visible = true
	_horse.position = center
	_horse.modulate.a = 0.0
	var dismount := create_tween()
	dismount.set_parallel(true)
	dismount.tween_property(_rider, "modulate:a", 0.0, 0.3)
	dismount.tween_property(_horse, "modulate:a", 1.0, 0.3)
	await dismount.finished
	_rider.visible = false
	if _subtitle != null:
		_subtitle.text = "Ready!"
	var horse_exit := create_tween()
	horse_exit.tween_interval(0.18)
	horse_exit.tween_property(_horse, "position:x", view_size.x + 220.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await horse_exit.finished
	visible = false
	_arrival_active = false
	arrival_finished.emit()


func _ensure_horse_art() -> void:
	if _horse == null:
		_horse = Sprite2D.new()
		_horse.name = "TrailHorse"
		_horse.texture = HORSE_TEXTURE
		_horse.scale = Vector2(0.82, 0.82)
		add_child(_horse)
	if _rider == null:
		_rider = Sprite2D.new()
		_rider.name = "CowboyHorse"
		_rider.texture = RIDE_TEXTURE_0
		_rider.scale = Vector2(0.82, 0.82)
		add_child(_rider)


func _place_badge_labels() -> void:
	if _banner != null:
		_banner.offset_top = -230.0
		_banner.offset_bottom = -150.0
		_banner.z_index = 5
	if _subtitle != null:
		_subtitle.offset_top = -145.0
		_subtitle.offset_bottom = -105.0
		_subtitle.z_index = 5
