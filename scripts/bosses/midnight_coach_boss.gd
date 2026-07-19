extends BossArena

## Midnight Coach: lasso three door handles in order while dodging defenses.

const COACH_FRAMES: Array[Texture2D] = [
	preload("res://assets/world/boss_midnight_coach_0.png"),
	preload("res://assets/world/boss_midnight_coach_1.png"),
	preload("res://assets/world/boss_midnight_coach_2.png"),
	preload("res://assets/world/boss_midnight_coach_3.png"),
]

var _coach: Node2D
var _coach_sprite: Sprite2D
var _horse_near: Sprite2D
var _horse_far: Sprite2D
var _driver_gun: RevolverOverlay
var _doors: Array[BossLassoTarget] = []
var _doors_done: int = 0
var _next_door: int = 0
var _dir: float = 1.0
var _base_speed: float = 150.0
var _speed: float = 150.0
var _gallop_t: float = 0.0
var _shot_timer: float = 2.0
var _burst_timer: float = 4.5
var _lantern_timer: float = 3.5
var _bursting: bool = false
var _shooting: bool = false
var _shot_generation: int = 0


func _ready() -> void:
	source_level = 7
	boss_title = "Midnight Coach — dodge shots, dust, and lanterns!"
	super._ready()
	_coach = $Coach as Node2D
	_coach_sprite = $Coach/Sprite2D as Sprite2D
	_horse_near = $Coach/HorseNear as Sprite2D
	_horse_far = $Coach/HorseFar as Sprite2D
	_driver_gun = RevolverOverlay.new()
	_driver_gun.name = "DriverGun"
	_driver_gun.z_index = 5
	_driver_gun.position = Vector2(-148, -95)
	_driver_gun.scale = Vector2(1.15, 1.15)
	_driver_gun.visible = false
	_coach.add_child(_driver_gun)
	_apply_coach_frame(0)
	_doors.clear()
	for i in range(3):
		var door := get_node_or_null("Coach/Door%d" % i) as BossLassoTarget
		if door != null:
			door.set_meta("door_index", i)
			door.set_lasso_active(i == 0)
			_doors.append(door)
	_refresh_door_hints()
	if hud != null:
		hud.show_toast("Driver shoots, coach surges, lanterns burn!", 2.6)


func _physics_process(delta: float) -> void:
	if _won or _coach == null:
		return
	_coach.position.x += _dir * _speed * delta
	if _coach.position.x > 1100.0:
		_dir = -1.0
	elif _coach.position.x < 560.0:
		_dir = 1.0
	_gallop_t += delta * (14.0 if _bursting else 10.0)
	_bob_horses()
	if not _bursting:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_start_speed_burst()
	_lantern_timer -= delta
	if _lantern_timer <= 0.0:
		_toss_lantern()
		_lantern_timer = randf_range(4.0, 6.2)
	_shot_timer -= delta
	if _shot_timer <= 0.0 and not _shooting:
		_try_driver_shot()


func _bob_horses() -> void:
	var amp := 5.0 if _bursting else 3.0
	if _horse_near != null:
		_horse_near.position.y = -42.0 + sin(_gallop_t) * amp
	if _horse_far != null:
		_horse_far.position.y = -48.0 + sin(_gallop_t + 0.7) * amp


func _apply_coach_frame(open_count: int) -> void:
	if _coach_sprite == null:
		return
	var idx := clampi(open_count, 0, COACH_FRAMES.size() - 1)
	_coach_sprite.texture = COACH_FRAMES[idx]


func _active_door() -> BossLassoTarget:
	if _next_door < 0 or _next_door >= _doors.size():
		return null
	return _doors[_next_door]


func _try_driver_shot() -> void:
	if player == null or _won:
		_shot_timer = 1.0
		return
	var door := _active_door()
	if door == null:
		_shot_timer = 1.2
		return
	# Only shoot when the cowboy is closing in on the next door.
	var dist := player.global_position.distance_to(door.global_position)
	if dist > 220.0 or absf(player.global_position.y - door.global_position.y) > 120.0:
		_shot_timer = 0.45
		return
	_fire_warning_shot()


