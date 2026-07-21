extends Node

## Standalone regression test for MovingPlatform obstruction turnaround.
##
## Verifies that shared moving platforms reverse before sinking into static
## terrain or into another moving platform, while never turning because of a
## rider on the player layer or a bandit body/hurt-area. Kept separate from the
## churny main test_runner.gd so it can be run headless on its own:
##
##   godot --headless --path . res://tests/test_moving_platform_obstruction.tscn

const MOVING_PLATFORM_SCENE := preload("res://scenes/world/moving_platform.tscn")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const OPPONENT_SCENE := preload("res://scenes/world/opponent.tscn")

const HALF_HEIGHT := 15.0
const HALF_WIDTH := 70.0


func _ready() -> void:
	var failures := 0
	failures += await _run("Platform reverses before entering the floor", _test_floor_reversal)
	failures += await _run("Two platforms turn and never overlap", _test_platform_vs_platform)
	failures += await _run("A player-layer rider never turns the platform", _test_player_ignored)
	failures += await _run("A bandit body/hurt-area never turns the platform", _test_bandit_ignored)
	if failures == 0:
		print("All moving-platform obstruction tests passed.")
		get_tree().quit(0)
	else:
		printerr("Moving-platform obstruction tests failed: %d" % failures)
		get_tree().quit(1)


func _run(name: String, callable: Callable) -> int:
	var error: Variant = await callable.call()
	if error == null:
		print("PASS: %s" % name)
		return 0
	printerr("FAIL: %s -> %s" % [name, str(error)])
	return 1


func _make_floor(top_y: float, center_x: float = 0.0, width: float = 4000.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 400.0)
	cs.shape = rect
	body.add_child(cs)
	body.position = Vector2(center_x, top_y + 200.0)
	add_child(body)
	return body


func _make_platform(pos: Vector2, pa: Vector2, pb: Vector2, speed: float) -> MovingPlatform:
	var platform := MOVING_PLATFORM_SCENE.instantiate() as MovingPlatform
	platform.point_a = pa
	platform.point_b = pb
	platform.move_speed = speed
	# Position must be set before entering the tree so _ready() captures the
	# right travel origin.
	platform.position = pos
	add_child(platform)
	return platform


func _test_floor_reversal() -> Variant:
	var floor_top := 300.0
	var floor_body := _make_floor(floor_top)
	# The route dives well below the floor top; the platform must stop above it.
	var platform := _make_platform(Vector2(0, 150), Vector2(0, -30), Vector2(0, 250), 600.0)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var max_bottom := -INF
	var min_y := INF
	var max_y := -INF
	for _i in range(240):
		await get_tree().physics_frame
		max_bottom = maxf(max_bottom, platform.global_position.y + HALF_HEIGHT)
		min_y = minf(min_y, platform.global_position.y)
		max_y = maxf(max_y, platform.global_position.y)

	var error: Variant = null
	if max_bottom > floor_top + 0.5:
		error = "Platform sank into the floor (bottom %.1f past top %.1f)." % [max_bottom, floor_top]
	elif max_y - min_y < 20.0:
		error = "Platform never traveled/reversed along its route (span %.1f)." % (max_y - min_y)
	platform.queue_free()
	floor_body.queue_free()
	return error


func _test_platform_vs_platform() -> Variant:
	# Two platforms head toward the same center line and must both turn back.
	var p1 := _make_platform(Vector2(-150, 0), Vector2(0, 0), Vector2(300, 0), 400.0)
	var p2 := _make_platform(Vector2(150, 0), Vector2(0, 0), Vector2(-300, 0), 400.0)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var min_gap := INF
	var p1_max_x := -INF
	var p2_min_x := INF
	for _i in range(240):
		await get_tree().physics_frame
		min_gap = minf(min_gap, absf(p2.global_position.x - p1.global_position.x))
		p1_max_x = maxf(p1_max_x, p1.global_position.x)
		p2_min_x = minf(p2_min_x, p2.global_position.x)

	var error: Variant = null
	# Two 140-wide boxes must never overlap: centers stay >= 140 apart.
	if min_gap < 2.0 * HALF_WIDTH - 2.0:
		error = "Moving platforms overlapped (closest center gap %.1f)." % min_gap
	elif p1_max_x < -130.0 or p2_min_x > 130.0:
		error = "Platforms did not approach before turning (p1 %.1f, p2 %.1f)." % [p1_max_x, p2_min_x]
	p1.queue_free()
	p2.queue_free()
	return error


func _test_player_ignored() -> Variant:
	var player := PLAYER_SCENE.instantiate() as Player
	player.position = Vector2(0, 0)
	add_child(player)
	# Freeze the player so it stays parked in the platform's path.
	player.set_physics_process(false)
	player.global_position = Vector2(0, 0)
	# Endpoint B lands at world x = 150, right past the parked rider at x = 0.
	var platform := _make_platform(Vector2(-150, 0), Vector2(0, 0), Vector2(300, 0), 400.0)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var reached := -INF
	for _i in range(200):
		await get_tree().physics_frame
		reached = maxf(reached, platform.global_position.x)

	var error: Variant = null
	if reached < 150.0 - 5.0:
		error = "Platform wrongly turned at a player rider (only reached x=%.1f)." % reached
	player.queue_free()
	platform.queue_free()
	return error


func _test_bandit_ignored() -> Variant:
	var bandit := OPPONENT_SCENE.instantiate() as Opponent
	bandit.position = Vector2(0, 0)
	add_child(bandit)
	# Freeze patrol so the bandit stays parked in the platform's path.
	bandit.set_physics_process(false)
	bandit.global_position = Vector2(0, 0)
	var platform := _make_platform(Vector2(-150, 0), Vector2(0, 0), Vector2(300, 0), 400.0)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var reached := -INF
	for _i in range(200):
		await get_tree().physics_frame
		reached = maxf(reached, platform.global_position.x)

	var error: Variant = null
	if reached < 150.0 - 5.0:
		error = "Platform wrongly turned at a bandit (only reached x=%.1f)." % reached
	bandit.queue_free()
	platform.queue_free()
	return error
