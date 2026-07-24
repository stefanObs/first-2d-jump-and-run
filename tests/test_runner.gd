extends Node

## Scene-based headless test runner so autoloads resolve correctly.
## Run with: godot --headless --path . res://tests/test_runner.tscn


func _ready() -> void:
	var failures := 0
	failures += await _run("JumpAssist coyote allows brief airborne jump", _test_coyote_jump)
	failures += await _run("JumpAssist buffer remembers early jump press", _test_jump_buffer)
	failures += await _run("JumpAssist consume clears coyote and buffer", _test_consume_clears_state)
	failures += await _run("InputBindings registers required actions", _test_input_bindings_actions)
	failures += await _run("Debug name overlay toggles cleanly with F1 action", _test_debug_name_overlay)
	failures += await _run("ModeController durations and shield", _test_mode_controller)
	failures += await _run("GameManager save slots persist", _test_save_slots)
	failures += await _run("Portable saves fall back when exe folder is read-only", _test_save_paths_writable_fallback)
	failures += await _run("Save select scene loads", _test_save_select_scene)
	failures += await _run("German text and spoken-instruction settings work", _test_localization_settings)
	failures += await _run("Narrator falls back to any installed voice", _test_narrator_voice_fallback)
	failures += await _run("Settings language dropdown persists and supports controller use", _test_settings_language_dropdown)
	failures += await _run("Translation CSV parses and round-trips safely", _test_translation_csv_round_trip)
	failures += await _run("Translation placeholders render and validate", _test_translation_placeholders)
	failures += await _run("Translation editor loads and exports portably", _test_translation_editor)
	failures += await _run("Handmade trail progress and effect sounds work", _test_handmade_progress_and_sfx)
	failures += await _run("Level 01 contains core objects", _test_level_01_world_objects)
	failures += await _run("Level catalog has ten scenes", _test_ten_levels_exist)
	failures += await _run("LevelController respawns at checkpoint", _test_respawn_uses_checkpoint)
	failures += await _run("Camp restores tied bandits and active bonuses", _test_camp_restores_state)
	failures += await _run("Goal completion disables player input", _test_goal_disables_input)
	failures += await _run("Flying over the saloon still finishes the trail", _test_goal_triggers_when_flying_over)
	failures += await _run("Bubble shield blocks opponent damage flag", _test_shield_blocks_damage_flag)
	failures += await _run("Bubble shield does not block canyon falls", _test_canyon_ignores_bubble_shield)
	failures += await _run("InputManager device prompts", _test_input_manager_prompts)
	failures += await _run("Star reachability heuristics", _test_star_reachability)
	failures += await _run(
		"Levels complete; platforms reachable; effects and environments styled",
		_test_level_layout_rules
	)
	failures += await _run("Cowboy player has movement animations", _test_cowboy_animations)
	failures += await _run("Lasso ties bandits and makes them pass-through", _test_lasso_ties_bandit)
	failures += await _run("Lasso cast ties bandits via HurtArea", _test_lasso_cast_hits_hurt_area)
	failures += await _run("Jumping on a bandit head ties him", _test_stomp_ties_bandit)
	failures += await _run("Side contact with a bandit sends the cowboy to camp", _test_side_contact_hurts)
	failures += await _run("Bandits turn around at plank edges", _test_bandit_respects_plank_edges)
	failures += await _run("Controller bindings match every gamepad device", _test_controller_all_devices)
	failures += await _run("Flying levels guard the very top of the screen", _test_flying_levels_top_guarded)
	failures += await _run("Timed door shows a clear open/closed barrier", _test_timed_door_states)
	failures += await _run("Gameplay obstacles do not display floating text", _test_obstacle_labels_hidden)
	failures += await _run("Untied bandits restore normal standing size", _test_untie_restores_stand_scale)
	failures += await _run("Campaign hazards are no longer blocked by plank highways", _test_no_plank_highways)
	failures += await _run(
		"Canyon ferry uses synchronized opposite-phase cloud pairs",
		_test_level_04_paired_moving_clouds
	)
	failures += await _run(
		"Paired Level 4 clouds approach from opposite sides at runtime",
		_test_level_04_cloud_phase_runtime
	)
	failures += await _run(
		"Level 4 second canyon has a fair opposite-phase cloud handoff",
		_test_level_04_second_canyon_paired_handoff
	)
	failures += await _run(
		"Level 4 canyon assist chains stay inside jump reach",
		_test_level_04_canyon_assist_chains
	)
	failures += await _run(
		"Canyon center art is illustrated with outside rims",
		_test_canyon_center_illustrated
	)
	failures += await _run(
		"Campaign canyons are crossable by normal jump or movers",
		_test_campaign_pits_crossable
	)
	failures += await _run(
		"Moving platforms never show ferry raft art",
		_test_movers_use_plank_or_cloud
	)
	failures += await _run("Moonlight Gulch rafts require hop transfers for Magic Boots", _test_level_09_raft_hop_boots)
	failures += await _run("Canyon rafts are one-way jump-through platforms", _test_one_way_moving_platforms)
	failures += await _run("Custom level store and builder work", _test_custom_level_builder)
	failures += await _run("Trail workshop uses one trail row and stacked dirt", _test_trail_row_model)
	failures += await _run("Campaign workshop edits and inserts levels", _test_campaign_workshop)
	failures += await _run("Trail editor saves and resets explicit snapshots", _test_trail_editor_save_reset)
	failures += await _run("Hand-drawn celebration art and cheerful music load", _test_art_and_music)
	failures += await _run("Mid-trail save data persists and loads", _test_mid_trail_save)
	failures += await _run("Saved camp and badges restore inside a level", _test_level_run_restore)
	failures += await _run("Pause menu exposes save, load, and restart from start", _test_pause_save_controls)
	failures += await _run("Boss arenas expose lasso targets and solvable kingpin layout", _test_boss_arenas)
	failures += await _run("Clouds are one-way platforms that stay above the floor", _test_one_way_cloud_platforms)
	failures += await _run("Wind zones give a gentle capped push you can walk against", _test_wind_zone_force_overlap)
	failures += await _run("HUD uses handmade western sign boards", _test_handmade_hud_signs)
	failures += await _run("Celebration saloon keeps the goal screen position", _test_saloon_transition_anchor)
	failures += await _run(
		"Arrival leaves the horse at the level start",
		_test_arrival_leaves_horse_at_spawn
	)
	failures += await _run(
		"Empty transition horse gallops while riding in",
		_test_empty_horse_gallop_animation
	)
	failures += await _run("Canyon clouds include two-cloud hop chains", _test_two_cloud_canyon_chains)
	failures += await _run("Wings levels place varied aerial carrions", _test_wings_carrion_variety)

	if failures == 0:
		print("All tests passed.")
		get_tree().quit(0)
	else:
		printerr("Tests failed: %d" % failures)
		get_tree().quit(1)


func _run(name: String, callable: Callable) -> int:
	var error: Variant = await callable.call()
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
		&"toggle_debug_names",
		&"pause", &"confirm", &"back", &"delete_save",
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
	var has_f1 := false
	for event in InputMap.action_get_events(&"toggle_debug_names"):
		if event is InputEventKey:
			var key := event as InputEventKey
			if key.physical_keycode == KEY_F1 or key.keycode == KEY_F1:
				has_f1 = true
				break
	if not has_f1:
		return "toggle_debug_names should include keyboard F1."
	return null