func _fire_warning_shot() -> void:
	_shooting = true
	_shot_generation += 1
	var shot_id := _shot_generation
	var face := 1.0 if player.global_position.x >= _coach.global_position.x else -1.0
	if _driver_gun != null:
		_driver_gun.position = Vector2(-148.0 + 8.0 * face, -95.0)
		_driver_gun.show_aim(face)
	report_progress("LOOK OUT!")
	await get_tree().create_timer(0.4).timeout
	if shot_id != _shot_generation or _won:
		_shooting = false
		return
	if _driver_gun != null:
		_driver_gun.show_flash()
	var bullet := BanditBullet.new()
	bullet.name = "CoachDriverBullet"
	bullet.setup(face)
	bullet.speed = 155.0
	bullet.hurt_player.connect(func(hit: Player) -> void:
		if hit != null and not hit.is_invulnerable():
			fail_soft()
	)
	add_child(bullet)
	var muzzle := _coach.global_position + Vector2(-148.0 + 40.0 * face, -95.0)
	if _driver_gun != null:
		muzzle = _driver_gun.global_position + _driver_gun.muzzle_position()
	bullet.global_position = muzzle
	await get_tree().create_timer(0.2).timeout
	if shot_id != _shot_generation:
		_shooting = false
		return
	if _driver_gun != null:
		_driver_gun.hide_gun()
	_shooting = false
	_shot_timer = randf_range(1.6, 2.4)


func _start_speed_burst() -> void:
	if _bursting or _won:
		return
	_bursting = true
	_speed = _base_speed * 2.15
	report_progress("Dust surge!")
	var dust := CoachDustCloud.new()
	dust.name = "CoachDust"
	dust.setup(_dir, 1.15)
	dust.hit_player.connect(func(hit: Player) -> void:
		if hit != null and not hit.is_invulnerable():
			fail_soft()
	)
	add_child(dust)
	# Trail just behind the coach body relative to travel direction.
	dust.global_position = _coach.global_position + Vector2(-70.0 * _dir, -10.0)
	var follow_t := 0.0
	while follow_t < 1.0 and is_instance_valid(dust) and not _won:
		await get_tree().process_frame
		follow_t += get_process_delta_time()
		if is_instance_valid(dust) and _coach != null:
			dust.global_position = _coach.global_position + Vector2(-55.0 * _dir, -10.0)
	_speed = _base_speed
	_bursting = false
	_burst_timer = randf_range(4.2, 6.0)


func _toss_lantern() -> void:
	if player == null or _won or _coach == null:
		return
	report_progress("Lantern!")
	var lantern := CoachLantern.new()
	lantern.name = "CoachLantern"
	var from := _coach.global_position + Vector2(-130.0, -110.0)
	var ground_y := 318.0
	lantern.setup(from, player.global_position.x, ground_y)
	lantern.hit_player.connect(func(hit: Player) -> void:
		if hit != null and not hit.is_invulnerable():
			fail_soft()
	)
	add_child(lantern)


func on_door_lassoed(index: int) -> void:
	if _won:
		return
	if index != _next_door:
		report_progress("Wrong door — start with door %d!" % (_next_door + 1))
		return
	_doors_done += 1
	_next_door += 1
	report_progress("Door %d open! (%d/3)" % [index + 1, _doors_done])
	if index < _doors.size() and _doors[index] != null:
		var door := _doors[index]
		if door.has_method("play_open"):
			door.call("play_open")
		else:
			door.set_lasso_active(false)
	_apply_coach_frame(_doors_done)
	_refresh_door_hints()
	# Defenses get a bit fiercer as doors open.
	_shot_timer = mini(_shot_timer, 1.0)
	_burst_timer = mini(_burst_timer, 2.5)
	if _doors_done >= 3:
		_shot_generation += 1
		_shooting = false
		win_boss()


func _refresh_door_hints() -> void:
	for i in range(_doors.size()):
		var door := _doors[i]
		if door == null:
			continue
		if door.has_method("is_open") and bool(door.call("is_open")):
			continue
		var is_next := i == _next_door and not _won
		door.set_lasso_active(is_next)
		if is_next:
			door.modulate = Color(1.25, 1.1, 0.45, 1)
		else:
			door.modulate = Color(1, 1, 1, 0.35)
