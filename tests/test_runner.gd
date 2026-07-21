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
	failures += await _run("Canyon rafts travel on steep required routes", _test_steep_canyon_rafts)
	failures += await _run("Custom level store and builder work", _test_custom_level_builder)
	failures += await _run("Campaign workshop edits and inserts levels", _test_campaign_workshop)
	failures += await _run("Hand-drawn celebration art and cheerful music load", _test_art_and_music)
	failures += await _run("Mid-trail save data persists and loads", _test_mid_trail_save)
	failures += await _run("Saved camp and badges restore inside a level", _test_level_run_restore)
	failures += await _run("Pause menu exposes save, load, and restart from start", _test_pause_save_controls)
	failures += await _run("Boss arenas expose lasso targets and solvable kingpin layout", _test_boss_arenas)
	failures += await _run("Clouds are one-way platforms that stay above the floor", _test_one_way_cloud_platforms)
	failures += await _run("Wind zones push while overlapping gusts", _test_wind_zone_force_overlap)
	failures += await _run("HUD uses handmade western sign boards", _test_handmade_hud_signs)
	failures += await _run("Celebration saloon keeps the goal screen position", _test_saloon_transition_anchor)
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
	var delete_dialog := scene.get_node_or_null("DeleteConfirmation") as ConfirmationDialog
	if error == null and delete_dialog == null:
		error = "Save deletion needs a confirmation dialog."
	var first_card := scene.get_node_or_null("Slots/Slot1") as Button
	if error == null and first_card != null and not first_card.text.contains("4: "):
		error = "Save cards should show level names as '<number>: <name>'."
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
	scene.queue_free()
	GameManager.erase_slot(0)
	return error


func _test_localization_settings() -> Variant:
	var previous_language := String(GameManager.get_settings().get("language", "en"))
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
	_free_level(node)
	return error


func _test_ten_levels_exist() -> Variant:
	if GameManager.LEVEL_SCENES.size() != 10:
		return "Expected 10 levels."
	if GameManager.level_name_for(2) != "2: Badge Meadow":
		return "Level names should use the '<number>: <name>' format."
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
	var wings := cowboy.get_node_or_null("WingArt") as Sprite2D
	if wings == null or wings.scale.x < 0.9:
		node.queue_free()
		return "Fly power should display large, clearly visible wings."
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
		if top_guards < 2 or top_guards > 3:
			return "Level %s should use 2-3 top-route carrions (found %d)." % [lv, top_guards]
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
	var lantern := door.get_node_or_null("StatusLantern") as Polygon2D
	var error: Variant = null
	if handmade_gate == null or handmade_gate.texture == null:
		error = "Timed door should use the hand-painted fence gate artwork."
	elif door.get_node_or_null("StatusPlate") != null or door.get_node_or_null("Barrier") != null:
		error = "Timed doors should not use generic status plates or barrier rectangles."
	elif lantern == null:
		error = "Timed door needs a status lantern so open and closed states are clear."
	else:
		door._open = false
		door._apply_state(false)
		var closed_scale := handmade_gate.scale
		var closed_color := lantern.color
		door._open = true
		door._apply_state(false)
		var open_scale := handmade_gate.scale
		var open_color := lantern.color
		if closed_color.is_equal_approx(open_color):
			error = "Open and closed gates must look clearly different."
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