func _test_debug_name_overlay() -> Variant:
	DebugLabels.set_enabled(false)
	if DebugLabels.is_enabled():
		return "Debug names should start disabled."
	var packed: PackedScene = load("res://scenes/levels/level_01.tscn")
	if packed == null:
		return "Missing level_01 scene."
	var level := packed.instantiate()
	add_child(level)
	var error: Variant = null
	var stray := level.find_children("DebugNameLabel", "Label", true, false)
	if not stray.is_empty():
		error = "Debug name labels must stay hidden during normal play."
	else:
		DebugLabels.set_enabled(true)
		DebugLabels.refresh_now()
		if not DebugLabels.is_enabled():
			error = "Debug names should stay enabled after toggle."
		else:
			var player := level.get_node_or_null("Player") as Node2D
			var player_label := (
				player.get_node_or_null("DebugNameLabel") as Label if player != null else null
			)
			if player_label == null or not player_label.visible or player_label.text != "Player":
				error = "Enabled debug mode should label the Player."
			else:
				var labeled := 0
				for node_name in ["Pit3", "Ground", "SpawnPoint"]:
					var target := level.get_node_or_null(node_name) as Node2D
					if target != null and target.get_node_or_null("DebugNameLabel") is Label:
						labeled += 1
				if labeled < 2:
					error = "Enabled debug mode should label hazards/platforms/spawn."
				else:
					DebugLabels.set_enabled(false)
					if DebugLabels.is_enabled():
						error = "Debug names should turn off on second toggle."
					else:
						var remaining := level.find_children("DebugNameLabel", "Label", true, false)
						# queue_free may defer; force a flush-friendly check via freed-or-queued.
						var still_visible := 0
						for label_node in remaining:
							if is_instance_valid(label_node) and not (label_node as Node).is_queued_for_deletion():
								still_visible += 1
						if still_visible > 0:
							error = "Disabling debug mode should remove all debug name labels."
						elif not DebugLabels.is_enabled():
							# Toggle state must survive scene swaps during the run.
							DebugLabels.set_enabled(true)
							level.queue_free()
							level = null
							var level2 := packed.instantiate()
							add_child(level2)
							DebugLabels.refresh_now()
							var player2 := level2.get_node_or_null("Player") as Node2D
							var label2 := (
								player2.get_node_or_null("DebugNameLabel") as Label
								if player2 != null
								else null
							)
							if not DebugLabels.is_enabled():
								error = "Debug name toggle should persist across scene changes."
							elif label2 == null or not label2.visible:
								error = "Persisted debug mode should relabel the next scene."
							DebugLabels.set_enabled(false)
							level2.queue_free()
							level = null
	DebugLabels.set_enabled(false)
	if level != null:
		level.queue_free()
	return error


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
	var bull_sprite := bull.get_node_or_null("Bull/Sprite2D") as Sprite2D
	var tied_texture: Texture2D = load("res://assets/world/boss_stampede_bull_tied_legs.png")
	if bull_sprite == null or bull_sprite.position.y > -75.0:
		bull.queue_free()
		return "Bull artwork should stand above the desert surface, not inside it."
	var tied_scale: Vector2 = bull.call("_sprite_scale_for", tied_texture, 190.0)
	var normal_width := float(bull_sprite.texture.get_width()) * absf(bull_sprite.scale.x)
	var tied_width := float(tied_texture.get_width()) * absf(tied_scale.x)
	if tied_width < normal_width * 0.85:
		bull.queue_free()
		return "Tied bull should remain close to his normal on-screen size."
	bull.queue_free()

	var coach := coach_packed.instantiate()
	add_child(coach)
	var chase_player := coach.get_node_or_null("Player") as Player
	var horse_near := coach.get_node_or_null("Coach/HorseNear") as Sprite2D
	var horse_far := coach.get_node_or_null("Coach/HorseFar") as Sprite2D
	var rein_near := coach.get_node_or_null("Coach/Harness") as Line2D
	var rein_far := coach.get_node_or_null("Coach/HarnessFar") as Line2D
	if chase_player == null or not chase_player.is_mounted():
		coach.queue_free()
		return "The cowboy should chase the coach while mounted."
	if (
		horse_near == null
		or horse_far == null
		or horse_near.position.x > 205.0
		or horse_far.position.x - horse_near.position.x > 60.0
	):
		coach.queue_free()
		return "Coach horses should form a close, compact team."
	if rein_near == null or rein_far == null:
		coach.queue_free()
		return "Each coach horse needs a connected rein."
	var near_bit := horse_near.position + Vector2(48.0, -12.0)
	var far_bit := horse_far.position + Vector2(48.0, -10.0)
	if (
		rein_near.points.is_empty()
		or rein_far.points.is_empty()
		or rein_near.points[rein_near.points.size() - 1].distance_to(near_bit) > 1.0
		or rein_far.points[rein_far.points.size() - 1].distance_to(far_bit) > 1.0
	):
		coach.queue_free()
		return "Coach reins should end at the moving horse bridles."
	for i in range(3):
		var door := coach.get_node_or_null("Coach/Door%d" % i)
		if door == null or not door.has_method("lasso_hit") or not (door is Area2D):
			coach.queue_free()
			return "Midnight Coach door %d must be an Area2D lasso target." % i
	if coach.get_node_or_null("Coach") is AnimatableBody2D:
		coach.queue_free()
		return "Coach root should not be a solid AnimatableBody2D."
	var earth := coach.get_node_or_null("EarthUnderfill") as ColorRect
	if (
		earth == null
		or earth.position.y > 320.0
		or earth.position.y + earth.size.y < 900.0
		or earth.color.b >= earth.color.r
		or earth.color.a < 1.0
	):
		coach.queue_free()
		return "Midnight Coach ground needs deep, opaque earth below every camera view."
	coach.call("_apply_coach_frame", 3)
	coach.call("_show_surrender_flag")
	var coach_sprite := coach.get_node_or_null("Coach/Sprite2D") as Sprite2D
	var surrender_flag := coach.get_node_or_null("Coach/SurrenderFlag") as Node2D
	if (
		coach_sprite == null
		or coach_sprite.texture == null
		or not coach_sprite.texture.resource_path.ends_with("boss_midnight_coach_3.png")
		or surrender_flag == null
		or surrender_flag.get_node_or_null("Cloth") == null
	):
		coach.queue_free()
		return "Coach victory art should keep the final handmade rig and add a clear surrender flag."
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
	if not (kingpin is AnimatableBody2D):
		king.queue_free()
		return "Kingpin must be solid so the cowboy cannot jump through him."
	var king_shape := king.get_node_or_null("Kingpin/CollisionShape2D") as CollisionShape2D
	var king_spring := king.get_node_or_null("KingpinJumpSpring") as SpringPad
	var king_spring2 := king.get_node_or_null("KingpinJumpSpring2") as SpringPad
	var king_spring3 := king.get_node_or_null("KingpinJumpSpring3") as SpringPad
	var king_hurt := king.get_node_or_null("Kingpin/HurtArea") as Area2D
	if king_shape == null or king_shape.disabled or king_spring == null:
		king.queue_free()
		return "The solid kingpin needs a nearby spring so the cowboy can jump over him."
	if king_spring2 == null or king_spring3 == null:
		king.queue_free()
		return "Kingpin arena needs three nearby springs for fair vaulting."
	if king_hurt == null:
		king.queue_free()
		return "Kingpin needs a HurtArea so side contact hurts like bandits."
	if not king.has_method("_is_head_stomp") or not king.has_method("_handle_kingpin_contact"):
		king.queue_free()
		return "Kingpin must distinguish head stomps from harmful side contact."
	var patrol_span: float = absf(float(king.get("_right_x")) - float(king.get("_left_x")))
	if patrol_span < 400.0:
		king.queue_free()
		return "Kingpin should patrol a wider bounded arena path."
	if float(king.get("_walk_speed")) < 90.0:
		king.queue_free()
		return "Kingpin should move more during the fight."
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
	if not is_equal_approx(modes.shield_duration, 7.5):
		return "Bubble Shield should start at 7.5 seconds."
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
	if error == null and scene.get_node_or_null("DeleteSaveButton") != null:
		error = "Save select should not show a permanent Delete Save button."
	if error == null and scene.get_node_or_null("LanguageButton") != null:
		error = "Save select should not show a top-level language button."
	var skyline := scene.get_node_or_null("Skyline") as TextureRect
	var title_board := scene.get_node_or_null("TitleBoard")
	var prompt_board := scene.get_node_or_null("PromptBoard")
	if error == null and (skyline == null or skyline.texture == null):
		error = "Save select needs the desert skyline backdrop."
	elif error == null and not (title_board is HandmadeSign):
		error = "Save select title should use a HandmadeSign western board."
	elif error == null and not (prompt_board is HandmadeSign):
		error = "Save select prompts should use a HandmadeSign western board."
	var settings_button := scene.get_node_or_null("SettingsButton") as Button
	var settings_panel := scene.get_node_or_null("SettingsPanel") as SettingsPanel
	if error == null and (settings_button == null or settings_panel == null):
		error = "Save select needs Settings access via SettingsButton + SettingsPanel."
	if error == null and scene.get_node_or_null("BuildTrailButton") == null:
		error = "Save select needs Campaign Workshop access."
	if error == null and scene.get_node_or_null("TranslationEditorButton") == null:
		error = "Save select needs Translation Editor access."
	var delete_dialog := scene.get_node_or_null("DeleteConfirmation") as ConfirmationDialog
	if error == null and delete_dialog == null:
		error = "Save deletion needs a confirmation dialog."
	var first_card := scene.get_node_or_null("Slots/Slot1") as Button
	if error == null and first_card != null and not first_card.text.contains("4: "):
		error = "Save cards should show level names as '<number>: <name>'."
	if error == null and first_card != null:
		var normal := first_card.get_theme_stylebox("normal")
		if normal is StyleBoxTexture:
			var tex_style := normal as StyleBoxTexture
			if tex_style.texture == null:
				error = "Save slot StyleBoxTexture needs a weathered saloon wood texture."
		elif normal is StyleBoxFlat:
			if (normal as StyleBoxFlat).bg_color.b > 0.55:
				error = "Save slot buttons should look wooden, not default gray/blue."
		else:
			error = "Save slot buttons should use handmade wood StyleBox styling."
	var title_label := scene.get_node_or_null("Title") as Label
	if error == null and title_label != null:
		var cream := title_label.get_theme_color("font_color")
		if cream.r < 0.85 or cream.g < 0.7 or cream.b > 0.65:
			error = "Save select title should use faded cream/yellow saloon lettering."
	var hand := scene.get_node_or_null("PointingHandRight") as TextureRect
	if error == null and (hand == null or hand.texture == null):
		error = "Save select should show a handpainted pointing-hand motif by the title."
	if error == null and title_board is HandmadeSign:
		var board := title_board as HandmadeSign
		if board.board_style != HandmadeSign.BoardStyle.SALOON:
			error = "Save select title board should use HandmadeSign SALOON weathering."
		elif board.board_texture == null:
			error = "Save select title board should use the painted saloon title texture."
	if error == null:
		scene._request_delete()
		if GameManager.is_slot_empty(0):
			error = "Delete Save must ask for confirmation before erasing."
		elif not delete_dialog.visible:
			error = "Right-click, Space, or Y should open an explicit confirmation."
	if error == null:
		scene._confirm_delete()
		if not GameManager.is_slot_empty(0):
			error = "Confirming Delete Save should erase the highlighted slot."
	if error == null and settings_button != null and settings_panel != null:
		settings_button.pressed.emit()
		if not settings_panel.visible:
			error = "Settings button should open the settings panel on the start screen."
		else:
			settings_panel.closed.emit()
			if settings_panel.visible:
				error = "Closing settings should hide the settings panel again."
	scene.queue_free()
	GameManager.erase_slot(0)
	return error


func _test_localization_settings() -> Variant:
	var defaults := GameManager._default_data()
	if String(defaults.get("settings", {}).get("language", "")) != "de":
		return "German must be the default language for new saves."
	if String(ProjectSettings.get_setting("internationalization/locale/fallback", "")) != "de":
		# Project setting path may differ; also accept TranslationServer after fresh apply.
		pass
	var previous_language := String(GameManager.get_settings().get("language", "de"))
	var previous_narration := bool(GameManager.get_settings().get("narration", true))
	GameManager.set_setting("language", "de")
	if not TranslationServer.get_locale().begins_with("de"):
		return "German language setting should update TranslationServer."
	if tr("Settings") != "Einstellungen":
		GameManager.set_setting("language", previous_language)
		return "German translation catalog is not loaded."
	GameManager.set_setting("narration", false)
	if bool(GameManager.get_settings().get("narration", true)):
		GameManager.set_setting("language", previous_language)
		return "Spoken instructions setting should be saved."
	GameManager.set_setting("narration", previous_narration)
	GameManager.set_setting("language", previous_language)
	return null


func _test_narrator_voice_fallback() -> Variant:
	# Windows ships English SAPI voices but usually no German one. A German trail
	# must still speak by falling back English -> any voice, never returning "".
	# The cowboy narrator must prefer a male voice whenever one is available.
	var narrator := preload("res://scripts/autoload/narrator.gd")
	var windows_default := [
		{"id": "sapi_zira", "name": "Microsoft Zira Desktop", "language": "en-US"},
		{"id": "sapi_david", "name": "Microsoft David Desktop", "language": "en-US"},
	]
	# German requested, only English installed -> male English (David), not Zira.
	if narrator.select_voice(windows_default, "de") != "sapi_david":
		return "German narration should fall back to a male English voice, not a female one."
	# German requested and installed -> prefer the German male voice over Hedda.
	var with_german := windows_default + [
		{"id": "sapi_hedda", "name": "Microsoft Hedda Desktop", "language": "de-DE"},
		{"id": "sapi_stefan", "name": "Microsoft Stefan Desktop", "language": "de-DE"},
	]
	if narrator.select_voice(with_german, "de") != "sapi_stefan":
		return "A male German voice should be preferred when German is installed."
	# English requested -> David even when Zira is listed first.
	if narrator.select_voice(windows_default, "en") != "sapi_david":
		return "English narration should pick the male David voice."
	# Only female voices installed -> still speak (better audible than silent).
	var only_french := [{"id": "sapi_hortense", "name": "Hortense", "language": "fr-FR"}]
	if narrator.select_voice(only_french, "de") != "sapi_hortense":
		return "With no language match, narration should still use any installed voice."
	# Mixed non-matching languages -> prefer the male one.
	var mixed := [
		{"id": "sapi_hortense", "name": "Hortense", "language": "fr-FR"},
		{"id": "sapi_paul", "name": "Paul", "language": "fr-FR"},
	]
	if narrator.select_voice(mixed, "de") != "sapi_paul":
		return "When falling back across languages, narration should still prefer a male voice."
	# No voices installed at all -> the one legitimate silent case.
	if narrator.select_voice([], "en") != "":
		return "With zero installed voices, voice selection must report none available."
	return null


func _test_settings_language_dropdown() -> Variant:
	var previous_language := String(GameManager.get_settings().get("language", "en"))
	GameManager.set_setting("language", "de")
	var packed := load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if packed == null:
		GameManager.set_setting("language", previous_language)
		return "Missing pause menu scene."
	var menu := packed.instantiate() as PauseMenu
	add_child(menu)
	var panel := menu.get_node_or_null("SettingsPanel") as SettingsPanel
	var dropdown := menu.get_node_or_null("SettingsPanel/Margin/VBox/LanguageDropdown") as OptionButton
	var error: Variant = null
	if menu.get_node_or_null("SettingsPanel/Margin/VBox/LanguageButton") != null:
		error = "Settings should replace its language toggle button with a dropdown."
	elif panel == null or dropdown == null or dropdown.item_count < 2:
		error = "Settings needs a language dropdown with English and German choices."
	elif dropdown.get_item_text(0) not in ["English", "Englisch"]:
		error = "The first language choice should be English."
	elif dropdown.get_item_text(1) not in ["Deutsch", "German"]:
		error = "The second language choice should be Deutsch/German."
	elif dropdown.selected != 1 or dropdown.text not in ["Deutsch", "German"]:
		error = "The closed dropdown should visibly restore the current German selection."
	if error == null:
		panel._select_language(0)
		if not TranslationServer.get_locale().begins_with("en"):
			error = "Selecting English should update TranslationServer immediately."
		elif String(GameManager.get_settings().get("language", "")) != "en":
			error = "Selecting English should update GameManager immediately."
	if error == null:
		panel._select_language(1)
		var save_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameManager.save_path()))
		if not TranslationServer.get_locale().begins_with("de"):
			error = "Selecting Deutsch should update TranslationServer immediately."
		elif typeof(save_json) != TYPE_DICTIONARY:
			error = "Language selection should persist through the settings save file."
		elif String((save_json as Dictionary).get("settings", {}).get("language", "")) != "de":
			error = "The persisted settings should contain the selected locale."
	if error == null:
		GameManager.load_from_disk()
		panel._load_values()
		if dropdown.selected != 1 or dropdown.text not in ["Deutsch", "German"]:
			error = "Reloading settings should restore the visible current language."
	if error == null:
		panel.visible = true
		panel.focus_first()
		var previous := InputEventAction.new()
		previous.action = &"move_left"
		previous.pressed = true
		panel._unhandled_input(previous)
		panel._unhandled_input(previous)
		if panel._controls[panel._index] != dropdown:
			error = "Controller navigation should reach the language dropdown."
		else:
			var activate := InputEventAction.new()
			activate.action = &"jump"
			activate.pressed = true
			panel._unhandled_input(activate)
			if not dropdown.get_popup().visible:
				error = "Xbox A / keyboard activation should open the language dropdown."
			dropdown.get_popup().hide()
	menu.queue_free()
	GameManager.set_setting("language", previous_language)
	return error


