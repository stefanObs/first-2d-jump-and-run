class_name LevelTransition
extends CanvasLayer

## Horse rides in from the left; cowboy leaves the saloon and mounts for the trail.

signal arrival_finished

const HORSE_TEXTURE := preload("res://assets/world/trail_horse.png")
const RIDE_TEXTURE_0 := preload("res://assets/world/cowboy_horse_ride_0.png")
const RIDE_TEXTURE_1 := preload("res://assets/world/cowboy_horse_ride_1.png")
const SALOON_TEXTURE := preload("res://assets/world/goal_saloon.png")

var _veil: ColorRect
var _banner: Label
var _subtitle: Label
var _horse: Sprite2D
var _rider: Sprite2D
var _cowboy: Sprite2D
var _saloon: Sprite2D
var _ride_phase: float = 0.0
var _arrival_active: bool = false
var _animating_rider: bool = false


func _ready() -> void:
	_veil = get_node_or_null("Veil") as ColorRect
	_banner = get_node_or_null("Banner") as Label
	_subtitle = get_node_or_null("Subtitle") as Label
	_ensure_horse_art()
	_place_badge_labels()
	visible = false
	layer = 100


func _process(delta: float) -> void:
	if not visible or not _animating_rider or _rider == null or not _rider.visible:
		return
	_ride_phase += delta
	_rider.texture = RIDE_TEXTURE_0 if int(_ride_phase / 0.14) % 2 == 0 else RIDE_TEXTURE_1


func play_celebration(message: String = "Yeehaw!", stars: int = 0) -> void:
	_arrival_active = false
	_animating_rider = false
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
	var ground_y := view_size.y * 0.64
	var saloon_x := view_size.x * 0.70
	# Saloon sits on the boardwalk; cowboy starts centered on the doorway.
	_saloon.visible = true
	_saloon.modulate.a = 1.0
	_saloon.position = Vector2(saloon_x, ground_y - 8.0)
	_horse.visible = true
	_horse.modulate.a = 1.0
	_horse.flip_h = false
	_horse.position = Vector2(-220.0, ground_y)
	_cowboy.visible = true
	_cowboy.modulate.a = 1.0
	_cowboy.position = Vector2(saloon_x, ground_y - 42.0)
	_cowboy.scale = Vector2(1.55, 1.55)
	_rider.visible = false
	_rider.modulate.a = 0.0


func set_progress(progress: float) -> void:
	if not visible or _arrival_active:
		return
	_ensure_horse_art()
	var view_size := get_viewport().get_visible_rect().size
	var ground_y := view_size.y * 0.64
	var saloon_x := view_size.x * 0.70
	var door_x := saloon_x
	var mount_x := view_size.x * 0.40
	_saloon.position = Vector2(saloon_x, ground_y - 8.0)
	if progress < 0.28:
		var arrival_ratio := progress / 0.28
		_horse.visible = true
		_horse.modulate.a = 1.0
		_horse.position = Vector2(lerpf(-220.0, mount_x, arrival_ratio), ground_y)
		_cowboy.visible = true
		_cowboy.modulate.a = 1.0
		_cowboy.position = Vector2(door_x, ground_y - 42.0)
		_rider.visible = false
		_animating_rider = false
	elif progress < 0.48:
		var mount_ratio := (progress - 0.28) / 0.20
		_horse.visible = true
		_horse.position = Vector2(mount_x, ground_y)
		_horse.modulate.a = 1.0
		var jump_y := ground_y - 42.0 - sin(mount_ratio * PI) * 78.0
		_cowboy.visible = true
		_cowboy.position = Vector2(lerpf(door_x, mount_x + 6.0, mount_ratio), jump_y)
		_cowboy.modulate.a = 1.0 - mount_ratio
		_rider.visible = mount_ratio > 0.55
		_rider.position = Vector2(mount_x, ground_y)
		_rider.modulate.a = clampf((mount_ratio - 0.55) / 0.45, 0.0, 1.0)
		_animating_rider = _rider.visible
	else:
		var ride_ratio := (progress - 0.48) / 0.52
		_horse.visible = false
		_cowboy.visible = false
		_rider.visible = true
		_rider.modulate.a = 1.0
		_rider.position = Vector2(lerpf(mount_x, view_size.x + 240.0, ride_ratio), ground_y)
		_animating_rider = true
	if _veil != null:
		_veil.color.a = lerpf(0.38, 0.72, progress)

