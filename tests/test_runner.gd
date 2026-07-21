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
	failures += _run("Portable saves fall back when exe folder is read-only", _test_save_paths_writable_fallback)
	failures += _run("Save select scene loads", _test_save_select_scene)
	failures += _run("Level 01 contains core objects", _test_level_01_world_objects)
	failures += _run("Level catalog has ten scenes", _test_ten_levels_exist)
	failures += _run("LevelController respawns at checkpoint", _test_respawn_uses_checkpoint)
	failures += _run("Camp restores tied bandits and active bonuses", _test_camp_restores_state)
	failures += _run("Goal completion disables player input", _test_goal_disables_input)
	failures += _run("Flying over the saloon still finishes the trail", _test_goal_triggers_when_flying_over)
	failures += _run("Bubble shield blocks opponent damage flag", _test_shield_blocks_damage_flag)
	failures += _run("Bubble shield does not block canyon falls", _test_canyon_ignores_bubble_shield)
	failures += _run("InputManager device prompts", _test_input_manager_prompts)
	failures += _run("Star reachability heuristics", _test_star_reachability)
	failures += _run(
		"Levels complete; platforms reachable; effects and environments styled",
		_test_level_layout_rules
	)
	failures += _run("Cowboy player has movement animations", _test_cowboy_animations)
	failures += _run("Lasso ties bandits and makes them pass-through", _test_lasso_ties_bandit)
	failures += _run("Lasso cast ties bandits via HurtArea", _test_lasso_cast_hits_hurt_area)
	failures += _run("Jumping on a bandit head ties him", _test_stomp_ties_bandit)
	failures += _run("Side contact with a bandit sends the cowboy to camp", _test_side_contact_hurts)
	failures += _run("Controller bindings match every gamepad device", _test_controller_all_devices)
	failures += _run("Flying levels guard the very top of the screen", _test_flying_levels_top_guarded)
	failures += _run("Timed door shows a clear open/closed barrier", _test_timed_door_states)
	failures += _run("Untied bandits restore normal standing size", _test_untie_restores_stand_scale)
	failures += _run("Campaign hazards are no longer blocked by plank highways", _test_no_plank_highways)
	failures += _run("Custom level store and builder work", _test_custom_level_builder)
	failures += _run("Hand-drawn celebration art and cheerful music load", _test_art_and_music)
	failures += _run("Mid-trail save data persists and loads", _test_mid_trail_save)
	failures += _run("Saved camp and badges restore inside a level", _test_level_run_restore)
	failures += _run("Pause menu exposes save, load, and restart from start", _test_pause_save_controls)
	failures += _run("Boss arenas expose lasso targets and solvable kingpin layout", _test_boss_arenas)

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
		&"move_left", &"move_right", &"jump", &"lasso", &"next_level", &"next_boss",
		&"pause", &"confirm", &"back",
		&"ui_up", &"ui_down", &"ui_left", &"ui_right",
	]
	for action in required:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			return "Missing input action: %s" % String(action)
	var has_boss_minus := false
	for event in InputMap.action_get_events(&"next_boss"):
		if event is InputEventKey:
			var key := event as InputEventKey
			if key.physical_keycode == KEY_KP_SUBTRACT or key.keycode == KEY_KP_SUBTRACT:
				has_boss_minus = true
				break
	if not has_boss_minus:
		return "next_boss should include numpad minus (KEY_KP_SUBTRACT)."
	return null