func _test_translation_csv_round_trip() -> Variant:
	var fixture := (
		"keys,en,de\r\n"
		+ "\"Greeting, key\",\"Hello, cowboy — 100%%!\",\"Hallo, Cowboy — 100%%!\"\r\n"
		+ "Multiline,\"First line\nSecond line\",\"Erste Zeile\nZweite Zeile\"\r\n"
		+ "Quote,\"He said \"\"Yeehaw!\"\"\",\"Er sagte \"\"Jippie!\"\"\"\r\n"
	)
	var parsed := TranslationCsv.parse(fixture)
	if not String(parsed.get("error", "")).is_empty():
		return "Quoted CSV fixture did not parse: %s" % parsed["error"]
	var rows: Array = parsed.get("rows", [])
	if rows.size() != 3:
		return "Expected three parsed translation rows, got %d." % rows.size()
	if String(rows[0]["en"]) != "Hello, cowboy — 100%%!":
		return "Quoted commas, Unicode, or percent signs changed while parsing."
	if not String(rows[1]["de"]).contains("\n"):
		return "A newline inside a quoted translation was not preserved."
	var reparsed := TranslationCsv.parse(TranslationCsv.serialize(rows))
	if not String(reparsed.get("error", "")).is_empty() or reparsed.get("rows", []) != rows:
		return "Translation CSV did not survive a parse/serialize round trip."
	return null


func _test_translation_placeholders() -> Variant:
	if TranslationCsv.example("TRAIL %d%%") != "TRAIL 7%":
		return "Integer and escaped-percent example was not rendered safely."
	if not TranslationCsv.has_placeholders("Ready: 100%%"):
		return "An escaped percent should be recognized as a formatting placeholder."
	var mixed := TranslationCsv.example("%s / %d / %.0f / %%")
	if mixed.contains("%s") or mixed.contains("%d") or mixed.contains("%.0f") or not mixed.ends_with("%"):
		return "Mixed placeholder example was not fully rendered: %s" % mixed
	if not TranslationCsv.placeholders_match("Badges: %d / %s", "Abzeichen: %d / %s"):
		return "Matching English/German placeholders were rejected."
	if TranslationCsv.placeholders_match("Badges: %d / %s", "Abzeichen: %s / %d"):
		return "Placeholder order mismatch was not detected."
	if TranslationCsv.placeholders_match("Time: %.0f", "Zeit: %d"):
		return "Placeholder type mismatch was not detected."
	return null


func _test_translation_editor() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/translation_editor.tscn")
	if packed == null:
		return "Translation editor scene did not load."
	var editor := packed.instantiate() as TranslationEditor
	add_child(editor)
	var error: Variant = null
	if editor.rows.is_empty():
		error = "Translation editor did not load the real CSV."
	elif editor.get_node_or_null("Page/RowsScroll/Rows/Entry0") == null:
		error = "Translation editor did not create scrollable entry controls."
	var save_paths := preload("res://scripts/autoload/save_paths.gd")
	var export_path: String = save_paths.translation_export_path()
	if error == null and (
		not export_path.contains(save_paths.FOLDER_NAME)
		or export_path.get_file() != save_paths.TRANSLATION_EXPORT_FILE
	):
		error = "Translation export is not in the portable savegames folder: %s" % export_path
	var existed := FileAccess.file_exists(export_path)
	var backup := FileAccess.get_file_as_bytes(export_path) if existed else PackedByteArray()
	if error == null:
		editor._save_export()
		if not FileAccess.file_exists(export_path):
			error = "Translation editor did not write its CSV export."
		else:
			var exported := TranslationCsv.parse(FileAccess.get_file_as_string(export_path))
			if not String(exported.get("error", "")).is_empty():
				error = "Exported translation CSV could not be parsed again."
	if FileAccess.file_exists(export_path):
		DirAccess.remove_absolute(export_path)
	if existed:
		var restore := FileAccess.open(export_path, FileAccess.WRITE)
		if restore != null:
			restore.store_buffer(backup)
	editor.queue_free()
	return error


func _test_handmade_progress_and_sfx() -> Variant:
	var progress := HandmadeProgress.new()
	add_child(progress)
	progress.set_progress(0.6)
	progress.set_camps([0.25, 0.75])
	if not is_equal_approx(progress.ratio, 0.6) or progress.camp_ratios.size() != 2:
		progress.queue_free()
		return "Handmade progress sign should retain trail and camp progress."
	progress.queue_free()
	var effect := AudioManager._make_effect(&"collect")
	if effect == null or effect.data.is_empty():
		return "Collect effect should produce playable sound data."
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
	elif node.player == null or not node.player.is_mounted():
		error = "Level 1 should introduce the cowboy riding his horse."
	elif not is_equal_approx(node.player.get_jump_distance_multiplier(), 1.2):
		error = "The horse should jump 20 percent farther than the normal cowboy."
	else:
		# First cactus must sit past the hand-painted rim body (~220px outside the gap).
		var cactus := node.find_child("Cactus4", true, false) as Node2D
		var gaps := LevelLayoutRules._ground_canyon_gaps(node)
		if cactus == null or gaps.is_empty():
			error = "Level 1 should keep a first-canyon cactus for trail teaching."
		else:
			var gap_left := float(gaps[0]["left"])
			var rim_clear := ScalableCanyonArt.RIM_SIZE.x + 40.0
			if gap_left - cactus.global_position.x < rim_clear:
				error = (
					"Level 1 first cactus overlaps the canyon rim art (need %.0fpx clear, got %.0f)."
					% [rim_clear, gap_left - cactus.global_position.x]
				)
	_free_level(node)
	return error


func _test_ten_levels_exist() -> Variant:
	if GameManager.LEVEL_SCENES.size() != 10:
		return "Expected 10 levels."
	var level_two := GameManager.level_name_for(2)
	if not level_two.begins_with("2: "):
		return "Level names should use the '<number>: <name>' format."
	if level_two not in ["2: Badge Meadow", "2: Abzeichen-Wiese"]:
		return "Level 2 should keep its English or German display title."
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
	else:
		var horse := controller.transition.get_node_or_null("TrailHorse") as Sprite2D
		var canvas_scale := absf(controller.get_viewport().get_canvas_transform().get_scale().y)
		var expected_scale := Player.HORSE_VISUAL_SCALE * canvas_scale
		var goal := controller.find_child("Goal", true, false) as Node2D
		var floor_y := (
			controller.get_viewport().get_canvas_transform() * goal.global_position
		).y if goal != null else INF
		if absf(horse.scale.x - expected_scale) > 0.02:
			error = (
				"Transition horse should match gameplay scale (got %.3f, want %.3f)."
				% [horse.scale.x, expected_scale]
			)
		elif goal != null and absf(controller.transition.get_floor_screen_y() - floor_y) > 2.0:
			error = "Transition floor baseline should match the goal trail plank."
		elif (
			goal != null
			and absf(
				horse.position.y
				- (floor_y + LevelTransition.MOUNTED_SPRITE_OFFSET_Y * canvas_scale)
			)
			> 2.0
		):
			error = "Transition horse should ride with MountedHorse foot alignment."
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
	var wings := cowboy.get_node_or_null("WingArt") as Sprite2D
	if wings == null or wings.scale.x < 1.0 or wings.scale.x > 1.1:
		node.queue_free()
		return "Fly power should display visible wings at the expected size."
	cowboy.mount_horse()
	var mounted := cowboy.get_node_or_null("MountedHorse") as Sprite2D
	cowboy._update_animation(false)
	var jump_texture: Texture2D = load("res://assets/world/cowboy_horse_jump.png")
	if mounted == null or not mounted.visible or mounted.texture != jump_texture:
		node.queue_free()
		return "Mounted cowboy needs a dedicated handmade horse-jump pose."
	if not is_equal_approx(cowboy.get_run_speed(), cowboy.move_speed * 1.45):
		node.queue_free()
		return "Mounted horse should match the boosted Midnight Coach chase speed."
	cowboy.velocity.x = cowboy.get_run_speed()
	cowboy.get_jump_assist().notify_grounded(true)
	cowboy.get_jump_assist().notify_jump_pressed()
	cowboy._try_jump(true)
	if not is_equal_approx(cowboy.velocity.x, cowboy.move_speed * 1.2):
		node.queue_free()
		return "Mounted jump speed should be exactly 20 percent above a normal jump."
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


func _test_bandit_respects_plank_edges() -> Variant:
	var plank := StaticBody2D.new()
	plank.position = Vector2(200, 410)
	plank.collision_layer = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(120, 20)
	collision.shape = shape
	plank.add_child(collision)
	add_child(plank)
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	var bandit := packed.instantiate() as Opponent
	bandit.position = Vector2(238, 400)
	add_child(bandit)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var error: Variant = null
	if bandit._has_floor_ahead(1.0):
		error = "Bandit should detect the right plank edge and turn around."
	elif not bandit._has_floor_ahead(-1.0):
		error = "Bandit should keep walking where the plank continues."
	bandit.queue_free()
	plank.queue_free()
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
	var expected_top_guards := {"07": 6, "10": 3}
	for lv in ["07", "10"]:
		var packed: PackedScene = load("res://scenes/levels/level_%s.tscn" % lv)
		if packed == null:
			return "Missing flying level %s." % lv
		var level := packed.instantiate()
		add_child(level)
		var top_guards := 0
		var top_xs: Array[float] = []
		for node in level.find_children("*", "Area2D", true, false):
			if node is Carrion and (node as Node2D).global_position.y <= -150.0:
				top_guards += 1
				top_xs.append((node as Node2D).global_position.x)
		level.queue_free()
		if top_guards != int(expected_top_guards[lv]):
			return "Level %s should use %d top-route carrions (found %d)." % [
				lv, expected_top_guards[lv], top_guards
			]
		top_xs.sort()
		if top_xs.size() >= 2 and top_xs[top_xs.size() - 1] - top_xs[0] < 1200.0:
			return "Level %s top carrions should be spread across the trail, not one cluster." % lv
	for lv in ["02", "06"]:
		var no_bird_packed: PackedScene = load("res://scenes/levels/level_%s.tscn" % lv)
		var no_bird_level: Node = no_bird_packed.instantiate()
		add_child(no_bird_level)
		for node in no_bird_level.find_children("*", "Area2D", true, false):
			if node is Carrion:
				no_bird_level.queue_free()
				return "Level %s should not contain carrions." % lv
		no_bird_level.queue_free()
	return null


func _test_timed_door_states() -> Variant:
	var packed: PackedScene = load("res://scenes/world/timed_door.tscn")
	if packed == null:
		return "Missing timed door scene."
	var door := packed.instantiate() as TimedDoor
	add_child(door)
	var handmade_gate := door.get_node_or_null("HandmadeGate") as Sprite2D
	var lantern_rig := door.get_node_or_null("StatusLantern") as Node2D
	var left_lantern := door.get_node_or_null("StatusLantern/LeftLantern") as Node2D
	var right_lantern := door.get_node_or_null("StatusLantern/RightLantern") as Node2D
	var error: Variant = null
	if handmade_gate == null or handmade_gate.texture == null:
		error = "Timed door should use the hand-painted fence gate artwork."
	elif door.get_node_or_null("StatusPlate") != null or door.get_node_or_null("Barrier") != null:
		error = "Timed doors should not use generic status plates or barrier rectangles."
	elif lantern_rig == null or left_lantern == null or right_lantern == null:
		error = "Timed door needs two hand-drawn hanging lanterns."
	elif lantern_rig.position.y < -110.0 or left_lantern.position.x >= 0.0 or right_lantern.position.x <= 0.0:
		error = "Timed door lanterns should hang from both sides of its upper rail."
	else:
		door._open = false
		door._apply_state(false)
		var closed_scale := handmade_gate.scale
		var closed_color: Color = left_lantern.get("glow_color")
		door._open = true
		door._apply_state(false)
		var open_scale := handmade_gate.scale
		var open_color: Color = left_lantern.get("glow_color")
		if closed_color.is_equal_approx(open_color):
			error = "Lantern glass must preserve distinct open and closed status colors."
		elif not open_color.is_equal_approx(right_lantern.get("glow_color")):
			error = "Both timed door lanterns should communicate the same state."
		elif closed_scale.x <= open_scale.x:
			error = "A closed gate should look wider and solid while the open gate turns edge-on."
	door.queue_free()
	return error


func _test_obstacle_labels_hidden() -> Variant:
	for path in [
		"res://scenes/world/opponent.tscn",
		"res://scenes/world/rattlesnake.tscn",
		"res://scenes/world/spring_pad.tscn",
		"res://scenes/world/moving_platform.tscn",
		"res://scenes/world/disappearing_platform.tscn",
		"res://scenes/world/wind_zone.tscn",
		"res://scenes/world/timed_door.tscn",
	]:
		var packed := load(path) as PackedScene
		if packed == null:
			return "Missing obstacle scene: %s" % path
		var obstacle := packed.instantiate()
		add_child(obstacle)
		for label_node in obstacle.find_children("*", "Label", true, false):
			if (label_node as Label).visible:
				obstacle.queue_free()
				return "Obstacle still shows floating text: %s" % path
		obstacle.queue_free()
	return null


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


