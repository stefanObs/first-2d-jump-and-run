extends BossArena

## Midnight Coach: endless rightward chase — lasso doors 1-2-3 while racing.

const COACH_FRAMES: Array[Texture2D] = [
	preload("res://assets/world/boss_midnight_coach_0.png"),
	preload("res://assets/world/boss_midnight_coach_1.png"),
	preload("res://assets/world/boss_midnight_coach_2.png"),
	preload("res://assets/world/boss_midnight_coach_3.png"),
]

const COACH_SURRENDER: Texture2D = preload("res://assets/world/boss_midnight_coach_surrender.png")

const SCREEN_LAG := 1280.0
const COACH_SPEED_RATIO := 0.75
const ACCEL := 160.0
const EARTH_TOP := 312.0
const EARTH_DEPTH := 1200.0
## Match WildWestTheme TrailFloor / backdrop tiling so the chase never drifts style.
const FLOOR_TOP := 320.0
const SURFACE_THICKNESS := 56.0
const DESERT_LOOP_PAD := 1800.0
const BACKDROP_SCALE := 1.35
const HILL_OVERLAP := 220.0
const SKY_OVERLAP := 8.0
const SKY_Y := -520.0
const SKY_H := 700.0
const HILL_H := 520.0

var _coach: Node2D
var _coach_sprite: Sprite2D
var _horse_near: Sprite2D
var _horse_far: Sprite2D
var _harness_near: Line2D
var _harness_far: Line2D
var _driver_gun: RevolverOverlay
var _ground: StaticBody2D
var _ground_visual: ColorRect
var _ground_shape: CollisionShape2D
var _background: ColorRect
var _earth_underfill: ColorRect
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
var _sky_root: Node2D
var _hills_root: Node2D
var _sand_sprites: Array[Sprite2D] = []
var _dirt_sprites: Array[Sprite2D] = []
var _hill_sprites: Array[Sprite2D] = []
var _sky_sprites: Array[Sprite2D] = []
var _sand_step: float = 0.0
var _dirt_step: float = 0.0
var _hill_step: float = 0.0
var _sky_step: float = 0.0


func _ready() -> void:
	source_level = 7
	boss_title = "Midnight Coach — chase and lasso doors 1-2-3!"
	super._ready()
	_coach = $Coach as Node2D
	_coach_sprite = $Coach/Sprite2D as Sprite2D
	_horse_near = $Coach/HorseNear as Sprite2D
	_horse_far = $Coach/HorseFar as Sprite2D
	_harness_near = $Coach/Harness as Line2D
	_harness_far = $Coach/HarnessFar as Line2D
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
	# The coach chase is ridden on horseback at the former Speed Star pace.
	# Mounted air speed is capped separately so jumps reach exactly 20% farther.
	if player != null:
		player.clear_modes()
		player.mount_horse()
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
		player.clear_modes()
		player.mount_horse()
	_speed = _player_run_speed() * COACH_SPEED_RATIO * 0.55
	_waiting = false


func _face_coach_forward() -> void:
	## Coach art faces left; flip the whole team so it races to the right.
	if _coach_sprite != null:
		_coach_sprite.flip_h = true
		_coach_sprite.position = Vector2(-20, -78)
	if _horse_near != null:
		_horse_near.position = Vector2(190, -42)
		_horse_near.flip_h = false
	if _horse_far != null:
		_horse_far.position = Vector2(240, -48)
		_horse_far.flip_h = false
	_update_reins()
	# Rear door closest to the chasing player (left), then mid, then front.
	var door_xs := [-90.0, -25.0, 45.0]
	for i in range(3):
		var door := _coach.get_node_or_null("Door%d" % i) as Node2D
		if door != null:
			door.position = Vector2(door_xs[i], -48.0)


