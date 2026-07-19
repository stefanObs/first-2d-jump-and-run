extends Node

## Scene-based headless test runner so autoloads resolve correctly.
## Run with: godot --headless --path . res://tests/test_runner.tscn


func _ready() -> void:
	var failures := 0
	failures += _run("JumpAssist coyote allows brief airborne jump", _test_coyote_jump)
	failures += _run("JumpAssist buffer remembers early jump press", _test_jump_buffer)
	failures += _run("JumpAssist consume clears coyote and buffer", _test_consume_clears_state)
	failures += _run("InputBindings registers required actions", _test_input_bindings_actions)
	failures += _run("ModeController durations and shield", _test_mode_controller)
	failures += _run("GameManager save slots persist", _test_save_slots)
	failures += _run("Save select scene loads", _test_save_select_scene)
	failures += _run("Level 01 contains core objects", _test_level_01_world_objects)
	failures += _run("Level catalog has ten scenes", _test_ten_levels_exist)
	failures += _run("LevelController respawns at checkpoint", _test_respawn_uses_checkpoint)
	failures += _run("Goal completion disables player input", _test_goal_disables_input)
	failures += _run("Bubble shield blocks opponent damage flag", _test_shield_blocks_damage_flag)
	failures += _run("InputManager device prompts", _test_input_manager_prompts)
	failures += _run("Star reachability heuristics", _test_star_reachability)
	failures += _run(
		"Levels complete; platforms reachable; effects and environments styled",
		_test_level_layout_rules
	)
	failures += _run("Cowboy player has movement animations", _test_cowboy_animations)
	failures += _run("Lasso ties bandits and makes them pass-through", _test_lasso_ties_bandit)
	failures += _run("Campaign hazards are no longer blocked by plank highways", _test_no_plank_highways)
	failures += _run("Custom level store and builder work", _test_custom_level_builder)
	failures += _run("Hand-drawn celebration art and cheerful music load", _test_art_and_music)
	failures += _run("Mid-trail save data persists and loads", _test_mid_trail_save)
	failures += _run("Saved camp and badges restore inside a level", _test_level_run_restore)
	failures += _run("Pause menu exposes save, load, and restart from start", _test_pause_save_controls)

	if failures == 0:
		print("All tests passed.")
		get_tree().quit(0)
	else:
		printerr("Tests failed: %d" % failures)
		get_tree().quit(1)


func _run(name: String, callable: Callable) -> int:
	var error: Variant = callable.call()
	if error == null:
		print("PASS: %s" % name)
		return 0
	printerr("FAIL: %s -> %s" % [name, str(error)])
	return 1


func _test_coyote_jump() -> Variant:
	var assist := JumpAssist.new(0.12, 0.12)
	assist.notify_grounded(true)
	assist.tick(0.016)
	assist.notify_grounded(false)
	assist.tick(0.05)
	if not assist.can_start_jump(false):
		return "Expected coyote jump to remain available."
	assist.tick(0.2)
	if assist.can_start_jump(false):
		return "Expected coyote window to expire."
	return null


func _test_jump_buffer() -> Variant:
	var assist := JumpAssist.new(0.12, 0.12)
	assist.notify_jump_pressed()
	assist.tick(0.05)
	assist.notify_grounded(true)
	if not assist.should_consume_buffered_jump(true):
		return "Expected buffered jump on landing."
	return null


func _test_consume_clears_state() -> Variant:
	var assist := JumpAssist.new(0.12, 0.12)
	assist.notify_grounded(true)
	assist.notify_jump_pressed()
	assist.consume_jump()
	if assist.coyote_remaining() != 0.0 or assist.buffer_remaining() != 0.0:
		return "Expected timers cleared."
	return null


func _test_input_bindings_actions() -> Variant:
	var required: Array[StringName] = [
		&"move_left", &"move_right", &"jump", &"lasso", &"next_level",
		&"pause", &"confirm", &"back",
		&"ui_up", &"ui_down", &"ui_left", &"ui_right",
	]
	for action in required:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			return "Missing input action: %s" % String(action)
	return null