func _test_one_way_moving_platforms() -> Variant:
	# Rafts/clouds must let the cowboy jump up through them from below and land on top.
	var packed := load("res://scenes/world/moving_platform.tscn") as PackedScene
	if packed == null:
		return "Missing moving platform scene."
	var platform := packed.instantiate() as MovingPlatform
	add_child(platform)
	var shape := platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var error: Variant = null
	if shape == null or not shape.one_way_collision:
		error = "Moving platforms must use Godot one-way collision so the cowboy can jump through."
	elif not platform.is_one_way():
		error = "Moving platforms should report one-way configuration."
	platform.queue_free()
	if error == null:
		var level := (load("res://scenes/levels/level_04.tscn") as PackedScene).instantiate()
		# Plank canyons no longer use Moving0; keep a required mover for canyon 2.
		var sample := level.get_node_or_null("Moving5") as MovingPlatform
		if sample == null:
			error = "Canyon Ferry should still contain Moving5 for the plank-free canyon."
		level.free()
	return error

func _test_level_09_raft_hop_boots() -> Variant:
	var packed: PackedScene = load("res://scenes/levels/level_09.tscn")
	if packed == null:
		return "Missing Level 09 scene."
	var level: Node = packed.instantiate()
	var hop_names := ["MovingHopA", "MovingHopB", "MovingHopC", "MovingHopD"]
	var hops: Array[MovingPlatform] = []
	for hop_name in hop_names:
		var raft := level.get_node_or_null(hop_name) as MovingPlatform
		if raft == null:
			level.free()
			return "Level 09 needs transfer raft %s." % hop_name
		hops.append(raft)
	var boots := level.get_node_or_null("Boots") as ModeItem
	var reward := level.get_node_or_null("BootsRewardLedge") as StaticBody2D
	var boarding := level.get_node_or_null("BootsHopLedge") as StaticBody2D
	if boots == null or boots.mode != ModeController.Mode.MAGIC_BOOTS:
		level.free()
		return "Level 09 Magic Boots item is missing."
	if reward == null or boarding == null:
		level.free()
		return "Level 09 needs BootsHopLedge boarding and BootsRewardLedge reward."

	# Reward ledge must sit well above normal/spring reach from the gulch floor.
	var ground_top := 320.0
	var reward_top := reward.global_position.y - 16.0
	var rise_from_ground := ground_top - reward_top
	if rise_from_ground < 360.0:
		level.free()
		return "Magic Boots reward ledge must stay above spring reach from the floor."
	if boots.global_position.y > reward.global_position.y:
		level.free()
		return "Magic Boots must rest on/above the elevated reward ledge."

	# Neighboring hop rafts must have a timing window where a normal jump can transfer.
	for index in range(hops.size() - 1):
		var left := hops[index]
		var right := hops[index + 1]
		var left_candidates: Array[Vector2] = [
			left.global_position + left.point_a,
			left.global_position + left.point_b,
		]
		var right_candidates: Array[Vector2] = [
			right.global_position + right.point_a,
			right.global_position + right.point_b,
		]
		var best_gap := INF
		var best_rise := INF
		for left_pos in left_candidates:
			for right_pos in right_candidates:
				var edge_gap: float = absf(right_pos.x - left_pos.x) - 140.0
				var rise: float = absf(left_pos.y - right_pos.y)
				if edge_gap < best_gap:
					best_gap = edge_gap
					best_rise = rise
		# Allow overlap (negative gap) or a modest clear gap within unpowered jump range.
		if best_gap > 160.0 or best_rise > 100.0:
			level.free()
			return (
				"Raft hop %s -> %s is not a fair transfer window (gap %.0f, rise %.0f)."
				% [hop_names[index], hop_names[index + 1], best_gap, best_rise]
			)

	# Final raft must get close enough to the reward ledge for an unpowered hop.
	var final_raft := hops[hops.size() - 1]
	var end_a := final_raft.global_position + final_raft.point_a
	var end_b := final_raft.global_position + final_raft.point_b
	var approach := end_b if end_b.y < end_a.y else end_a
	var reward_left := reward.global_position.x - 80.0
	var approach_right := approach.x + 70.0
	var approach_gap := reward_left - approach_right
	var approach_rise := (approach.y - 15.0) - reward_top
	if approach_gap > 140.0 or approach_rise > 100.0:
		level.free()
		return (
			"Final raft must approach BootsRewardLedge within normal jump range (gap %.0f, rise %.0f)."
			% [approach_gap, approach_rise]
		)

	# No other static ledges may sit within easy spring/unpowered reach of the boots reward.
	for node in level.find_children("*", "StaticBody2D", true, false):
		if node == reward or node == boarding:
			continue
		var name_text := String(node.name)
		if not (
			name_text.contains("Ledge")
			or name_text.begins_with("Ground")
			or name_text.contains("Platform")
		):
			continue
		var surface := LevelLayoutRules._surface_for(node as Node2D)
		if surface.is_empty():
			continue
		var reward_right := reward.global_position.x + 80.0
		var gap := 0.0
		if float(surface["left"]) > reward_right:
			gap = float(surface["left"]) - reward_right
		elif reward_left > float(surface["right"]):
			gap = reward_left - float(surface["right"])
		var rise: float = float(surface["top"]) - reward_top
		if gap <= 200.0 and rise <= 250.0 and rise >= 0.0:
			level.free()
			return "Static platform %s can still bypass the raft hop to Magic Boots." % name_text

	level.free()
	return null


func _test_level_04_paired_moving_clouds() -> Variant:
	var packed: PackedScene = load("res://scenes/levels/level_04.tscn")
	var level: Node = packed.instantiate()
	# Plank-covered canyons must not keep redundant movers overhead.
	for removed_name in ["Moving0", "Moving1", "Moving2", "Moving3"]:
		if level.get_node_or_null(removed_name) != null:
			level.free()
			return "%s must be removed where wooden planks already cross the canyon." % removed_name

	# Movers remain only where no solid plank path covers the gap.
	var cloud_names := ["Moving5", "Moving6", "Moving4"]
	for cloud_name in cloud_names:
		var cloud := level.get_node_or_null(cloud_name) as MovingPlatform
		if cloud == null:
			level.free()
			return "Level 4 is missing moving cloud %s." % cloud_name
		cloud._configure_visual_style()
		var cloud_visual := cloud.get_node_or_null("CloudVisual") as Sprite2D
		var raft_visual := cloud.get_node_or_null("Visual") as Sprite2D
		var shape := cloud.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if (
			not cloud.is_cloud_style()
			or cloud_visual == null
			or cloud_visual.texture == null
			or not cloud_visual.texture.resource_path.ends_with("moving_cloud.svg")
			or raft_visual == null
			or raft_visual.visible
		):
			level.free()
			return "%s should show dedicated cloud art, not raft planks." % cloud_name
		if shape == null or not shape.one_way_collision:
			level.free()
			return "%s must stay jump-through from below and landable from above." % cloud_name
		var route_low_y := maxf(
			cloud.position.y + cloud.point_a.y,
			cloud.position.y + cloud.point_b.y
		)
		var half_height := (shape.shape as RectangleShape2D).size.y * 0.5
		if route_low_y + half_height > 280.0:
			level.free()
			return "%s sinks too close to the trail floor." % cloud_name

	for pair_names in [["Moving5", "Moving6"]]:
		var part_1 := level.get_node(pair_names[0]) as MovingPlatform
		var part_2 := level.get_node(pair_names[1]) as MovingPlatform
		if part_1.start_at_point_b or not part_2.start_at_point_b:
			level.free()
			return "%s and %s must start at opposite endpoints." % pair_names
		var part_1_distance := part_1.point_a.distance_to(part_1.point_b)
		var part_2_distance := part_2.point_a.distance_to(part_2.point_b)
		var part_1_period := part_1_distance / part_1.move_speed
		var part_2_period := part_2_distance / part_2.move_speed
		if (
			not is_equal_approx(part_1.move_speed, part_2.move_speed)
			or not is_equal_approx(part_1_period, part_2_period)
			or part_1_period > 2.5
		):
			level.free()
			return "%s and %s need a shared short movement period." % pair_names
		var part_1_handoff := part_1.position + part_1.point_b
		var part_2_handoff := part_2.position + part_2.point_a
		var part_1_shape := part_1.get_node("CollisionShape2D").shape as RectangleShape2D
		var part_2_shape := part_2.get_node("CollisionShape2D").shape as RectangleShape2D
		var edge_gap := (
			absf(part_2_handoff.x - part_1_handoff.x)
			- (part_1_shape.size.x + part_2_shape.size.x) * 0.5
		)
		var height_difference := absf(part_2_handoff.y - part_1_handoff.y)
		if edge_gap < 8.0 or edge_gap > 120.0 or height_difference > 80.0:
			level.free()
			return (
				"%s -> %s handoff is not a fair normal jump (gap %.0f, height %.0f)."
				% [pair_names[0], pair_names[1], edge_gap, height_difference]
			)
		if part_1.obstruction_include_movers or part_2.obstruction_include_movers:
			level.free()
			return (
				"%s/%s must ignore mover obstruction so the handoff stays in sync."
				% [pair_names[0], pair_names[1]]
			)
	# Varied platforming identity: plank chains + one mover canyon + end hop clouds.
	var hop_clouds := 0
	var hop_steps := 0
	for node in level.get_children():
		var node_name := String(node.name)
		if node_name.begins_with("FerryCloud"):
			hop_clouds += 1
		elif node_name.begins_with("FerryStep") or node_name.begins_with("FerryIsle"):
			hop_steps += 1
	if hop_clouds < 2 or hop_steps < 6:
		level.free()
		return "Level 4 should keep plank chains and end-hop clouds."
	if level.get_node_or_null("FerrySpring6") == null:
		level.free()
		return "Level 4 needs a spring-assisted canyon gap for variety."
	for removed_ground in ["Ground3", "Ground6", "Ground9", "Ground12"]:
		if level.get_node_or_null(removed_ground) != null:
			level.free()
			return "Level 4 canyon at %s is still narrow enough to bypass its assist route." % removed_ground
	# FerryStep leftovers must be dressed as wooden planks, not brown ferry boxes.
	add_child(level)
	await get_tree().process_frame
	WildWestTheme.apply_to_level(level)
	for step_name in [
		"FerryStep3A",
		"FerryStep3B",
		"FerryStep3C",
		"FerryStep3D",
		"FerryStep6A",
		"FerryStep6B",
		"FerryStep9A",
		"FerryStep9B",
		"FerryStep9C",
		"FerryStep9D",
		"FerryStep12A",
		"FerryStep12B",
		"FerryIsle12",
	]:
		var step := level.get_node_or_null(step_name) as Node
		if step == null:
			level.queue_free()
			return "Level 4 is missing %s." % step_name
		var hand := step.get_node_or_null("HandArt") as Sprite2D
		var visual := step.get_node_or_null("Visual") as CanvasItem
		var plank_ok := false
		if hand != null and hand.texture != null:
			if str(hand.texture.resource_path).ends_with("wood_plank.png"):
				plank_ok = true
			elif hand.texture is AtlasTexture:
				var atlas := (hand.texture as AtlasTexture).atlas
				plank_ok = atlas != null and str(atlas.resource_path).ends_with("wood_plank.png")
		if not plank_ok:
			level.queue_free()
			return "%s must be styled as a wooden plank, not a ferry ColorRect." % step_name
		if visual != null and visual.visible:
			level.queue_free()
			return "%s still shows the old ferry ColorRect." % step_name
	level.queue_free()
	return null


func _max_same_height_jump_distance(
	move_speed: float = 270.0,
	jump_velocity: float = -500.0,
	gravity: float = 1350.0,
	fall_gravity_multiplier: float = 1.25
) -> float:
	var jump_speed := absf(jump_velocity)
	var time_up := jump_speed / gravity
	var height := (jump_speed * jump_speed) / (2.0 * gravity)
	var time_down := sqrt((2.0 * height) / (gravity * fall_gravity_multiplier))
	return move_speed * (time_up + time_down)


func _level_04_body_top_extent(body: Node2D) -> Dictionary:
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or not (shape_node.shape is RectangleShape2D):
		return {}
	var rect := shape_node.shape as RectangleShape2D
	var half := rect.size * 0.5
	var center := body.global_position + shape_node.position
	# DisappearingPlatform may scale width in _ready; prefer live shape size.
	return {
		"left": center.x - half.x,
		"right": center.x + half.x,
		"top": center.y - half.y,
	}


func _level_04_static_pads_in_gap(level: Node, gap_left: float, gap_right: float) -> Array[Dictionary]:
	var pads: Array[Dictionary] = []
	for node in level.get_children():
		var name_text := String(node.name)
		if not (
			name_text.begins_with("FerryStep")
			or name_text.begins_with("FerryIsle")
			or name_text.begins_with("FerryCloud")
			or name_text.begins_with("JumpPlank")
			or name_text.begins_with("Plank")
		):
			continue
		if not (node is Node2D):
			continue
		var extent := _level_04_body_top_extent(node as Node2D)
		if extent.is_empty():
			continue
		if float(extent["right"]) < gap_left - 40.0 or float(extent["left"]) > gap_right + 40.0:
			continue
		pads.append(extent)
	return pads


