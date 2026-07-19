extends BossArena

## Midnight Coach: endless rightward chase — lasso doors 1-2-3 while racing.

const COACH_FRAMES: Array[Texture2D] = [
	preload("res://assets/world/boss_midnight_coach_0.png"),
	preload("res://assets/world/boss_midnight_coach_1.png"),
	preload("res://assets/world/boss_midnight_coach_2.png"),
	preload("res://assets/world/boss_midnight_coach_3.png"),
]
const COACH_SURRENDER := preload("res://assets/world/boss_midnight_coach_surrender.png")

const SCREEN_LAG := 1280.0
const COACH_SPEED_RATIO := 0.75
const ACCEL := 160.0

var _coach: Node2D
var _coach_sprite: Sprite2D
var _horse_near: Sprite2D
var _horse_far: Sprite2D
var _driver_gun: RevolverOverlay
var _ground: StaticBody2D
var _ground_visual: ColorRect
var _ground_shape: CollisionShape2D
var _background: ColorRect
var _doors: Array[BossLassoTarget] = []
var _doors_done: int = 0
var _next_door: int = 0
var _speed: float = 0.0
var _target_speed: float = 200.0
var _waiting: bool = false
var _gallop_t: float = 0.0
var _shot_timer: float = 2.0
var _lantern_timer: float = 3.5
var _burst_timer: float = 5.0
var _bursting: bool = false
var _shooting: bool = false
var _shot_generation: int = 0
var _ground_half_w: float = 800.0
var _desert_root: Node2D
var _desert_built_to: float = 0.0
var _hills_root: Node2D
var _hills_built_to: float = 0.0


func _ready() -> void:
	source_level = 7
	boss_title = "Midnight Coach — chase and lasso doors 1-2-3!"
	super._ready()
	_coach = $Coach as Node2D
	_coach_sprite = $Coach/Sprite2D as Sprite2D
	_horse_near = $Coach/HorseNear as Sprite2D
	_horse_far = $Coach/HorseFar as Sprite2D
	_ground = $Ground as StaticBody2D
	_ground_visual = $Ground/Visual as ColorRect
	_ground_shape = $Ground/CollisionShape2D as CollisionShape2D
	_background = $Background as ColorRect
	_driver_gun = RevolverOverlay.new()
	_driver_gun.name = "DriverGun"
	_driver_gun.z_index = 5
	_driver_gun.position = Vector2(148, -95)
	_driver_gun.scale = Vector2(1.15, 1.15)
	_driver_gun.visible = false
	_coach.add_child(_driver_gun)
	_face_coach_forward()
	_apply_coach_frame(0)
	_doors.clear()
	for i in range(3):
		var door := get_node_or_null("Coach/Door%d" % i) as BossLassoTarget
		if door != null:
			door.set_meta("door_index", i)
			door.set_lasso_active(i == 0)
			_doors.append(door)
	_refresh_door_hints()
	_setup_desert_floor()
	# Infinite Speed Star for the race.
	if player != null:
		player.activate_mode(ModeController.Mode.SPEED_STAR, 0.0, true)
		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam != null:
			cam.limit_right = 100000
	# Remove the pickup — boost is granted for the whole fight.
	var star := get_node_or_null("SpeedStar")
	if star != null:
		star.queue_free()
	combat_started.connect(_on_combat_started)
	if hud != null:
		hud.show_toast("Keep up! Coach waits if you fall a screen behind.", 2.8)


func _on_combat_started() -> void:
	if player != null:
		player.activate_mode(ModeController.Mode.SPEED_STAR, 0.0, true)
	_speed = _player_run_speed() * COACH_SPEED_RATIO * 0.55
	_waiting = false


func _face_coach_forward() -> void:
	## Coach art faces left; flip the whole team so it races to the right.
	if _coach_sprite != null:
		_coach_sprite.flip_h = true
		_coach_sprite.position = Vector2(-20, -78)
	if _horse_near != null:
		_horse_near.position = Vector2(230, -42)
		_horse_near.flip_h = false
	if _horse_far != null:
		_horse_far.position = Vector2(300, -48)
		_horse_far.flip_h = false
	var harness := _coach.get_node_or_null("Harness") as Line2D
	if harness != null:
		harness.points = PackedVector2Array([Vector2(120, -70), Vector2(160, -62), Vector2(210, -55)])
	# Rear door closest to the chasing player (left), then mid, then front.
	var door_xs := [-90.0, -25.0, 45.0]
	for i in range(3):
		var door := _coach.get_node_or_null("Door%d" % i) as Node2D
		if door != null:
			door.position = Vector2(door_xs[i], -48.0)


