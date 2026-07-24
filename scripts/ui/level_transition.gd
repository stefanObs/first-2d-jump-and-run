class_name LevelTransition
extends CanvasLayer

## Transparent overlay: cowboy leaves the finished trail's saloon and rides onward.

signal arrival_finished

const HORSE_TEXTURE := preload("res://assets/world/trail_horse.png")
const HORSE_GALLOP_0 := preload("res://assets/world/trail_horse_gallop_0.png")
const HORSE_GALLOP_1 := preload("res://assets/world/trail_horse_gallop_1.png")
const RIDE_TEXTURE_0 := preload("res://assets/world/cowboy_horse_ride_0.png")
const RIDE_TEXTURE_1 := preload("res://assets/world/cowboy_horse_ride_1.png")
const SALOON_TEXTURE := preload("res://assets/world/goal_saloon.png")
## Screen-space fallback when no goal/floor anchor exists (tuned for default trail zoom).
const SALOON_CENTER_ABOVE_PLANK := 92.0
const TRANSITION_GROUND_RATIO := 0.69
## Cowboy stands this far below the saloon sprite center (doorway / boardwalk).
const COWBOY_BELOW_SALOON := 50.0
## Horse mounts just left of the doorway, then rides off-screen.
const MOUNT_LEFT_OF_DOOR := 36.0
const HORSE_APPROACH_DISTANCE := 280.0
## Matches Player MountedHorse local Y so hooves sit on the trail floor.
const MOUNTED_SPRITE_OFFSET_Y := -64.0
const PLAYER_IDLE_SCALE := 1.35
const GOAL_SALOON_WORLD_SCALE := 1.85
const GALLOP_FRAME_TIME := 0.14

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
var _animating_empty_horse: bool = false
var _saloon_screen_pos: Vector2 = Vector2.ZERO
var _has_saloon_anchor: bool = false
## True when the finished level's Goal saloon is still visible behind us.
var _uses_live_level_saloon: bool = false
var _floor_screen_y: float = 0.0
var _has_floor_baseline: bool = false
## Next-trail spawn where the cowboy dismounts and leaves the horse.
var _spawn_screen_pos: Vector2 = Vector2.ZERO
var _has_spawn_anchor: bool = false
## Canvas/camera scale so overlay sprites match in-world gameplay size.
var _world_to_screen_scale: float = 1.0


func _ready() -> void:
	_veil = get_node_or_null("Veil") as ColorRect
	_skyline = get_node_or_null("HandmadeSkyline") as TextureRect
	_banner = get_node_or_null("Banner") as Label
	_subtitle = get_node_or_null("Subtitle") as Label
	_ensure_horse_art()
	_place_badge_labels()
	_apply_transparent_backdrop()
	hide_overlay()
	layer = 100


func _process(delta: float) -> void:
	if not visible:
		return
	if _animating_rider and _rider != null and _rider.visible:
		_ride_phase += delta
		_rider.texture = RIDE_TEXTURE_0 if int(_ride_phase / GALLOP_FRAME_TIME) % 2 == 0 else RIDE_TEXTURE_1
		return
	if _animating_empty_horse and _horse != null and _horse.visible:
		_ride_phase += delta
		_horse.texture = HORSE_GALLOP_0 if int(_ride_phase / GALLOP_FRAME_TIME) % 2 == 0 else HORSE_GALLOP_1
		# Soft hoof bob so the empty gallop reads as motion, not a slide.
		var bob := sin(_ride_phase * TAU / (GALLOP_FRAME_TIME * 2.0)) * 3.0 * _world_to_screen_scale
		_horse.position.y = _ride_center_y() + bob