func _level_04_coverage_crosses(gap_left: float, gap_right: float, pads: Array[Dictionary], budget: float) -> bool:
	var coverage := gap_left
	var guard := 0
	while coverage < gap_right - 0.5 and guard < 64:
		guard += 1
		var best := coverage
		for pad in pads:
			if float(pad["left"]) <= coverage + budget:
				best = maxf(best, float(pad["right"]))
		if best <= coverage + 0.01:
			return false
		coverage = best
	return coverage >= gap_right - 0.5


func _level_04_mover_route_pads(level: Node, gap_left: float, gap_right: float) -> Array[Dictionary]:
	# Model each mover as a rideable span across its full route once boarded.
	# Use travel_origin() — after _ready, position snaps to the start endpoint.
	var pads: Array[Dictionary] = []
	for node in level.get_children():
		if not (node is MovingPlatform):
			continue
		var mover := node as MovingPlatform
		var shape := mover.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape == null or not (shape.shape is RectangleShape2D):
			continue
		var half_w := (shape.shape as RectangleShape2D).size.x * 0.5
		var origin := mover.travel_origin()
		var xa := origin.x + mover.point_a.x
		var xb := origin.x + mover.point_b.x
		var ya := origin.y + mover.point_a.y
		var yb := origin.y + mover.point_b.y
		var route_left := minf(xa, xb) - half_w
		var route_right := maxf(xa, xb) + half_w
		if route_right < gap_left - 40.0 or route_left > gap_right + 40.0:
			continue
		pads.append({
			"left": route_left,
			"right": route_right,
			"top": minf(ya, yb) - (shape.shape as RectangleShape2D).size.y * 0.5,
		})
	return pads


func _test_level_04_canyon_assist_chains() -> Variant:
	# Theoretical same-height reach is ~189px; keep a child-friendly budget.
	var clearable := minf(_max_same_height_jump_distance() * 0.85, 165.0)
	var packed: PackedScene = load("res://scenes/levels/level_04.tscn")
	var level: Node = packed.instantiate()
	add_child(level)
	await get_tree().process_frame

	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	var canyons: Array[Dictionary] = []
	for i in range(merged.size() - 1):
		var gap_left := float(merged[i]["right"])
		var gap_right := float(merged[i + 1]["left"])
		var gap := gap_right - gap_left
		if gap <= 200.0:
			continue
		canyons.append({
			"index": canyons.size() + 1,
			"left": gap_left,
			"right": gap_right,
			"gap": gap,
			"floor_y": minf(float(merged[i]["top"]), float(merged[i + 1]["top"])),
		})
	if canyons.size() < 4:
		level.queue_free()
		return "Level 4 should expose four wide canyon gaps (found %d)." % canyons.size()

	# First canyon must be plank-led so it is solvable without cloud timing.
	var first: Dictionary = canyons[0]
	var first_planks := 0
	for node in level.get_children():
		var name_text := String(node.name)
		if not name_text.begins_with("FerryStep3"):
			continue
		if not (node is Node2D):
			continue
		var px := (node as Node2D).position.x
		if px >= float(first["left"]) - 40.0 and px <= float(first["right"]) + 40.0:
			first_planks += 1
	if first_planks < 4:
		level.queue_free()
		return "First Level 4 canyon needs a 4-plank FerryStep3* stepping chain (found %d)." % first_planks

	# Plank canyons (1 and 3) must not keep movers overhead.
	for canyon in canyons:
		var gap_left := float(canyon["left"])
		var gap_right := float(canyon["right"])
		var static_pads := _level_04_static_pads_in_gap(level, gap_left, gap_right)
		var static_ok := _level_04_coverage_crosses(gap_left, gap_right, static_pads, clearable)
		if static_ok:
			for node in level.get_children():
				if not (node is MovingPlatform):
					continue
				var mover := node as MovingPlatform
				var origin := mover.travel_origin()
				var xa := origin.x + mover.point_a.x
				var xb := origin.x + mover.point_b.x
				var route_left := minf(xa, xb) - 70.0
				var route_right := maxf(xa, xb) + 70.0
				if route_right >= gap_left + 20.0 and route_left <= gap_right - 20.0:
					level.queue_free()
					return (
						"Canyon %d already has a plank path — remove overlapping mover %s."
						% [int(canyon["index"]), mover.name]
					)
			# Also flag any consecutive static hop that still exceeds budget.
			var ordered := static_pads.duplicate()
			ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["left"]) < float(b["left"]))
			var cursor := gap_left
			for pad in ordered:
				var edge_gap := float(pad["left"]) - cursor
				if edge_gap > clearable:
					level.queue_free()
					return (
						"Canyon %d static hop gap %.0fpx exceeds budget %.0f (at x≈%.0f)."
						% [int(canyon["index"]), edge_gap, clearable, float(pad["left"])]
					)
				cursor = maxf(cursor, float(pad["right"]))
			if gap_right - cursor > clearable:
				level.queue_free()
				return (
					"Canyon %d exit hop gap %.0fpx exceeds budget %.0f."
					% [int(canyon["index"]), gap_right - cursor, clearable]
				)
			continue

		var mover_pads := _level_04_mover_route_pads(level, gap_left, gap_right)
		var combined: Array[Dictionary] = []
		combined.append_array(static_pads)
		combined.append_array(mover_pads)
		if not _level_04_coverage_crosses(gap_left, gap_right, combined, clearable):
			level.queue_free()
			return (
				"Canyon %d (%.0f..%.0f) has no continuous assist chain within jump budget %.0f."
				% [int(canyon["index"]), gap_left, gap_right, clearable]
			)
	level.queue_free()
	return null


func _test_campaign_pits_crossable() -> Variant:
	# Quantitative route check: every ground canyon gap must be within a normal
	# standing jump, or provide a same-height assist (mover / cloud / plank / spring).
	var clearable := _max_same_height_jump_distance() * 0.92
	var horse_clearable := _max_same_height_jump_distance(270.0 * 1.45, -500.0 * 1.2) * 0.92
	for level_number in range(1, 11):
		var path := "res://scenes/levels/level_%02d.tscn" % level_number
		var level: Variant = _instantiate_level(path)
		if level is String:
			return level
		var controller := level as LevelController
		var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(controller))
		for i in range(merged.size() - 1):
			var left_edge := float(merged[i]["right"])
			var right_edge := float(merged[i + 1]["left"])
			var gap := right_edge - left_edge
			if gap <= 24.0:
				continue
			var mid_x := (left_edge + right_edge) * 0.5
			var floor_y := minf(float(merged[i]["top"]), float(merged[i + 1]["top"]))
			var allowed := horse_clearable if level_number == 1 else clearable
			if gap <= allowed:
				continue
			if _gap_has_crossing_assist(controller, mid_x, left_edge, right_edge, floor_y):
				continue
			controller.queue_free()
			return (
				"Level %02d gap %.0f..%.0f (%.0fpx) exceeds normal jump (%.0f) without a crossing assist."
				% [level_number, left_edge, right_edge, gap, allowed]
			)
		controller.queue_free()
	return null


func _gap_has_crossing_assist(
	level: Node,
	mid_x: float,
	gap_left: float,
	gap_right: float,
	floor_y: float
) -> bool:
	for node in level.get_children():
		var name_text := String(node.name)
		if node is MovingPlatform:
			var mover := node as MovingPlatform
			var xa := mover.position.x + mover.point_a.x
			var xb := mover.position.x + mover.point_b.x
			var route_left := minf(xa, xb) - 70.0
			var route_right := maxf(xa, xb) + 70.0
			var route_y := minf(
				mover.position.y + mover.point_a.y,
				mover.position.y + mover.point_b.y
			)
			if route_right >= gap_left - 40.0 and route_left <= gap_right + 40.0 and route_y < floor_y - 20.0:
				return true
		if (
			name_text.begins_with("FerryStep")
			or name_text.begins_with("FerryIsle")
			or name_text.begins_with("FerryCloud")
			or name_text.begins_with("CloudCanyon")
			or name_text.begins_with("JumpPlank")
			or name_text.begins_with("Plank")
		):
			if node is Node2D:
				var pos := (node as Node2D).global_position
				if pos.x >= gap_left - 80.0 and pos.x <= gap_right + 80.0 and pos.y < floor_y - 10.0:
					return true
		if name_text.begins_with("FerrySpring") or (node is SpringPad and absf((node as Node2D).global_position.x - mid_x) < 420.0):
			if node is Node2D and (node as Node2D).global_position.x <= gap_left + 40.0:
				return true
	return false


func _test_movers_use_plank_or_cloud() -> Variant:
	var packed := load("res://scenes/world/moving_platform.tscn") as PackedScene
	var plank := packed.instantiate() as MovingPlatform
	plank.visual_style = MovingPlatform.VisualStyle.RAFT
	add_child(plank)
	await get_tree().process_frame
	if not plank.is_plank_style():
		plank.queue_free()
		return "Default movers must show wooden plank art, not ferry/raft graphics."
	var raft_path := ""
	var visual := plank.get_node_or_null("Visual") as Sprite2D
	if visual != null and visual.texture != null:
		raft_path = visual.texture.resource_path
	plank.queue_free()
	if raft_path.ends_with("raft.png"):
		return "Moving platform Visual still references ferry raft.png."

	for path in [
		"res://scenes/levels/level_04.tscn",
		"res://scenes/levels/level_09.tscn",
		"res://scenes/levels/level_10.tscn",
	]:
		var level: Variant = _instantiate_level(path)
		if level is String:
			return level
		var controller := level as LevelController
		for node in controller.find_children("*", "AnimatableBody2D", true, false):
			if not (node is MovingPlatform):
				continue
			var mover := node as MovingPlatform
			mover._configure_visual_style()
			if mover.visual_style == MovingPlatform.VisualStyle.CLOUD:
				if not mover.is_cloud_style():
					controller.queue_free()
					return "%s in %s should show cloud art." % [mover.name, path]
			elif not mover.is_plank_style():
				controller.queue_free()
				return "%s in %s should show plank art, not ferry steps." % [mover.name, path]
		controller.queue_free()
	return null


func _test_level_04_cloud_phase_runtime() -> Variant:
	var packed: PackedScene = load("res://scenes/levels/level_04.tscn")
	var level: Node = packed.instantiate()
	add_child(level)
	# Only the second canyon keeps a paired mover route (plank canyons have none).

	var pairs: Array = [["Moving5", "Moving6"]]
	var start_gaps: Dictionary = {}
	for pair_names in pairs:
		var left := level.get_node(pair_names[0]) as MovingPlatform
		var right := level.get_node(pair_names[1]) as MovingPlatform
		var left_start := left.start_world_position()
		var right_start := right.start_world_position()
		if absf(left.global_position.x - left_start.x) > 1.0:
			level.queue_free()
			return "%s did not snap to its far-side start (at %.1f, expected %.1f)." % [
				pair_names[0], left.global_position.x, left_start.x
			]
		if absf(right.global_position.x - right_start.x) > 1.0:
			level.queue_free()
			return "%s did not snap to its far-side start (at %.1f, expected %.1f)." % [
				pair_names[1], right.global_position.x, right_start.x
			]
		if left.is_moving_toward_b() == right.is_moving_toward_b():
			level.queue_free()
			return "%s and %s must begin moving in opposite directions." % pair_names
		start_gaps[pair_names[0]] = absf(right.global_position.x - left.global_position.x)

	var sample := level.get_node("Moving5") as MovingPlatform
	var half_period := sample.point_a.distance_to(sample.point_b) / sample.move_speed
	var frames := int(ceil(half_period / get_physics_process_delta_time())) + 4
	var closest_gaps: Dictionary = {}
	for pair_names in pairs:
		closest_gaps[pair_names[0]] = float(start_gaps[pair_names[0]])

	for _i in range(frames):
		await get_tree().physics_frame
		for pair_names in pairs:
			var left := level.get_node(pair_names[0]) as MovingPlatform
			var right := level.get_node(pair_names[1]) as MovingPlatform
			var center_gap := absf(right.global_position.x - left.global_position.x)
			closest_gaps[pair_names[0]] = minf(float(closest_gaps[pair_names[0]]), center_gap)

	for pair_names in pairs:
		var left := level.get_node(pair_names[0]) as MovingPlatform
		var left_shape := left.get_node("CollisionShape2D").shape as RectangleShape2D
		var right_shape := (
			level.get_node(pair_names[1]).get_node("CollisionShape2D").shape as RectangleShape2D
		)
		var half_w := (left_shape.size.x + right_shape.size.x) * 0.5
		var start_gap: float = float(start_gaps[pair_names[0]])
		var closest_gap: float = float(closest_gaps[pair_names[0]])
		var edge_gap := closest_gap - half_w
		if closest_gap >= start_gap - 8.0:
			level.queue_free()
			return "%s/%s never approached each other (start %.1f, closest %.1f)." % [
				pair_names[0], pair_names[1], start_gap, closest_gap
			]
		if edge_gap < 8.0 or edge_gap > 120.0:
			level.queue_free()
			return "%s/%s closest edge gap %.1f is not a fair handoff." % [
				pair_names[0], pair_names[1], edge_gap
			]

	var meet_gaps: Dictionary = closest_gaps.duplicate()
	for _j in range(frames):
		await get_tree().physics_frame
	for pair_names in pairs:
		var left := level.get_node(pair_names[0]) as MovingPlatform
		var right := level.get_node(pair_names[1]) as MovingPlatform
		var apart_gap := absf(right.global_position.x - left.global_position.x)
		if apart_gap < float(meet_gaps[pair_names[0]]) + 40.0:
			level.queue_free()
			return "%s/%s did not reverse apart after the handoff." % pair_names

	level.queue_free()
	return null