func _test_steep_canyon_rafts() -> Variant:
	var packed: PackedScene = load("res://scenes/levels/level_04.tscn")
	var level: Node = packed.instantiate()
	var rafts: Array[MovingPlatform] = []
	for node in level.find_children("*", "AnimatableBody2D", true, false):
		if node is MovingPlatform:
			rafts.append(node as MovingPlatform)
	if rafts.size() < 2:
		level.free()
		return "Level 4 should keep at least two steep canyon rafts."
	var steep_rafts := 0
	for raft in rafts:
		var route := raft.point_b - raft.point_a
		var angle := rad_to_deg(atan2(absf(route.y), absf(route.x)))
		if angle >= 34.0 and angle <= 36.0:
			steep_rafts += 1
	if steep_rafts < 2:
		level.free()
		return "Level 4 needs at least two ~35-degree raft crossings (found %d)." % steep_rafts
	# Varied platforming identity: not every canyon is an ultra-wide raft-only gap.
	var hop_clouds := 0
	var hop_steps := 0
	for node in level.get_children():
		var node_name := String(node.name)
		if node_name.begins_with("FerryCloud"):
			hop_clouds += 1
		elif node_name.begins_with("FerryStep") or node_name.begins_with("FerryIsle"):
			hop_steps += 1
	if hop_clouds < 2 or hop_steps < 2:
		level.free()
		return "Level 4 should mix cloud/plank hops with raft canyons."
	if level.get_node_or_null("FerrySpring6") == null:
		level.free()
		return "Level 4 needs a spring-assisted ferry gap for variety."
	for removed_ground in ["Ground3", "Ground6", "Ground9", "Ground12"]:
		if level.get_node_or_null(removed_ground) != null:
			level.free()
			return "Level 4 canyon at %s is still narrow enough to bypass its raft." % removed_ground
	level.free()
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
		error = "The editor should keep a live preview document below its grid."
	preview.queue_free()
	var editor_packed: PackedScene = load("res://scenes/ui/level_editor.tscn")
	GameManager.active_custom_slot = 2
	var editor := editor_packed.instantiate()
	add_child(editor)
	var embedded_preview := editor.find_child("LevelPreview", true, false) as LevelPreview
	if error == null and (embedded_preview == null or embedded_preview.custom_minimum_size.y < 140.0):
		error = "The editor needs an always-visible preview below the editing area."
	editor.queue_free()
	for i in range(paths.size()):
		if FileAccess.file_exists(paths[i]):
			DirAccess.remove_absolute(paths[i])
		if existed[i]:
			var restore := FileAccess.open(paths[i], FileAccess.WRITE)
			if restore != null:
				restore.store_buffer(backups[i])
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
		"res://assets/world/trail_horse.png",
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
	var pit := controller.find_child("Pit3", true, false) as Hazard
	if pit == null:
		controller.queue_free()
		return "Level fixture is missing Pit3."
	var pit_mouth := pit.get_node_or_null("PitMouth") as ScalableCanyonArt
	if (
		pit_mouth == null
		or pit_mouth.get_node_or_null("LeftRim") == null
		or pit_mouth.get_node_or_null("RightRim") == null
	):
		controller.queue_free()
		return "Pit needs separate handmade canyon rims."
	var floor_top := 320.0
	if absf(pit_mouth.floor_top - floor_top) > 4.0:
		controller.queue_free()
		return "Canyon rim should meet the trail floor."
	# Opening should cover the fall gap between Ground2 and Ground3.
	var g2 := controller.get_node_or_null("Ground2/Visual") as ColorRect
	var g3 := controller.get_node_or_null("Ground3/Visual") as ColorRect
	if g2 != null and g3 != null:
		var gap_left: float = controller.get_node("Ground2").position.x + maxf(g2.offset_left, g2.offset_right)
		var gap_right: float = controller.get_node("Ground3").position.x + minf(g3.offset_left, g3.offset_right)
		if absf(pit_mouth.gap_left - gap_left) > 12.0 or absf(pit_mouth.gap_right - gap_right) > 12.0:
			controller.queue_free()
			return "Canyon borders should match the fall gap."
		var left_scale := (pit_mouth.get_node("LeftRim") as Sprite2D).scale
		pit_mouth.configure(floor_top, gap_left, gap_right + 600.0)
		if (
			pit_mouth.opening_width() < gap_right - gap_left + 590.0
			or (pit_mouth.get_node("LeftRim") as Sprite2D).scale != left_scale
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
	wind.wind_force = Vector2(180, -25)
	add_child(wind)
	var player_packed: PackedScene = load("res://scenes/player/player.tscn")
	var player := player_packed.instantiate() as Player
	add_child(player)
	player.global_position = wind.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	player.external_velocity = Vector2.ZERO
	wind._physics_process(0.016)
	var after := player.external_velocity
	var error: Variant = null
	if after.x < 100.0:
		error = "Wind should apply a strong push while the cowboy overlaps the gust zone."
	elif not is_equal_approx(after.y, wind.wind_force.y):
		error = "Wind should apply its full indicated direction (including upward lift)."
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
	transition.play_celebration("Yeehaw!", 2, anchor)
	var saloon := transition.get_node_or_null("CelebrationSaloon") as Sprite2D
	var cowboy := transition.get_node_or_null("CelebrationCowboy") as Sprite2D
	var error: Variant = null
	if saloon == null or cowboy == null:
		error = "Celebration needs saloon and cowboy sprites."
	elif saloon.position.distance_to(anchor) > 1.0:
		error = "Celebration saloon should stay at the passed goal screen position."
	elif absf(cowboy.position.y - (saloon.position.y + 50.0)) > 1.0:
		error = "Cowboy should keep the doorway stance relative to the saloon."
	elif transition.get_saloon_screen_position().distance_to(anchor) > 1.0:
		error = "Transition should expose the anchored saloon screen position."
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