func play_celebration(
	message: String = "Yeehaw!",
	stars: int = 0,
	saloon_screen_position: Vector2 = Vector2.INF,
	floor_screen_y: float = INF,
	world_to_screen_scale: float = INF
) -> void:
	_arrival_active = false
	_animating_rider = false
	_animating_empty_horse = false
	_ride_phase = 0.0
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
	_resolve_presentation(view_size, saloon_screen_position, floor_screen_y, world_to_screen_scale)
	_apply_ride_scales()
	var ride_y := _ride_center_y()
	var door_pos := _cowboy_door_position()
	# Keep the finished trail visible; only draw a fallback saloon when no live Goal exists.
	_saloon.visible = not _uses_live_level_saloon
	_saloon.modulate.a = 1.0
	_saloon.position = _saloon_screen_pos
	_horse.visible = true
	_horse.modulate.a = 1.0
	_horse.flip_h = false
	_horse.texture = HORSE_GALLOP_0
	_horse.position = Vector2(_horse_start_x(), ride_y)
	_animating_empty_horse = true
	_cowboy.visible = true
	_cowboy.modulate.a = 1.0
	_cowboy.position = door_pos
	_rider.visible = false
	_rider.modulate.a = 0.0


func set_progress(progress: float) -> void:
	if not visible or _arrival_active:
		return
	_ensure_horse_art()
	_apply_transparent_backdrop()
	_apply_ride_scales()
	var view_size := get_viewport().get_visible_rect().size
	var ride_y := _ride_center_y()
	var door_pos := _cowboy_door_position()
	var mount_x := _mount_x()
	_saloon.position = _saloon_screen_pos
	_saloon.visible = not _uses_live_level_saloon
	if progress < 0.28:
		var arrival_ratio := progress / 0.28
		_horse.visible = true
		_horse.modulate.a = 1.0
		_horse.position.x = lerpf(_horse_start_x(), mount_x, arrival_ratio)
		# Y bob is applied in _process while the empty horse gallops.
		if not _animating_empty_horse:
			_horse.position.y = ride_y
		_animating_empty_horse = true
		_cowboy.visible = true
		_cowboy.modulate.a = 1.0
		_cowboy.position = door_pos
		_rider.visible = false
		_animating_rider = false
	elif progress < 0.48:
		var mount_ratio := (progress - 0.28) / 0.20
		_set_empty_horse_idle(Vector2(mount_x, ride_y))
		var jump_y := door_pos.y - sin(mount_ratio * PI) * 78.0 * _world_to_screen_scale
		_cowboy.visible = true
		_cowboy.position = Vector2(lerpf(door_pos.x, mount_x + 6.0, mount_ratio), jump_y)
		_cowboy.modulate.a = 1.0 - mount_ratio
		_rider.visible = mount_ratio > 0.55
		_rider.position = Vector2(mount_x, ride_y)
		_rider.modulate.a = clampf((mount_ratio - 0.55) / 0.45, 0.0, 1.0)
		_animating_rider = _rider.visible
		if _rider.visible:
			_horse.visible = false
	else:
		var ride_ratio := (progress - 0.48) / 0.52
		_horse.visible = false
		_animating_empty_horse = false
		_cowboy.visible = false
		_rider.visible = true
		_rider.modulate.a = 1.0
		_rider.position = Vector2(lerpf(mount_x, view_size.x + 240.0, ride_ratio), ride_y)
		_animating_rider = true


func _set_empty_horse_idle(pos: Vector2) -> void:
	_animating_empty_horse = false
	if _horse == null:
		return
	_horse.visible = true
	_horse.texture = HORSE_TEXTURE
	_horse.position = pos
	_horse.modulate.a = 1.0


func play_arrival(
	spawn_screen_position: Vector2 = Vector2.INF,
	floor_screen_y: float = INF,
	world_to_screen_scale: float = INF
) -> void:
	_arrival_active = true
	visible = true
	_ensure_horse_art()
	_apply_transparent_backdrop()
	_animating_empty_horse = false
	_animating_rider = false
	_ride_phase = 0.0
	if is_finite(world_to_screen_scale) and world_to_screen_scale > 0.0:
		_world_to_screen_scale = world_to_screen_scale
	else:
		_world_to_screen_scale = _detect_world_to_screen_scale()
	if is_finite(floor_screen_y):
		_floor_screen_y = floor_screen_y
		_has_floor_baseline = true
	else:
		_has_floor_baseline = false
	if spawn_screen_position != Vector2.INF and spawn_screen_position.is_finite():
		_spawn_screen_pos = spawn_screen_position
		_has_spawn_anchor = true
	else:
		_has_spawn_anchor = false
	_apply_ride_scales()
	_run_arrival()