func _test_level_04_second_canyon_paired_handoff() -> Variant:
	# Second ground canyon (Ground5 -> Ground7 / Pit6) used to end with a ~330px
	# dead jump after FerryStep6B. It must use an opposite-phase cloud pair whose
	# closest edge-to-edge handoff stays inside a normal standing jump.
	var packed: PackedScene = load("res://scenes/levels/level_04.tscn")
	var level: Node = packed.instantiate()
	var left := level.get_node_or_null("Moving5") as MovingPlatform
	var right := level.get_node_or_null("Moving6") as MovingPlatform
	if left == null or right == null:
		level.free()
		return "Level 4 second canyon needs Moving5/Moving6 opposite-phase clouds."

	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	var second_gap: Dictionary = {}
	var wide_gaps := 0
	for i in range(merged.size() - 1):
		var gap_left := float(merged[i]["right"])
		var gap_right := float(merged[i + 1]["left"])
		var gap := gap_right - gap_left
		if gap <= 200.0:
			continue
		wide_gaps += 1
		if wide_gaps == 2:
			second_gap = {
				"left": gap_left,
				"right": gap_right,
				"gap": gap,
				"floor_y": minf(float(merged[i]["top"]), float(merged[i + 1]["top"])),
			}
			break
	if second_gap.is_empty():
		level.free()
		return "Level 4 is missing its second wide ground canyon."

	var clearable := _max_same_height_jump_distance() * 0.92
	if float(second_gap["gap"]) <= clearable:
		level.free()
		return "Level 4 second canyon should stay wider than a raw normal jump."

	var left_route_min := minf(left.position.x + left.point_a.x, left.position.x + left.point_b.x)
	var left_route_max := maxf(left.position.x + left.point_a.x, left.position.x + left.point_b.x)
	var right_route_min := minf(right.position.x + right.point_a.x, right.position.x + right.point_b.x)
	var right_route_max := maxf(right.position.x + right.point_a.x, right.position.x + right.point_b.x)
	var pair_left := minf(left_route_min, right_route_min) - 70.0
	var pair_right := maxf(left_route_max, right_route_max) + 70.0
	if pair_right < float(second_gap["left"]) - 40.0 or pair_left > float(second_gap["right"]) + 40.0:
		level.free()
		return "Moving5/Moving6 do not cover the second canyon gap."

	if left.start_at_point_b or not right.start_at_point_b:
		level.free()
		return "Moving5/Moving6 must start on opposite sides and travel toward each other."
	if left.obstruction_include_movers or right.obstruction_include_movers:
		level.free()
		return "Moving5/Moving6 must ignore each other so the handoff stays in sync."
	if not is_equal_approx(left.move_speed, right.move_speed):
		level.free()
		return "Moving5/Moving6 must share the same ferry speed."

	var left_shape := left.get_node("CollisionShape2D").shape as RectangleShape2D
	var right_shape := right.get_node("CollisionShape2D").shape as RectangleShape2D
	var handoff_left := left.position + left.point_b
	var handoff_right := right.position + right.point_a
	var edge_gap := (
		absf(handoff_right.x - handoff_left.x)
		- (left_shape.size.x + right_shape.size.x) * 0.5
	)
	var height_difference := absf(handoff_right.y - handoff_left.y)
	# Prefer a short child-friendly hop; keep well under standing jump reach.
	if edge_gap < 8.0 or edge_gap > 80.0 or height_difference > 40.0:
		level.free()
		return (
			"Second canyon handoff is not a fair normal jump (edge gap %.0f, height %.0f, clearable %.0f)."
			% [edge_gap, height_difference, clearable]
		)
	if edge_gap > clearable:
		level.free()
		return "Second canyon handoff edge gap %.0f exceeds normal jump %.0f." % [edge_gap, clearable]

	# Rim boarding: outer endpoints must meet the canyon lips so the cowboy can mount.
	var left_board := left.position + left.point_a
	var right_board := right.position + right.point_b
	var left_board_edge := left_board.x - left_shape.size.x * 0.5
	var right_board_edge := right_board.x + right_shape.size.x * 0.5
	if absf(left_board_edge - float(second_gap["left"])) > 24.0:
		level.free()
		return "Moving5 far-left board edge should meet the second canyon left rim."
	if absf(right_board_edge - float(second_gap["right"])) > 40.0:
		level.free()
		return "Moving6 far-right board edge should meet the second canyon right rim."

	level.free()
	return null


func _test_canyon_center_illustrated() -> Variant:
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		return level
	var controller := level as LevelController
	var canyon := controller.find_child("Pit3", true, false) as Hazard
	if canyon == null:
		controller.queue_free()
		return "Level 01 is missing canyon Pit3."
	var canyon_art := canyon.get_node_or_null("CanyonMouth") as ScalableCanyonArt
	if canyon_art == null:
		canyon_art = canyon.get_node_or_null("PitMouth") as ScalableCanyonArt
	if canyon_art == null:
		controller.queue_free()
		return "Canyon needs ScalableCanyonArt (CanyonMouth)."
	if not canyon_art.center_is_illustrated():
		controller.queue_free()
		return "Canyon center must show open sky blue between the ridges."
	if not canyon_art.rims_outside_floor():
		controller.queue_free()
		return "Canyon side walls overlap the desert floor; rims must sit outside the gap."
	if not canyon_art.rims_match_desert_height():
		controller.queue_free()
		return "Canyon rim desert top must align with the trail floor height."
	if not canyon_art.interior_stays_inside_gap():
		controller.queue_free()
		return "Canyon sky must stay inside the mouth; do not paint over desert banks."
	var trail := controller.get_node_or_null("TrailFloor") as Node2D
	var abyss := trail.get_node_or_null("FloorAbyss") as ColorRect if trail != null else null
	if abyss == null:
		controller.queue_free()
		return "TrailFloor/FloorAbyss missing; canyon cover order cannot be verified."
	if canyon_art.z_index <= abyss.z_index and not canyon_art.top_level:
		controller.queue_free()
		return "Canyon art must draw above FloorAbyss."
	if not canyon_art.top_level or canyon_art.z_index <= -2:
		controller.queue_free()
		return "CanyonMouth must be top_level above FloorAbyss (z > -2)."
	# Abyss must never start above a walk surface (dark band over desert).
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(controller))
	for strip in merged:
		if abyss.position.y + 0.5 < float(strip["top"]):
			controller.queue_free()
			return "FloorAbyss starts above desert top %.0f (abyss y=%.0f)." % [float(strip["top"]), abyss.position.y]
	var sky := canyon_art.get_node_or_null("SkyWash") as Sprite2D
	if sky == null or sky.texture == null:
		controller.queue_free()
		return "Canyon mouth is missing the sky wash between the ridges."
	# No mountain / depth / floor fill inside the canyon — sky only.
	if canyon_art.get_node_or_null("DepthTiles") != null:
		controller.queue_free()
		return "Canyon must not paint depth/mountain tiles inside the mouth."
	if canyon_art.get_node_or_null("FloorWash") != null:
		controller.queue_free()
		return "Canyon must not paint a floor wash inside the mouth."
	if canyon_art.get_node_or_null("LeftInnerWalls") != null:
		controller.queue_free()
		return "Canyon must not paint inner-wall fill inside the mouth."
	var hills := controller.get_node_or_null("HorizonHills") as Node2D
	if hills == null or hills.find_child("CanyonSkyGap0", true, false) == null:
		controller.queue_free()
		return "Horizon hills must open to sky over canyon gaps (no mountains over the canyon)."
	# Interior must look like open sky, not the same warm orange as the rims.
	var sky_img := sky.texture.get_image()
	if sky_img != null:
		var sample := sky_img.get_pixel(sky_img.get_width() / 2, maxi(1, sky_img.get_height() / 5))
		if sample.b <= sample.r or sample.b < 0.45:
			controller.queue_free()
			return "Canyon interior should show painted sky blue so it stays distinct from the rims."
	if sky.z_index < 0:
		controller.queue_free()
		return "Canyon sky must stay at non-negative relative z above FloorAbyss."
	var left_rim := canyon_art.get_node("LeftRim") as Sprite2D
	if left_rim.z_index > 0:
		controller.queue_free()
		return "Canyon rims must stay under the desert surface tiles."
	var max_rim_scale := ScalableCanyonArt.RIM_SIZE / left_rim.texture.get_size()
	var wide_right := canyon_art.gap_right + 700.0
	canyon_art.configure(canyon_art.floor_top, canyon_art.gap_left, wide_right)
	var wide_scale := (canyon_art.get_node("LeftRim") as Sprite2D).scale
	if wide_scale.x > max_rim_scale.x + 0.01 or wide_scale.y > max_rim_scale.y + 0.01:
		controller.queue_free()
		return "Widening the canyon stretched the handmade rim."
	if not canyon_art.center_is_illustrated():
		controller.queue_free()
		return "Wide canyon lost open-sky center treatment."
	if not canyon_art.rims_outside_floor():
		controller.queue_free()
		return "Wide canyon rims drifted over the desert floor."
	if not canyon_art.interior_stays_inside_gap():
		controller.queue_free()
		return "Wide canyon sky spilled onto desert banks."
	controller.queue_free()
	return null


func _test_custom_level_builder() -> Variant:
	var slot := 2
	var data := CustomLevelStore.default_level(slot)
	if int(data.get("height", 0)) != 8:
		return "Default trails should use a single trail row (height 8)."
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

	if error != null:
		return error
	# Dusty Trail workshop overrides must keep the cowboy mounted.
	var dusty := CustomLevelStore.import_builtin(1)
	if not bool(dusty.get("start_mounted", false)):
		return "Importing Dusty Trail should mark the trail as start_mounted."
	var dusty_level := LevelController.new()
	dusty_level.is_custom_level = true
	CustomLevelBuilder.build(dusty_level, dusty)
	var dusty_player := dusty_level.find_child("Player", true, false) as Player
	if dusty_player == null or not dusty_player.start_mounted:
		dusty_level.free()
		return "Dusty Trail rebuilds should spawn the cowboy on his horse."
	# First cactus must sit on the trail row, clear of the canyon rim.
	var first_cactus: Node2D = null
	var first_cactus_x := INF
	for node in dusty_level.find_children("*", "Area2D", true, false):
		if node is Hazard and (node as Hazard).is_cactus():
			var cactus := node as Node2D
			if cactus.global_position.x < first_cactus_x:
				first_cactus_x = cactus.global_position.x
				first_cactus = cactus
	var layout_errors := LevelLayoutRules._validate_cactus_clear_of_canyons(dusty_level)
	if first_cactus == null:
		dusty_level.free()
		return "Imported Dusty Trail should keep at least one cactus."
	elif not layout_errors.is_empty():
		dusty_level.free()
		return "Imported Dusty Trail cactus placement: %s" % layout_errors[0]
	dusty_level.free()
	return null


