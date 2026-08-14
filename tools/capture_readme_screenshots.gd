extends Node

## Capture real in-game screenshots / short loops for docs/showcase/.
## Run:
##   godot --path . res://tools/capture_readme_screenshots.tscn
## Prefer a real display (not --headless) so the viewport renders.
## Trail shots place the cowboy mid-level (never at the spawn door).

const OUT_DIR := "res://docs/showcase"
const SIZE := Vector2i(1280, 720)
## Fraction of spawn→goal for stills / motion (clear of the start podium).
const MID_TRAIL_T := 0.48
const RUN_TRAIL_T := 0.42


func _ready() -> void:
	get_tree().root.content_scale_size = SIZE
	DisplayServer.window_set_size(SIZE)
	call_deferred("_capture_all")


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _settle(4)

	await _shot_scene("res://scenes/ui/save_select.tscn", "title_card.png", 10)
	await _shot_level("res://scenes/levels/level_01.tscn", "desert_trail.png", MID_TRAIL_T, 14)
	await _shot_level("res://scenes/levels/level_04.tscn", "desert_canyon.png", MID_TRAIL_T, 14)
	await _shot_level("res://scenes/levels/level_11.tscn", "cave_trail.png", MID_TRAIL_T, 14)
	await _shot_level("res://scenes/levels/level_12.tscn", "cave_bats.png", 0.45, 14)
	await _shot_boss("res://scenes/bosses/boss_stampede_bull.tscn", "boss_bull.png", 12)
	await _shot_boss("res://scenes/bosses/boss_midnight_coach.tscn", "boss_coach.png", 12)
	await _shot_boss("res://scenes/bosses/boss_outlaw_kingpin.tscn", "boss_kingpin.png", 12)
	await _shot_boss("res://scenes/bosses/boss_cave_dragon.tscn", "boss_dragon.png", 14)

	# Short motion loops (PNG frame sequences → GIFs assembled by Python).
	await _loop_level(
		"res://scenes/levels/level_01.tscn",
		"run",
		RUN_TRAIL_T,
		16,
		func(player: Player, _i: int) -> void:
			if player == null:
				return
			player.velocity = Vector2(180.0, player.velocity.y)
			player.set_input_enabled(false)
	)
	await _loop_boss(
		"res://scenes/bosses/boss_cave_dragon.tscn",
		"dragon",
		18
	)

	print("README screenshots written to ", OUT_DIR)
	get_tree().quit(0)


func _shot_scene(path: String, filename: String, frames: int) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Missing scene: %s" % path)
		return
	var scene: Node = packed.instantiate()
	add_child(scene)
	await _settle(frames)
	_hide_debug_chrome(scene)
	await _settle(2)
	await _save_viewport(filename)
	scene.queue_free()
	await _settle(2)


func _shot_level(path: String, filename: String, trail_t: float, frames: int) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Missing level: %s" % path)
		return
	var level: Node = packed.instantiate()
	add_child(level)
	if level is LevelController:
		var lc := level as LevelController
		if lc.has_method("setup_level"):
			lc.setup_level()
	await _settle(frames)
	_place_cowboy_mid_trail(level, trail_t)
	_hide_hud_labels(level)
	await _settle(8)
	# Let feet settle on the desert/cave crust after the teleport.
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_rescue_cowboy_onto_floor(level)
	_hide_hud_labels(level)
	await _settle(4)
	await _save_viewport(filename)
	level.queue_free()
	await _settle(2)


func _shot_boss(path: String, filename: String, frames: int) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Missing boss: %s" % path)
		return
	var boss: Node = packed.instantiate()
	add_child(boss)
	# Boss arenas run a ~3.4s countdown before combat — wait it out in real time.
	await get_tree().create_timer(4.0).timeout
	_hide_hud_labels(boss)
	_hide_boss_overlay(boss)
	await _settle(4)
	await _save_viewport(filename)
	boss.queue_free()
	await _settle(2)