func get_spawn_screen_position() -> Vector2:
	return _spawn_screen_pos


func leaves_horse_at_spawn() -> bool:
	## Arrival ends with the empty horse still at the level start, not ridden away.
	return (
		_horse != null
		and _horse.visible
		and _has_spawn_anchor
		and absf(_horse.position.x - _spawn_screen_pos.x) <= 2.0
	)


func is_empty_horse_galloping() -> bool:
	## Riderless approach uses dedicated gallop frames (not the standing trail horse).
	return (
		_animating_empty_horse
		and _horse != null
		and _horse.visible
		and (_horse.texture == HORSE_GALLOP_0 or _horse.texture == HORSE_GALLOP_1)
	)

func _resolve_presentation(
	view_size: Vector2,
	saloon_screen_position: Vector2,
	floor_screen_y: float,
	world_to_screen_scale: float
) -> void:
	_resolve_saloon_anchor(view_size, saloon_screen_position)
	if is_finite(world_to_screen_scale) and world_to_screen_scale > 0.0:
		_world_to_screen_scale = world_to_screen_scale
	else:
		_world_to_screen_scale = _detect_world_to_screen_scale()
	if is_finite(floor_screen_y):
		_floor_screen_y = floor_screen_y
		_has_floor_baseline = true
	else:
		_has_floor_baseline = false
		_floor_screen_y = _saloon_screen_pos.y + SALOON_CENTER_ABOVE_PLANK


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


func _detect_world_to_screen_scale() -> float:
	var canvas := get_viewport().get_canvas_transform()
	var scale := canvas.get_scale()
	if absf(scale.y) > 0.001:
		return absf(scale.y)
	if absf(scale.x) > 0.001:
		return absf(scale.x)
	return 1.0


func _ground_y() -> float:
	if _has_floor_baseline:
		return _floor_screen_y
	return _saloon_screen_pos.y + SALOON_CENTER_ABOVE_PLANK


func _ride_center_y() -> float:
	## Sprite center sits above the feet baseline, matching MountedHorse.
	return _ground_y() + MOUNTED_SPRITE_OFFSET_Y * _world_to_screen_scale


func _ride_visual_scale() -> float:
	return Player.HORSE_VISUAL_SCALE * _world_to_screen_scale


func _cowboy_visual_scale() -> float:
	return PLAYER_IDLE_SCALE * _world_to_screen_scale


func _cowboy_door_position() -> Vector2:
	return _saloon_screen_pos + Vector2(0.0, COWBOY_BELOW_SALOON)


func _mount_x() -> float:
	return _cowboy_door_position().x - MOUNT_LEFT_OF_DOOR


func _horse_start_x() -> float:
	return _mount_x() - HORSE_APPROACH_DISTANCE


func get_saloon_screen_position() -> Vector2:
	return _saloon_screen_pos


func get_floor_screen_y() -> float:
	return _ground_y()


func get_ride_center_y() -> float:
	return _ride_center_y()


func get_ride_visual_scale() -> float:
	return _ride_visual_scale()


func uses_live_level_saloon() -> bool:
	return _uses_live_level_saloon