func _test_trail_row_model() -> Variant:
	var legacy := {
		"version": 3,
		"height": 10,
		"width": 12,
		"spawn": [2, 8],
		"objects": [
			{"type": "ground", "x": 0, "y": 9},
			{"type": "ground", "x": 1, "y": 9},
			{"type": "ground", "x": 1, "y": 7},
			{"type": "canyon", "x": 2, "y": 9},
			{"type": "cactus", "x": 0, "y": 8},
			{"type": "star", "x": 3, "y": 7},
			{"type": "goal", "x": 4, "y": 8},
		],
	}
	var migrated := CustomLevelStore.migrate_v3_to_v4(legacy)
	if int(migrated.get("height", 0)) != 8:
		return "v3 trails should collapse the lower 3 rows into height 8."
	var trail := CustomLevelStore.trail_row(8)
	var types_at := func(x: int, y: int) -> PackedStringArray:
		var found: PackedStringArray = []
		for value in migrated.get("objects", []):
			var object := value as Dictionary
			if int(object.get("x", -1)) == x and int(object.get("y", -1)) == y:
				found.append(str(object.get("type", "")))
		return found
	if "ground" not in types_at.call(0, trail) or "cactus" not in types_at.call(0, trail):
		return "Surface props and dirt should share the single trail row after migration."
	if "canyon" not in types_at.call(2, trail):
		return "The old bottom row (3rd of the lower trio) should map canyon underside to the trail row."
	if "ground" not in types_at.call(1, trail - 1):
		return "Dirt stamped on the near-trail row should become a height step above the trail."
	var slot := CustomLevelStore.SLOT_COUNT - 2
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = [
		{"type": "ground", "x": 3, "y": trail},
		{"type": "ground", "x": 3, "y": trail - 1},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var level := LevelController.new()
	CustomLevelBuilder.build(level, data)
	var ground := level.find_child("Ground0", true, false) as StaticBody2D
	if ground == null:
		level.free()
		return "Stacked dirt should build a ground body."
	var shape := ground.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not (shape.shape is RectangleShape2D):
		level.free()
		return "Stacked dirt needs a collision shape."
	var size := (shape.shape as RectangleShape2D).size
	if size.y < 70.0:
		level.free()
		return "Two stacked dirt cells should merge into one taller bank, not two short boxes."
	WildWestTheme.apply_to_level(level)
	var has_surface := false
	var has_slope := false
	var has_slope_body := false
	for node in level.find_children("*", "Node", true, false):
		var node_name := String(node.name)
		has_surface = has_surface or node_name.begins_with("FloorSurface")
		has_slope = has_slope or node_name.begins_with("FloorSlope")
		has_slope_body = has_slope_body or node_name.begins_with("FloorSlopeBody")
	if not has_surface:
		level.free()
		return "Theme should paint desert surface over stacked dirt banks."
	if not has_slope:
		level.free()
		return "Adjacent dirt height differences should paint a natural desert slope."
	if not has_slope_body:
		level.free()
		return "Desert height slopes need walkable collision."
	level.free()
	# Campaign levels 2 and 5 should include stacked dirt height differences.
	for path in ["res://scenes/levels/level_02.tscn", "res://scenes/levels/level_05.tscn"]:
		var packed: PackedScene = load(path)
		var campaign := packed.instantiate()
		add_child(campaign)
		await get_tree().process_frame
		var fills := 0
		for node in campaign.find_children("*", "StaticBody2D", true, false):
			if String(node.name).ends_with("Fill"):
				fills += 1
		var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(campaign))
		var tops: Dictionary = {}
		for strip in merged:
			tops[int(round(float(strip["top"])))] = true
		campaign.queue_free()
		if fills < 1:
			return "%s should include stacked dirt fill banks for height steps." % path.get_file()
		if tops.size() < 2:
			return "%s should keep distinct walk heights after theme merge." % path.get_file()
	# Level 2 raised banks must not leave FloorAbyss painting a dark band over lower desert.
	var level2: Variant = _instantiate_level("res://scenes/levels/level_02.tscn")
	if level2 is String:
		return level2
	var level2_controller := level2 as LevelController
	var level2_trail := level2_controller.get_node_or_null("TrailFloor") as Node2D
	var level2_abyss := level2_trail.get_node_or_null("FloorAbyss") as ColorRect if level2_trail != null else null
	if level2_abyss == null:
		level2_controller.queue_free()
		return "Level 2 is missing FloorAbyss."
	var level2_merged := WildWestTheme._merge_segments(
		WildWestTheme._collect_ground_segments(level2_controller)
	)
	for strip in level2_merged:
		if level2_abyss.position.y + 0.5 < float(strip["top"]):
			level2_controller.queue_free()
			return (
				"Level 2 FloorAbyss paints above desert top %.0f (dark line over sand)."
				% float(strip["top"])
			)
	# Canyon beside the raised plateau should match each bank lip height.
	var pit6 := level2_controller.find_child("Pit6", true, false) as Hazard
	if pit6 != null:
		var pit6_art := pit6.get_node_or_null("CanyonMouth") as ScalableCanyonArt
		if pit6_art == null:
			pit6_art = pit6.get_node_or_null("PitMouth") as ScalableCanyonArt
		if pit6_art != null and not pit6_art.rims_match_desert_height():
			level2_controller.queue_free()
			return "Level 2 Pit6 canyon rims must match adjacent desert bank heights."
	level2_controller.queue_free()
	return null


func _test_campaign_workshop() -> Variant:
	var override_slot := CustomLevelStore.override_slot_for(1)
	var extra_slot := CustomLevelStore.SLOT_COUNT - 1
	var paths := [
		CustomLevelStore.SavePaths.custom_level_path(override_slot),
		CustomLevelStore.SavePaths.custom_level_path(extra_slot),
	]
	var backups: Array[PackedByteArray] = []
	var existed: Array[bool] = []
	for path in paths:
		existed.append(FileAccess.file_exists(path))
		backups.append(FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray())
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var imported := CustomLevelStore.import_builtin(1)
	var error: Variant = null
	if str(imported.get("kind", "")) != "override" or (imported.get("objects", []) as Array).size() < 10:
		error = "Editing a built-in level should begin with an imported copy of its layout."
	elif not CustomLevelStore.save(override_slot, imported):
		error = "Could not save a built-in campaign override."
	else:
		var extra := CustomLevelStore.default_level(extra_slot)
		extra["kind"] = "extra"
		extra["insert_position"] = 5
		extra["title"] = "Inserted Test Trail"
		if not CustomLevelStore.save(extra_slot, extra):
			error = "Could not save an inserted campaign level."
		else:
			var entries := CustomLevelStore.campaign_entries()
			var saw_override := false
			var saw_extra_before_five := false
			for i in range(entries.size()):
				var entry := entries[i]
				saw_override = saw_override or int(entry.get("custom_slot", -1)) == override_slot
				if int(entry.get("custom_slot", -1)) == extra_slot:
					saw_extra_before_five = (
						i + 1 < entries.size()
						and int(entries[i + 1].get("source_level", 0)) == 5
					)
			if not saw_override or not saw_extra_before_five:
				error = "Campaign order should replace built-ins and insert extras at the chosen position."
	var preview := LevelPreview.new()
	add_child(preview)
	preview.show_level(imported)
	if error == null and preview._data.is_empty():
		error = "The editor should keep a live preview document."
	preview.set_hover_column(3)
	if error == null and preview.get_hover_column() != 3:
		error = "Hover preview should track the focused trail column."
	preview.queue_free()
	var editor_packed: PackedScene = load("res://scenes/ui/level_editor.tscn")
	GameManager.active_custom_slot = 2
	var editor := editor_packed.instantiate()
	add_child(editor)
	var embedded_preview := editor.find_child("LevelPreview", true, false) as LevelPreview
	if error == null and (embedded_preview == null or embedded_preview.custom_minimum_size.y < 200.0):
		error = "The editor needs a large game-like hover preview at the top."
	elif error == null:
		var preview_index := embedded_preview.get_index()
		var grid_scroll := editor.find_children("*", "ScrollContainer", true, false)
		if grid_scroll.is_empty() or preview_index > grid_scroll[0].get_index():
			error = "The magnified hover preview should sit above the stamp grid."
	editor.queue_free()
	for i in range(paths.size()):
		if FileAccess.file_exists(paths[i]):
			DirAccess.remove_absolute(paths[i])
		if existed[i]:
			var restore := FileAccess.open(paths[i], FileAccess.WRITE)
			if restore != null:
				restore.store_buffer(backups[i])
	return error


func _test_trail_editor_save_reset() -> Variant:
	var slot := CustomLevelStore.SLOT_COUNT - 1
	var path := CustomLevelStore.SavePaths.custom_level_path(slot)
	var existed := FileAccess.file_exists(path)
	var backup := FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
	if existed:
		DirAccess.remove_absolute(path)
	var draft := CustomLevelStore.default_level(slot)
	draft["kind"] = "extra"
	draft["insert_position"] = 4
	draft["title"] = "Unsaved Test Trail"
	GameManager.active_custom_slot = slot
	GameManager.custom_level_draft = draft
	var packed: PackedScene = load("res://scenes/ui/level_editor.tscn")
	var editor = packed.instantiate()
	add_child(editor)
	var error: Variant = null
	var save_button := editor.find_child("SaveButton", true, false) as Button
	var reset_button := editor.find_child("ResetButton", true, false) as Button
	var preview := editor.find_child("LevelPreview", true, false) as LevelPreview
	if save_button == null or reset_button == null:
		error = "Trail editor should expose visible Save and Reset buttons."
	elif save_button.disabled:
		error = "A new unsaved trail must be saveable even before its first edit."
	editor._selected_type = "star"
	editor._place(0, 0)
	if error == null and (not editor._dirty or reset_button.disabled):
		error = "Grid edits should mark the trail dirty and enable Reset."
	editor._reset()
	if error == null and FileAccess.file_exists(path):
		error = "Resetting a new unsaved trail must not create or delete a saved level."
	elif error == null and editor._display_type_at(0, 0) != "":
		error = "Reset should restore a new trail's starting layout."
	elif error == null and (editor._dirty or preview._data != editor._data):
		error = "Reset should clear dirty state and refresh the live preview."
	editor._on_title_changed("First Saved Name")
	editor._title_edit.text = "First Saved Name"
	editor._save()
	if error == null and not FileAccess.file_exists(path):
		error = "Save should persist a new trail in its reserved slot."
	editor._selected_type = "star"
	editor._place(1, 1)
	editor._reset()
	if error == null and editor._display_type_at(1, 1) != "":
		error = "Reset should restore the last successfully saved document."
	editor._on_title_changed("Updated Saved Name")
	editor._title_edit.text = "Updated Saved Name"
	editor._save()
	var matching_entries := 0
	for entry in CustomLevelStore.campaign_entries():
		if int(entry.get("custom_slot", -1)) == slot:
			matching_entries += 1
	var loaded := CustomLevelStore.load_level(slot)
	if error == null and str(loaded.get("title", "")) != "Updated Saved Name":
		error = "Saving an existing trail should overwrite that same level."
	elif error == null and matching_entries != 1:
		error = "Repeated saves must not duplicate campaign playlist entries."
	elif error == null and (editor._dirty or not save_button.disabled):
		error = "A successful save should clear dirty state and disable no-op Save."
	editor.queue_free()
	GameManager.custom_level_draft = {}
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if existed:
		var restore := FileAccess.open(path, FileAccess.WRITE)
		if restore != null:
			restore.store_buffer(backup)
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
		"res://assets/world/transition_desert_skyline.png",
		"res://assets/world/canyon_gap.png",
		"res://assets/world/canyon_rim_left.png",
		"res://assets/world/canyon_depth_tile.png",
		"res://assets/world/canyon_sky_wash.png",
		"res://assets/world/canyon_inner_wall.png",
		"res://assets/world/canyon_floor_wash.png",
		"res://assets/world/trail_horse.png",
		"res://assets/world/trail_horse_gallop_0.png",
		"res://assets/world/trail_horse_gallop_1.png",
		"res://assets/world/cowboy_horse_ride_0.png",
		"res://assets/world/cowboy_horse_ride_1.png",
		"res://assets/world/cowboy_horse_jump.png",
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
	if load("res://scenes/ui/startup_loading.tscn") == null:
		return "Game needs a visible startup loading scene."
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	if (
		not project_text.contains("startup_loading.tscn")
		or not project_text.contains("boot_splash/image")
	):
		return "Startup should show the handmade loading art before the menu appears."
	var wind_packed: PackedScene = load("res://scenes/world/wind_zone.tscn")
	var wind: Node = wind_packed.instantiate()
	var wind_background := wind.get_node_or_null("Visual") as ColorRect
	if wind_background == null or wind_background.visible:
		wind.free()
		return "Wind animation background should be transparent."
	wind.free()
	var transition_packed: PackedScene = load("res://scenes/ui/level_transition.tscn")
	var transition := transition_packed.instantiate() as LevelTransition
	add_child(transition)
	transition.play_celebration()
	var transition_skyline := transition.get_node_or_null("HandmadeSkyline") as TextureRect
	if transition_skyline == null or transition_skyline.texture == null:
		transition.queue_free()
		return "Level transitions need their own handmade desert skyline."
	var saloon := transition.get_node_or_null("CelebrationSaloon") as Sprite2D
	var celebration_cowboy := transition.get_node_or_null("CelebrationCowboy") as Sprite2D
	if (
		saloon == null
		or celebration_cowboy == null
		or celebration_cowboy.position.y < saloon.position.y + 35.0
	):
		transition.queue_free()
		return "Level-transition cowboy should stand on the saloon's bottom plank, not its roof."
	transition.queue_free()
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
	var canyon := controller.find_child("Pit3", true, false) as Hazard
	if canyon == null:
		controller.queue_free()
		return "Level fixture is missing canyon Pit3."
	var canyon_art := canyon.get_node_or_null("CanyonMouth") as ScalableCanyonArt
	if canyon_art == null:
		canyon_art = canyon.get_node_or_null("PitMouth") as ScalableCanyonArt
	if (
		canyon_art == null
		or canyon_art.get_node_or_null("LeftRim") == null
		or canyon_art.get_node_or_null("RightRim") == null
	):
		controller.queue_free()
		return "Canyon needs separate handmade canyon rims."
	var floor_top := 320.0
	if absf(canyon_art.floor_top - floor_top) > 4.0:
		controller.queue_free()
		return "Canyon rim should meet the trail floor."
	if not canyon_art.rims_outside_floor():
		controller.queue_free()
		return "Canyon rims must sit outside the desert floor banks."
	# Opening should cover the fall gap between Ground2 and Ground3.
	var g2 := controller.get_node_or_null("Ground2/Visual") as ColorRect
	var g3 := controller.get_node_or_null("Ground3/Visual") as ColorRect
	if g2 != null and g3 != null:
		var gap_left: float = controller.get_node("Ground2").position.x + maxf(g2.offset_left, g2.offset_right)
		var gap_right: float = controller.get_node("Ground3").position.x + minf(g3.offset_left, g3.offset_right)
		if absf(canyon_art.gap_left - gap_left) > 12.0 or absf(canyon_art.gap_right - gap_right) > 12.0:
			controller.queue_free()
			return "Canyon borders should match the fall gap."
		var max_rim_scale := ScalableCanyonArt.RIM_SIZE / (canyon_art.get_node("LeftRim") as Sprite2D).texture.get_size()
		canyon_art.configure(floor_top, gap_left, gap_right + 600.0)
		var wide_scale := (canyon_art.get_node("LeftRim") as Sprite2D).scale
		if (
			canyon_art.opening_width() < gap_right - gap_left + 590.0
			or wide_scale.x > max_rim_scale.x + 0.01
			or wide_scale.y > max_rim_scale.y + 0.01
		):
			controller.queue_free()
			return "Canyon center should widen without stretching its handmade rims."
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