func _setup_desert_floor() -> void:
	# BossArena applies WildWestTheme first, which paints a *finite* TrailFloor /
	# SkyArt / HorizonHills from the starting Background width.  Past that strip
	# the old chase spawned a differently scaled DesertFloor — style drift mid-race.
	# Tear those finite layers down and keep one looping set of trail-matched tiles.
	for node_name in ["TrailFloor", "SkyArt", "HorizonHills", "RaceHills", "DesertFloor", "EarthUnderfill"]:
		var stale := get_node_or_null(node_name)
		if stale != null:
			stale.free()

	# Deep opaque earth behind the shallow trail crust so wide cameras never show
	# the clear-colour void under the race course.
	_earth_underfill = ColorRect.new()
	_earth_underfill.name = "EarthUnderfill"
	_earth_underfill.z_index = -14
	_earth_underfill.position = Vector2(-400.0, EARTH_TOP)
	_earth_underfill.size = Vector2(DESERT_LOOP_PAD * 2.0 + 800.0, EARTH_DEPTH)
	_earth_underfill.color = Color(0.20, 0.075, 0.025, 1.0)
	_earth_underfill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_earth_underfill)

	_sky_root = Node2D.new()
	_sky_root.name = "SkyArt"
	_sky_root.z_index = -19
	add_child(_sky_root)

	_hills_root = Node2D.new()
	_hills_root.name = "HorizonHills"
	_hills_root.z_index = -16
	add_child(_hills_root)

	_desert_root = Node2D.new()
	_desert_root.name = "DesertFloor"
	_desert_root.z_index = 0
	add_child(_desert_root)

	if _ground_visual != null:
		_ground_visual.visible = false
		_ground_visual.color = WildWestTheme.sand_color()

	_build_looping_desert_layers()
	_sync_desert_loop(0.0)


func _build_looping_desert_layers() -> void:
	_sand_sprites.clear()
	_dirt_sprites.clear()
	_hill_sprites.clear()
	_sky_sprites.clear()

	var sand: Texture2D = load("res://assets/world/trail_desert_tile.png")
	var dirt: Texture2D = load("res://assets/world/trail_dirt_tile.png")
	var hills: Texture2D = load("res://assets/world/horizon_hills_strip.png")
	var sky: Texture2D = load("res://assets/world/sky_handdrawn.png")
	var span := DESERT_LOOP_PAD * 2.0 + 800.0
	var start_x := -DESERT_LOOP_PAD

	if sand != null and _desert_root != null:
		var sand_size := sand.get_size()
		var scale_y := SURFACE_THICKNESS / sand_size.y
		var tile_w := sand_size.x * scale_y
		var overlap := minf(24.0, tile_w * 0.18)
		_sand_step = maxf(tile_w - overlap, 1.0)
		var x := start_x
		var i := 0
		while x < start_x + span:
			var sprite := Sprite2D.new()
			sprite.name = "ChaseSand%d" % i
			sprite.texture = sand
			sprite.centered = false
			sprite.position = Vector2(x, FLOOR_TOP)
			sprite.scale = Vector2(scale_y, scale_y)
			sprite.z_index = 1
			_desert_root.add_child(sprite)
			_sand_sprites.append(sprite)
			x += _sand_step
			i += 1

	if dirt != null and _desert_root != null:
		var dirt_size := dirt.get_size()
		var dirt_h := dirt_size.y * (SURFACE_THICKNESS / maxf(dirt_size.y, 1.0))
		var scale_y := dirt_h / dirt_size.y
		var tile_w := dirt_size.x * scale_y
		var overlap := minf(24.0, tile_w * 0.18)
		_dirt_step = maxf(tile_w - overlap, 1.0)
		var dirt_y0 := FLOOR_TOP + SURFACE_THICKNESS - 2.0
		# A few dirt rows match TrailFloor crust depth; EarthUnderfill covers deeper.
		for row in range(4):
			var x := start_x
			var i := 0
			var y := dirt_y0 + row * (dirt_h - 2.0)
			while x < start_x + span:
				var under := Sprite2D.new()
				under.name = "ChaseDirt%d_%d" % [row, i]
				under.texture = dirt
				under.centered = false
				under.position = Vector2(x, y)
				under.scale = Vector2(scale_y, scale_y)
				under.z_index = 0
				_desert_root.add_child(under)
				_dirt_sprites.append(under)
				x += _dirt_step
				i += 1

	if hills != null and _hills_root != null:
		var hill_size := hills.get_size()
		var tile_w := hill_size.x * BACKDROP_SCALE
		_hill_step = maxf(tile_w - HILL_OVERLAP, 1.0)
		var hill_y := FLOOR_TOP - HILL_H + 10.0
		var x := start_x - 100.0
		var i := 0
		while x < start_x + span + 200.0:
			var hill := Sprite2D.new()
			hill.name = "ChaseHill%d" % i
			hill.texture = hills
			hill.centered = false
			hill.position = Vector2(x, hill_y)
			hill.scale = Vector2(tile_w / hill_size.x, HILL_H / hill_size.y)
			hill.modulate = Color(1, 1, 1, 0.98)
			_hills_root.add_child(hill)
			_hill_sprites.append(hill)
			x += _hill_step
			i += 1

	if sky != null and _sky_root != null:
		var sky_size := sky.get_size()
		var tile_w := sky_size.x * BACKDROP_SCALE
		_sky_step = maxf(tile_w - SKY_OVERLAP, 1.0)
		var x := start_x - 100.0
		var i := 0
		while x < start_x + span + 200.0:
			var sky_sprite := Sprite2D.new()
			sky_sprite.name = "ChaseSky%d" % i
			sky_sprite.texture = sky
			sky_sprite.centered = false
			sky_sprite.position = Vector2(x, SKY_Y)
			sky_sprite.scale = Vector2(tile_w / sky_size.x, SKY_H / sky_size.y)
			_sky_root.add_child(sky_sprite)
			_sky_sprites.append(sky_sprite)
			x += _sky_step
			i += 1