func _apply_ride_scales() -> void:
	var horse_scale := Vector2.ONE * _ride_visual_scale()
	var cowboy_scale := Vector2.ONE * _cowboy_visual_scale()
	if _horse != null:
		_horse.scale = horse_scale
	if _rider != null:
		_rider.scale = horse_scale
	if _cowboy != null and _cowboy.texture != null:
		_cowboy.scale = cowboy_scale
	if _saloon != null:
		_saloon.scale = Vector2.ONE * (GOAL_SALOON_WORLD_SCALE * _world_to_screen_scale)


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
	if not _has_floor_baseline:
		_floor_screen_y = view_size.y * TRANSITION_GROUND_RATIO
		_has_floor_baseline = true
	var ride_y := _ride_center_y()
	# Dismount at the next trail's start — leave the horse where the cowboy begins.
	var drop_x := view_size.x * 0.22
	if _has_spawn_anchor:
		drop_x = _spawn_screen_pos.x
	else:
		_spawn_screen_pos = Vector2(drop_x, _floor_screen_y)
		_has_spawn_anchor = true
	var drop := Vector2(drop_x, ride_y)
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
	_rider.position = Vector2(-240.0, ride_y)
	_animating_rider = true
	var ride_in := create_tween()
	ride_in.tween_property(_rider, "position", drop, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await ride_in.finished
	_horse.visible = true
	_horse.position = drop
	_horse.modulate.a = 0.0
	_cowboy.visible = true
	_cowboy.position = Vector2(drop.x + 8.0, _floor_screen_y - 18.0 * _world_to_screen_scale)
	_cowboy.modulate.a = 0.0
	var dismount := create_tween()
	dismount.set_parallel(true)
	dismount.tween_property(_rider, "modulate:a", 0.0, 0.28)
	dismount.tween_property(_horse, "modulate:a", 1.0, 0.28)
	dismount.tween_property(_cowboy, "modulate:a", 1.0, 0.28)
	await dismount.finished
	_rider.visible = false
	_animating_rider = false
	# Horse stays idle at the level start; cowboy fades into the live player.
	_set_empty_horse_idle(drop)
	if _subtitle != null:
		_subtitle.text = tr("Ready!")
	var settle := create_tween()
	settle.tween_interval(0.28)
	settle.set_parallel(true)
	settle.tween_property(_cowboy, "modulate:a", 0.0, 0.35)
	if _banner != null:
		settle.tween_property(_banner, "modulate:a", 0.0, 0.35)
	if _subtitle != null:
		settle.tween_property(_subtitle, "modulate:a", 0.0, 0.35)
	await settle.finished
	hide_overlay()
	_arrival_active = false
	arrival_finished.emit()


func hide_overlay() -> void:
	## Fully dismiss transition chrome so banner/subtitle never linger in gameplay.
	_arrival_active = false
	_animating_rider = false
	_animating_empty_horse = false
	visible = false
	if _banner != null:
		_banner.text = ""
		_banner.modulate.a = 0.0
	if _subtitle != null:
		_subtitle.text = ""
		_subtitle.modulate.a = 0.0
	if _horse != null:
		_horse.visible = false
		_horse.modulate.a = 0.0
	if _rider != null:
		_rider.visible = false
		_rider.modulate.a = 0.0
	if _cowboy != null:
		_cowboy.visible = false
		_cowboy.modulate.a = 0.0
	if _saloon != null:
		_saloon.visible = false
	if _veil != null:
		_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_veil.color = Color(0.0, 0.0, 0.0, 0.0)


func _ensure_horse_art() -> void:
	if _saloon == null:
		_saloon = Sprite2D.new()
		_saloon.name = "CelebrationSaloon"
		_saloon.texture = SALOON_TEXTURE
		_saloon.z_index = 1
		add_child(_saloon)
	if _horse == null:
		_horse = Sprite2D.new()
		_horse.name = "TrailHorse"
		_horse.texture = HORSE_TEXTURE
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
		_rider.z_index = 4
		add_child(_rider)
	_apply_ride_scales()


func _load_cowboy_idle_texture() -> void:
	var walk: Texture2D = load("res://assets/player/idle_0.png")
	if walk == null:
		walk = load("res://assets/player/run_0.png")
	if walk != null:
		_cowboy.texture = walk
	else:
		_cowboy.texture = RIDE_TEXTURE_0


func _place_badge_labels() -> void:
	if _banner != null:
		_banner.offset_top = -230.0
		_banner.offset_bottom = -150.0
		_banner.z_index = 5
	if _subtitle != null:
		_subtitle.offset_top = -145.0
		_subtitle.offset_bottom = -105.0
		_subtitle.z_index = 5