func _test_boss_arenas() -> Variant:
	var bull_packed: PackedScene = load("res://scenes/bosses/boss_stampede_bull.tscn")
	var coach_packed: PackedScene = load("res://scenes/bosses/boss_midnight_coach.tscn")
	var king_packed: PackedScene = load("res://scenes/bosses/boss_outlaw_kingpin.tscn")
	if bull_packed == null or coach_packed == null or king_packed == null:
		return "Missing one or more boss scenes."
	var bull := bull_packed.instantiate()
	add_child(bull)
	var ring := bull.get_node_or_null("Bull/LassoRing")
	if ring == null or not ring.has_method("lasso_hit") or not (ring is Area2D):
		bull.queue_free()
		return "Stampede Bull needs an Area2D lasso ring with lasso_hit."
	if bull.get_node_or_null("WallLeft") == null or bull.get_node_or_null("WallRight") == null:
		bull.queue_free()
		return "Stampede Bull arena needs left and right walls."
	for art_path in [
		"res://assets/world/boss_stampede_bull.png",
		"res://assets/world/boss_stampede_bull_tied_legs.png",
		"res://assets/world/boss_stampede_bull_down.png",
	]:
		if load(art_path) == null:
			bull.queue_free()
			return "Missing bull art: %s" % art_path
	var spawn := bull.get_node_or_null("SpawnPoint") as Marker2D
	var wall_l := bull.get_node_or_null("WallLeft") as Node2D
	var wall_r := bull.get_node_or_null("WallRight") as Node2D
	if spawn == null or wall_l == null or wall_r == null:
		bull.queue_free()
		return "Bull arena missing spawn or walls."
	if spawn.position.x <= wall_l.position.x or spawn.position.x >= wall_r.position.x:
		bull.queue_free()
		return "Player spawn must be between the bull arena walls."
	bull.queue_free()

	var coach := coach_packed.instantiate()
	add_child(coach)
	for i in range(3):
		var door := coach.get_node_or_null("Coach/Door%d" % i)
		if door == null or not door.has_method("lasso_hit") or not (door is Area2D):
			coach.queue_free()
			return "Midnight Coach door %d must be an Area2D lasso target." % i
	if coach.get_node_or_null("Coach") is AnimatableBody2D:
		coach.queue_free()
		return "Coach root should not be a solid AnimatableBody2D."
	for frame_path in [
		"res://assets/world/boss_midnight_coach_0.png",
		"res://assets/world/boss_midnight_coach_1.png",
		"res://assets/world/boss_midnight_coach_2.png",
		"res://assets/world/boss_midnight_coach_3.png",
		"res://assets/world/boss_midnight_coach_surrender.png",
	]:
		if load(frame_path) == null:
			coach.queue_free()
			return "Missing coach door frame: %s" % frame_path
	coach.queue_free()

	var king := king_packed.instantiate()
	add_child(king)
	var kingpin := king.get_node_or_null("Kingpin")
	var target := king.get_node_or_null("Kingpin/LassoTarget")
	var guard0 := king.get_node_or_null("Guard0") as Node2D
	var guard1 := king.get_node_or_null("Guard1") as Node2D
	if kingpin is AnimatableBody2D:
		king.queue_free()
		return "Kingpin must not be a solid AnimatableBody2D blocking the path."
	if target == null or not target.has_method("lasso_hit") or not (target is Area2D):
		king.queue_free()
		return "Kingpin needs an Area2D lasso target."
	if guard0 == null or guard1 == null or kingpin == null:
		king.queue_free()
		return "Kingpin arena missing guards or boss node."
	if guard0.position.x >= (kingpin as Node2D).position.x or guard1.position.x >= (kingpin as Node2D).position.x:
		king.queue_free()
		return "Guards must stand in front (left) of the kingpin."
	king.queue_free()

	# Shared 5-heart boss logic lives on BossArena.
	for packed in [bull_packed, coach_packed, king_packed]:
		var arena: Node = packed.instantiate()
		add_child(arena)
		if not arena.has_method("lose_heart") or not arena.has_method("get_heart_drop_position"):
			arena.queue_free()
			return "Boss arenas must expose lose_heart / get_heart_drop_position."
		if int(arena.get("max_hearts")) != 5:
			arena.queue_free()
			return "Boss arenas should start with 5 hearts."
		arena.queue_free()
	var player_probe := Player.new()
	if not player_probe.has_method("play_boss_heart_recovery"):
		player_probe.free()
		return "Player needs play_boss_heart_recovery for boss heart drops."
	player_probe.free()
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
	modes.restore(ModeController.Mode.WINGS, 7.0, 20.0)
	if not modes.is_flying() or not is_equal_approx(modes.remaining, 20.0):
		return "A camp-restored mode should have at least twenty seconds."
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
	var path := GameManager.save_path()
	if not str(path).contains("savegames"):
		return "Saves should live under a savegames folder, got: %s" % path
	if not FileAccess.file_exists(path):
		return "Save file was not written to disk."
	GameManager.load_from_disk()
	var reloaded := GameManager.get_slot(0)
	if int(reloaded.get("current_level", 0)) != 2:
		return "Save data did not persist."
	# Older save formats must be rejected.
	var path_write := FileAccess.open(path, FileAccess.WRITE)
	if path_write == null:
		return "Could not rewrite save for version test."
	path_write.store_string(JSON.stringify({
		"version": GameManager.SAVE_VERSION - 1,
		"slots": [{"empty": false, "current_level": 9, "stars": 99}],
		"settings": {},
	}, "\t"))
	path_write = null
	GameManager.load_from_disk()
	if not GameManager.is_slot_empty(0):
		return "Saves from older game versions should be discarded."
	if int(GameManager.get_slot(0).get("current_level", 0)) == 9:
		return "Old save progress must not remain after a version bump."
	GameManager.erase_slot(0)
	return null