func _sync_desert_loop(focus_x: float) -> void:
	## Recycle the same trail-matched tiles forever — identical look at any chase X.
	_recycle_sprite_row(_sand_sprites, _sand_step, focus_x)
	_recycle_sprite_row(_dirt_sprites, _dirt_step, focus_x)
	_recycle_sprite_row(_hill_sprites, _hill_step, focus_x)
	_recycle_sprite_row(_sky_sprites, _sky_step, focus_x)
	if _earth_underfill != null:
		_earth_underfill.position.x = focus_x - DESERT_LOOP_PAD
		_earth_underfill.size.x = DESERT_LOOP_PAD * 2.0 + 800.0


func _recycle_sprite_row(sprites: Array[Sprite2D], step: float, focus_x: float) -> void:
	if sprites.is_empty() or step <= 0.0:
		return
	var min_x := INF
	for sprite in sprites:
		if not is_instance_valid(sprite):
			continue
		min_x = minf(min_x, sprite.position.x)
	if min_x == INF:
		return
	var left_keep := focus_x - DESERT_LOOP_PAD
	# Shift the whole strip by whole tile steps so the desert phase never drifts.
	if min_x >= left_keep - step:
		return
	var shift_steps := int(floor((left_keep - min_x) / step))
	if shift_steps <= 0:
		return
	var shift := float(shift_steps) * step
	for sprite in sprites:
		if is_instance_valid(sprite):
			sprite.position.x += shift


func desert_surface_scale() -> Vector2:
	## Test helper: trail-matched sand scale must stay constant for the whole chase.
	if _sand_sprites.is_empty() or not is_instance_valid(_sand_sprites[0]):
		return Vector2.ZERO
	return _sand_sprites[0].scale


func desert_loop_coverage_at(focus_x: float) -> Dictionary:
	## Test helper: after syncing to a large X, tiles must still bracket the focus.
	_sync_desert_loop(focus_x)
	var min_x := INF
	var max_x := -INF
	for sprite in _sand_sprites:
		if not is_instance_valid(sprite):
			continue
		min_x = minf(min_x, sprite.position.x)
		max_x = maxf(max_x, sprite.position.x + _sand_step)
	return {
		"min_x": min_x,
		"max_x": max_x,
		"step": _sand_step,
		"count": _sand_sprites.size(),
		"scale": desert_surface_scale(),
	}