func _test_mode_controller() -> Variant:
	var modes := ModeController.new()
	if not is_equal_approx(modes.wings_duration, 30.0):
		return "Wings should start at 30 seconds."
	if not is_equal_approx(modes.boots_duration, 30.0):
		return "Magic Boots should start at 30 seconds."
	if not is_equal_approx(modes.speed_duration, 30.0):
		return "Speed Star should start at 30 seconds."
	if not is_equal_approx(modes.shield_duration, 15.0):
		return "Bubble Shield should start at 15 seconds."
	modes.activate(ModeController.Mode.BUBBLE_SHIELD)
	if not modes.has_shield():
		return "Expected bubble shield."
	modes.tick(modes.shield_duration + 0.1)
	if modes.has_shield():
		return "Expected shield expiry."
	modes.activate(ModeController.Mode.WINGS)
	if not modes.is_flying():
		return "Expected flying mode."
	modes.activate(ModeController.Mode.SPEED_STAR)
	if modes.move_speed_multiplier() <= 1.0:
		return "Expected speed boost."
	modes.activate(ModeController.Mode.MAGIC_BOOTS)
	if modes.jump_multiplier() <= 1.0:
		return "Expected jump boost."
	var before_badge := modes.remaining
	modes.extend_from_badge()
	if not is_equal_approx(modes.remaining - before_badge, 5.0):
		return "A badge should add exactly five seconds to the active mode."
	return null


func _test_save_slots() -> Variant:
	GameManager.erase_slot(0)
	GameManager.erase_slot(1)
	GameManager.erase_slot(2)
	if not GameManager.is_slot_empty(0):
		return "Slot 0 should be empty."
	GameManager.debug_set_slot(0, {
		"empty": false,
		"current_level": 1,
		"stars": 0,
		"play_time_sec": 0.0,
		"completed": false,
	})
	GameManager.active_slot_index = 0
	GameManager.complete_level(1, 2)
	var updated := GameManager.get_slot(0)
	if int(updated.get("current_level", 0)) != 2:
		return "Completing level 1 should unlock level 2."
	if int(updated.get("stars", 0)) != 2:
		return "Stars should be stored."
	GameManager.save_to_disk()
	GameManager.load_from_disk()
	var reloaded := GameManager.get_slot(0)
	if int(reloaded.get("current_level", 0)) != 2:
		return "Save data did not persist."
	GameManager.erase_slot(0)
	return null


func _test_save_select_scene() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	if scene.get_node_or_null("Slots/Slot1") == null:
		scene.queue_free()
		return "Save select missing slots."
	scene.queue_free()
	return null


func _test_level_01_world_objects() -> Variant:
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		return level
	var node := level as LevelController
	var error: Variant = null
	if node.find_child("Checkpoint", true, false) == null:
		error = "Missing Checkpoint."
	elif node.find_child("Goal", true, false) == null:
		error = "Missing Goal."
	elif node.find_child("PauseMenu", true, false) == null:
		error = "Missing PauseMenu."
	elif node.find_child("Hud", true, false) == null:
		error = "Missing Hud."
	_free_level(node)
	return error


func _test_ten_levels_exist() -> Variant:
	if GameManager.LEVEL_SCENES.size() != 10:
		return "Expected 10 levels."
	for path in GameManager.LEVEL_SCENES:
		if load(path) == null:
			return "Missing scene: %s" % path
	return null


func _test_respawn_uses_checkpoint() -> Variant:
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		return level
	var controller := level as LevelController
	var checkpoint := controller.find_child("Checkpoint", true, false) as Checkpoint
	checkpoint.activate()
	controller.respawn_player()
	var error: Variant = null
	if controller.player.global_position.distance_to(checkpoint.get_respawn_position()) > 0.1:
		error = "Respawn position mismatch."
	_free_level(controller)
	return error


func _test_goal_disables_input() -> Variant:
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		return level
	var controller := level as LevelController
	controller.begin_completion()
	var error: Variant = null
	if controller.player.input_enabled:
		error = "Input should be disabled."
	_free_level(controller)
	return error


func _test_shield_blocks_damage_flag() -> Variant:
	var player := Player.new()
	add_child(player)
	player.activate_mode(ModeController.Mode.BUBBLE_SHIELD)
	if not player.is_invulnerable():
		player.queue_free()
		return "Shield should grant invulnerability."
	player.clear_modes()
	var still := player.is_invulnerable()
	player.queue_free()
	if still:
		return "Clearing modes should remove shield."
	return null