func _setup_desert_floor() -> void:
	_desert_root = Node2D.new()
	_desert_root.name = "DesertFloor"
	_desert_root.z_index = -12
	add_child(_desert_root)
	_hills_root = get_node_or_null("HorizonHills") as Node2D
	if _hills_root == null:
		_hills_root = Node2D.new()
		_hills_root.name = "RaceHills"
		_hills_root.z_index = -16
		add_child(_hills_root)
	if _ground_visual != null:
		_ground_visual.color = WildWestTheme.sand_color()
	_extend_desert_to(2400.0)


func _extend_desert_to(right_x: float) -> void:
	var sand: Texture2D = load("res://assets/world/trail_desert_tile.png")
	var dirt: Texture2D = load("res://assets/world/trail_dirt_tile.png")
	var hills: Texture2D = load("res://assets/world/horizon_hills_strip.png")
	var floor_y := 320.0
	if sand != null and _desert_root != null:
		var tile_w := float(sand.get_width()) * 1.2
		var x := _desert_built_to
		if x <= 0.0:
			x = -400.0
		while x < right_x + 400.0:
			var sprite := Sprite2D.new()
			sprite.texture = sand
			sprite.centered = false
			sprite.position = Vector2(x, floor_y - 8.0)
			sprite.scale = Vector2(1.2, 1.15)
			_desert_root.add_child(sprite)
			if dirt != null:
				var under := Sprite2D.new()
				under.texture = dirt
				under.centered = false
				under.position = Vector2(x, floor_y + 36.0)
				under.scale = Vector2(1.2, 1.0)
				under.z_index = -1
				_desert_root.add_child(under)
			x += tile_w - 4.0
		_desert_built_to = x
	if hills != null and _hills_root != null:
		var tile_w := float(hills.get_width()) * 1.35
		var tile_h := 520.0
		var x := _hills_built_to
		if x <= 0.0:
			x = -500.0
		while x < right_x + 600.0:
			var hill := Sprite2D.new()
			hill.texture = hills
			hill.centered = false
			hill.position = Vector2(x, floor_y - tile_h + 10.0)
			hill.scale = Vector2(tile_w / float(hills.get_width()), tile_h / float(hills.get_height()))
			hill.modulate = Color(1, 1, 1, 0.98)
			_hills_root.add_child(hill)
			x += tile_w - 220.0
		_hills_built_to = x


func _player_run_speed() -> float:
	if player == null:
		return 270.0 * 1.45
	return player.move_speed * 1.45


func _physics_process(delta: float) -> void:
	if _won or _coach == null or not combat_ready:
		return
	_update_chase(delta)
	_ensure_world_ahead()
	_gallop_t += delta * (14.0 if _bursting or not _waiting else 8.0)
	_bob_horses()
	_lantern_timer -= delta
	if _lantern_timer <= 0.0:
		_toss_lantern()
		_lantern_timer = randf_range(4.0, 6.2)
	_shot_timer -= delta
	if _shot_timer <= 0.0 and not _shooting:
		_try_driver_shot()
	if not _bursting and not _waiting:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_start_speed_burst()


func _update_chase(delta: float) -> void:
	if player == null:
		return
	var lag := _coach.global_position.x - player.global_position.x
	_target_speed = _player_run_speed() * COACH_SPEED_RATIO
	if lag > SCREEN_LAG:
		# More than one screen behind — coach stops and waits.
		_waiting = true
		_speed = 0.0
		_bursting = false
	elif _waiting:
		# Player caught up enough to see the coach again — ease back up.
		if lag < SCREEN_LAG * 0.85:
			_waiting = false
			report_progress("They're rolling again!")
	if not _waiting:
		var want := _target_speed * (1.35 if _bursting else 1.0)
		_speed = move_toward(_speed, want, ACCEL * delta)
	_coach.position.x += _speed * delta


func _ensure_world_ahead() -> void:
	if _ground == null or player == null:
		return
	var need_right := maxf(player.global_position.x, _coach.global_position.x) + 2000.0
	_extend_desert_to(need_right)
	var half := need_right * 0.5
	if half <= _ground_half_w:
		return
	_ground_half_w = half
	_ground.position.x = half
	if _ground_visual != null:
		_ground_visual.offset_left = -half
		_ground_visual.offset_right = half
		_ground_visual.color = WildWestTheme.sand_color()
	if _ground_shape != null and _ground_shape.shape is RectangleShape2D:
		var rect := (_ground_shape.shape as RectangleShape2D).duplicate() as RectangleShape2D
		rect.size = Vector2(half * 2.0, 64.0)
		_ground_shape.shape = rect
	if _background != null:
		_background.offset_left = -400.0
		_background.offset_right = need_right + 800.0
		_background.color = WildWestTheme.desert_sky_color()


func _bob_horses() -> void:
	var amp := 5.0 if (not _waiting) else 1.5
	if _horse_near != null:
		_horse_near.position.y = -42.0 + sin(_gallop_t) * amp
	if _horse_far != null:
		_horse_far.position.y = -48.0 + sin(_gallop_t + 0.7) * amp