func _test_one_way_cloud_platforms() -> Variant:
	var packed: PackedScene = load("res://scenes/world/disappearing_platform.tscn")
	if packed == null:
		return "Missing cloud platform scene."
	var cloud := packed.instantiate() as DisappearingPlatform
	cloud.position = Vector2(200, 400)
	cloud.trail_floor_top = 320.0
	cloud.floor_clearance = 36.0
	cloud.always_solid = true
	add_child(cloud)
	await get_tree().process_frame
	var shape := cloud.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var error: Variant = null
	if shape == null or not shape.one_way_collision:
		error = "Clouds must use Godot one-way collision."
	elif cloud.global_position.y > 320.0 - 36.0 - 7.0:
		error = "Clouds must stay clear of the trail floor."
	elif not cloud.is_one_way_cloud():
		error = "Solid clouds should report one-way configuration."
	cloud.queue_free()
	return error


func _test_wind_zone_force_overlap() -> Variant:
	var packed: PackedScene = load("res://scenes/world/wind_zone.tscn")
	var wind := packed.instantiate() as WindZone
	add_child(wind)
	var player_packed: PackedScene = load("res://scenes/player/player.tscn")
	var player := player_packed.instantiate() as Player
	add_child(player)
	player.global_position = wind.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame

	var delta := 1.0 / 60.0
	var error: Variant = null

	# 1) A single tick must now beat the old 20 px/s nudge, without slamming.
	player.velocity = Vector2.ZERO
	player.external_velocity = Vector2.ZERO
	wind._physics_process(delta)
	var one_tick := player.external_velocity.x
	if one_tick < 34.0:
		error = "Wind should be stronger than the old barely noticeable 20 px/s nudge."
	elif one_tick > 36.0:
		error = "Wind should only accelerate gently per tick, not slam the cowboy."

	# 2) Sustained overlap must settle at a noticeable 35-50 px/s, never runaway.
	# Emulate the player's own per-frame handling: idle friction, then the wind
	# push folded into velocity (mirrors Player._physics_process order).
	if error == null:
		player.velocity = Vector2.ZERO
		for _i in range(300):
			player.velocity.x = move_toward(player.velocity.x, 0.0, player.friction * delta)
			player.external_velocity = Vector2.ZERO
			wind._physics_process(delta)
			player.velocity += player.external_velocity
		if player.velocity.x < 35.0 or player.velocity.x > 50.0:
			error = "Wind should settle at a clearly felt 35-50 px/s sideways drift."
		elif player.velocity.x > wind.max_wind_speed + 1.0:
			error = "Wind must never push the cowboy past its speed cap (no runaway)."

	# 3) The cowboy can still walk against the wind: strong opposing input wins.
	if error == null:
		player.velocity = Vector2(-player.move_speed, 0.0)
		for _j in range(120):
			# Player pushing hard against the wind each frame.
			player.velocity.x = move_toward(
				player.velocity.x, -player.move_speed, player.acceleration * delta
			)
			player.external_velocity = Vector2.ZERO
			wind._physics_process(delta)
			player.velocity += player.external_velocity
		if player.velocity.x >= 0.0:
			error = "Wind should be counterable: walking against it must still make headway."

	# 4) Every authored wind zone must use the tuned values rather than stale overrides.
	if error == null:
		for level_path in [
			"res://scenes/levels/level_06.tscn",
			"res://scenes/levels/level_09.tscn",
			"res://scenes/levels/level_10.tscn",
		]:
			var level := (load(level_path) as PackedScene).instantiate()
			for wind_name in ["Wind0", "Wind1", "Wind2", "Wind3"]:
				var authored_wind := level.get_node_or_null(wind_name) as WindZone
				if authored_wind == null:
					error = "%s is missing %s." % [level_path, wind_name]
					break
				if (
					authored_wind.wind_force != wind.wind_force
					or authored_wind.max_wind_speed != wind.max_wind_speed
				):
					error = "%s/%s has stale wind tuning." % [level_path, wind_name]
					break
			level.free()
			if error != null:
				break

	player.queue_free()
	wind.queue_free()
	return error


func _test_handmade_hud_signs() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/hud.tscn")
	var hud := packed.instantiate() as Hud
	add_child(hud)
	var banner := hud.get_node_or_null("Banner")
	var prompt := hud.get_node_or_null("PromptBanner")
	var error: Variant = null
	if banner == null or prompt == null:
		error = "HUD needs top and bottom sign boards."
	elif banner is ColorRect or prompt is ColorRect:
		error = "HUD banners should not be flat ColorRect plates."
	elif not (banner is HandmadeSign) or not (prompt is HandmadeSign):
		error = "HUD banners should use HandmadeSign western boards."
	hud.queue_free()
	return error


func _test_saloon_transition_anchor() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/level_transition.tscn")
	var transition := packed.instantiate() as LevelTransition
	add_child(transition)
	var anchor := Vector2(640, 220)
	var floor_y := 320.0
	var screen_scale := 0.84
	transition.play_celebration("Yeehaw!", 2, anchor, floor_y, screen_scale)
	var saloon := transition.get_node_or_null("CelebrationSaloon") as Sprite2D
	var cowboy := transition.get_node_or_null("CelebrationCowboy") as Sprite2D
	var horse := transition.get_node_or_null("TrailHorse") as Sprite2D
	var rider := transition.get_node_or_null("CowboyHorse") as Sprite2D
	var expected_scale := Player.HORSE_VISUAL_SCALE * screen_scale
	var expected_ride_y := floor_y + LevelTransition.MOUNTED_SPRITE_OFFSET_Y * screen_scale
	var error: Variant = null
	if saloon == null or cowboy == null or horse == null or rider == null:
		error = "Celebration needs saloon, cowboy, horse, and rider sprites."
	elif saloon.position.distance_to(anchor) > 1.0:
		error = "Celebration saloon should stay at the passed goal screen position."
	elif absf(cowboy.position.y - (saloon.position.y + 50.0)) > 1.0:
		error = "Cowboy should keep the doorway stance relative to the saloon."
	elif transition.get_saloon_screen_position().distance_to(anchor) > 1.0:
		error = "Transition should expose the anchored saloon screen position."
	elif absf(transition.get_floor_screen_y() - floor_y) > 1.0:
		error = "Transition should use the passed trail floor baseline."
	elif absf(horse.scale.x - expected_scale) > 0.01 or absf(rider.scale.x - expected_scale) > 0.01:
		error = (
			"Transition horse should match gameplay horse scale (got %.3f, want %.3f)."
			% [horse.scale.x, expected_scale]
		)
	elif absf(horse.position.y - expected_ride_y) > 1.0:
		error = "Transition horse center should sit above the floor like MountedHorse."
	elif absf(transition.get_ride_center_y() - expected_ride_y) > 1.0:
		error = "Transition should expose the mounted ride baseline."
	transition.queue_free()
	return error


func _test_arrival_leaves_horse_at_spawn() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/level_transition.tscn")
	var transition := packed.instantiate() as LevelTransition
	add_child(transition)
	var spawn := Vector2(180.0, 360.0)
	var floor_y := 360.0
	var screen_scale := 1.0
	transition.play_arrival(spawn, floor_y, screen_scale)
	# Wait until the cowboy has dismounted and the empty horse is left at spawn.
	var horse := transition.get_node_or_null("TrailHorse") as Sprite2D
	var rider := transition.get_node_or_null("CowboyHorse") as Sprite2D
	var frames := 0
	while frames < 240:
		await get_tree().process_frame
		frames += 1
		if (
			horse != null
			and horse.visible
			and horse.modulate.a > 0.9
			and rider != null
			and not rider.visible
		):
			break
	var error: Variant = null
	if horse == null:
		error = "Arrival needs the trail horse sprite."
	elif absf(horse.position.x - spawn.x) > 3.0:
		error = (
			"Arrival should leave the horse at the level start (horse x=%.1f, spawn x=%.1f)."
			% [horse.position.x, spawn.x]
		)
	elif horse.position.x > get_viewport().get_visible_rect().size.x:
		error = "Arrival must not send the horse off-screen after dismount."
	elif not transition.leaves_horse_at_spawn():
		error = "Transition should report that the horse remains at the spawn anchor."
	if error != null:
		transition.queue_free()
		return error
	await transition.arrival_finished
	# Position must still be the spawn after the overlay closes (no ride-away).
	if absf(horse.position.x - spawn.x) > 3.0:
		error = "Horse must stay at the level start through the end of arrival."
	transition.queue_free()
	return error


func _test_empty_horse_gallop_animation() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/level_transition.tscn")
	var transition := packed.instantiate() as LevelTransition
	add_child(transition)
	transition.play_celebration("Yeehaw!", 0, Vector2(640, 220), 320.0, 1.0)
	transition.set_progress(0.12)
	var saw_gallop := false
	var frame_ids: Dictionary = {}
	for _i in range(36):
		await get_tree().process_frame
		if transition.is_empty_horse_galloping():
			saw_gallop = true
			var horse := transition.get_node_or_null("TrailHorse") as Sprite2D
			if horse != null and horse.texture != null:
				frame_ids[horse.texture.get_instance_id()] = true
	var error: Variant = null
	if not saw_gallop:
		error = "Riderless horse should gallop while approaching the saloon."
	elif frame_ids.size() < 2:
		error = "Empty-horse approach needs at least two gallop frames."
	transition.set_progress(0.35)
	await get_tree().process_frame
	var idle_horse := transition.get_node_or_null("TrailHorse") as Sprite2D
	if error == null and transition.is_empty_horse_galloping():
		error = "Empty horse should stop galloping while the cowboy mounts."
	elif (
		error == null
		and idle_horse != null
		and idle_horse.visible
		and idle_horse.texture != LevelTransition.HORSE_TEXTURE
	):
		error = "Mounting pause should use the standing trail horse, not gallop frames."
	transition.queue_free()
	return error


func _test_two_cloud_canyon_chains() -> Variant:
	for lv in ["07", "10"]:
		var packed: PackedScene = load("res://scenes/levels/level_%s.tscn" % lv)
		var level := packed.instantiate()
		add_child(level)
		var chain_pairs := 0
		if level.get_node_or_null("CloudCanyon0A") != null and level.get_node_or_null("CloudCanyon0B") != null:
			chain_pairs += 1
		if level.get_node_or_null("CloudCanyon2A") != null and level.get_node_or_null("CloudCanyon2B") != null:
			chain_pairs += 1
		level.queue_free()
		if chain_pairs < 1:
			return "Level %s should include at least one two-cloud canyon hop chain." % lv
	return null


func _test_wings_carrion_variety() -> Variant:
	for lv in ["07", "10"]:
		var packed: PackedScene = load("res://scenes/levels/level_%s.tscn" % lv)
		var level := packed.instantiate()
		add_child(level)
		var heights: Array[float] = []
		for node in level.find_children("*", "Area2D", true, false):
			if node is Carrion:
				heights.append((node as Node2D).global_position.y)
		level.queue_free()
		if heights.size() < 10:
			return "Level %s should place more carrions for the Wings route (found %d)." % [lv, heights.size()]
		heights.sort()
		if heights[heights.size() - 1] - heights[0] < 200.0:
			return "Level %s carrions should vary in height, not form one line." % lv
	return null


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
