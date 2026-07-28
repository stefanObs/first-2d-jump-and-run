extends Node

## Capture real in-game screenshots / short loops for docs/showcase/.
## Run:
##   godot --path . res://tools/capture_readme_screenshots.tscn
## Prefer a real display (not --headless) so the viewport renders.

const OUT_DIR := "res://docs/showcase"
const SIZE := Vector2i(1280, 720)


func _ready() -> void:
	get_tree().root.content_scale_size = SIZE
	DisplayServer.window_set_size(SIZE)
	call_deferred("_capture_all")


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _settle(4)

	await _shot_scene("res://scenes/ui/save_select.tscn", "title_card.png", Vector2.ZERO, 10)
	await _shot_level("res://scenes/levels/level_01.tscn", "desert_trail.png", Vector2(520, 280), 14)
	await _shot_level("res://scenes/levels/level_04.tscn", "desert_canyon.png", Vector2(900, 260), 14)
	await _shot_level("res://scenes/levels/level_11.tscn", "cave_trail.png", Vector2(480, 280), 14)
	await _shot_level("res://scenes/levels/level_12.tscn", "cave_bats.png", Vector2(700, 240), 14)
	await _shot_boss("res://scenes/bosses/boss_stampede_bull.tscn", "boss_bull.png", 12)
	await _shot_boss("res://scenes/bosses/boss_midnight_coach.tscn", "boss_coach.png", 12)
	await _shot_boss("res://scenes/bosses/boss_outlaw_kingpin.tscn", "boss_kingpin.png", 12)
	await _shot_boss("res://scenes/bosses/boss_cave_dragon.tscn", "boss_dragon.png", 14)

	# Short motion loops (PNG frame sequences → GIFs assembled by Python).
	await _loop_level(
		"res://scenes/levels/level_01.tscn",
		"run",
		Vector2(420, 280),
		16,
		func(player: Player, i: int) -> void:
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


func _shot_scene(path: String, filename: String, cam_focus: Vector2, frames: int) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Missing scene: %s" % path)
		return
	var scene: Node = packed.instantiate()
	add_child(scene)
	await _settle(frames)
	if cam_focus != Vector2.ZERO:
		_focus_camera(scene, cam_focus)
		await _settle(4)
	_hide_debug_chrome(scene)
	await _settle(2)
	await _save_viewport(filename)
	scene.queue_free()
	await _settle(2)


func _shot_level(path: String, filename: String, cam_focus: Vector2, frames: int) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("Missing level: %s" % path)
		return
	var level: Node = packed.instantiate()
	add_child(level)
	if level is LevelController:
		var lc := level as LevelController
		if lc.has_method("setup_level") and lc.player == null:
			lc.setup_level()
	await _settle(frames)
	_focus_camera(level, cam_focus)
	_hide_hud_labels(level)
	await _settle(6)
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
	cam_focus: Vector2,
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
		if lc.has_method("setup_level") and lc.player == null:
			lc.setup_level()
	await _settle(10)
	_focus_camera(level, cam_focus)
	_hide_hud_labels(level)
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


func _focus_camera(host: Node, world_pos: Vector2) -> void:
	var player := host.find_child("Player", true, false) as Player
	if player != null:
		player.global_position = world_pos
		player.velocity = Vector2.ZERO
		player.set_input_enabled(false)
		var cam := player.get_node_or_null("Camera2D") as Camera2D
		if cam != null:
			cam.position_smoothing_enabled = false
			cam.force_update_scroll()
		return
	var cam2 := host.find_child("Camera2D", true, false) as Camera2D
	if cam2 != null:
		cam2.global_position = world_pos
		cam2.force_update_scroll()


func _hide_hud_labels(host: Node) -> void:
	var hud := host.find_child("Hud", true, false)
	if hud != null and hud is CanvasItem:
		(hud as CanvasItem).visible = false
	var pause := host.find_child("PauseMenu", true, false)
	if pause != null and pause is CanvasItem:
		(pause as CanvasItem).visible = false
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