func _test_input_manager_prompts() -> Variant:
	InputManager.active_device = InputManager.Device.KEYBOARD
	var keyboard_jump := InputManager.prompt_for(&"jump")
	InputManager.active_device = InputManager.Device.CONTROLLER
	var controller_jump := InputManager.prompt_for(&"jump")
	if keyboard_jump == controller_jump:
		return "Keyboard and controller prompts should differ."
	return null


func _test_star_reachability() -> Variant:
	var jump_h := StarReachability.max_jump_height()
	var boots_h := StarReachability.max_boots_jump_height()
	if jump_h < 80.0 or jump_h > 90.0:
		return "Unexpected base jump height: %s" % str(jump_h)
	if boots_h <= jump_h:
		return "Boots jump should be higher than base jump."
	if not StarReachability.is_star_reachable_from_surface(320.0, 280.0, jump_h):
		return "Ground-adjacent star at y=280 should be reachable."
	if StarReachability.is_star_reachable_from_surface(320.0, 200.0, jump_h):
		return "Star 120px above ground should be unreachable without assists."
	if not StarReachability.is_star_reachable_from_surface(194.0, 170.0, jump_h):
		return "Star above level 6 platform should be reachable once mounted."
	if not StarReachability.is_star_reachable_from_surface(320.0, 194.0, boots_h, 12.0):
		return "Magic Boots should be able to mount the level 6 platform."
	return null


func _test_level_layout_rules() -> Variant:
	for path in GameManager.LEVEL_SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			return "Missing level: %s" % path
		var level: Node = packed.instantiate()
		add_child(level)
		if level is LevelController:
			(level as LevelController).setup_level()
		var errors := LevelLayoutRules.validate_level_node(level)
		level.queue_free()
		if not errors.is_empty():
			return "%s -> %s" % [path, ", ".join(errors)]
	return null


func _test_cowboy_animations() -> Variant:
	var packed: PackedScene = load("res://scenes/player/player.tscn")
	if packed == null:
		return "Missing player scene."
	var node := packed.instantiate()
	add_child(node)
	var cowboy := node as Player
	if cowboy == null:
		node.queue_free()
		return "Player scene root is not Player."
	var sprite := cowboy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		node.queue_free()
		return "Cowboy AnimatedSprite2D frames were not set up."
	for anim_name in [&"idle", &"run", &"jump", &"celebrate"]:
		if not sprite.sprite_frames.has_animation(anim_name):
			node.queue_free()
			return "Missing cowboy animation: %s" % String(anim_name)
		if sprite.sprite_frames.get_frame_count(anim_name) < 1:
			node.queue_free()
			return "Cowboy animation has no frames: %s" % String(anim_name)
	node.queue_free()
	return null


func _test_lasso_ties_bandit() -> Variant:
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	if packed == null:
		return "Missing opponent scene."
	var node := packed.instantiate()
	add_child(node)
	var bandit := node as Opponent
	if bandit == null:
		node.queue_free()
		return "Opponent scene root is not Opponent."
	bandit.bounty_bandit = true
	var bounty_amount := [0]
	bandit.bounty_caught.connect(func(_opponent: Opponent, amount: int) -> void:
		bounty_amount[0] = amount
	)
	bandit.tie_up()
	if not bandit.is_tied():
		node.queue_free()
		return "A lasso hit should tie the bandit."
	if bandit.collision_layer != 0:
		node.queue_free()
		return "Tied bandits should not block the cowboy."
	if bandit.get_node_or_null("TiedRopes") == null:
		node.queue_free()
		return "Tied bandits should show rope artwork."
	var walk := bandit.get_node_or_null("WalkSprite") as AnimatedSprite2D
	if walk == null or walk.sprite_frames == null or not walk.sprite_frames.has_animation(&"tied"):
		node.queue_free()
		return "Tied bandits should switch to the floor-bound sprite."
	if bandit.z_index >= 0:
		node.queue_free()
		return "Tied bandit and rope should render behind the cowboy."
	if int(bounty_amount[0]) != 2:
		node.queue_free()
		return "A red-scarf bounty bandit should award two badges."
	node.queue_free()
	return null