func _loop_level(
	path: String,
	prefix: String,
	trail_t: float,
	frame_count: int,
	tick: Callable
) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		return
	var level: Node = packed.instantiate()
	add_child(level)
	if level is LevelController:
		var lc := level as LevelController
		if lc.has_method("setup_level"):
			lc.setup_level()
	await _settle(10)
	_place_cowboy_mid_trail(level, trail_t)
	_hide_hud_labels(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var player := level.find_child("Player", true, false) as Player
	for i in range(frame_count):
		if tick.is_valid():
			tick.call(player, i)
		await _settle(2)
		await _save_viewport("%s_frame_%02d.png" % [prefix, i])
	level.queue_free()
	await _settle(2)


func _loop_boss(path: String, prefix: String, frame_count: int) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		return
	var boss: Node = packed.instantiate()
	add_child(boss)
	await get_tree().create_timer(4.0).timeout
	_hide_boss_overlay(boss)
	for i in range(frame_count):
		await _settle(2)
		await _save_viewport("%s_frame_%02d.png" % [prefix, i])
	boss.queue_free()
	await _settle(2)


func _hide_boss_overlay(host: Node) -> void:
	for layer in host.find_children("*", "CanvasLayer", true, false):
		var cl := layer as CanvasLayer
		if cl == null:
			continue
		# Countdown / hearts sit on high layers; keep gameplay HUD if any.
		if cl.layer >= 40:
			cl.visible = false


## Put the cowboy about halfway to the saloon/gate — never on the spawn podium.
func _place_cowboy_mid_trail(host: Node, trail_t: float) -> void:
	var player := host.find_child("Player", true, false) as Player
	if player == null:
		return
	var spawn := host.find_child("SpawnPoint", true, false) as Node2D
	var goal := host.find_child("Goal", true, false) as Node2D
	var spawn_x := spawn.global_position.x if spawn != null else player.global_position.x
	var goal_x := goal.global_position.x if goal != null else spawn_x + 3200.0
	var span := maxf(goal_x - spawn_x, 800.0)
	var target_x := spawn_x + span * clampf(trail_t, 0.28, 0.72)
	# Keep clear of the first screen after spawn and of the final saloon.
	target_x = clampf(target_x, spawn_x + 900.0, goal_x - 500.0)
	target_x = _solid_dirt_x_near(host, target_x, spawn_x, goal_x)
	var surface := WildWestTheme.walk_surface_at(host, target_x)
	var feet_y := float(surface.get("y", player.global_position.y))
	player.global_position = Vector2(target_x, feet_y)
	player.velocity = Vector2.ZERO
	player.set_input_enabled(false)
	# Keep the cowboy in front of cave ceiling décor / mesa tiles for clear stills.
	player.z_index = maxi(player.z_index, 5)
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.position_smoothing_enabled = false
		cam.force_update_scroll()


func _rescue_cowboy_onto_floor(host: Node) -> void:
	var player := host.find_child("Player", true, false) as Player
	if player == null:
		return
	if player.is_on_floor():
		return
	# Fell into a canyon — scoot inland onto solid dirt and snap again.
	var spawn := host.find_child("SpawnPoint", true, false) as Node2D
	var goal := host.find_child("Goal", true, false) as Node2D
	var spawn_x := spawn.global_position.x if spawn != null else player.global_position.x
	var goal_x := goal.global_position.x if goal != null else spawn_x + 3200.0
	var x := _solid_dirt_x_near(host, player.global_position.x, spawn_x, goal_x)
	var surface := WildWestTheme.walk_surface_at(host, x)
	player.global_position = Vector2(x, float(surface.get("y", player.global_position.y)) - 2.0)
	player.velocity = Vector2.ZERO
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.force_update_scroll()


func _solid_dirt_x_near(host: Node, prefer_x: float, spawn_x: float, goal_x: float) -> float:
	## Nudge off canyon/pit mouths so the cowboy stands on continuous dirt.
	var best_x := prefer_x
	var best_score := -INF
	for step in range(-24, 25):
		var x := prefer_x + float(step) * 40.0
		if x < spawn_x + 900.0 or x > goal_x - 500.0:
			continue
		var surface := WildWestTheme.walk_surface_at(host, x)
		var surface_y := float(surface.get("y", 320.0))
		var angle := absf(float(surface.get("angle", 0.0)))
		## Prefer flat crust with solid neighbors so we are not on a lip.
		var score := 20.0 - angle * 6.0 - absf(x - prefer_x) * 0.008
		if not _has_ground_under(host, x, surface_y):
			score -= 80.0
		elif not (
			_has_ground_under(host, x - 80.0, surface_y)
			and _has_ground_under(host, x + 80.0, surface_y)
		):
			score -= 50.0
		if score > best_score:
			best_score = score
			best_x = x
	return best_x


func _has_ground_under(host: Node, world_x: float, surface_y: float) -> bool:
	if host.get_world_2d() == null or host.get_world_2d().direct_space_state == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(world_x, surface_y - 8.0),
		Vector2(world_x, surface_y + 120.0)
	)
	query.collision_mask = 1
	var hit: Dictionary = host.get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()


func _hide_hud_labels(host: Node) -> void:
	for name in ["Hud", "PauseMenu", "LevelTransition"]:
		var node := host.find_child(name, true, false)
		if node != null and node is CanvasItem:
			(node as CanvasItem).visible = false
	for layer in host.find_children("*", "CanvasLayer", true, false):
		var cl := layer as CanvasLayer
		if cl == null:
			continue
		if String(cl.name).begins_with("Hud") or cl.layer >= 20:
			cl.visible = false
	_hide_debug_chrome(host)


func _hide_debug_chrome(host: Node) -> void:
	for node in host.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null:
			continue
		var n := String(label.name)
		if n.contains("Debug") or n.contains("Hint") or n == "HintLabel":
			label.visible = false


func _save_viewport(filename: String) -> void:
	# Two post-draw waits: first after free/clear can still be a blank buffer.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img == null:
		push_error("Viewport image null for %s" % filename)
		return
	# Drop alpha so README embeds stay opaque.
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	# Skip near-uniform dumps (cleared viewport between scenes).
	var sample := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	var corner := img.get_pixel(8, 8)
	if absf(sample.r - corner.r) < 0.02 and absf(sample.g - corner.g) < 0.02 and absf(sample.b - corner.b) < 0.02:
		var mean := (sample.r + sample.g + sample.b) / 3.0
		if mean < 0.08 or mean > 0.92:
			push_warning("Skipping blank viewport for %s" % filename)
			return
	var path := "%s/%s" % [OUT_DIR, filename]
	var err := img.save_png(path)
	if err != OK:
		push_error("Failed saving %s (%s)" % [path, str(err)])
	else:
		print("wrote ", path, " ", img.get_width(), "x", img.get_height())


func _settle(frames: int) -> void:
	for _i in range(maxi(frames, 1)):
		await get_tree().process_frame