func _test_save_paths_writable_fallback() -> Variant:
	var save_paths := preload("res://scripts/autoload/save_paths.gd")
	var root: String = save_paths.root_dir()
	if not root.contains(save_paths.FOLDER_NAME):
		return "Save root should live under a savegames folder, got: %s" % root
	# A fresh directory in a writable place is reported writable.
	var writable := OS.get_user_data_dir().path_join("write_probe_%d" % Time.get_ticks_usec())
	if not save_paths._dir_is_writable(writable):
		return "Expected a fresh user directory to be writable: %s" % writable
	DirAccess.remove_absolute(writable)
	# A location that cannot be created (nested inside a file) is not writable —
	# this is what triggers the per-user fallback for a read-only exe folder.
	var blocker := OS.get_user_data_dir().path_join("blocker_%d" % Time.get_ticks_usec())
	var handle := FileAccess.open(blocker, FileAccess.WRITE)
	if handle == null:
		return "Could not create blocker file for writability test."
	handle.store_8(0)
	handle = null
	var not_writable: bool = save_paths._dir_is_writable(blocker.path_join(save_paths.FOLDER_NAME))
	DirAccess.remove_absolute(blocker)
	if not_writable:
		return "A directory nested inside a file must not be reported writable."
	return null


func _test_save_select_scene() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		return "Missing save select scene."
	GameManager.erase_slot(0)
	GameManager.debug_set_slot(0, {"empty": false, "current_level": 4})
	var scene := packed.instantiate()
	add_child(scene)
	var error: Variant = null
	if scene.get_node_or_null("Slots/Slot1") == null:
		error = "Save select missing slots."
	var delete_button := scene.get_node_or_null("DeleteSaveButton") as Button
	if error == null and delete_button == null:
		error = "Save select needs a visible Delete Save button."
	elif error == null and delete_button.disabled:
		error = "Delete Save should be enabled for a non-empty highlighted slot."
	if error == null:
		scene._request_delete()
		if GameManager.is_slot_empty(0):
			error = "Delete Save must ask for confirmation before erasing."
		elif not delete_button.text.contains("CONFIRM"):
			error = "Delete Save confirmation should be explicit."
	if error == null:
		scene._request_delete()
		if not GameManager.is_slot_empty(0):
			error = "Confirming Delete Save should erase the highlighted slot."
	scene.queue_free()
	GameManager.erase_slot(0)
	return error


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


func _test_camp_restores_state() -> Variant:
	var level: Variant = _instantiate_level("res://scenes/levels/level_05.tscn")
	if level is String:
		return level
	var controller := level as LevelController
	var bandit := controller.find_child("Opponent0", true, false) as Opponent
	var checkpoint_b := controller.find_child("CheckpointB", true, false) as Checkpoint
	if bandit == null or checkpoint_b == null:
		_free_level(controller)
		return "Camp-state fixture is missing a bandit or checkpoint."
	bandit.tie_up(false)
	controller.respawn_player()
	if bandit.is_tied():
		_free_level(controller)
		return "A bandit tied after the camp should be untied on respawn."
	bandit.tie_up(false)
	controller.player.activate_mode(ModeController.Mode.WINGS)
	controller.player.get_modes().remaining = 7.0
	checkpoint_b.activate()
	controller.player.get_modes().remaining = 1.0
	controller.respawn_player()
	var error: Variant = null
	if not bandit.is_tied():
		error = "A bandit tied before camp activation should stay tied."
	elif not controller.player.get_modes().is_flying():
		error = "The active camp bonus should be restored."
	elif controller.player.get_modes().remaining < 20.0:
		error = "A restored camp bonus should have at least twenty seconds."
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
	elif controller.player.visible:
		error = "Cowboy should switch from the player sprite to the horse transition."
	elif controller.transition == null:
		error = "Horse transition is missing."
	elif controller.transition.get_node_or_null("TrailHorse") == null:
		error = "Horse transition should create the saddle horse."
	elif controller.transition.get_node_or_null("CowboyHorse") == null:
		error = "Horse transition should create the mounted cowboy."
	_free_level(controller)
	return error


func _test_goal_triggers_when_flying_over() -> Variant:
	var goal_scene: PackedScene = load("res://scenes/world/goal.tscn")
	var goal := goal_scene.instantiate() as Goal
	add_child(goal)
	goal.global_position = Vector2(5000, 400)

	var player := Player.new()
	add_child(player)
	# High above the doorway — would miss the collision box while flying.
	player.global_position = Vector2(5000, 40)

	goal._process(0.016)
	var error: Variant = null
	if not goal.is_triggered():
		error = "Reaching the saloon's X while flying high should finish the trail."
	player.queue_free()
	goal.queue_free()
	return error