func _test_no_plank_highways() -> Variant:
	for path in GameManager.LEVEL_SCENES:
		var packed: PackedScene = load(path)
		var level := packed.instantiate()
		var numbered_planks := 0
		for node in level.find_children("Platform*", "StaticBody2D", true, false):
			if String(node.name).trim_prefix("Platform").is_valid_int():
				numbered_planks += 1
		level.free()
		if numbered_planks > 12:
			return "%s still has a blocking plank highway." % path
	return null


func _test_custom_level_builder() -> Variant:
	var slot := 2
	var data := CustomLevelStore.default_level(slot)
	if not CustomLevelStore.save(slot, data):
		return "Could not save custom trail."
	var loaded := CustomLevelStore.load_level(slot)
	if str(loaded.get("title", "")) != "Family Trail 3":
		CustomLevelStore.erase(slot)
		return "Custom trail did not round-trip."
	var level := LevelController.new()
	level.is_custom_level = true
	CustomLevelBuilder.build(level, loaded)
	var error: Variant = null
	if level.get_node_or_null("SpawnPoint") == null:
		error = "Custom builder missing SpawnPoint."
	elif level.find_child("Goal", true, false) == null:
		error = "Custom builder missing Goal."
	elif level.find_child("Player", true, false) == null:
		error = "Custom builder missing Player."
	elif level.find_child("Ground0", true, false) == null:
		error = "Custom builder missing ground."
	level.free()
	CustomLevelStore.erase(slot)
	return error


func _test_art_and_music() -> Variant:
	var texture: Texture2D = load("res://assets/player/celebrate.png")
	if texture == null:
		return "Hand-drawn celebration art did not load."
	for path in [
		"res://assets/world/sky_handdrawn.png",
		"res://assets/world/trail_desert_tile.png",
		"res://assets/world/trail_dirt_tile.png",
		"res://assets/world/horizon_hills_strip.png",
		"res://assets/world/canyon_gap.png",
	]:
		if load(path) == null:
			return "Missing hand-drawn world art: %s" % path
	var music: AudioStream = load("res://assets/audio/cheerful_cowboy_trail.wav")
	if music == null:
		return "Cheerful trail music did not load."
	if AudioServer.get_bus_index(&"Music") < 0:
		return "Music bus was not created."
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		return level
	var controller := level as LevelController
	if controller.get_node_or_null("SkyArt") == null:
		controller.queue_free()
		return "Level is missing hand-drawn sky art."
	if controller.get_node_or_null("TrailFloor") == null:
		controller.queue_free()
		return "Level is missing hand-drawn trail floor."
	if controller.get_node_or_null("HorizonHills") == null:
		controller.queue_free()
		return "Level is missing endless horizon hills."
	var pit := controller.find_child("Pit3", true, false) as Hazard
	if pit == null:
		controller.queue_free()
		return "Level fixture is missing Pit3."
	var pit_mouth := pit.get_node_or_null("PitMouth") as Sprite2D
	if pit_mouth == null or not pit_mouth.visible or pit_mouth.texture == null:
		controller.queue_free()
		return "Pit canyon mouth was not configured."
	var floor_top := 320.0
	var tex_h := float(pit_mouth.texture.get_height())
	var world_top := (
		pit.global_position.y
		+ (pit_mouth.position.y - tex_h * 0.5 * pit_mouth.scale.y) * pit.scale.y
	)
	if absf(world_top - floor_top) > 4.0:
		controller.queue_free()
		return "Canyon rim should meet the trail floor (top=%.1f, expected %.1f)." % [world_top, floor_top]
	# Opening should cover the fall gap between Ground2 and Ground3.
	var g2 := controller.get_node_or_null("Ground2/Visual") as ColorRect
	var g3 := controller.get_node_or_null("Ground3/Visual") as ColorRect
	if g2 != null and g3 != null:
		var gap_left: float = controller.get_node("Ground2").position.x + maxf(g2.offset_left, g2.offset_right)
		var gap_right: float = controller.get_node("Ground3").position.x + minf(g3.offset_left, g3.offset_right)
		var tex_w := float(pit_mouth.texture.get_width())
		var world_w := tex_w * pit_mouth.scale.x * pit.scale.x
		var center_x := pit.global_position.x + pit_mouth.position.x * pit.scale.x
		var open_left := center_x - world_w * 0.5 + world_w * Hazard.OPENING_LEFT
		var open_right := center_x - world_w * 0.5 + world_w * Hazard.OPENING_RIGHT
		if absf(open_left - gap_left) > 12.0 or absf(open_right - gap_right) > 12.0:
			controller.queue_free()
			return "Canyon borders should match the fall gap (open=%.0f..%.0f gap=%.0f..%.0f)." % [
				open_left, open_right, gap_left, gap_right
			]
	controller.queue_free()
	return null