func _apply_coach_frame(open_count: int) -> void:
	if _coach_sprite == null:
		return
	var idx := clampi(open_count, 0, COACH_FRAMES.size() - 1)
	_coach_sprite.texture = COACH_FRAMES[idx]
	_coach_sprite.centered = true
	_coach_sprite.flip_h = true
	_coach_sprite.scale = Vector2(0.92, 0.92)
	_coach_sprite.position = Vector2(-20, -78)


func _active_door() -> BossLassoTarget:
	if _next_door < 0 or _next_door >= _doors.size():
		return null
	return _doors[_next_door]


func _try_driver_shot() -> void:
	if player == null or _won or _waiting:
		_shot_timer = 1.0
		return
	var door := _active_door()
	if door == null:
		_shot_timer = 1.2
		return
	var dist := player.global_position.distance_to(door.global_position)
	if dist > 240.0 or absf(player.global_position.y - door.global_position.y) > 120.0:
		_shot_timer = 0.45
		return
	_fire_warning_shot()


func _fire_warning_shot() -> void:
	_shooting = true
	_shot_generation += 1
	var shot_id := _shot_generation
	var face := -1.0  # Player approaches from behind (left).
	if player != null and player.global_position.x > _coach.global_position.x:
		face = 1.0
	if _driver_gun != null:
		_driver_gun.position = Vector2(140.0 + 8.0 * face, -95.0)
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
	var muzzle := _coach.global_position + Vector2(140.0 + 40.0 * face, -95.0)
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
	if _bursting or _won or _waiting:
		return
	_bursting = true
	report_progress("Dust surge!")
	var dust := CoachDustCloud.new()
	dust.name = "CoachDust"
	dust.setup(1.0, 1.15)
	dust.hit_player.connect(func(hit: Player) -> void:
		if hit != null and not hit.is_invulnerable():
			fail_soft()
	)
	add_child(dust)
	dust.global_position = _coach.global_position + Vector2(-90.0, -10.0)
	var follow_t := 0.0
	while follow_t < 1.0 and is_instance_valid(dust) and not _won:
		await get_tree().process_frame
		follow_t += get_process_delta_time()
		if is_instance_valid(dust) and _coach != null:
			dust.global_position = _coach.global_position + Vector2(-75.0, -10.0)
	_bursting = false
	_burst_timer = randf_range(4.5, 6.5)


func _toss_lantern() -> void:
	if player == null or _won or _coach == null or _waiting:
		return
	report_progress("Lantern!")
	var lantern := CoachLantern.new()
	lantern.name = "CoachLantern"
	var from := _coach.global_position + Vector2(130.0, -110.0)
	var ground_y := 318.0
	lantern.setup(from, player.global_position.x, ground_y)
	lantern.hit_player.connect(func(hit: Player) -> void:
		if hit != null and not hit.is_invulnerable():
			fail_soft()
	)
	add_child(lantern)


func get_heart_drop_position() -> Vector2:
	var rx := 220.0
	if _coach != null:
		rx = _coach.global_position.x - 200.0
	return Vector2(rx, 320.0)


func _on_heart_recovered() -> void:
	if player != null:
		player.activate_mode(ModeController.Mode.SPEED_STAR, 0.0, true)
	report_progress("Catch up!")


func on_door_lassoed(index: int) -> void:
	if _won or not combat_ready:
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
	_shot_timer = mini(_shot_timer, 1.0)
	if _doors_done >= 3:
		_shot_generation += 1
		_shooting = false
		await _play_win_animation()
		await win_boss()


func _play_win_animation() -> void:
	## Driver raises both hands in surrender before the arena clears.
	combat_ready = false
	_waiting = true
	_speed = 0.0
	_target_speed = 0.0
	_bursting = false
	if player != null:
		player.set_input_enabled(false)
	if _driver_gun != null:
		_driver_gun.hide_gun()
	for door in _doors:
		if door != null:
			door.set_lasso_active(false)
	report_progress("Driver gives up!")
	if _coach_sprite != null and COACH_SURRENDER != null:
		var base_scale := _coach_sprite.scale
		var base_y := _coach_sprite.position.y
		_coach_sprite.texture = COACH_SURRENDER
		_face_coach_forward()
		var bob := create_tween()
		bob.tween_property(_coach_sprite, "position:y", base_y - 6.0, 0.18)
		bob.tween_property(_coach_sprite, "position:y", base_y, 0.22)
		var pulse := create_tween()
		pulse.tween_property(_coach_sprite, "scale", base_scale * Vector2(1.04, 0.96), 0.15)
		pulse.tween_property(_coach_sprite, "scale", base_scale, 0.2)
	if _horse_near != null:
		var horse_y := _horse_near.position.y
		var ht := create_tween()
		ht.tween_property(_horse_near, "position:y", horse_y - 4.0, 0.2)
		ht.tween_property(_horse_near, "position:y", horse_y, 0.25)
	await get_tree().create_timer(1.6).timeout


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