func _test_shield_blocks_damage_flag() -> Variant:
	var player := Player.new()
	add_child(player)
	player.activate_mode(ModeController.Mode.BUBBLE_SHIELD)
	if not player.is_invulnerable():
		player.queue_free()
		return "Shield should grant invulnerability."
	if player.has_timed_invulnerability():
		player.queue_free()
		return "Shield alone should not count as timed invulnerability."
	player.clear_modes()
	var still := player.is_invulnerable()
	player.queue_free()
	if still:
		return "Clearing modes should remove shield."
	return null


func _test_canyon_ignores_bubble_shield() -> Variant:
	var player := Player.new()
	add_child(player)
	player.activate_mode(ModeController.Mode.BUBBLE_SHIELD)
	var hazard := Hazard.new()
	hazard.scale = Vector2(2.0, 2.0)
	add_child(hazard)
	var emitted := {"hit": false}
	hazard.hurt.connect(func(_p: Player) -> void: emitted["hit"] = true)
	hazard._on_body_entered(player)
	var hit: bool = emitted["hit"]
	player.queue_free()
	hazard.queue_free()
	if not hit:
		return "Canyon should hurt the player even with a Bubble Shield."
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
	var hurt_area := bandit.get_node_or_null("HurtArea") as Area2D
	if hurt_area == null or hurt_area.collision_layer == 0 or not hurt_area.monitorable:
		node.queue_free()
		return "Bandit HurtArea must be lasso-detectable on layer 1."
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


func _test_lasso_cast_hits_hurt_area() -> Variant:
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	var bandit := packed.instantiate() as Opponent
	bandit.position = Vector2(300, 400)
	add_child(bandit)
	var lasso := LassoCast.new()
	lasso.position = Vector2(200, 360)
	add_child(lasso)
	lasso.setup(1.0)
	var hurt := bandit.get_node_or_null("HurtArea") as Area2D
	lasso._on_area_entered(hurt)
	var error: Variant = null
	if not bandit.is_tied():
		error = "Lasso should tie a bandit when it hits HurtArea."
	lasso.queue_free()
	bandit.queue_free()
	return error


func _test_stomp_ties_bandit() -> Variant:
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	var bandit := packed.instantiate() as Opponent
	bandit.position = Vector2(200, 400)
	add_child(bandit)
	var player := Player.new()
	player.position = Vector2(200, 360)
	add_child(player)
	# Landing on the bandit zeroes fall speed — stomps must still count by height.
	player.velocity = Vector2.ZERO
	var hurt := [false]
	bandit.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	bandit._on_body_entered(player)
	var error: Variant = null
	if not bandit.is_tied():
		error = "Jumping onto a bandit's head should tie him even after landing."
	elif hurt[0]:
		error = "A head stomp should not hurt the cowboy."
	elif player.velocity.y >= 0.0:
		error = "A head stomp should bounce the cowboy upward."
	player.queue_free()
	bandit.queue_free()
	return error


func _test_side_contact_hurts() -> Variant:
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	var bandit := packed.instantiate() as Opponent
	bandit.position = Vector2(200, 400)
	add_child(bandit)
	var player := Player.new()
	# Same feet height as the bandit = a side bump, not a head stomp.
	player.position = Vector2(200, 400)
	add_child(player)
	var hurt := [false]
	bandit.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	bandit._on_body_entered(player)
	var error: Variant = null
	if bandit.is_tied():
		error = "Walking into a bandit's side must not tie him."
	elif not hurt[0]:
		error = "Any non-stomp contact should send the cowboy back to camp."
	player.queue_free()
	bandit.queue_free()
	return error


func _test_controller_all_devices() -> Variant:
	for action in [&"jump", &"move_left", &"move_right", &"lasso", &"pause"]:
		var found := false
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				found = true
				if event.device != -1:
					return "Controller binding for %s must match all devices (device=-1)." % String(action)
		if not found:
			return "Action %s has no controller binding." % String(action)
	return null


func _test_flying_levels_top_guarded() -> Variant:
	for lv in ["02", "06", "07", "10"]:
		var packed: PackedScene = load("res://scenes/levels/level_%s.tscn" % lv)
		if packed == null:
			return "Missing flying level %s." % lv
		var level := packed.instantiate()
		add_child(level)
		var top_guards := 0
		for node in level.find_children("*", "Area2D", true, false):
			if node is Carrion and (node as Node2D).global_position.y <= -200.0:
				top_guards += 1
		level.queue_free()
		if top_guards < 5:
			return "Level %s needs carrions guarding the very top (found %d)." % [lv, top_guards]
	return null