func _test_mid_trail_save() -> Variant:
	GameManager.erase_slot(0)
	GameManager.debug_set_slot(0, {
		"empty": false,
		"current_level": 3,
	})
	GameManager.active_slot_index = 0
	var badges: Array[String] = ["TrailStar0", "SpringStar2"]
	if not GameManager.save_run_state(3, "CheckpointB", badges, 2, 45.5):
		return "Could not save mid-trail state."
	GameManager.load_from_disk()
	var state := GameManager.get_run_state(3)
	var error: Variant = null
	if state.is_empty():
		error = "Saved run state did not persist."
	elif str(state.get("checkpoint_name", "")) != "CheckpointB":
		error = "Saved checkpoint did not persist."
	elif int(state.get("stars_found", 0)) != 2:
		error = "Saved badge count did not persist."
	elif (state.get("collected_badges", []) as Array).size() != 2:
		error = "Collected badge identities did not persist."
	GameManager.clear_run_state()
	if GameManager.has_run_state(3):
		error = "Clearing run state should remove the load point."
	GameManager.erase_slot(0)
	return error


func _test_pause_save_controls() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	if packed == null:
		return "Missing pause menu scene."
	var menu := packed.instantiate()
	add_child(menu)
	var error: Variant = null
	for path in [
		"Panel/Margin/VBox/SaveButton",
		"Panel/Margin/VBox/LoadButton",
		"Panel/Margin/VBox/RestartButton",
		"Panel/Margin/VBox/SaveSelectButton",
	]:
		if menu.get_node_or_null(path) == null:
			error = "Pause menu missing %s." % path
			break
	var restart := menu.get_node_or_null("Panel/Margin/VBox/RestartButton") as Button
	if error == null and restart != null and restart.text != "Restart from Start":
		error = "Restart action should clearly say it starts over."
	var start_screen := menu.get_node_or_null("Panel/Margin/VBox/SaveSelectButton") as Button
	if error == null and start_screen != null and start_screen.text != "Back to Start Screen":
		error = "Pause menu should offer a clear return to the start screen."
	menu.queue_free()
	return error


func _test_level_run_restore() -> Variant:
	GameManager.erase_slot(0)
	GameManager.debug_set_slot(0, {"empty": false, "current_level": 1})
	GameManager.active_slot_index = 0
	var badges: Array[String] = ["TrailStar0"]
	GameManager.save_run_state(1, "CheckpointB", badges, 1, 12.0)
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		GameManager.erase_slot(0)
		return level
	var controller := level as LevelController
	var checkpoint := controller.find_child("CheckpointB", true, false) as Checkpoint
	var error: Variant = null
	if checkpoint == null:
		error = "Level fixture is missing CheckpointB."
	elif controller.player.stars_collected != 1:
		error = "Saved badge count was not restored to the player."
	elif controller.get_active_respawn_position().distance_to(checkpoint.get_respawn_position()) > 0.1:
		error = "Saved camp was not restored as the active respawn."
	var saved_badge := controller.find_child("TrailStar0", true, false) as Star
	if error == null and saved_badge != null and saved_badge.visible:
		error = "Previously collected badge should stay hidden after loading."
	_free_level(controller)
	GameManager.erase_slot(0)
	return error


func _instantiate_level(path: String) -> Variant:
	var packed: PackedScene = load(path)
	if packed == null:
		return "Failed to load: %s" % path
	var level: Node = packed.instantiate()
	if not (level is LevelController):
		level.free()
		return "Root is not LevelController."
	add_child(level)
	(level as LevelController).setup_level()
	if (level as LevelController).player == null:
		_free_level(level)
		return "Player missing."
	return level


func _free_level(level: Node) -> void:
	if is_instance_valid(level):
		level.queue_free()
