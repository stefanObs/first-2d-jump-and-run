class_name LevelTransition
extends CanvasLayer

## Transparent overlay: cowboy leaves the finished trail's saloon and rides onward.

signal arrival_finished

const HORSE_TEXTURE := preload("res://assets/world/trail_horse.png")
const RIDE_TEXTURE_0 := preload("res://assets/world/cowboy_horse_ride_0.png")
const RIDE_TEXTURE_1 := preload("res://assets/world/cowboy_horse_ride_1.png")
const SALOON_TEXTURE := preload("res://assets/world/goal_saloon.png")
const SALOON_CENTER_ABOVE_PLANK := 92.0
const TRANSITION_GROUND_RATIO := 0.69
## Cowboy stands this far below the saloon sprite center (doorway / boardwalk).
const COWBOY_BELOW_SALOON := 50.0
## Horse mounts just left of the doorway, then rides off-screen.
const MOUNT_LEFT_OF_DOOR := 36.0
const HORSE_APPROACH_DISTANCE := 280.0

var _veil: ColorRect
var _skyline: TextureRect
var _banner: Label
var _subtitle: Label
var _horse: Sprite2D
var _rider: Sprite2D
var _cowboy: Sprite2D
var _saloon: Sprite2D
var _ride_phase: float = 0.0
var _arrival_active: bool = false
var _animating_rider: bool = false
var _saloon_screen_pos: Vector2 = Vector2.ZERO
var _has_saloon_anchor: bool = false
## True when the finished level's Goal saloon is still visible behind us.
var _uses_live_level_saloon: bool = false


func _ready() -> void:
	_veil = get_node_or_null("Veil") as ColorRect
	_skyline = get_node_or_null("HandmadeSkyline") as TextureRect
	_banner = get_node_or_null("Banner") as Label
	_subtitle = get_node_or_null("Subtitle") as Label
	_ensure_horse_art()
	_place_badge_labels()
	_apply_transparent_backdrop()
	visible = false
	layer = 100


func _process(delta: float) -> void:
	if not visible or not _animating_rider or _rider == null or not _rider.visible:
		return
	_ride_phase += delta
	_rider.texture = RIDE_TEXTURE_0 if int(_ride_phase / 0.14) % 2 == 0 else RIDE_TEXTURE_1


func play_celebration(
	message: String = "Yeehaw!",
	stars: int = 0,
	saloon_screen_position: Vector2 = Vector2.INF
) -> void:
	_arrival_active = false
	_animating_rider = false
	visible = true
	_ensure_horse_art()
	_apply_transparent_backdrop()
	var view_size := get_viewport().get_visible_rect().size
	if _banner != null:
		_banner.text = tr(message)
		_banner.modulate.a = 1.0
	if _subtitle != null:
		_subtitle.text = tr("Badges found: %d") % stars
		_subtitle.modulate.a = 1.0
	if _banner != null and _subtitle != null:
		Narrator.speak("%s %s" % [_banner.text, _subtitle.text])
	_resolve_saloon_anchor(view_size, saloon_screen_position)
	var ground_y := _ground_y_for_saloon()
	var door_pos := _cowboy_door_position()
	# Keep the finished trail visible; only draw a fallback saloon when no live Goal exists.
	_saloon.visible = not _uses_live_level_saloon
	_saloon.modulate.a = 1.0
	_saloon.position = _saloon_screen_pos
	_horse.visible = true
	_horse.modulate.a = 1.0
	_horse.flip_h = false
	_horse.position = Vector2(_horse_start_x(), ground_y)
	_cowboy.visible = true
	_cowboy.modulate.a = 1.0
	_cowboy.position = door_pos
	_cowboy.scale = Vector2(1.55, 1.55)
	_rider.visible = false
	_rider.modulate.a = 0.0


func set_progress(progress: float) -> void:
	if not visible or _arrival_active:
		return
	_ensure_horse_art()
	_apply_transparent_backdrop()
	var view_size := get_viewport().get_visible_rect().size
	var ground_y := _ground_y_for_saloon()
	var door_pos := _cowboy_door_position()
	var mount_x := _mount_x()
	_saloon.position = _saloon_screen_pos
	_saloon.visible = not _uses_live_level_saloon
	if progress < 0.28:
		var arrival_ratio := progress / 0.28
		_horse.visible = true
		_horse.modulate.a = 1.0
		_horse.position = Vector2(lerpf(_horse_start_x(), mount_x, arrival_ratio), ground_y)
		_cowboy.visible = true
		_cowboy.modulate.a = 1.0
		_cowboy.position = door_pos
		_rider.visible = false
		_animating_rider = false
	elif progress < 0.48:
		var mount_ratio := (progress - 0.28) / 0.20
		_horse.visible = true
		_horse.position = Vector2(mount_x, ground_y)
		_horse.modulate.a = 1.0
		var jump_y := door_pos.y - sin(mount_ratio * PI) * 78.0
		_cowboy.visible = true
		_cowboy.position = Vector2(lerpf(door_pos.x, mount_x + 6.0, mount_ratio), jump_y)
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


func play_arrival() -> void:
	_arrival_active = true
	visible = true
	_ensure_horse_art()
	_apply_transparent_backdrop()
	_run_arrival()


func _resolve_saloon_anchor(view_size: Vector2, saloon_screen_position: Vector2) -> void:
	if saloon_screen_position != Vector2.INF and saloon_screen_position.is_finite():
		_saloon_screen_pos = saloon_screen_position
		_has_saloon_anchor = true
		_uses_live_level_saloon = true
		return
	if _has_saloon_anchor:
		return
	# Fallback when no goal position was passed (tests / custom callers).
	var ground_y := view_size.y * TRANSITION_GROUND_RATIO
	_saloon_screen_pos = Vector2(view_size.x * 0.70, ground_y - SALOON_CENTER_ABOVE_PLANK)
	_has_saloon_anchor = true
	_uses_live_level_saloon = false


func _ground_y_for_saloon() -> float:
	return _saloon_screen_pos.y + SALOON_CENTER_ABOVE_PLANK


func _cowboy_door_position() -> Vector2:
	return _saloon_screen_pos + Vector2(0.0, COWBOY_BELOW_SALOON)


func _mount_x() -> float:
	return _cowboy_door_position().x - MOUNT_LEFT_OF_DOOR


func _horse_start_x() -> float:
	return _mount_x() - HORSE_APPROACH_DISTANCE


func get_saloon_screen_position() -> Vector2:
	return _saloon_screen_pos


func uses_live_level_saloon() -> bool:
	return _uses_live_level_saloon


func _apply_transparent_backdrop() -> void:
	if _skyline != null:
		_skyline.visible = false
		_skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _veil != null:
		# Fully transparent input blocker so the finished (or next) level stays visible.
		_veil.color = Color(0.0, 0.0, 0.0, 0.0)
		_veil.mouse_filter = Control.MOUSE_FILTER_STOP


func _run_arrival() -> void:
	var view_size := get_viewport().get_visible_rect().size
	var ground_y := view_size.y * TRANSITION_GROUND_RATIO
	var center := Vector2(view_size.x * 0.45, ground_y)
	_apply_transparent_backdrop()
	if _banner != null:
		_banner.text = tr("Next trail!")
		_banner.modulate.a = 1.0
	if _subtitle != null:
		_subtitle.text = tr("The cowboy rides in...")
		_subtitle.modulate.a = 1.0
	if _banner != null and _subtitle != null:
		Narrator.speak("%s %s" % [_banner.text, _subtitle.text])
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
		_subtitle.text = tr("Ready!")
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