func _player_run_speed() -> float:
	if player == null:
		return 270.0 * Player.HORSE_SPEED_MULTIPLIER
	return player.get_run_speed()


func _process(_delta: float) -> void:
	if _coach != null:
		_update_reins()


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
	var focus_x := maxf(player.global_position.x, _coach.global_position.x if _coach != null else 0.0)
	var need_right := focus_x + 2000.0
	_sync_desert_loop(focus_x)
	if _background != null:
		_background.offset_left = focus_x - DESERT_LOOP_PAD
		_background.offset_right = focus_x + DESERT_LOOP_PAD + 800.0
		_background.color = WildWestTheme.desert_sky_color()
	var sky_band := get_node_or_null("SkyBand") as ColorRect
	if sky_band != null:
		sky_band.offset_left = focus_x - DESERT_LOOP_PAD
		sky_band.offset_right = focus_x + DESERT_LOOP_PAD + 800.0
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


func _bob_horses() -> void:
	var amp := 5.0 if (not _waiting) else 1.5
	if _horse_near != null:
		_horse_near.position.y = -42.0 + sin(_gallop_t) * amp
	if _horse_far != null:
		_horse_far.position.y = -48.0 + sin(_gallop_t + 0.7) * amp
	_update_reins()


func _update_reins() -> void:
	# Each rein ends at a horse's moving bridle, so the lines never float in
	# the gap when the team bobs through its gallop cycle.
	if _harness_near != null and _horse_near != null:
		_harness_near.points = PackedVector2Array([
			Vector2(110.0, -96.0),
			Vector2(150.0, -82.0),
			_horse_near.position + Vector2(48.0, -12.0),
		])
	if _harness_far != null and _horse_far != null:
		_harness_far.points = PackedVector2Array([
			Vector2(104.0, -92.0),
			Vector2(168.0, -80.0),
			_horse_far.position + Vector2(48.0, -10.0),
		])


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
		player.clear_modes()
		player.mount_horse()
	report_progress("Catch up!")


func on_door_lassoed(index: int) -> void:
	if _won or not combat_ready:
		return
	if index != _next_door:
		report_progress(tr("Wrong door — start with door %d!") % (_next_door + 1))
		return
	_doors_done += 1
	_next_door += 1
	report_progress(tr("Door %d open! (%d/3)") % [index + 1, _doors_done])
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
	## Keep the established coach, team, and harness together while the driver
	## puts both hands up in surrender before the arena clears.
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
			# Surrender art already shows all three open doors.
			door.visible = false
	report_progress("Driver gives up!")
	_apply_surrender_pose()
	if _coach != null:
		# Settle the complete rig as one silhouette. Moving only the carriage
		# made its wheels, horses, and reins look detached in the old finale.
		var base_y := _coach.position.y
		var settle := create_tween()
		settle.tween_property(_coach, "position:y", base_y - 5.0, 0.16)
		settle.tween_property(_coach, "position:y", base_y + 2.0, 0.20)
		settle.tween_property(_coach, "position:y", base_y, 0.18)
	await get_tree().create_timer(1.6).timeout


func _apply_surrender_pose() -> void:
	## Same canvas size / scale / offset as the door frames so the rig does not
	## jump; the handmade surrender texture shows hands-up instead of a flag.
	if _coach_sprite == null:
		return
	var flag := _coach.get_node_or_null("SurrenderFlag") if _coach != null else null
	if flag != null:
		flag.queue_free()
	_coach_sprite.texture = COACH_SURRENDER
	_coach_sprite.centered = true
	_coach_sprite.flip_h = true
	_coach_sprite.scale = Vector2(0.92, 0.92)
	_coach_sprite.position = Vector2(-20, -78)


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