func play_arrival() -> void:
	_arrival_active = true
	visible = true
	_ensure_horse_art()
	_run_arrival()


func _run_arrival() -> void:
	var view_size := get_viewport().get_visible_rect().size
	var ground_y := view_size.y * 0.62
	var center := Vector2(view_size.x * 0.45, ground_y)
	if _veil != null:
		_veil.color = Color(1.0, 0.82, 0.48, 0.62)
	if _banner != null:
		_banner.text = "Next trail!"
		_banner.modulate.a = 1.0
	if _subtitle != null:
		_subtitle.text = "The cowboy rides in..."
		_subtitle.modulate.a = 1.0
	_saloon.visible = false
	_cowboy.visible = false
	_horse.visible = false
	_rider.visible = true
	_rider.modulate.a = 1.0
	_rider.position = Vector2(-240.0, ground_y)
	_animating_rider = true
	var ride_in := create_tween()
	ride_in.tween_property(_rider, "position", center, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await ride_in.finished
	_horse.visible = true
	_horse.position = center
	_horse.modulate.a = 0.0
	_cowboy.visible = true
	_cowboy.position = center + Vector2(8.0, -36.0)
	_cowboy.modulate.a = 0.0
	var dismount := create_tween()
	dismount.set_parallel(true)
	dismount.tween_property(_rider, "modulate:a", 0.0, 0.28)
	dismount.tween_property(_horse, "modulate:a", 1.0, 0.28)
	dismount.tween_property(_cowboy, "modulate:a", 1.0, 0.28)
	await dismount.finished
	_rider.visible = false
	_animating_rider = false
	if _subtitle != null:
		_subtitle.text = "Ready!"
	var horse_exit := create_tween()
	horse_exit.tween_interval(0.18)
	horse_exit.set_parallel(true)
	horse_exit.tween_property(_horse, "position:x", view_size.x + 240.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	horse_exit.tween_property(_cowboy, "modulate:a", 0.0, 0.35)
	await horse_exit.finished
	visible = false
	_arrival_active = false
	arrival_finished.emit()


func _ensure_horse_art() -> void:
	if _saloon == null:
		_saloon = Sprite2D.new()
		_saloon.name = "CelebrationSaloon"
		_saloon.texture = SALOON_TEXTURE
		_saloon.scale = Vector2(1.55, 1.55)
		_saloon.z_index = 1
		add_child(_saloon)
	if _horse == null:
		_horse = Sprite2D.new()
		_horse.name = "TrailHorse"
		_horse.texture = HORSE_TEXTURE
		_horse.scale = Vector2(0.82, 0.82)
		_horse.z_index = 2
		add_child(_horse)
	if _cowboy == null:
		_cowboy = Sprite2D.new()
		_cowboy.name = "CelebrationCowboy"
		_cowboy.z_index = 3
		add_child(_cowboy)
		_load_cowboy_idle_texture()
	if _rider == null:
		_rider = Sprite2D.new()
		_rider.name = "CowboyHorse"
		_rider.texture = RIDE_TEXTURE_0
		_rider.scale = Vector2(0.82, 0.82)
		_rider.z_index = 4
		add_child(_rider)


func _load_cowboy_idle_texture() -> void:
	var walk: Texture2D = load("res://assets/player/idle_0.png")
	if walk == null:
		walk = load("res://assets/player/run_0.png")
	if walk != null:
		_cowboy.texture = walk
		_cowboy.scale = Vector2(1.55, 1.55)
	else:
		_cowboy.texture = RIDE_TEXTURE_0
		_cowboy.scale = Vector2(0.55, 0.55)


func _place_badge_labels() -> void:
	if _banner != null:
		_banner.offset_top = -230.0
		_banner.offset_bottom = -150.0
		_banner.z_index = 5
	if _subtitle != null:
		_subtitle.offset_top = -145.0
		_subtitle.offset_bottom = -105.0
		_subtitle.z_index = 5