func _test_timed_door_states() -> Variant:
	var packed: PackedScene = load("res://scenes/world/timed_door.tscn")
	if packed == null:
		return "Missing timed door scene."
	var door := packed.instantiate() as TimedDoor
	add_child(door)
	var barrier := door.get_node_or_null("Barrier") as ColorRect
	var error: Variant = null
	if barrier == null:
		error = "Timed door needs a visible barrier fill so its state is clear."
	else:
		door._open = false
		door._apply_state(false)
		var closed_color := barrier.color
		door._open = true
		door._apply_state(false)
		var open_color := barrier.color
		if closed_color.is_equal_approx(open_color):
			error = "Open and closed gates must look clearly different."
		elif closed_color.a <= open_color.a:
			error = "A closed gate should read as a solid, blocking barrier."
	door.queue_free()
	return error


func _test_untie_restores_stand_scale() -> Variant:
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	var bandit := packed.instantiate() as Opponent
	add_child(bandit)
	var walk := bandit.get_node_or_null("WalkSprite") as AnimatedSprite2D
	if walk == null:
		bandit.queue_free()
		return "Bandit walk sprite missing."
	var stand := bandit.get_stand_scale()
	bandit.tie_up(false)
	bandit.untie_for_respawn()
	var error: Variant = null
	if not is_equal_approx(absf(walk.scale.y), stand):
		error = "Respawned bandits should return to normal standing size."
	elif not is_equal_approx(absf(walk.scale.x), stand):
		error = "Respawned bandit width should match standing size."
	bandit.queue_free()
	return error


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
		"res://assets/world/trail_horse.png",
		"res://assets/world/cowboy_horse_ride_0.png",
		"res://assets/world/cowboy_horse_ride_1.png",
		"res://assets/world/lantern_fly_0.png",
		"res://assets/world/lantern_fly_1.png",
		"res://assets/world/lantern_ground.png",
		"res://assets/world/sunset_backdrop.png",
		"res://assets/world/sunset_rider_0.png",
		"res://assets/world/sunset_rider_1.png",
	]:
		if load(path) == null:
			return "Missing hand-drawn world art: %s" % path
	var music: AudioStream = load("res://assets/audio/cheerful_cowboy_trail.wav")
	if music == null:
		return "Cheerful trail music did not load."
	var country: AudioStream = load("res://assets/audio/country_version.mp3")
	if country == null:
		return "Country start/finale theme did not load."
	var victory_script := FileAccess.get_file_as_string("res://scripts/ui/victory_horizon.gd")
	if not victory_script.contains("VOM PAPI FÜR FINN"):
		return "Sunset finale should dedicate the trail: VOM PAPI FÜR FINN."
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
	var tied: Array[String] = ["Opponent1"]
	if not GameManager.save_run_state(
		3, "CheckpointB", badges, 2, 45.5, tied, ModeController.Mode.WINGS, 22.0
	):
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
	elif (state.get("tied_opponents", []) as Array).size() != 1:
		error = "Tied opponent identities did not persist."
	elif int(state.get("active_mode", 0)) != ModeController.Mode.WINGS:
		error = "Active camp bonus did not persist."
	elif not is_equal_approx(float(state.get("mode_remaining", 0.0)), 22.0):
		error = "Camp bonus timer did not persist."
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
	if error == null and restart != null and restart.text != "Restart Trail at Level 1":
		error = "Restart action should clearly say it returns to Level 1."
	var start_screen := menu.get_node_or_null("Panel/Margin/VBox/SaveSelectButton") as Button
	if error == null and start_screen != null and start_screen.text != "Back to Start Screen":
		error = "Pause menu should offer a clear return to the start screen."
	menu.queue_free()
	GameManager.erase_slot(0)
	GameManager.debug_set_slot(0, {
		"empty": false,
		"current_level": 8,
		"stars": 12,
		"completed": true,
		"resume": {"level_number": 8, "checkpoint_name": "CheckpointB"},
	})
	GameManager.active_slot_index = 0
	GameManager.reset_campaign_to_start()
	var reset_slot := GameManager.get_slot(0)
	if error == null and int(reset_slot.get("current_level", -1)) != 1:
		error = "Restart from Start must reset the active save to Level 1."
	elif error == null and not (reset_slot.get("resume", {}) as Dictionary).is_empty():
		error = "Restart from Start must clear the later-level checkpoint."
	elif error == null and int(reset_slot.get("stars", 0)) != 12:
		error = "Restarting at Level 1 should keep previously earned badges."
	GameManager.erase_slot(0)
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
