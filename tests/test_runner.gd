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
	failures += await _run("Menu buttons have hover and click feedback", _test_menu_button_hover_and_click)
	failures += await _run("Save select offers Advanced Mode in Settings", _test_settings_trail_mode_dropdown)
	failures += await _run("Settings dropdown popups stay readable", _test_settings_dropdown_popup_contrast)
	failures += await _run("Settings trail mode selection applies to slots", _test_settings_trail_mode_selection)
	failures += await _run("Settings trail mode persists through refresh", _test_settings_trail_mode_refresh)
	failures += await _run("Advanced Mode lives and badge milestones", _test_advanced_mode_lives)
	failures += await _run("Advanced Mode lives hearts show in HUD", _test_advanced_mode_lives_hud)
	failures += await _run("Advanced Mode respawn costs a life", _test_advanced_mode_respawn_cost)
	failures += await _run("Advanced Mode game over scene exists", _test_advanced_mode_game_over_scene)
	failures += await _run("Advanced Mode boss fights skip boss hearts", _test_advanced_boss_skips_hearts)
	failures += await _run(
		"Element reference link visible iff debug mode is on",
		_test_element_reference_link
	)
	failures += await _run(
		"Translation editor button visible iff debug mode is on",
		_test_translation_editor_button_debug_gate
	)
	failures += await _run("German text and language settings work", _test_localization_settings)
	failures += await _run("Settings language dropdown persists and supports controller use", _test_settings_language_dropdown)
	failures += await _run("Settings stores player character choice", _test_settings_player_character)
	failures += await _run(
		"Save slots remember rider and trail mode",
		_test_slot_remembers_character_and_trail_mode
	)
	failures += await _run("Translation CSV parses and round-trips safely", _test_translation_csv_round_trip)
	failures += await _run("Translation placeholders render and validate", _test_translation_placeholders)
	failures += await _run("Translation editor loads and exports portably", _test_translation_editor)
	failures += await _run("Handmade trail progress and effect sounds work", _test_handmade_progress_and_sfx)
	failures += await _run("Level 01 contains core objects", _test_level_01_world_objects)
	failures += await _run("Level catalog has sixteen scenes", _test_sixteen_levels_exist)
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
	failures += await _run(
		"Rattlesnakes stay clear of canyon approaches",
		_test_rattlesnakes_clear_of_canyons
	)
	failures += await _run(
		"Desert campaign levels use rattlesnakes not scorpions",
		_test_desert_levels_use_rattlesnakes
	)
	failures += await _run(
		"Canyons that end higher need an approach spring",
		_test_canyon_up_needs_spring
	)
	failures += await _run(
		"Levels 7-10 keep 2-10 continuous height differences",
		_test_late_level_height_differences
	)
	failures += await _run("Lasso ties bandits and makes them pass-through", _test_lasso_ties_bandit)
	failures += await _run("Treasure chest random loot and reveal", _test_treasure_chest)
	failures += await _run("Treasure chest resets on respawn before camp", _test_treasure_chest_respawn_reset)
	failures += await _run("Treasure chest height ratio", _test_treasure_chest_height_ratio)
	failures += await _run("Treasure chest campaign placement", _test_treasure_chest_campaign_placement)
	failures += await _run("Treasure chests stand on walk surface", _test_treasure_chest_on_walk_surface)
	failures += await _run("Lasso cast ties bandits via HurtArea", _test_lasso_cast_hits_hurt_area)
	failures += await _run("Jumping on a bandit head ties him", _test_stomp_ties_bandit)
	failures += await _run("Trail bull charges toward the player", _test_bull_charges_player)
	failures += await _run("Bulls turn at pit and canyon edges", _test_bull_turns_at_gap)
	failures += await _run("Bulls turn after the cowboy jumps over", _test_bull_turns_after_jump_over)
	failures += await _run("Bulls never stamp on pits or canyons", _test_bull_stamp_avoids_gaps)
	failures += await _run(
		"Ground stamps never sit on pits or canyons",
		_test_ground_stamps_avoid_gaps
	)
	failures += await _run(
		"Trail editor saloon stamps only on the floor",
		_test_saloon_stamp_only_on_floor
	)
	failures += await _run(
		"Workshop stamps cannot overlap footprints",
		_test_workshop_stamps_no_overlap
	)
	failures += await _run("Lasso ties trail bulls", _test_lasso_ties_bull)
	failures += await _run("Jumping on a bull head ties it", _test_stomp_ties_bull)
	failures += await _run("Side contact with a bull sends the cowboy to camp", _test_bull_side_contact_hurts)
	failures += await _run("Ninja ambushes in front of the player", _test_ninja_ambush_spawn)
	failures += await _run("Ninja sword attack hurts the cowboy", _test_ninja_sword_hurts)
	failures += await _run("Lasso ties ninjas", _test_lasso_ties_ninja)
	failures += await _run("Jumping on a ninja head ties him", _test_stomp_ties_ninja)
	failures += await _run("Ninja throws shuriken at flying player", _test_ninja_shuriken_vs_wings)
	failures += await _run("Ninja jumps pits and canyons", _test_ninja_jumps_gaps)
	failures += await _run("Ninja hops onto planks the cowboy can reach", _test_ninja_hops_onto_planks)
	failures += await _run("Ninja shows only one facing sprite", _test_ninja_single_sprite)
	failures += await _run("Ninja follows dune slope height while chasing", _test_ninja_follows_slope_height)
	failures += await _run("Three chasing ninjas stay cheap per frame", _test_ninja_chase_performance)
	failures += await _run("Ninja resets to dormancy on respawn", _test_ninja_respawn_restore)
	failures += await _run("Workshop preview shows stamped ninjas", _test_workshop_preview_shows_ninja)
	failures += await _run("Shuriken sprite is handcrafted art", _test_shuriken_art)
	failures += await _run("Side contact with a bandit sends the cowboy to camp", _test_side_contact_hurts)
	failures += await _run("Upward contact with a bandit sends the cowboy to camp", _test_upward_contact_hurts)
	failures += await _run(
		"Standing above a bandit without falling sends the cowboy to camp",
		_test_standing_above_hurts
	)
	failures += await _run("Bandits turn around at plank edges", _test_bandit_respects_plank_edges)
	failures += await _run("Controller bindings match every gamepad device", _test_controller_all_devices)
	failures += await _run("Flying levels guard the very top of the screen", _test_flying_levels_top_guarded)
	failures += await _run("Timed door shows a clear open/closed barrier", _test_timed_door_states)
	failures += await _run("Cave trails carry no ranch gates", _test_cave_trails_have_no_doors)
	failures += await _run("Wing Chasm hands out wings at camp", _test_wing_chasm_hands_out_wings_at_camp)
	failures += await _run(
		"Conveyors do not push into open canyons",
		_test_conveyors_do_not_push_into_canyons
	)
	failures += await _run("Gameplay obstacles do not display floating text", _test_obstacle_labels_hidden)
	failures += await _run("Untied bandits restore normal standing size", _test_untie_restores_stand_scale)
	failures += await _run("Bandits stand on the desert surface", _test_bandits_stand_on_desert)
	failures += await _run("Cacti align to desert slopes", _test_cactus_aligns_to_desert_slope)
	failures += await _run("Dune crest stays walkable without jumping", _test_slope_crest_walkable)
	failures += await _run("Slope ground collision clears dune bridge", _test_slope_ground_bridge_clear)
	failures += await _run("Slope earth fill stays below crust line", _test_slope_dirt_below_crust)
	failures += await _run("Slope underfill covers dune wedge", _test_slope_underfill_covers_wedge)
	failures += await _run("Slope underfill uses warm bank earth", _test_slope_underfill_earth_color)
	failures += await _run("Cave floor tiles are solid without holes", _test_cave_floor_tiles_solid)
	failures += await _run("Cave sky wash tucks under the floor", _test_cave_sky_meets_floor)
	failures += await _run("Cave camp sprites have transparent backgrounds", _test_cave_camp_transparent)
	failures += await _run("Cave skeleton feet sit on the ground", _test_skeleton_feet_on_ground)
	failures += await _run("Tied skeleton bow gap is transparent", _test_skeleton_tied_bow_transparent)
	failures += await _run("Filled save can pick Advanced Mode", _test_filled_slot_advanced_mode_select)
	failures += await _run("Bandits play walk animation while moving", _test_bandit_walk_animation)
	failures += await _run("Cave skeletons loft arrows at flyers above", _test_skeleton_shoots_up_at_flyer)
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
	failures += await _run(
		"Moonlight Gulch springs and planks clear the gulch floor",
		_test_level_09_gulch_clearance
	)
	failures += await _run(
		"Moonlight Gulch workshop import keeps ledges and hop movers",
		_test_level_09_workshop_parity
	)
	failures += await _run(
		"Canyon lips are not walkable over blue sky",
		_test_canyon_lips_not_walkable_over_sky
	)
	failures += await _run(
		"Ninja keeps walking under a flying player between throws",
		_test_ninja_walks_under_flyer
	)
	failures += await _run(
		"Ceiling drips and stalactites hang from the cave ceiling",
		_test_ceiling_hangings_from_ceiling
	)
	failures += await _run(
		"Cowboy climb frames are not the cowgirl back view",
		_test_cowboy_climb_not_cowgirl
	)
	failures += await _run("Canyon rafts are one-way jump-through platforms", _test_one_way_moving_platforms)
	failures += await _run("Custom level store and builder work", _test_custom_level_builder)
	failures += await _run("Ladder branches land on the upper ledge", _test_ladder_branch_upper_ledge)
	failures += await _run("Cave levels place belts fences and ladders", _test_cave_levels_belts_fences_ladders)
	failures += await _run("Workshop default trail width matches built-ins", _test_workshop_default_width)
	failures += await _run("Workshop trail length add and remove", _test_workshop_trail_length_resize)
	failures += await _run("Trail workshop uses one trail row and stacked dirt", _test_trail_row_model)
	failures += await _run("Workshop ground props stamp one row above dirt", _test_workshop_ground_prop_offset)
	failures += await _run(
		"Workshop stamp catalog matches campaign and separates threats",
		_test_workshop_stamp_catalog
	)
	failures += await _run(
		"Horse theme bans chests and power-up items",
		_test_horse_theme_bans_items_and_chests
	)
	failures += await _run("Fixed pits use pit.png at native size", _test_fixed_pit_art)
	failures += await _run("Workshop pits require trail dirt", _test_pit_dirt_placement)
	failures += await _run("Pit falls match canyon respawn rules", _test_pit_canyon_parity)
	failures += await _run("Workshop preview click requests stamp placement", _test_workshop_preview_stamp)
	failures += await _run("Workshop preview hover ghost tracks cursor", _test_workshop_preview_ghost)
	failures += await _run("Workshop preview ghost matches stamp size", _test_workshop_preview_ghost_size)
	failures += await _run("Workshop stamp grid can collapse", _test_workshop_grid_collapse)
	failures += await _run("Workshop right click removes stamp", _test_workshop_right_click_remove)
	failures += await _run("Workshop preview click places stamp", _test_workshop_preview_places_stamp)
	failures += await _run("Airborne bandits fall to walkable ground", _test_airborne_bandit_falls)
	failures += await _run("Buried bandits lift onto the floor", _test_buried_bandit_lifts)
	failures += await _run("Level 10 bandits stand on the walk surface", _test_level_10_bandits_on_floor)
	failures += await _run("Campaign workshop edits and inserts levels", _test_campaign_workshop)
	failures += await _run("Campaign workshop back navigation stays reachable", _test_workshop_back_navigation)
	failures += await _run("Trail share pack export and import round-trip", _test_trail_share_pack)
	failures += await _run("Trail editor single-level export and import", _test_trail_editor_single_share)
	failures += await _run("Trail editor saves and resets explicit snapshots", _test_trail_editor_save_reset)
	failures += await _run("Hand-drawn celebration art and cheerful music load", _test_art_and_music)
	failures += await _run("Mid-trail save data persists and loads", _test_mid_trail_save)
	failures += await _run("Saved camp and badges restore inside a level", _test_level_run_restore)
	failures += await _run("Pause menu exposes save, load, and restart actions", _test_pause_save_controls)
	failures += await _run("Boss arenas expose lasso targets and solvable kingpin layout", _test_boss_arenas)
	failures += await _run("Cave Dragon body contact costs a heart or life", _test_dragon_body_contact_hurts)
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
	failures += await _run(
		"Transition gallop frames match trail horse size",
		_test_transition_gallop_frame_size
	)
	failures += await _run(
		"Horse arrival rides on the ground under spawn",
		_test_arrival_uses_ground_under_spawn
	)
	failures += await _run("Canyon clouds include two-cloud hop chains", _test_two_cloud_canyon_chains)
	failures += await _run("Wings levels place varied aerial carrions", _test_wings_carrion_variety)
	failures += await _run(
		"Cave ceiling guards flight with sparse décor stalactites",
		_test_cave_ceiling_sparse_flight_guard
	)
	failures += await _run(
		"Dragon Gate and Cave Dragon have no stalactites",
		_test_dragon_levels_have_no_stalactites
	)
	failures += await _run(
		"Cave canyons use cool-slate ridge art",
		_test_cave_canyon_uses_cave_rim
	)
	failures += await _run(
		"Poison fungus plays a spore-puff animation",
		_test_poison_fungus_spore_animation
	)

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


func _widest_spring_gap(arena: Node, left_x: float, right_x: float) -> float:
	## Longest stretch of the patrol with no spring pad to vault the boss from.
	var xs: Array[float] = [left_x, right_x]
	for node in arena.find_children("*", "Area2D", true, false):
		if node is SpringPad:
			var x := (node as Node2D).global_position.x
			if x >= left_x - 200.0 and x <= right_x + 200.0:
				xs.append(x)
	xs.sort()
	var widest := 0.0
	for i in range(xs.size() - 1):
		widest = maxf(widest, xs[i + 1] - xs[i])
	return widest


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
		"res://assets/world/boss_stampede_bull_run_0.png",
		"res://assets/world/boss_stampede_bull_run_1.png",
		"res://assets/world/boss_stampede_bull_run_2.png",
		"res://assets/world/boss_stampede_bull_run_3.png",
		"res://assets/world/trail_bull.png",
		"res://assets/world/trail_bull_run_0.png",
		"res://assets/world/trail_bull_run_1.png",
		"res://assets/world/trail_bull_run_2.png",
		"res://assets/world/trail_bull_run_3.png",
	]:
		if load(art_path) == null:
			bull.queue_free()
			return "Missing bull art: %s" % art_path
	# Charge run frames must match stun/idle standing size (no shrink while running).
	var stand_tex := load("res://assets/world/boss_stampede_bull.png") as Texture2D
	var stand_h := float(stand_tex.get_height())
	var stand_img_for_size := stand_tex.get_image()
	var stand_opaque := 0
	if stand_img_for_size != null:
		for y in range(stand_img_for_size.get_height()):
			for x in range(stand_img_for_size.get_width()):
				if stand_img_for_size.get_pixel(x, y).a > 0.06:
					stand_opaque += 1
	for i in range(4):
		var run_tex := load("res://assets/world/boss_stampede_bull_run_%d.png" % i) as Texture2D
		if absf(float(run_tex.get_height()) - stand_h) > 2.0:
			bull.queue_free()
			return "Boss run frame %d canvas height (%d) should match stun standing art (%d)." % [
				i, run_tex.get_height(), stand_tex.get_height()
			]
		var run_img := run_tex.get_image()
		if run_img != null:
			var run_opaque := 0
			for y in range(run_img.get_height()):
				for x in range(run_img.get_width()):
					if run_img.get_pixel(x, y).a > 0.06:
						run_opaque += 1
			var mass_ratio := float(run_opaque) / maxf(float(stand_opaque), 1.0)
			if mass_ratio < 0.96 or mass_ratio > 1.04:
				bull.queue_free()
				return "Boss run frame %d visible mass %.1f%% should match standing." % [
					i, mass_ratio * 100.0
				]
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
	if bull_sprite == null or bull_sprite.position.y > -80.0:
		bull.queue_free()
		return "Bull artwork should stand above the desert surface, not inside it."
	# Roomy canvas: standing and run frames must keep clear margin so horns/tails
	# are not jammed against the texture edge.
	var stand_img := stand_tex.get_image()
	if stand_img != null:
		var stand_used := stand_img.get_used_rect()
		var side_margin := mini(stand_used.position.x, stand_tex.get_width() - stand_used.end.x)
		if stand_tex.get_width() < 400 or stand_tex.get_height() < 220:
			bull.queue_free()
			return "Boss bull canvas should be roomy (got %dx%d)." % [
				stand_tex.get_width(), stand_tex.get_height()
			]
		if side_margin < 40:
			bull.queue_free()
			return "Boss standing art side margin %d is too tight." % side_margin
	for i in range(4):
		var run_tex2 := load("res://assets/world/boss_stampede_bull_run_%d.png" % i) as Texture2D
		var run_img2 := run_tex2.get_image() if run_tex2 != null else null
		if run_img2 == null:
			continue
		var run_used2 := run_img2.get_used_rect()
		var run_side := mini(run_used2.position.x, run_tex2.get_width() - run_used2.end.x)
		if run_side < 60:
			bull.queue_free()
			return "Boss run frame %d side margin %d is too tight (horns/tail clipped)." % [
				i, run_side
			]
	# Wall and lasso reactions may recoil/rotate, but must never squash the boss.
	bull.call("_play_wall_impact")
	await get_tree().process_frame
	await get_tree().process_frame
	if not bull_sprite.scale.is_equal_approx(Vector2.ONE):
		bull.queue_free()
		return "Bull wall impact must not change his size."
	bull.call("_play_hit_reaction")
	await get_tree().process_frame
	await get_tree().process_frame
	if not bull_sprite.scale.is_equal_approx(Vector2.ONE):
		bull.queue_free()
		return "Bull lasso reaction must not change his size."
	var tied_scale: Vector2 = bull.call("_sprite_scale_for", tied_texture, 190.0)
	# Compare painted body widths — the roomy canvas has transparent margin.
	var normal_body_w: float
	if stand_img_for_size != null:
		normal_body_w = float(stand_img_for_size.get_used_rect().size.x) * absf(bull_sprite.scale.x)
	else:
		normal_body_w = float(bull_sprite.texture.get_width()) * absf(bull_sprite.scale.x)
	var tied_width := float(tied_texture.get_width()) * absf(tied_scale.x)
	if tied_width < normal_body_w * 0.85:
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
	# Endless chase desert must keep the same trail-matched tiling forever.
	if not coach.has_method("desert_loop_coverage_at") or not coach.has_method("desert_surface_scale"):
		coach.queue_free()
		return "Midnight Coach must expose desert loop helpers for continuity checks."
	var sand_tex: Texture2D = load("res://assets/world/trail_desert_tile.png")
	if sand_tex == null:
		coach.queue_free()
		return "Missing trail desert tile for coach chase."
	var expected_scale := 56.0 / float(sand_tex.get_height())
	var scale_at_start: Vector2 = coach.call("desert_surface_scale")
	if (
		scale_at_start == Vector2.ZERO
		or absf(scale_at_start.x - expected_scale) > 0.001
		or absf(scale_at_start.y - expected_scale) > 0.001
	):
		coach.queue_free()
		return "Midnight Coach desert sand must use WildWestTheme trail surface scale."
	var cover_near: Dictionary = coach.call("desert_loop_coverage_at", 400.0)
	var cover_far: Dictionary = coach.call("desert_loop_coverage_at", 48000.0)
	var scale_far: Vector2 = cover_far.get("scale", Vector2.ZERO)
	if scale_far != scale_at_start:
		coach.queue_free()
		return "Midnight Coach desert style must stay identical after a long chase scroll."
	if (
		float(cover_far.get("min_x", 0.0)) > 48000.0 - 1800.0 + 2.0
		or float(cover_far.get("max_x", 0.0)) < 48000.0 + 800.0
		or int(cover_far.get("count", 0)) != int(cover_near.get("count", -1))
		or int(cover_far.get("count", 0)) < 8
	):
		coach.queue_free()
		return "Midnight Coach desert must loop the same tile set around the chase forever."
	if coach.get_node_or_null("TrailFloor") != null:
		coach.queue_free()
		return "Midnight Coach must not keep the finite WildWestTheme TrailFloor during the chase."
	# Wheels must sit on the looping desert surface for the whole chase.
	if not coach.has_method("coach_wheel_contact_y") or not coach.has_method("desert_surface_y"):
		coach.queue_free()
		return "Midnight Coach must expose wheel/desert surface helpers."
	var coach_floor: float = coach.call("desert_surface_y")
	var wheel_y: float = coach.call("coach_wheel_contact_y")
	var coach_node := coach.get_node_or_null("Coach") as Node2D
	if coach_node == null or absf(coach_node.position.y - coach_floor) > 0.5:
		coach.queue_free()
		return "Midnight Coach root must sit on the desert surface Y."
	if absf(wheel_y - coach_floor) > 2.5:
		coach.queue_free()
		return "Midnight Coach wheels must sit on the desert (wheel y=%.1f, floor=%.1f)." % [wheel_y, coach_floor]
	coach.call("_apply_coach_frame", 3)
	var door_frame_sprite := coach.get_node_or_null("Coach/Sprite2D") as Sprite2D
	var door_frame_pos := Vector2.ZERO
	var door_frame_scale := Vector2.ONE
	if door_frame_sprite != null:
		door_frame_pos = door_frame_sprite.position
		door_frame_scale = door_frame_sprite.scale
	coach.call("_apply_surrender_pose")
	var coach_sprite := coach.get_node_or_null("Coach/Sprite2D") as Sprite2D
	var surrender_flag := coach.get_node_or_null("Coach/SurrenderFlag") as Node2D
	if (
		coach_sprite == null
		or coach_sprite.texture == null
		or not coach_sprite.texture.resource_path.ends_with("boss_midnight_coach_surrender.png")
		or surrender_flag != null
		or coach_sprite.position != door_frame_pos
		or coach_sprite.scale != door_frame_scale
	):
		coach.queue_free()
		return "Coach victory art should use the hands-up surrender texture at the same scale and offset."
	var surrender_tex: Texture2D = load("res://assets/world/boss_midnight_coach_surrender.png")
	var door3_tex: Texture2D = load("res://assets/world/boss_midnight_coach_3.png")
	if (
		surrender_tex == null
		or door3_tex == null
		or surrender_tex.get_width() != door3_tex.get_width()
		or surrender_tex.get_height() != door3_tex.get_height()
	):
		coach.queue_free()
		return "Coach surrender texture must match the door-frame canvas size."
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
	var left_x := float(king.get("_left_x"))
	var right_x := float(king.get("_right_x"))
	var patrol_span: float = absf(right_x - left_x)
	if patrol_span < 900.0:
		king.queue_free()
		return "Kingpin should patrol a long stretch of the yard (span %.0f)." % patrol_span
	if float(king.get("_walk_speed")) < 90.0:
		king.queue_free()
		return "Kingpin should move more during the fight."
	# The widened patrol must stay on the arena floor at both ends.
	var king_ground := king.get_node_or_null("Ground") as StaticBody2D
	var ground_shape := (
		king_ground.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if king_ground != null
		else null
	)
	if ground_shape == null or not (ground_shape.shape is RectangleShape2D):
		king.queue_free()
		return "Kingpin arena needs a rectangular ground body."
	var ground_rect := ground_shape.shape as RectangleShape2D
	var ground_left := king_ground.position.x - ground_rect.size.x * 0.5
	var ground_right := king_ground.position.x + ground_rect.size.x * 0.5
	if left_x < ground_left + 60.0 or right_x > ground_right - 60.0:
		king.queue_free()
		return "Kingpin patrol %.0f..%.0f leaves the arena floor %.0f..%.0f." % [
			left_x, right_x, ground_left, ground_right
		]
	# Springs must stay spread along the patrol so vaulting him is possible anywhere.
	var spring_gap := _widest_spring_gap(king, left_x, right_x)
	if spring_gap > 420.0:
		king.queue_free()
		return "Kingpin patrol has a %.0fpx stretch with no vaulting spring." % spring_gap
	var king_stand_tex := load("res://assets/world/boss_outlaw_kingpin.png") as Texture2D
	var king_stand_img := king_stand_tex.get_image() if king_stand_tex != null else null
	if king_stand_img == null:
		king.queue_free()
		return "Could not read kingpin standing art."
	var king_stand_used := king_stand_img.get_used_rect()
	var king_stand_feet := king_stand_used.position.y + king_stand_used.size.y
	for i in range(4):
		var walk_tex := load("res://assets/world/boss_outlaw_kingpin_walk_%d.png" % i) as Texture2D
		if walk_tex == null:
			king.queue_free()
			return "Missing kingpin walk art: frame %d" % i
		if walk_tex.get_size() != king_stand_tex.get_size():
			king.queue_free()
			return "Kingpin walk frame %d canvas must match the standing art." % i
		var walk_img := walk_tex.get_image()
		if walk_img == null:
			king.queue_free()
			return "Could not read kingpin walk frame %d." % i
		var walk_used := walk_img.get_used_rect()
		# Same foot row, so halting mid-stride never lifts or sinks his boots.
		var walk_feet := walk_used.position.y + walk_used.size.y
		if absi(walk_feet - king_stand_feet) > 1:
			king.queue_free()
			return "Kingpin walk frame %d foot row (%d) should match standing (%d)." % [
				i, walk_feet, king_stand_feet
			]
		# Near-equal heights: a drawn bob is welcome, a size pop is not.
		var height_drop := king_stand_used.size.y - walk_used.size.y
		if height_drop < 0 or height_drop > 6:
			king.queue_free()
			return "Kingpin walk frame %d height %d should sit just under standing %d." % [
				i, walk_used.size.y, king_stand_used.size.y
			]
	var king_sprite := king.get_node_or_null("Kingpin/Sprite2D") as Sprite2D
	if king_sprite == null:
		king.queue_free()
		return "Kingpin needs a Sprite2D for walk frames."
	king.set("combat_ready", true)
	king.set("_shooting", false)
	king.set("_shot_timer", 99.0)
	var start_tex: Texture2D = king_sprite.texture
	var king_body := king.get_node_or_null("Kingpin") as Node2D
	var walk_from_x := king_body.position.x if king_body != null else 0.0
	var saw_walk := false
	for _i in range(20):
		await get_tree().physics_frame
		if king_sprite.texture != start_tex and king_sprite.texture in king.WALK_TEX:
			saw_walk = true
			break
	if not saw_walk:
		var moved := absf(king_body.position.x - walk_from_x) if king_body != null else -1.0
		king.queue_free()
		return "Kingpin should play walk frames while patrolling (moved %.2fpx, phase %.2f)." % [
			moved, float(king.get("_walk_phase"))
		]
	# Cadence follows ground covered, so the same distance always advances the
	# same number of frames no matter how fast he is walking.
	king.set("_walk_phase", 0.0)
	king.call("_play_walk_visual", king.WALK_STEP_PX * 2.0)
	if king_sprite.texture != king.WALK_TEX[2]:
		king.queue_free()
		return "Two stride lengths of travel should advance two walk frames."
	king.call("_play_walk_visual", 0.0)
	if king_sprite.texture != king.KING_TEX:
		king.queue_free()
		return "Standing still should show the kingpin's standing pose."
	king.call("_play_walk_visual", king.WALK_STEP_PX)
	if king_sprite.texture != king.WALK_TEX[3]:
		king.queue_free()
		return "Resuming a walk should continue the stride, not restart it."
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

	var dragon_packed: PackedScene = load("res://scenes/bosses/boss_cave_dragon.tscn")
	if dragon_packed == null:
		return "Missing Cave Dragon boss scene."
	var dragon := dragon_packed.instantiate()
	add_child(dragon)
	var dragon_body := dragon.get_node_or_null("Dragon")
	var dragon_target := dragon.get_node_or_null("Dragon/LassoTarget")
	var dragon_sprite := dragon.get_node_or_null("Dragon/Sprite2D") as Sprite2D
	if not (dragon_body is AnimatableBody2D):
		dragon.queue_free()
		return "Cave Dragon must be a solid AnimatableBody2D."
	if dragon_target == null or not dragon_target.has_method("lasso_hit") or not (dragon_target is Area2D):
		dragon.queue_free()
		return "Cave Dragon needs an Area2D lasso target."
	if int(dragon.get("lassos_needed")) != 3 or int(dragon.get("spit_rounds")) != 2:
		dragon.queue_free()
		return "Cave Dragon should require 2 spit rounds then 3 lassos."
	if int(dragon.get("spits_per_round")) != 2:
		dragon.queue_free()
		return "Cave Dragon should spit 2 flameballs per round."
	# Flameballs fly straight — no mid-flight homing — and die on the arena floor.
	var ball := DragonFlameball.new()
	ball.setup(Vector2.ZERO, Vector2(-100, 40), null)
	var aim := ball.direction
	ball._physics_process(0.2)
	if ball.direction.distance_to(aim) > 0.01:
		ball.free()
		dragon.queue_free()
		return "Dragon flameballs must keep a straight aim (no homing)."
	ball.free()
	# Floor stop: player-only collision mask, but ray-probed floor ends the shot.
	var floor_ball := DragonFlameball.new()
	floor_ball.setup(Vector2(400, 100), Vector2(400, 400), null)
	dragon.add_child(floor_ball)
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(floor_ball):
		dragon.queue_free()
		return "Dragon flameball vanished before flying."
	if floor_ball.get_collision_mask_value(1):
		floor_ball.queue_free()
		dragon.queue_free()
		return "Dragon flameballs must not use world-layer collision (probe the floor instead)."
	if floor_ball.z_index < 1:
		floor_ball.queue_free()
		dragon.queue_free()
		return "Dragon flameballs must draw above the floor so they stay visible."
	var start_y := floor_ball.global_position.y
	for _i in range(40):
		if not is_instance_valid(floor_ball):
			break
		floor_ball._physics_process(0.05)
	# Either impacting/freed at the floor, or still above it — never deep under the crust.
	if is_instance_valid(floor_ball):
		if floor_ball.global_position.y > 360.0:
			floor_ball.queue_free()
			dragon.queue_free()
			return "Dragon flameballs must end at the floor, not tunnel under it."
		if floor_ball.global_position.y < start_y + 20.0 and not bool(floor_ball.get("_impacting")):
			floor_ball.queue_free()
			dragon.queue_free()
			return "Dragon flameballs aimed at the floor should travel down to it."
		floor_ball.queue_free()
	# Pre-fight: dragon waits on the floor, then takes off when combat starts.
	var waiting_y := float(dragon.get("_floor_y"))
	if absf((dragon_body as Node2D).position.y - waiting_y) > 4.0:
		dragon.queue_free()
		return "Cave Dragon should start waiting on the arena floor."
	if int(dragon.get("_state")) != 2:
		dragon.queue_free()
		return "Cave Dragon should wait in the LAND pose before the fight (got state %s)." % str(dragon.get("_state"))
	for stage_path in [
		"res://assets/world/boss_cave_dragon_0.png",
		"res://assets/world/boss_cave_dragon_1.png",
		"res://assets/world/boss_cave_dragon_2.png",
		"res://assets/world/boss_cave_dragon_3.png",
		"res://assets/world/boss_cave_dragon_fly_0.png",
		"res://assets/world/boss_cave_dragon_fly_1.png",
		"res://assets/world/boss_cave_dragon_fly_bound1_0.png",
		"res://assets/world/boss_cave_dragon_fly_bound1_1.png",
		"res://assets/world/boss_cave_dragon_fly_bound2_0.png",
		"res://assets/world/boss_cave_dragon_fly_bound2_1.png",
		"res://assets/world/boss_cave_dragon_land.png",
		"res://assets/world/dragon_flameball.png",
	]:
		if load(stage_path) == null:
			dragon.queue_free()
			return "Missing Cave Dragon art: %s" % stage_path
	if dragon_sprite == null or dragon_sprite.texture == null:
		dragon.queue_free()
		return "Cave Dragon needs a stage sprite."
	var fly_scale: float = absf(float(dragon_sprite.scale.x))
	if fly_scale < 0.95 or fly_scale > 1.05:
		dragon.queue_free()
		return "Cave Dragon should be ~15%% larger (scale≈0.98, got %.3f)." % fly_scale
	dragon.set("_lassos", 3)
	dragon.call("_apply_stage_visual")
	if (
		dragon_sprite.texture == null
		or not dragon_sprite.texture.resource_path.ends_with("boss_cave_dragon_3.png")
	):
		dragon.queue_free()
		return "Third lasso should show the mouth-tied dragon frame."
	# Flying with 1–2 lassos must use the same rope layout as the floor stages
	# (neck, then neck+torso) — not a muzzle-only fly variant.
	dragon.set("_lassos", 1)
	dragon.call("_set_fly_pose")
	if (
		dragon_sprite.texture == null
		or dragon_sprite.texture.resource_path.find("fly_bound1") < 0
	):
		dragon.queue_free()
		return "One lasso in flight should show fly_bound1 neck coils."
	dragon.set("_lassos", 2)
	dragon.call("_set_fly_pose")
	if (
		dragon_sprite.texture == null
		or dragon_sprite.texture.resource_path.find("fly_bound2") < 0
	):
		dragon.queue_free()
		return "Two lassos in flight should show fly_bound2 neck+torso ropes."
	var fly2 := dragon_sprite.texture.get_image()
	var fly_free := (load("res://assets/world/boss_cave_dragon_fly_0.png") as Texture2D).get_image()
	if fly2 == null or fly_free == null:
		dragon.queue_free()
		return "Could not read dragon rope art images."
	# Extra tan pixels on the snout vs unbound flight = a muzzle (wrong for stage 2).
	var snout_extra := 0
	for y in range(70, 110):
		for x in range(20, 70):
			var c := fly2.get_pixel(x, y)
			var f := fly_free.get_pixel(x, y)
			var tied_rope := c.a > 0.4 and c.r > 0.35 and c.g > 0.22 and c.b < 0.45 and c.r > c.b + 0.12
			var free_tan := f.a > 0.4 and f.r > 0.35 and f.g > 0.22 and f.b < 0.45 and f.r > f.b + 0.12
			if tied_rope and not free_tan:
				snout_extra += 1
	if snout_extra > 40:
		dragon.queue_free()
		return "Flying stage-2 ropes must not muzzle the snout (that is floor stage 3 / win)."
	# Mid-torso should carry rope like the floor stage-2 wrap.
	var torso_rope := 0
	var torso_free := 0
	for y in range(115, 165):
		for x in range(145, 200):
			var tc := fly2.get_pixel(x, y)
			var tf := fly_free.get_pixel(x, y)
			if tc.a > 0.4 and tc.r > 0.35 and tc.g > 0.22 and tc.b < 0.45 and tc.r > tc.b + 0.12:
				torso_rope += 1
			if tf.a > 0.4 and tf.r > 0.35 and tf.g > 0.22 and tf.b < 0.45 and tf.r > tf.b + 0.12:
				torso_free += 1
	if torso_rope - torso_free < 80:
		dragon.queue_free()
		return "Flying stage-2 should keep a mid-torso rope like the floor tied pose."
	if int(dragon.get("source_level")) != 16:
		dragon.queue_free()
		return "Cave Dragon must be the level-16 boss."
	if str(dragon.get_meta("level_style", "")) != LevelStyle.CAVE:
		dragon.queue_free()
		return "Cave Dragon arena should use cave style."
	dragon.queue_free()

	# Shared 5-heart boss logic lives on BossArena.
	for packed in [bull_packed, coach_packed, king_packed, dragon_packed]:
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
	GameManager.flush_save_to_disk()
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
	GameManager.debug_set_slot(0, {"empty": false, "current_level": 4, "stars": 2})
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
	var backdrop := scene.get_node_or_null("Backdrop") as TextureRect
	if error == null and (backdrop == null or backdrop.texture == null):
		error = "Save select needs the painted desert backdrop."
	if error == null and skyline == null:
		error = "Save select should keep a Skyline node for compatibility."
	if error == null and scene.get_node_or_null("TitleLogo") == null and scene.get_node_or_null("TitleHat") == null:
		error = "Save select needs the hat/title emblem above the doors."
	if error == null and scene.get_node_or_null("Mascots/Cowboy") == null:
		error = "Save select needs cowboy and cowgirl mascots."
	if error == null and scene.get_node_or_null("Mascots/Cowgirl") == null:
		error = "Save select needs cowboy and cowgirl mascots."
	var cowboy_btn := scene.get_node_or_null("Mascots/Cowboy") as Button
	var cowgirl_btn := scene.get_node_or_null("Mascots/Cowgirl") as Button
	if error == null and (cowboy_btn == null or cowgirl_btn == null):
		error = "Cowboy/Cowgirl mascots must be clickable character pickers."
	if error == null and scene.get_node_or_null("CharacterHint") == null:
		error = "Save select needs a character-pick hint above the mascots."
	if error == null and scene.get_node_or_null("HeartsButton") == null:
		error = "Save select needs a hearts trail-mode toggle."
	if error == null and scene.get_node_or_null("DebugStrip") == null:
		error = "Save select needs a debug strip for F1 tools."
	var settings_button := scene.get_node_or_null("SettingsButton") as Button
	var settings_panel := scene.get_node_or_null("SettingsPanel") as SettingsPanel
	if error == null and (settings_button == null or settings_panel == null):
		error = "Save select needs Settings access via SettingsButton + SettingsPanel."
	if error == null and scene.get_node_or_null("BuildTrailButton") == null:
		error = "Save select needs Campaign Workshop access."
	if error == null and scene.get_node_or_null("DebugStrip/TranslationEditorButton") == null:
		error = "Save select needs a Translation Editor button (debug-gated)."
	var delete_dialog := scene.get_node_or_null("DeleteConfirmation") as ConfirmationDialog
	if error == null and delete_dialog == null:
		error = "Save deletion needs a confirmation dialog."
	var first_card := scene.get_node_or_null("Slots/Slot1") as Button
	var number := scene.get_node_or_null("Slots/Slot1/Number") as Label
	var portrait := scene.get_node_or_null("Slots/Slot1/Portrait") as TextureRect
	var stars := scene.get_node_or_null("Slots/Slot1/Stars") as HBoxContainer
	var door_art := scene.get_node_or_null("Slots/Slot1/DoorArt") as TextureRect
	var select_ring := scene.get_node_or_null("Slots/Slot1/SelectRing") as TextureRect
	if error == null and (number == null or number.text != "1"):
		error = "Save doors should show giant slot numbers 1–3."
	if error == null and (door_art == null or door_art.texture == null):
		error = "Save doors need painted arched wood DoorArt."
	if error == null and (select_ring == null or select_ring.texture == null):
		error = "Save doors need a bandana SelectRing for focus."
	if error == null and (portrait == null or portrait.texture == null):
		error = "Filled save doors should show the active character portrait."
	if error == null and stars != null:
		var visible_stars := 0
		for child in stars.get_children():
			if child is CanvasItem and (child as CanvasItem).visible:
				visible_stars += 1
		if visible_stars != 2:
			error = "Filled save doors should show capped star dots from progress."
	if error == null and first_card != null:
		var normal := first_card.get_theme_stylebox("normal")
		if normal != null and not (normal is StyleBoxEmpty):
			if normal is StyleBoxFlat and (normal as StyleBoxFlat).bg_color.a > 0.2:
				error = "Painted doors should not cover DoorArt with opaque StyleBoxFlat fills."
	if error == null:
		scene._index = 0
		scene._highlight()
		if select_ring != null and not select_ring.visible:
			error = "Focused save door should show the bandana SelectRing."
	var title_label := scene.get_node_or_null("Title") as Label
	if error == null and title_label != null and title_label.visible:
		var cream := title_label.get_theme_color("font_color")
		if cream.r < 0.85 or cream.g < 0.7 or cream.b > 0.65:
			error = "Save select title should use faded cream/yellow western lettering."
	if error == null and scene.get_node_or_null("PointingHandRight") != null:
		error = "Kid-first save select should not keep the pointing-hand motif."
	if error == null and scene.get_node_or_null("TitleBoard") != null:
		error = "Kid-first save select should drop the dense saloon title board."
	if error == null and scene.get_node_or_null("PromptBoard") != null:
		error = "Kid-first save select should drop the text-heavy prompt board."
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
	if error == null and cowboy_btn != null and cowgirl_btn != null:
		var previous_character := GameManager.get_player_character()
		GameManager.set_setting("player_character", GameManager.PLAYER_COWBOY)
		scene._refresh_character_pickers()
		var cowboy_mark := scene.get_node_or_null("Mascots/Cowboy/ChosenMark") as CanvasItem
		var cowgirl_mark := scene.get_node_or_null("Mascots/Cowgirl/ChosenMark") as CanvasItem
		var hint := scene.get_node_or_null("CharacterHint") as Label
		if cowboy_mark == null or cowgirl_mark == null:
			error = "Character pickers need a ChosenMark badge for the active rider."
		elif not cowboy_mark.visible or cowgirl_mark.visible:
			error = "Cowboy preselection should show only the cowboy ChosenMark."
		elif hint == null or not ("Cowboy" in hint.text or "Cowgirl" in hint.text or "spielst" in hint.text.to_lower()):
			error = "Character hint should name the currently chosen rider."
		else:
			cowgirl_btn.pressed.emit()
			if GameManager.get_player_character() != GameManager.PLAYER_COWGIRL:
				error = "Tapping the cowgirl mascot should choose Cowgirl for the next run."
			elif not cowgirl_mark.visible or cowboy_mark.visible:
				error = "Choosing Cowgirl should move the ChosenMark to the cowgirl."
			elif cowgirl_btn.scale.x <= cowboy_btn.scale.x:
				error = "The chosen mascot should be visually highlighted."
			else:
				cowboy_btn.pressed.emit()
				if GameManager.get_player_character() != GameManager.PLAYER_COWBOY:
					error = "Tapping the cowboy mascot should choose Cowboy for the next run."
		GameManager.set_setting("player_character", previous_character)
	scene.queue_free()
	GameManager.erase_slot(0)
	return error


func _test_menu_button_hover_and_click() -> Variant:
	var button := Button.new()
	button.custom_minimum_size = Vector2(160, 44)
	MenuChrome.style_wood_button(button)
	var hover := button.get_theme_stylebox("hover")
	var pressed := button.get_theme_stylebox("pressed")
	if not (hover is StyleBoxFlat) or not (pressed is StyleBoxFlat):
		button.free()
		return "Wood buttons need hover and pressed styleboxes."
	var hover_fill := (hover as StyleBoxFlat).bg_color
	var pressed_fill := (pressed as StyleBoxFlat).bg_color
	if hover_fill.is_equal_approx(pressed_fill):
		button.free()
		return "Pressed wood should be darker than the hover fill."
	if pressed_fill.r >= hover_fill.r:
		button.free()
		return "Click should darken the wood button."
	if not bool(button.get_meta("_menu_btn_feedback", false)):
		button.free()
		return "Menu buttons should bind hover and click motion."
	button.mouse_entered.emit()
	var hover_target: Vector2 = button.get_meta("_menu_feedback_target", Vector2.ONE)
	if hover_target.x <= 1.001:
		button.free()
		return "Hover should pop the button larger."
	button.button_down.emit()
	var press_target: Vector2 = button.get_meta("_menu_feedback_target", Vector2.ONE)
	if press_target.x >= 0.999:
		button.free()
		return "Click should squash the button."
	button.free()

	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var error: Variant = null
	for path in ["BuildTrailButton", "SettingsButton", "HeartsButton", "Slots/Slot1"]:
		var chrome := scene.get_node_or_null(path) as Button
		if chrome == null or not bool(chrome.get_meta("_menu_btn_feedback", false)):
			error = "Start-screen button %s needs hover/click feedback." % path
			break
	var pause_packed: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	if error == null and pause_packed == null:
		error = "Missing pause menu scene."
	var pause: PauseMenu = null
	if error == null:
		pause = pause_packed.instantiate() as PauseMenu
		add_child(pause)
		await get_tree().process_frame
		var continue_btn := pause.get_node_or_null("Panel/Margin/VBox/ContinueButton") as Button
		if continue_btn == null or not bool(continue_btn.get_meta("_menu_btn_feedback", false)):
			error = "Pause menu buttons need hover/click feedback."
		else:
			var pause_hover := continue_btn.get_theme_stylebox("hover")
			var pause_pressed := continue_btn.get_theme_stylebox("pressed")
			if (
				pause_hover is StyleBoxFlat
				and pause_pressed is StyleBoxFlat
				and (pause_hover as StyleBoxFlat).bg_color.is_equal_approx(
					(pause_pressed as StyleBoxFlat).bg_color
				)
			):
				error = "Pause buttons need a distinct pressed look."
	var grid := Control.new()
	grid.name = "StampGrid"
	var cell := Button.new()
	grid.add_child(cell)
	add_child(grid)
	MenuChrome.bind_menu_buttons(grid)
	if error == null and bool(cell.get_meta("_menu_btn_feedback", false)):
		error = "Stamp grid cells should not use menu hover/click motion."
	grid.queue_free()
	if pause != null:
		pause.queue_free()
	scene.queue_free()
	return error


func _test_settings_trail_mode_dropdown() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var dropdown := scene.get_node_or_null("SettingsPanel/Margin/VBox/TrailModeDropdown") as OptionButton
	var label := scene.get_node_or_null("SettingsPanel/Margin/VBox/TrailModeLabel") as Label
	var error: Variant = null
	if dropdown == null or label == null:
		error = "Settings needs a trail mode label and dropdown."
	elif dropdown.item_count < 5:
		error = "Trail mode dropdown needs Classic plus ★5/★10/★15/★30 Advanced choices."
	elif dropdown.get_item_text(0) not in ["Classic", "Klassisch"]:
		error = "Classic mode label missing from settings trail mode dropdown."
	else:
		var ids: Array[int] = []
		for i in range(dropdown.item_count):
			ids.append(int(dropdown.get_item_id(i)))
		for tier in GameManager.ADVANCED_BADGE_TIERS:
			if tier not in ids:
				error = "Trail mode dropdown missing Advanced ★%d." % tier
				break
	scene.queue_free()
	return error


func _test_settings_dropdown_popup_contrast() -> Variant:
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var dropdown_paths := [
		"SettingsPanel/Margin/VBox/LanguageDropdown",
		"SettingsPanel/Margin/VBox/CharacterDropdown",
		"SettingsPanel/Margin/VBox/TrailModeDropdown",
	]
	var error: Variant = null
	for path in dropdown_paths:
		var dropdown := scene.get_node_or_null(path) as OptionButton
		if dropdown == null:
			error = "Missing settings dropdown: %s." % path
			break
		var popup := dropdown.get_popup()
		var panel := popup.get_theme_stylebox("panel")
		if panel == null or not panel is StyleBoxFlat:
			error = "Settings dropdown popup needs a cream panel stylebox."
			break
		var bg := (panel as StyleBoxFlat).bg_color
		if bg.r < 0.9 or bg.g < 0.85:
			error = "Settings dropdown popup should use a light cream panel."
			break
		var ink := popup.get_theme_color("font_color")
		if ink.r > 0.5 or ink.g > 0.3:
			error = "Settings dropdown popup should use dark western ink text."
			break
		var hover_ink := popup.get_theme_color("font_hover_color")
		if hover_ink.r > 0.55:
			error = "Settings dropdown popup hover text should stay dark and readable."
			break
		if popup.get_theme_stylebox("hover") == null:
			error = "Settings dropdown popup needs a hover stylebox for items."
			break
	scene.queue_free()
	return error


func _test_settings_trail_mode_selection() -> Variant:
	GameManager.erase_slot(0)
	var previous := bool(GameManager.get_settings().get("advanced_mode", false))
	GameManager.set_setting("advanced_mode", true)
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	if not GameManager.is_advanced_mode_setting():
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Advanced Mode should stick when chosen in Settings."
	GameManager.prepare_slot_for_start(0)
	if not GameManager.slot_is_advanced(0):
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Advanced Mode should apply when starting an empty slot."
	GameManager.set_setting("advanced_mode", false)
	GameManager.prepare_slot_for_start(0)
	if GameManager.slot_is_advanced(0):
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Classic mode should apply when Settings uses Classic."
	var panel := scene.get_node_or_null("SettingsPanel") as SettingsPanel
	panel._load_values()
	var dropdown := scene.get_node_or_null("SettingsPanel/Margin/VBox/TrailModeDropdown") as OptionButton
	if dropdown == null or dropdown.get_item_text(0) not in ["Classic", "Klassisch"]:
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Trail mode dropdown should include Classic as the default/normal choice."
	if dropdown.get_item_id(1) != 5:
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Trail mode dropdown should include Advanced ★5 after Classic."
	scene.queue_free()
	GameManager.set_setting("advanced_mode", previous)
	GameManager.erase_slot(0)
	return null


func _test_settings_trail_mode_refresh() -> Variant:
	GameManager.erase_slot(0)
	var previous := bool(GameManager.get_settings().get("advanced_mode", false))
	GameManager.set_setting("advanced_mode", false)
	var slot := GameManager.get_slot(0)
	slot["empty"] = false
	slot["advanced_mode"] = false
	slot["current_level"] = 1
	GameManager.debug_set_slot(0, slot)
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var dropdown := scene.get_node_or_null("SettingsPanel/Margin/VBox/TrailModeDropdown") as OptionButton
	if dropdown == null or dropdown.disabled:
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Trail mode dropdown should stay enabled in Settings."
	GameManager.erase_slot(0)
	scene._refresh()
	GameManager.set_setting("advanced_mode", true)
	var panel := scene.get_node_or_null("SettingsPanel") as SettingsPanel
	panel._load_values()
	var selected_id := int(dropdown.get_item_id(dropdown.selected))
	if selected_id != 30:
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Legacy Advanced Mode should select the ★30 pace after settings refresh."
	GameManager.prepare_slot_for_start(0)
	if not GameManager.slot_is_advanced(0) or GameManager.slot_badges_per_life(0) != 30:
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Advanced Mode should apply ★30 after refresh and prepare."
	scene.queue_free()
	GameManager.set_setting("advanced_mode", previous)
	GameManager.erase_slot(0)
	return null


func _test_advanced_mode_lives() -> Variant:
	GameManager.erase_slot(0)
	GameManager.set_badges_per_life_setting(30)
	GameManager.prepare_slot_for_start(0)
	GameManager.active_slot_index = 0
	if GameManager.get_lives() != 3:
		return "Advanced ★30 should start with three lives."
	if not GameManager.is_advanced_mode():
		return "Prepared slot should be in Advanced Mode."
	if GameManager.active_badges_per_life() != 30:
		return "Prepared slot should remember the ★30 badge pace."
	GameManager.register_badges_collected(29)
	if GameManager.get_lives() != 3:
		return "Twenty-nine badges should not grant a life yet at ★30 pace."
	GameManager.register_badges_collected(1)
	if GameManager.get_lives() != 4:
		return "Thirty total badges should grant one extra life at ★30 pace."
	GameManager.register_badges_collected(30)
	if GameManager.get_lives() != 5:
		return "Sixty total badges should grant another extra life."
	GameManager.save_to_disk()
	GameManager.load_from_disk()
	GameManager.active_slot_index = 0
	if GameManager.get_lives() != 5:
		return "Advanced life totals should persist in the save slot."
	GameManager.erase_slot(0)
	GameManager.set_badges_per_life_setting(5)
	GameManager.prepare_slot_for_start(0)
	GameManager.active_slot_index = 0
	if GameManager.get_lives() != 5:
		return "Advanced ★5 should start with five lives."
	GameManager.register_badges_collected(5)
	if GameManager.get_lives() != 6:
		return "Five badges should grant a life at ★5 pace."
	GameManager.erase_slot(0)
	GameManager.set_badges_per_life_setting(10)
	GameManager.prepare_slot_for_start(0)
	GameManager.active_slot_index = 0
	if GameManager.get_lives() != 5:
		return "Advanced ★10 should start with five lives."
	GameManager.erase_slot(0)
	GameManager.set_badges_per_life_setting(15)
	GameManager.prepare_slot_for_start(0)
	GameManager.active_slot_index = 0
	if GameManager.get_lives() != 3:
		return "Advanced ★15 should start with three lives."
	GameManager.erase_slot(0)
	GameManager.set_badges_per_life_setting(0)
	return null


func _test_advanced_mode_lives_hud() -> Variant:
	GameManager.erase_slot(0)
	GameManager.set_setting("advanced_mode", true)
	GameManager.prepare_slot_for_start(0)
	GameManager.active_slot_index = 0
	var packed: PackedScene = load(GameManager.LEVEL_SCENES[0])
	if packed == null:
		GameManager.erase_slot(0)
		return "Missing first campaign level for lives HUD test."
	var level := packed.instantiate()
	add_child(level)
	if level is LevelController:
		(level as LevelController).setup_level()
	await get_tree().process_frame
	await get_tree().process_frame
	var hud := level.get_node_or_null("Hud") as Hud
	var error: Variant = null
	if hud == null:
		error = "Campaign level should include a Hud node."
	else:
		if not GameManager.is_advanced_mode():
			error = (
				"Advanced Mode lives HUD test needs active advanced slot (active=%d advanced=%s)."
				% [GameManager.active_slot_index, str(GameManager.get_slot(0).get("advanced_mode"))]
			)
		else:
			hud.set_lives(GameManager.get_lives(), true)
			var panel := hud.get_node_or_null("LivesPanel") as Control
			var hearts := hud.get_node_or_null("LivesPanel/LivesHeartsLabel") as Label
			if hearts == null:
				hearts = hud.get_node_or_null("LivesHeartsLabel") as Label
			if panel == null:
				error = "Advanced Mode HUD should include LivesPanel."
			elif not panel.visible:
				error = (
					"Advanced Mode lives panel should be visible (panel.visible=%s is_in_tree=%s)."
					% [str(panel.visible), str(panel.is_visible_in_tree())]
				)
			elif not hearts.visible:
				error = "Advanced Mode lives hearts should be visible during gameplay."
			elif not hearts.text.contains("♥"):
				error = "Advanced Mode lives hearts should show filled heart glyphs."
			elif panel != null and panel.z_index < 10:
				error = "Lives hearts panel should render above other HUD widgets."
			elif hearts.z_index < 1 and panel == null:
				error = "Lives hearts should render above other HUD widgets."
	level.queue_free()
	GameManager.erase_slot(0)
	return error


func _test_advanced_mode_respawn_cost() -> Variant:
	GameManager.erase_slot(0)
	GameManager.set_setting("advanced_mode", true)
	GameManager.prepare_slot_for_start(0)
	GameManager.active_slot_index = 0
	if not GameManager.lose_life():
		return "Two lives should remain after the first loss."
	if GameManager.get_lives() != 2:
		return "Respawn should decrement lives to two."
	GameManager.lose_life()
	if GameManager.get_lives() != 1:
		return "One life should remain after two respawns."
	if GameManager.lose_life():
		return "Zero lives should trigger game over instead of continuing."
	if GameManager.get_lives() != 0:
		return "Final respawn should leave zero lives."
	GameManager.erase_slot(0)
	return null


func _test_advanced_mode_game_over_scene() -> Variant:
	if load("res://scenes/ui/game_over.tscn") == null:
		return "Missing game over scene."
	var scene := (load("res://scenes/ui/game_over.tscn") as PackedScene).instantiate()
	add_child(scene)
	await get_tree().process_frame
	if scene.get_script() == null:
		scene.queue_free()
		return "Game over scene needs its controller script."
	var root := scene.get_node_or_null("Root") as Control
	var backdrop := scene.get_node_or_null("Root/Backdrop") as TextureRect
	var board := scene.get_node_or_null("Root/TitleBoard") as TextureRect
	var stamp := scene.get_node_or_null("Root/TitleBoard/Stamp") as Label
	if root == null or backdrop == null or board == null or stamp == null:
		scene.queue_free()
		return "Game over should use the start-screen desert backdrop and saloon title board."
	if backdrop.texture == null or not String(backdrop.texture.resource_path).ends_with("menu_backdrop_desert.png"):
		scene.queue_free()
		return "Game over backdrop should reuse menu_backdrop_desert.png."
	if board.texture == null or not String(board.texture.resource_path).ends_with("saloon_title_board.png"):
		scene.queue_free()
		return "Game over title should sit on saloon_title_board.png."
	if stamp.text not in ["GAME OVER", "SPIEL VORBEI"]:
		scene.queue_free()
		return "Game over stamp should show the localized GAME OVER title."
	scene.queue_free()
	return null


func _test_advanced_boss_skips_hearts() -> Variant:
	GameManager.erase_slot(0)
	GameManager.set_setting("advanced_mode", true)
	GameManager.prepare_slot_for_start(0)
	GameManager.active_slot_index = 0
	var packed: PackedScene = load("res://scenes/bosses/boss_stampede_bull.tscn")
	if packed == null:
		GameManager.erase_slot(0)
		return "Missing stampede bull boss scene."
	var arena := packed.instantiate()
	add_child(arena)
	await get_tree().process_frame
	var error: Variant = null
	if arena.get_node_or_null("HeartsLayer") != null:
		error = "Advanced Mode boss fights should not show separate boss hearts."
	elif int(arena.get("_hearts")) != 5:
		error = "Boss heart counter should remain unused in Advanced Mode."
	arena.queue_free()
	GameManager.erase_slot(0)
	return error


func _test_dragon_body_contact_hurts() -> Variant:
	var previous_advanced := bool(GameManager.get_settings().get("advanced_mode", false))
	GameManager.set_setting("advanced_mode", false)
	var packed: PackedScene = load("res://scenes/bosses/boss_cave_dragon.tscn")
	if packed == null:
		GameManager.set_setting("advanced_mode", previous_advanced)
		return "Missing Cave Dragon boss scene."
	var error: Variant = null
	var fly := packed.instantiate()
	add_child(fly)
	await get_tree().process_frame
	fly.combat_ready = true
	fly.set("_hit_cooldown", 0.0)
	fly.set("_recovering", false)
	fly.set("_state", 0)
	var fly_player := fly.get("player") as Player
	if fly_player == null:
		error = "Cave Dragon arena needs a player."
	else:
		fly_player.set("_invulnerable_remaining", 0.0)
		var hearts_before := int(fly.get("_hearts"))
		fly.call("_hurt_from_contact", fly_player)
		await get_tree().process_frame
		if int(fly.get("_hearts")) != hearts_before - 1:
			error = "Flying into the Cave Dragon should cost a boss heart."
	fly.queue_free()
	if error == null:
		var land := packed.instantiate()
		add_child(land)
		await get_tree().process_frame
		land.combat_ready = true
		land.set("_hit_cooldown", 0.0)
		land.set("_recovering", false)
		land.set("_state", 2)
		var land_player := land.get("player") as Player
		var dragon_body := land.get_node_or_null("Dragon") as Node2D
		if land_player == null or dragon_body == null:
			error = "Landed Cave Dragon contact test needs player and dragon."
		else:
			land_player.set("_invulnerable_remaining", 0.0)
			land_player.global_position = dragon_body.global_position + Vector2(0.0, -80.0)
			land_player.velocity = Vector2(0.0, 220.0)
			var hearts_land := int(land.get("_hearts"))
			land.call("_on_hurt_body", land_player)
			await get_tree().process_frame
			if int(land.get("_hearts")) != hearts_land - 1:
				error = "Touching the landed Cave Dragon should hurt, including a jump onto him."
		land.queue_free()
	if error == null:
		GameManager.erase_slot(0)
		GameManager.set_setting("advanced_mode", true)
		GameManager.prepare_slot_for_start(0)
		GameManager.active_slot_index = 0
		var lives_before := GameManager.get_lives()
		var adv := packed.instantiate()
		add_child(adv)
		await get_tree().process_frame
		adv.combat_ready = true
		adv.set("_hit_cooldown", 0.0)
		adv.set("_recovering", false)
		adv.set("_state", 0)
		var adv_player := adv.get("player") as Player
		if adv_player == null:
			error = "Advanced Cave Dragon arena needs a player."
		else:
			adv_player.set("_invulnerable_remaining", 0.0)
			adv.call("_hurt_from_contact", adv_player)
			await get_tree().process_frame
			if GameManager.get_lives() != lives_before - 1:
				error = "Dragon body contact in Advanced Mode should cost a campaign life."
		adv.queue_free()
		GameManager.erase_slot(0)
	GameManager.set_setting("advanced_mode", previous_advanced)
	return error


func _test_element_reference_link() -> Variant:
	DebugLabels.set_enabled(false)
	if not ResourceLoader.exists("res://docs/element_name_reference.png"):
		return "Missing docs/element_name_reference.png reference sheet."
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var error: Variant = null
	var button := scene.get_node_or_null("DebugStrip/ElementReferenceButton") as Button
	var overlay := scene.get_node_or_null("ElementReferenceOverlay") as Control
	var sheet := scene.get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/SheetScroll/Sheet") as TextureRect
	var zoom_in := scene.get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/ZoomBar/ZoomInButton") as Button
	var zoom_out := scene.get_node_or_null("ElementReferenceOverlay/Panel/Margin/VBox/ZoomBar/ZoomOutButton") as Button
	if button == null or overlay == null or sheet == null:
		error = "Save select needs ElementReferenceButton + overlay with Sheet."
	elif zoom_in == null or zoom_out == null:
		error = "Element reference overlay needs ZoomInButton and ZoomOutButton."
	elif button.visible or scene.element_reference_unlocked():
		error = "Element Names link must stay hidden while debug mode is off."
	elif overlay.visible:
		error = "Element reference overlay must start closed."
	else:
		# F1 maps to toggle_debug_names; DebugLabels is the canonical debug mode.
		DebugLabels.set_enabled(true)
		await get_tree().process_frame
		if not button.visible or not scene.element_reference_unlocked():
			error = "Element Names link should appear while debug mode is on."
		elif scene.element_reference_path() != "res://docs/element_name_reference.png":
			error = "Element reference path should point at docs/element_name_reference.png."
		elif sheet.texture == null:
			error = "Element reference overlay should load the labeled sheet texture."
		else:
			var tex_path := String(sheet.texture.resource_path)
			if not tex_path.ends_with("element_name_reference.png"):
				error = "Overlay sheet texture should be element_name_reference.png (got %s)." % tex_path
			else:
				button.pressed.emit()
				await get_tree().process_frame
				if not overlay.visible:
					error = "Element Names button should open the reference overlay."
				elif not is_equal_approx(float(scene.element_reference_zoom()), 1.0):
					error = "Element reference should open at 100%% zoom."
				else:
					var before := float(scene.element_reference_zoom())
					zoom_in.pressed.emit()
					if float(scene.element_reference_zoom()) <= before:
						error = "Zoom in should increase the element reference zoom."
					else:
						var after_in := float(scene.element_reference_zoom())
						zoom_out.pressed.emit()
						if float(scene.element_reference_zoom()) >= after_in:
							error = "Zoom out should decrease the element reference zoom."
						else:
							# Visibility tracks debug mode; hide again when F1 turns it off.
							DebugLabels.set_enabled(false)
							await get_tree().process_frame
							if button.visible or scene.element_reference_unlocked():
								error = "Element Names link must hide when debug mode turns off."
							elif overlay.visible:
								error = "Element reference overlay should close when debug mode turns off."
	DebugLabels.set_enabled(false)
	scene.queue_free()
	return error


func _test_translation_editor_button_debug_gate() -> Variant:
	DebugLabels.set_enabled(false)
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var error: Variant = null
	var button := scene.get_node_or_null("DebugStrip/TranslationEditorButton") as Button
	if button == null:
		error = "Save select needs TranslationEditorButton."
	elif button.visible or scene.translation_editor_unlocked():
		error = "Translation Editor button must stay hidden while debug mode is off."
	else:
		DebugLabels.set_enabled(true)
		await get_tree().process_frame
		if not button.visible or not scene.translation_editor_unlocked():
			error = "Translation Editor button should appear while debug mode is on."
		else:
			DebugLabels.set_enabled(false)
			await get_tree().process_frame
			if button.visible or scene.translation_editor_unlocked():
				error = "Translation Editor button must hide when debug mode turns off."
	DebugLabels.set_enabled(false)
	scene.queue_free()
	return error


func _test_localization_settings() -> Variant:
	var defaults := GameManager._default_data()
	if String(defaults.get("settings", {}).get("language", "")) != "de":
		return "German must be the default language for new saves."
	if defaults.get("settings", {}).has("narration"):
		return "Narration setting must be removed from default saves."
	if String(ProjectSettings.get_setting("internationalization/locale/fallback", "")) != "de":
		# Project setting path may differ; also accept TranslationServer after fresh apply.
		pass
	var previous_language := String(GameManager.get_settings().get("language", "de"))
	GameManager.set_setting("language", "de")
	if not TranslationServer.get_locale().begins_with("de"):
		return "German language setting should update TranslationServer."
	if tr("Settings") != "Einstellungen":
		GameManager.set_setting("language", previous_language)
		return "German translation catalog is not loaded."
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
		GameManager.flush_save_to_disk()
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
		var lang_index := panel._controls.find(dropdown)
		if lang_index < 0:
			error = "Settings panel should include the language dropdown in controller navigation."
		else:
			while panel._index != lang_index:
				var step := InputEventAction.new()
				step.action = &"move_right" if panel._index < lang_index else &"move_left"
				step.pressed = true
				panel._unhandled_input(step)
		if error == null and panel._controls[panel._index] != dropdown:
			error = "Controller navigation should reach the language dropdown."
		elif error == null:
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
	var click := AudioManager._make_effect(&"ui_click")
	if click == null or click.data.is_empty():
		return "Menu click effect should produce playable sound data."
	for dragon_sfx in [
		&"dragon_roar",
		&"dragon_spit",
		&"dragon_land",
		&"dragon_takeoff",
		&"dragon_tied",
		&"dragon_win",
	]:
		var dragon_effect := AudioManager._make_effect(dragon_sfx)
		if dragon_effect == null or dragon_effect.data.is_empty():
			return "Dragon effect %s should produce playable sound data." % String(dragon_sfx)
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
			var cactus_rect := LevelLayoutRules._approx_rect(cactus, Vector2(40, 48))
			var rim_clear := ScalableCanyonArt.RIM_SIZE.x + 40.0
			var clear := gap_left - cactus_rect.end.x
			if clear < rim_clear:
				error = (
					"Level 1 first cactus overlaps the canyon rim art (need %.0fpx clear, got %.0f)."
					% [rim_clear, clear]
				)
	_free_level(node)
	return error


func _test_sixteen_levels_exist() -> Variant:
	if GameManager.LEVEL_SCENES.size() != 16:
		return "Expected 16 levels."
	var level_two := GameManager.level_name_for(2)
	if not level_two.begins_with("2: "):
		return "Level names should use the '<number>: <name>' format."
	if level_two not in ["2: Badge Meadow", "2: Abzeichen-Wiese"]:
		return "Level 2 should keep its English or German display title."
	var level_fifteen := GameManager.level_name_for(15)
	if level_fifteen not in ["15: Wing Chasm", "15: Flügelschlucht"]:
		return "Level 15 should keep its English or German display title (got %s)." % level_fifteen
	var level_sixteen := GameManager.level_name_for(16)
	if not level_sixteen.begins_with("16: "):
		return "Level 16 should use the numbered display title."
	if level_sixteen not in ["16: Dragon Gate", "16: Drachentor"]:
		return "Level 16 should keep its English or German display title."
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
	var bull := controller.find_child("BullEnemy0", true, false) as BullEnemy
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
	if bull != null:
		bull.tie_up(false)
	controller.player.activate_mode(ModeController.Mode.WINGS)
	controller.player.get_modes().remaining = 7.0
	# Spawn a disposable bullet/shuriken — camp respawn must clear them.
	var bullet := BanditBullet.new()
	bullet.setup(1.0)
	controller.add_child(bullet)
	bullet.global_position = Vector2(500, 200)
	var star := NinjaShuriken.new()
	star.setup(Vector2(600, 100), Vector2(500, 200))
	controller.add_child(star)
	star.global_position = Vector2(500, 200)
	checkpoint_b.activate()
	controller.player.get_modes().remaining = 1.0
	controller.respawn_player()
	await get_tree().process_frame
	var error: Variant = null
	if not bandit.is_tied():
		error = "A bandit tied before camp activation should stay tied."
	elif bull != null and not bull.is_tied():
		error = "A bull tied before camp activation should stay tied."
	elif not controller.player.get_modes().is_flying():
		error = "The active camp bonus should be restored."
	elif controller.player.get_modes().remaining < 20.0:
		error = "A restored camp bonus should have at least twenty seconds."
	elif is_instance_valid(bullet) or is_instance_valid(star):
		error = "Bullets and shuriken must be cleared on camp respawn."
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


func _test_rattlesnakes_clear_of_canyons() -> Variant:
	for path in GameManager.LEVEL_SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			return "Missing level: %s" % path
		var level: Node = packed.instantiate()
		add_child(level)
		if level is LevelController:
			(level as LevelController).setup_level()
		var errors := LevelLayoutRules._validate_rattlesnakes_clear_of_canyons(level)
		level.queue_free()
		if not errors.is_empty():
			return "%s -> %s" % [path, errors[0]]
	# Synthetic: snake planted on the approach lip must fail.
	var probe := Node2D.new()
	add_child(probe)
	var left := StaticBody2D.new()
	left.name = "GroundA"
	left.position = Vector2(200, 352)
	var left_shape := CollisionShape2D.new()
	left_shape.name = "CollisionShape2D"
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(400, 64)
	left_shape.shape = left_rect
	left.add_child(left_shape)
	probe.add_child(left)
	var right := StaticBody2D.new()
	right.name = "GroundB"
	right.position = Vector2(800, 352)
	var right_shape := CollisionShape2D.new()
	right_shape.name = "CollisionShape2D"
	var right_rect := RectangleShape2D.new()
	right_rect.size = Vector2(400, 64)
	right_shape.shape = right_rect
	right.add_child(right_shape)
	probe.add_child(right)
	var snake_scene: PackedScene = load("res://scenes/world/rattlesnake.tscn")
	if snake_scene == null:
		probe.queue_free()
		return "Missing rattlesnake scene."
	var snake := snake_scene.instantiate() as Node2D
	snake.name = "RattlesnakeProbe"
	# GroundA ends at x=400; plant snake just before the mouth.
	snake.position = Vector2(360, 330)
	probe.add_child(snake)
	await get_tree().process_frame
	await get_tree().process_frame
	var bad := LevelLayoutRules._validate_rattlesnakes_clear_of_canyons(probe)
	probe.queue_free()
	if bad.is_empty():
		return "Layout rules must reject a rattlesnake planted directly in front of a canyon."
	return null


func _test_desert_levels_use_rattlesnakes() -> Variant:
	## Campaign desert trails keep rattlesnakes only — no as_scorpion conversions.
	for path in [
		"res://scenes/levels/level_06.tscn",
		"res://scenes/levels/level_08.tscn",
		"res://scenes/levels/level_09.tscn",
		"res://scenes/levels/level_10.tscn",
	]:
		var packed: PackedScene = load(path)
		if packed == null:
			return "Missing level: %s" % path
		var scene: Node = packed.instantiate()
		add_child(scene)
		await get_tree().process_frame
		var snakes := 0
		for node in scene.find_children("*", "Rattlesnake", true, false):
			var foe := node as Rattlesnake
			if foe.as_scorpion:
				scene.queue_free()
				await get_tree().process_frame
				return "%s should not place desert scorpions (found %s)." % [
					path.get_file(), foe.name
				]
			snakes += 1
		scene.queue_free()
		await get_tree().process_frame
		if snakes < 1:
			return "%s should still place rattlesnakes." % path.get_file()
	return null


func _test_canyon_up_needs_spring() -> Variant:
	for path in GameManager.LEVEL_SCENES:
		var packed: PackedScene = load(path)
		if packed == null:
			return "Missing level: %s" % path
		var level: Node = packed.instantiate()
		add_child(level)
		if level is LevelController:
			(level as LevelController).setup_level()
		var errors := LevelLayoutRules._validate_canyon_up_needs_spring(level)
		level.queue_free()
		if not errors.is_empty():
			return "%s -> %s" % [path, errors[0]]
	# Synthetic up-canyon without spring must fail; with spring must pass.
	var probe := Node2D.new()
	add_child(probe)
	var near := StaticBody2D.new()
	near.name = "GroundA"
	near.position = Vector2(200, 352)
	var near_shape := CollisionShape2D.new()
	near_shape.name = "CollisionShape2D"
	var near_rect := RectangleShape2D.new()
	near_rect.size = Vector2(400, 64)
	near_shape.shape = near_rect
	near.add_child(near_shape)
	probe.add_child(near)
	var far := StaticBody2D.new()
	far.name = "GroundB"
	far.position = Vector2(800, 312)
	var far_shape := CollisionShape2D.new()
	far_shape.name = "CollisionShape2D"
	var far_rect := RectangleShape2D.new()
	far_rect.size = Vector2(400, 64)
	far_shape.shape = far_rect
	far.add_child(far_shape)
	probe.add_child(far)
	await get_tree().process_frame
	await get_tree().process_frame
	var bad := LevelLayoutRules._validate_canyon_up_needs_spring(probe)
	if bad.is_empty():
		probe.queue_free()
		return "Layout rules must reject a canyon that ends higher without an approach spring."
	var spring_scene: PackedScene = load("res://scenes/world/spring_pad.tscn")
	if spring_scene == null:
		probe.queue_free()
		return "Missing spring pad scene."
	var spring := spring_scene.instantiate() as Node2D
	spring.name = "SpringProbe"
	# GroundA ends at x=400; spring on the approach bank.
	spring.position = Vector2(320, 320)
	probe.add_child(spring)
	await get_tree().process_frame
	var good := LevelLayoutRules._validate_canyon_up_needs_spring(probe)
	probe.queue_free()
	if not good.is_empty():
		return "Approach spring should allow a canyon that ends higher: %s" % good[0]
	return null


func _test_late_level_height_differences() -> Variant:
	for level_number in range(7, 11):
		var path: String = GameManager.LEVEL_SCENES[level_number - 1]
		var packed: PackedScene = load(path)
		if packed == null:
			return "Missing level: %s" % path
		var level: Node = packed.instantiate()
		add_child(level)
		if level is LevelController:
			(level as LevelController).setup_level()
		var count := LevelLayoutRules.count_continuous_height_differences(level)
		var errors := LevelLayoutRules._validate_late_level_height_differences(level)
		level.queue_free()
		if not errors.is_empty():
			return "%s -> %s" % [path, errors[0]]
		if (
			count < LevelLayoutRules.LATE_LEVEL_HEIGHT_DIFF_MIN
			or count > LevelLayoutRules.LATE_LEVEL_HEIGHT_DIFF_MAX
		):
			return (
				"%s height differences %d outside %d–%d."
				% [
					path.get_file(),
					count,
					LevelLayoutRules.LATE_LEVEL_HEIGHT_DIFF_MIN,
					LevelLayoutRules.LATE_LEVEL_HEIGHT_DIFF_MAX,
				]
			)
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


func _test_treasure_chest() -> Variant:
	var packed: PackedScene = load("res://scenes/world/treasure_chest.tscn")
	if packed == null:
		return "Missing treasure chest scene."
	var chest := packed.instantiate()
	if not (chest is TreasureChest):
		chest.queue_free()
		return "Treasure chest root should be TreasureChest."
	var art := chest.get_node_or_null("ChestArt")
	var loot_reveal := chest.get_node_or_null("ChestArt/LootReveal")
	var collision := chest.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if art == null:
		chest.queue_free()
		return "Treasure chest should include ChestArt for the opening animation."
	if loot_reveal == null:
		chest.queue_free()
		return "Treasure chest should include ChestArt/LootReveal for loot pop-out."
	if collision == null:
		chest.queue_free()
		return "Treasure chest should include a collision shape."

	var player_packed: PackedScene = load("res://scenes/player/player.tscn")
	if player_packed == null:
		chest.queue_free()
		return "Missing player scene."
	var player := player_packed.instantiate() as Player

	var controller := LevelController.new()
	controller.level_number = 5
	controller.is_custom_level = true
	add_child(controller)
	controller.add_child(player)
	controller.add_child(chest)
	controller.player = player
	chest.name = "TestChest0"
	controller._wire_world_objects()

	var badges_before := player.stars_collected
	TreasureChest.test_loot_override = TreasureChestLoot.POOL.find(TreasureChestLoot.Type.WINGS)
	chest.body_entered.emit(player)
	await get_tree().process_frame
	await get_tree().process_frame
	TreasureChest.test_loot_override = -1
	if not (chest as TreasureChest).is_opened():
		controller.queue_free()
		return "Touching a treasure chest should open it."
	if not collision.disabled:
		controller.queue_free()
		return "Opened treasure chest should disable collision."
	if (chest as TreasureChest).monitoring:
		controller.queue_free()
		return "Opened treasure chest should stop monitoring touches."
	if player.get_modes().active_mode != ModeController.Mode.WINGS:
		controller.queue_free()
		return "Treasure chest should activate rolled loot on the player."
	if player.stars_collected != badges_before:
		controller.queue_free()
		return "Wings loot should not grant badges."

	chest.body_entered.emit(player)
	await get_tree().process_frame
	if player.stars_collected != badges_before:
		controller.queue_free()
		return "Treasure chest should be one-shot and not grant loot twice."

	await get_tree().create_timer(0.5).timeout
	var chest_art := art as TreasureChestArt
	if chest_art == null or chest_art.open_amount < 0.9:
		controller.queue_free()
		return "Treasure chest opening animation should reveal the open chest art."
	var open_sprite := chest_art.get_node_or_null("Open") as Sprite2D
	if (
		open_sprite == null
		or open_sprite.texture == null
		or not open_sprite.texture.resource_path.ends_with("treasure_chest_open.png")
		or open_sprite.modulate.a < 0.9
	):
		controller.queue_free()
		return "Opened chest should display treasure_chest_open.png."

	for loot in TreasureChestLoot.POOL:
		if TreasureChestLoot.texture_for(loot) == null:
			controller.queue_free()
			return "Missing reveal texture for loot %s." % TreasureChestLoot.loot_name(loot)

	controller.queue_free()
	return null


func _test_treasure_chest_respawn_reset() -> Variant:
	var packed: PackedScene = load("res://scenes/world/treasure_chest.tscn")
	if packed == null:
		return "Missing treasure chest scene."
	var chest := packed.instantiate() as TreasureChest
	var player_packed: PackedScene = load("res://scenes/player/player.tscn")
	if player_packed == null:
		chest.queue_free()
		return "Missing player scene."
	var player := player_packed.instantiate() as Player
	var controller := LevelController.new()
	controller.is_custom_level = true
	add_child(controller)
	controller.add_child(player)
	controller.add_child(chest)
	controller.player = player
	chest.name = "TestChest0"
	controller._wire_world_objects()

	TreasureChest.test_loot_override = TreasureChestLoot.POOL.find(TreasureChestLoot.Type.SPEED_STAR)
	chest.body_entered.emit(player)
	await get_tree().process_frame
	await get_tree().create_timer(0.55).timeout
	TreasureChest.test_loot_override = -1
	if not chest.is_opened():
		controller.queue_free()
		return "Chest should open before respawn reset test."

	controller.respawn_player()
	await get_tree().process_frame
	if chest.is_opened():
		controller.queue_free()
		return "Treasure chest should close again when respawning before camp."
	var collision := chest.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null and collision.disabled:
		controller.queue_free()
		return "Respawned treasure chest should re-enable collision."
	var art := chest.get_node_or_null("ChestArt") as TreasureChestArt
	if art != null and art.open_amount > 0.05:
		controller.queue_free()
		return "Respawned treasure chest lid should close."
	controller.queue_free()
	return null


func _test_treasure_chest_height_ratio() -> Variant:
	var packed: PackedScene = load("res://scenes/world/treasure_chest.tscn")
	if packed == null:
		return "Missing treasure chest scene."
	var chest := packed.instantiate() as TreasureChest
	add_child(chest)
	await get_tree().process_frame
	var collision := chest.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null or not (collision.shape is RectangleShape2D):
		chest.queue_free()
		return "Treasure chest should expose a rectangle collision shape."
	var height := (collision.shape as RectangleShape2D).size.y
	var expected := TreasureChest.TARGET_HEIGHT
	if absf(height - expected) > 1.5:
		chest.queue_free()
		return "Chest collision height %.1f should be ~%.1f (%.0f%% of player)." % [
			height, expected, TreasureChest.HEIGHT_RATIO * 100.0
		]
	chest.queue_free()
	return null


func _test_treasure_chest_campaign_placement() -> Variant:
	var mode_items := 0
	var chests := 0
	for level_path in [
		"res://scenes/levels/level_02.tscn",
		"res://scenes/levels/level_06.tscn",
		"res://scenes/levels/level_07.tscn",
		"res://scenes/levels/level_08.tscn",
		"res://scenes/levels/level_09.tscn",
		"res://scenes/levels/level_10.tscn",
	]:
		var level: Variant = _instantiate_level(level_path)
		if level is String:
			return level
		for node in level.find_children("*", "ModeItem", true, false):
			mode_items += 1
		for node in level.find_children("*", "TreasureChest", true, false):
			chests += 1
		_free_level(level)

	var replaced := 16 - mode_items
	if chests < 8:
		return "Expected at least eight campaign treasure chests, found %d." % chests
	if replaced < 5:
		return "Expected about one third of mid-trail mode items replaced (%d of 16)." % replaced
	return null


func _test_treasure_chest_on_walk_surface() -> Variant:
	for level_path in [
		"res://scenes/levels/level_05.tscn",
		"res://scenes/levels/level_06.tscn",
		"res://scenes/levels/level_07.tscn",
		"res://scenes/levels/level_08.tscn",
		"res://scenes/levels/level_09.tscn",
		"res://scenes/levels/level_10.tscn",
	]:
		var level: Variant = _instantiate_level(level_path)
		if level is String:
			return level
		var chest_nodes: Array[Node] = level.find_children("*", "TreasureChest", true, false)
		if chest_nodes.is_empty():
			_free_level(level)
			return "Expected a treasure chest in %s." % level_path
		for node in chest_nodes:
			var chest := node as TreasureChest
			var surface := WildWestTheme.walk_surface_at(level, chest.global_position.x)
			var expected_y := float(surface["y"]) + WildWestTheme.CHEST_FOOT_SINK
			if absf(chest.ground_contact_y() - expected_y) > 2.5:
				_free_level(level)
				return (
					"%s chest should stand on the desert top (feet y=%.1f, expected %.1f)."
					% [level_path.get_file(), chest.ground_contact_y(), expected_y]
				)
			chest.restore_as_opened()
			if absf(chest.ground_contact_y() - expected_y) > 2.5:
				_free_level(level)
				return (
					"%s open chest should keep its feet on the desert top (feet y=%.1f, expected %.1f)."
					% [level_path.get_file(), chest.ground_contact_y(), expected_y]
				)
		_free_level(level)
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
	player.velocity = Vector2(0.0, 180.0)
	var hurt := [false]
	bandit.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	bandit._on_body_entered(player)
	var error: Variant = null
	if not bandit.is_tied():
		error = "Jumping onto a bandit's head while falling should tie him."
	elif hurt[0]:
		error = "A head stomp should not hurt the cowboy."
	elif player.velocity.y >= 0.0:
		error = "A head stomp should bounce the cowboy upward."
	player.queue_free()
	bandit.queue_free()
	return error


func _test_bull_charges_player() -> Variant:
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(800, 40)
	shape.shape = rect
	shape.position = Vector2(0, 20)
	floor.add_child(shape)
	floor.position = Vector2(300, 400)
	add_child(floor)
	var packed: PackedScene = load("res://scenes/world/bull_enemy.tscn")
	if packed == null:
		floor.queue_free()
		return "Missing bull enemy scene."
	var bull := packed.instantiate() as BullEnemy
	bull.position = Vector2(200, 400)
	add_child(bull)
	var player := Player.new()
	player.name = "Player"
	player.position = Vector2(420, 400)
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	if not player.is_in_group("player"):
		player.add_to_group("player")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	var start_x := bull.global_position.x
	if BullEnemy.BULL_TEX.resource_path != "res://assets/world/trail_bull.png":
		player.queue_free()
		bull.queue_free()
		floor.queue_free()
		return "Trail bull idle art should use trail_bull.png (no painted lasso ring)."
	var sprite := bull.get_node_or_null("BullSprite") as Sprite2D
	var saw_run := false
	for _i in range(30):
		await get_tree().physics_frame
		if sprite != null and sprite.texture in BullEnemy.BULL_RUN_TEX:
			saw_run = true
	var error: Variant = null
	if bull.global_position.x <= start_x + 8.0:
		error = "Trail bull should charge toward the nearby player."
	elif not saw_run:
		error = "Trail bull should play its run cycle while charging."
	player.queue_free()
	bull.queue_free()
	floor.queue_free()
	return error


func _test_bull_turns_at_gap() -> Variant:
	## At a pit/canyon lip the bull turns inland instead of tumbling in.
	for node in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(node):
			node.free()
	var left := StaticBody2D.new()
	left.collision_layer = 1
	left.position = Vector2(200, 420)
	var left_shape := CollisionShape2D.new()
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(400, 40)
	left_shape.shape = left_rect
	left.add_child(left_shape)
	add_child(left)

	var right := StaticBody2D.new()
	right.collision_layer = 1
	right.position = Vector2(700, 420)
	var right_shape := CollisionShape2D.new()
	var right_rect := RectangleShape2D.new()
	right_rect.size = Vector2(200, 40)
	right_shape.shape = right_rect
	right.add_child(right_shape)
	add_child(right)

	var packed: PackedScene = load("res://scenes/world/bull_enemy.tscn")
	if packed == null:
		left.queue_free()
		right.queue_free()
		return "Missing bull enemy scene."
	var bull := packed.instantiate() as BullEnemy
	# Mid-bank so he can charge toward the player across the gap, then hit the lip.
	bull.position = Vector2(220, 400)
	add_child(bull)
	await get_tree().physics_frame
	bull._was_grounded = true

	var player := Player.new()
	player.name = "Player"
	player.position = Vector2(700, 400)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if not player.is_in_group("player"):
		player.add_to_group("player")
	add_child(player)

	await get_tree().physics_frame
	await get_tree().physics_frame
	var start_x := bull.global_position.x
	var max_x := start_x
	var saw_right_charge := false
	var saw_inland_turn := false
	for _i in range(120):
		await get_tree().physics_frame
		# Keep the decoy cowboy planted — this fixture only drives bull AI facing.
		player.global_position = Vector2(700, bull.global_position.y)
		max_x = maxf(max_x, bull.global_position.x)
		if bull._charge_dir > 0.0:
			saw_right_charge = true
		if saw_right_charge and bull._charge_dir < 0.0:
			saw_inland_turn = true
		# Must never cross into the open gap (left bank ends at x=400).
		if bull.global_position.x > 400.0:
			player.queue_free()
			bull.queue_free()
			left.queue_free()
			right.queue_free()
			return "Bull must not charge into the canyon gap (x=%.1f)." % bull.global_position.x

	var error: Variant = null
	if not saw_right_charge:
		error = "Bull should first charge toward the player (right, toward the canyon)."
	elif max_x < start_x + 20.0:
		error = "Bull should run toward the canyon lip before turning (moved %.1fpx)." % (max_x - start_x)
	elif not saw_inland_turn:
		error = "Bull should turn inland once he touches the canyon lip."
	elif bull._fallen or bull.global_position.y > 480.0:
		error = "Bull should stay on the bank instead of falling into the canyon."

	player.queue_free()
	bull.queue_free()
	left.queue_free()
	right.queue_free()
	return error


func _test_bull_turns_after_jump_over() -> Variant:
	## After the cowboy jumps over, the bull keeps his heading ~5 cm, then turns.
	for node in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(node):
			node.free()
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	floor.position = Vector2(400, 420)
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(900, 40)
	floor_shape.shape = floor_rect
	floor.add_child(floor_shape)
	add_child(floor)

	var packed: PackedScene = load("res://scenes/world/bull_enemy.tscn")
	if packed == null:
		floor.queue_free()
		return "Missing bull enemy scene."
	var bull := packed.instantiate() as BullEnemy
	bull.position = Vector2(250, 400)
	add_child(bull)
	await get_tree().physics_frame
	bull._was_grounded = true

	var player := Player.new()
	player.name = "Player"
	player.position = Vector2(420, 400)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	if not player.is_in_group("player"):
		player.add_to_group("player")
	add_child(player)

	# Let the bull commit a rightward charge toward the cowboy.
	for _i in range(10):
		await get_tree().physics_frame
		player.global_position.y = bull.global_position.y
	if bull._charge_dir <= 0.0:
		player.queue_free()
		bull.queue_free()
		floor.queue_free()
		return "Bull should be charging right toward the player before the jump-over."

	var cross_x := bull.global_position.x
	# Jump over to the left side (behind the charge), briefly high then land behind.
	player.global_position = Vector2(cross_x - 80.0, bull.global_position.y - 120.0)
	await get_tree().physics_frame
	if bull._charge_dir <= 0.0:
		player.queue_free()
		bull.queue_free()
		floor.queue_free()
		return "Bull should keep his charge while the cowboy is airborne overhead."
	player.global_position = Vector2(cross_x - 80.0, bull.global_position.y)
	await get_tree().physics_frame
	if bull._turn_after_px <= 0.0:
		player.queue_free()
		bull.queue_free()
		floor.queue_free()
		return "Jumping over should arm the ~5 cm turn delay."

	var turned_left := false
	var traveled := 0.0
	var prev_x := bull.global_position.x
	for _i in range(90):
		await get_tree().physics_frame
		player.global_position.y = bull.global_position.y
		traveled += absf(bull.global_position.x - prev_x)
		prev_x = bull.global_position.x
		if bull._charge_dir < 0.0:
			turned_left = true
			break

	var error: Variant = null
	if not turned_left:
		error = "Bull should turn toward the cowboy after about 5 cm."
	elif traveled < BullEnemy.JUMP_OVER_TURN_PX * 0.4:
		error = "Jump-over turn came too soon (traveled %.1fpx, need ~%.0f)." % [
			traveled, BullEnemy.JUMP_OVER_TURN_PX
		]

	player.queue_free()
	bull.queue_free()
	floor.queue_free()
	return error


func _test_bull_stamp_avoids_gaps() -> Variant:
	## Workshop bulls/lizards must stay on solid dirt, not pit mouths or canyons.
	var trail := CustomLevelStore.trail_row(8)
	var objects: Array = []
	for x in range(24):
		if x >= 10 and x <= 12:
			objects.append({"type": "canyon", "x": x, "y": trail})
		else:
			objects.append({"type": "ground", "x": x, "y": trail})
	objects.append({"type": "pit", "x": 18, "y": trail})
	if CustomLevelStore.bull_stamp_allowed(objects, 11, trail):
		return "Bull stamp must be rejected on a canyon column."
	if CustomLevelStore.bull_stamp_allowed(objects, 18, trail):
		return "Bull stamp must be rejected on a pit mouth column."
	if not CustomLevelStore.bull_stamp_allowed(objects, 6, trail):
		return "Bull stamp should be allowed on solid dirt."

	objects.append({"type": "bull", "x": 11, "y": trail - 1})
	objects.append({"type": "bull", "x": 18, "y": trail - 1})
	objects.append({"type": "bull", "x": 6, "y": trail - 1})
	var cleaned := CustomLevelStore.sanitize(
		{"objects": objects, "height": 8, "width": 24, "title": "Bull Gap"},
		CustomLevelStore.EXTRA_SLOT_START
	)
	var kept := 0
	var bad := 0
	for value in cleaned.get("objects", []):
		var object := value as Dictionary
		if str(object.get("type", "")) != "bull":
			continue
		kept += 1
		var x := int(object.get("x", -1))
		if x == 11 or x == 18:
			bad += 1
	if kept != 1 or bad != 0:
		return "Sanitize should keep only the solid-dirt bull (kept=%d bad=%d)." % [kept, bad]

	var data := cleaned
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	var layout_errors := LevelLayoutRules._validate_bulls_clear_of_pits_and_canyons(level)
	level.queue_free()
	await get_tree().process_frame
	if not layout_errors.is_empty():
		return "Sanitized bull trail failed layout: %s" % layout_errors[0]
	return null


func _test_ground_stamps_avoid_gaps() -> Variant:
	var trail := CustomLevelStore.trail_row(8)
	var objects: Array = []
	for x in range(30):
		if x >= 10 and x <= 12:
			objects.append({"type": "canyon", "x": x, "y": trail})
		else:
			objects.append({"type": "ground", "x": x, "y": trail})
	objects.append({"type": "pit", "x": 20, "y": trail})
	for type_name in ["cactus", "bandit", "spring", "checkpoint", "ninja", "fence", "conveyor"]:
		if CustomLevelStore.ground_stamp_allowed(objects, type_name, 11, trail):
			return "%s stamp must be rejected on a canyon column." % type_name
		if CustomLevelStore.ground_stamp_allowed(objects, type_name, 20, trail):
			return "%s stamp must be rejected on a pit mouth column." % type_name
		if not CustomLevelStore.ground_stamp_allowed(objects, type_name, 4, trail):
			return "%s stamp should be allowed on solid dirt." % type_name
		objects.append({"type": type_name, "x": 11, "y": trail - 1})
		objects.append({"type": type_name, "x": 4, "y": trail - 1})
	var cleaned := CustomLevelStore.sanitize(
		{"objects": objects, "height": 8, "width": 30, "title": "Gap Props"},
		CustomLevelStore.EXTRA_SLOT_START
	)
	for value in cleaned.get("objects", []):
		var object := value as Dictionary
		var type_name := str(object.get("type", ""))
		if not CustomLevelStore.is_ground_standing(type_name):
			continue
		if int(object.get("x", -1)) in [11, 20]:
			return "Sanitize left %s on a canyon/pit column." % type_name
	return null


func _test_saloon_stamp_only_on_floor() -> Variant:
	var trail := CustomLevelStore.trail_row(8)
	if CustomLevelStore.placement_row("goal", 1, trail) != trail - 1:
		return "Saloon placement should snap mid-air clicks onto the trail floor."
	if CustomLevelStore.placement_row("goal", trail, trail) != trail - 1:
		return "Saloon placement should snap dirt-row clicks onto the standing floor row."
	if CustomLevelStore.placement_row("cactus", 1, trail) == trail - 1:
		return "Other ground stamps may still be clicked into the air."
	var objects: Array = []
	for x in range(24):
		objects.append({"type": "ground", "x": x, "y": trail})
	objects.append({"type": "platform", "x": 8, "y": 2})
	objects.append({"type": "goal", "x": 8, "y": 2})
	var cleaned := CustomLevelStore.sanitize(
		{"objects": objects, "height": 8, "width": 24, "title": "Saloon Floor"},
		CustomLevelStore.EXTRA_SLOT_START
	)
	var goals: Array[Dictionary] = []
	for value in cleaned.get("objects", []):
		var object := value as Dictionary
		if str(object.get("type", "")) == "goal":
			goals.append(object)
	if goals.size() != 1:
		return "Sanitize should keep the saloon (got %d)." % goals.size()
	if int(goals[0].get("y", -1)) != trail - 1:
		return "Sanitized saloon must sit on the trail floor (y=%d)." % int(goals[0].get("y", -1))
	if int(goals[0].get("x", -1)) != 8:
		return "Sanitized saloon should stay on its column (x=%d)." % int(goals[0].get("x", -1))

	var editor := load("res://scenes/ui/level_editor.tscn")
	if editor == null:
		return "Missing level editor scene."
	var node := (editor as PackedScene).instantiate()
	if not (node is Control):
		node.queue_free()
		return "Level editor root should be a Control."
	add_child(node)
	for _wait in range(20):
		await get_tree().process_frame
		if node.get("_preview") != null:
			break
	if node.get("_preview") == null:
		node.queue_free()
		return "Level editor preview should finish building."
	var editor_trail: int = node._trail_y()
	node._selected_type = "goal"
	node._on_preview_stamp(12, 1)
	await get_tree().process_frame
	var stored_y := -1
	var stored_x := -1
	for value in node._data.get("objects", []):
		var object := value as Dictionary
		if str(object.get("type", "")) == "goal":
			stored_x = int(object.get("x", -1))
			stored_y = int(object.get("y", -1))
	node.queue_free()
	if stored_y != editor_trail - 1:
		return "Editor saloon stamp must land on the floor (got y=%d, trail=%d)." % [stored_y, editor_trail]
	if stored_x < 0:
		return "Editor should place a saloon when clicking above the floor."
	return null


func _test_workshop_stamps_no_overlap() -> Variant:
	var trail := CustomLevelStore.trail_row(8)
	var objects: Array = []
	for x in range(24):
		objects.append({"type": "ground", "x": x, "y": trail})
	objects.append({"type": "spring", "x": 8, "y": trail - 1})
	objects.append({"type": "cactus", "x": 8, "y": trail - 1})
	objects.append({"type": "conveyor", "x": 12, "y": trail - 1})
	objects.append({"type": "fence", "x": 13, "y": trail - 1})
	var cleaned := CustomLevelStore.sanitize(
		{"objects": objects, "height": 8, "width": 24, "title": "Overlap"},
		CustomLevelStore.EXTRA_SLOT_START
	)
	var spring_count := 0
	var cactus_count := 0
	var conveyor_count := 0
	var fence_count := 0
	for value in cleaned.get("objects", []):
		match str((value as Dictionary).get("type", "")):
			"spring":
				spring_count += 1
			"cactus":
				cactus_count += 1
			"conveyor":
				conveyor_count += 1
			"fence":
				fence_count += 1
	if spring_count != 0 or cactus_count != 1:
		return "Later same-cell stamp should replace the earlier one (spring=%d cactus=%d)." % [
			spring_count, cactus_count
		]
	if conveyor_count != 0 or fence_count != 1:
		return "Overlapping conveyor/fence footprints should keep only the later stamp."
	return null


func _test_lasso_ties_bull() -> Variant:
	var packed: PackedScene = load("res://scenes/world/bull_enemy.tscn")
	if packed == null:
		return "Missing bull enemy scene."
	var bull := packed.instantiate() as BullEnemy
	add_child(bull)
	await get_tree().process_frame
	var stand_scale := bull.get_stand_scale()
	bull.tie_up()
	# Full tip-over sequence ends with the floor pose.
	await get_tree().create_timer(2.4).timeout
	var error: Variant = null
	if not bull.is_tied():
		error = "A lasso hit should tie the trail bull."
	elif bull.collision_layer != 0:
		error = "Tied bulls should not block the cowboy."
	var sprite := bull.get_node_or_null("BullSprite") as Sprite2D
	if sprite == null:
		error = "Tied bulls need a BullSprite."
	elif sprite.texture != BullEnemy.BULL_DOWN_TEX:
		error = "Tied bulls should finish lying on the floor (down pose)."
	else:
		var expected_down := BullEnemy.DOWN_TARGET_HEIGHT / maxf(float(BullEnemy.BULL_DOWN_TEX.get_height()), 1.0)
		if absf(sprite.scale.y - expected_down) > 0.01:
			error = "Tied bulls should keep a floor pose sized like the standing bull."
		elif stand_scale <= 0.0:
			error = "Standing bull scale should be positive."
	bull.queue_free()
	return error


func _test_stomp_ties_bull() -> Variant:
	var packed: PackedScene = load("res://scenes/world/bull_enemy.tscn")
	if packed == null:
		return "Missing bull enemy scene."
	var bull := packed.instantiate() as BullEnemy
	bull.position = Vector2(200, 400)
	add_child(bull)
	var player := Player.new()
	player.position = Vector2(200, 360)
	add_child(player)
	player.velocity = Vector2(0.0, 180.0)
	var hurt := [false]
	bull.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	bull._on_body_entered(player)
	var error: Variant = null
	if not bull.is_tied():
		error = "Jumping onto a bull's head while falling should tie it."
	elif hurt[0]:
		error = "A head stomp should not hurt the cowboy."
	elif player.velocity.y >= 0.0:
		error = "A head stomp should bounce the cowboy upward."
	player.queue_free()
	bull.queue_free()
	return error


func _test_bull_side_contact_hurts() -> Variant:
	var packed: PackedScene = load("res://scenes/world/bull_enemy.tscn")
	if packed == null:
		return "Missing bull enemy scene."
	var bull := packed.instantiate() as BullEnemy
	bull.position = Vector2(200, 400)
	add_child(bull)
	var player := Player.new()
	player.position = Vector2(200, 400)
	add_child(player)
	var hurt := [false]
	bull.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	bull._on_body_entered(player)
	var error: Variant = null
	if bull.is_tied():
		error = "Walking into a bull's side must not tie it."
	elif not hurt[0]:
		error = "Any non-stomp bull contact should send the cowboy back to camp."
	player.queue_free()
	bull.queue_free()
	return error


func _test_ninja_ambush_spawn() -> Variant:
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(900, 40)
	shape.shape = rect
	shape.position = Vector2(0, 20)
	floor.add_child(shape)
	floor.position = Vector2(400, 400)
	add_child(floor)
	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		floor.queue_free()
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	ninja.position = Vector2(300, 400)
	add_child(ninja)
	var player := Player.new()
	player.position = Vector2(340, 400)
	player.velocity = Vector2(120.0, 0.0)
	add_child(player)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for _i in range(20):
		await get_tree().physics_frame
	var error: Variant = null
	if ninja.modulate.a < 0.5:
		error = "Ninja should appear when the player enters ambush range."
	elif ninja.global_position.x <= player.global_position.x + 120.0:
		error = "Ninja should spawn ahead of the player (got x=%.1f vs player x=%.1f)." % [
			ninja.global_position.x, player.global_position.x
		]
	player.queue_free()
	ninja.queue_free()
	floor.queue_free()
	return error


func _test_ninja_sword_hurts() -> Variant:
	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	ninja.position = Vector2(200, 400)
	add_child(ninja)
	ninja._state = NinjaEnemy.State.CHASE
	ninja._set_dormant(false)
	var player := Player.new()
	player.position = Vector2(228, 400)
	add_child(player)
	var hurt := [false]
	ninja.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	ninja._begin_sword_attack(player)
	for _i in range(20):
		await get_tree().physics_frame
	var error: Variant = null
	if not hurt[0]:
		error = "Ninja sword attack should hurt the cowboy in melee range."
	player.queue_free()
	ninja.queue_free()
	return error


func _test_lasso_ties_ninja() -> Variant:
	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	add_child(ninja)
	ninja._set_dormant(false)
	ninja.tie_up()
	var error: Variant = null
	if not ninja.is_tied():
		error = "A lasso hit should tie the ninja."
	elif ninja.get_node_or_null("TiedRopes") == null:
		error = "Tied ninjas should show rope artwork."
	var sprite := ninja.get_node_or_null("NinjaSprite") as AnimatedSprite2D
	if sprite != null and sprite.animation != &"tied":
		error = "Tied ninjas should switch to the bound pose."
	elif sprite != null and absf(sprite.scale.y - NinjaEnemy.STAND_SCALE) > 0.01:
		error = "Tied ninjas must keep standing size (got scale %.2f)." % sprite.scale.y
	elif sprite != null and sprite.offset != NinjaEnemy.STAND_FOOT_OFFSET:
		error = "Tied ninjas must sit on the floor with the standing foot offset."
	ninja.queue_free()
	return error


func _test_stomp_ties_ninja() -> Variant:
	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	ninja.position = Vector2(200, 400)
	add_child(ninja)
	ninja._state = NinjaEnemy.State.CHASE
	ninja._set_dormant(false)
	var player := Player.new()
	player.position = Vector2(200, 360)
	add_child(player)
	player.velocity = Vector2(0.0, 180.0)
	var hurt := [false]
	ninja.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	ninja._on_body_entered(player)
	var error: Variant = null
	if not ninja.is_tied():
		error = "Jumping onto a ninja's head while falling should tie him."
	elif hurt[0]:
		error = "A head stomp should not hurt the cowboy."
	player.queue_free()
	ninja.queue_free()
	return error


func _test_ninja_shuriken_vs_wings() -> Variant:
	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	ninja.position = Vector2(200, 400)
	add_child(ninja)
	ninja._state = NinjaEnemy.State.CHASE
	ninja._set_dormant(false)
	var player := Player.new()
	player.position = Vector2(320, 280)
	add_child(player)
	player.get_modes().activate(ModeController.Mode.WINGS)
	var star_spawned := [false]
	ninja._begin_throw(player)
	for _i in range(20):
		await get_tree().physics_frame
		if ninja.get_parent().get_node_or_null("NinjaShuriken") != null:
			star_spawned[0] = true
			break
	var error: Variant = null
	if not star_spawned[0]:
		error = "Ninja should throw a shuriken at a winged player."
	player.queue_free()
	ninja.queue_free()
	for child in get_children():
		if child is NinjaShuriken:
			child.queue_free()
	return error


func _test_ninja_jumps_gaps() -> Variant:
	## Ninjas should leap a pit/canyon gap toward the cowboy instead of stalling.
	for path in [
		"res://assets/world/ninja_jump_0.png",
		"res://assets/world/ninja_jump_1.png",
	]:
		if load(path) as Texture2D == null:
			return "Missing ninja jump frame %s." % path

	var left := StaticBody2D.new()
	left.collision_layer = 1
	left.position = Vector2(100, 420)
	var left_shape := CollisionShape2D.new()
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(200, 40)
	left_shape.shape = left_rect
	left.add_child(left_shape)
	add_child(left)

	var right := StaticBody2D.new()
	right.collision_layer = 1
	right.position = Vector2(460, 420)
	var right_shape := CollisionShape2D.new()
	var right_rect := RectangleShape2D.new()
	right_rect.size = Vector2(200, 40)
	right_shape.shape = right_rect
	right.add_child(right_shape)
	add_child(right)

	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		left.queue_free()
		right.queue_free()
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	ninja.position = Vector2(188, 400)
	add_child(ninja)
	ninja._state = NinjaEnemy.State.CHASE
	ninja._set_dormant(false)

	var player := Player.new()
	player.name = "Player"
	player.position = Vector2(480, 400)
	player.set_physics_process(false)
	add_child(player)

	await get_tree().physics_frame
	await get_tree().physics_frame

	var landing := ninja._find_gap_landing(1.0)
	if landing.is_empty():
		player.queue_free()
		ninja.queue_free()
		left.queue_free()
		right.queue_free()
		return "Ninja gap probe should find the far bank."
	if not ninja._gap_is_imminent(1.0):
		player.queue_free()
		ninja.queue_free()
		left.queue_free()
		right.queue_free()
		return "Gap should read as imminent on the pit lip."

	ninja._facing = 1.0
	ninja._handle_ground_player(player, 0.016)
	if ninja._state != NinjaEnemy.State.JUMP:
		player.queue_free()
		ninja.queue_free()
		left.queue_free()
		right.queue_free()
		return "Chase should start a gap JUMP when the cowboy is across a pit."

	var sprite := ninja.get_node_or_null("NinjaSprite") as AnimatedSprite2D
	if sprite == null or sprite.animation != &"jump":
		player.queue_free()
		ninja.queue_free()
		left.queue_free()
		right.queue_free()
		return "Ninja jump should play the jump animation frames."

	var cleared_gap := false
	for _i in range(90):
		await get_tree().physics_frame
		if ninja.global_position.x >= 360.0:
			cleared_gap = true
			break

	var error: Variant = null
	if not cleared_gap:
		error = "Ninja should land past the gap (x=%.1f)." % ninja.global_position.x

	player.queue_free()
	ninja.queue_free()
	left.queue_free()
	right.queue_free()
	return error


func _test_ninja_hops_onto_planks() -> Variant:
	## Any plank the cowboy can jump onto, the ninja must be able to follow him onto.
	for node in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(node):
			node.free()

	var floor_body := StaticBody2D.new()
	floor_body.collision_layer = 1
	floor_body.position = Vector2(400, 420)
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(800, 40)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	var player := Player.new()
	player.name = "Player"
	player.set_physics_process(false)
	add_child(player)
	# A plank exactly at the cowboy's apex is the hardest one he can still reach.
	var reach := StarReachability.max_jump_height(player.jump_velocity, player.gravity)
	var plank_top := 400.0 - (reach - 6.0)
	var plank := StaticBody2D.new()
	plank.collision_layer = 1
	plank.position = Vector2(340, plank_top + 12.0)
	var plank_shape := CollisionShape2D.new()
	var plank_rect := RectangleShape2D.new()
	plank_rect.size = Vector2(80, 24)
	plank_shape.shape = plank_rect
	plank.add_child(plank_shape)
	add_child(plank)
	player.position = Vector2(340, plank_top)

	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		player.queue_free()
		plank.queue_free()
		floor_body.queue_free()
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	ninja.position = Vector2(250, 400)
	add_child(ninja)
	ninja._state = NinjaEnemy.State.CHASE
	ninja._set_dormant(false)

	await get_tree().physics_frame
	await get_tree().physics_frame

	var error: Variant = null
	if ninja._find_ledge_landing(1.0).is_empty():
		error = "Ninja should spot a plank lip sitting inside the cowboy's jump apex."
	else:
		var landed := false
		for _i in range(120):
			await get_tree().physics_frame
			if absf(ninja.global_position.y - plank_top) <= 4.0:
				landed = true
				break
		if not landed:
			error = "Ninja should hop onto the plank (y=%.1f, plank top %.1f)." % [
				ninja.global_position.y, plank_top
			]

	player.queue_free()
	ninja.queue_free()
	plank.queue_free()
	floor_body.queue_free()
	return error


func _test_ninja_single_sprite() -> Variant:
	## Only one drawable body — never a hidden scene Sprite2D plus the animated one.
	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	add_child(ninja)
	await get_tree().process_frame
	var drawables := 0
	for child in ninja.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			drawables += 1
	var anim := ninja.get_node_or_null("NinjaSprite") as AnimatedSprite2D
	var error: Variant = null
	if drawables != 1 or anim == null:
		error = "Ninja must have exactly one animated sprite (found %d drawables)." % drawables
	else:
		ninja._apply_facing(-1.0)
		if not anim.flip_h or anim.scale.x < 0.0:
			error = "Facing left should flip_h without a negative scale mirror."
		ninja._apply_facing(1.0)
		if anim.flip_h or anim.scale.x < 0.0:
			error = "Facing right should clear flip_h and keep positive scale."
		# Respawn rebuild must not leave a second body behind.
		ninja.restore_for_respawn()
		await get_tree().process_frame
		drawables = 0
		for child in ninja.get_children():
			if child is Sprite2D or child is AnimatedSprite2D:
				drawables += 1
		if drawables != 1:
			error = "After respawn restore the ninja still has %d drawables." % drawables
	ninja.queue_free()
	return error


func _test_ninja_follows_slope_height() -> Variant:
	## Chase must ride the dune crust, not skim a flat Y across the height step.
	var slot := 0
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = [
		{"type": "ground", "x": 3, "y": trail},
		{"type": "ground", "x": 3, "y": trail - 1},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "ninja", "x": 3, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	WildWestTheme.apply_to_level(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	if merged.size() < 2:
		level.queue_free()
		return "Height-step trail should build adjacent dirt banks."
	var span := WildWestTheme._slope_span(merged[0], merged[1])
	if span.is_empty():
		level.queue_free()
		return "Expected a walkable dune between stacked dirt banks."
	var ninja := level.find_child("Ninja0", true, false) as NinjaEnemy
	var player := level.get_node_or_null("Player") as Player
	if ninja == null or player == null:
		level.queue_free()
		return "Slope chase test needs the ninja and the cowboy."
	var x_start := float(span["x_start"]) + 20.0
	var x_mid := (float(span["x_start"]) + float(span["x_end"])) * 0.5
	var start_surface := WildWestTheme.walk_surface_at(level, x_start)
	var mid_surface := WildWestTheme.walk_surface_at(level, x_mid)
	ninja.set_physics_process(false)
	ninja._activated = true
	ninja._state = NinjaEnemy.State.CHASE
	ninja._set_dormant(false)
	ninja.global_position = Vector2(x_start, float(start_surface["y"]))
	player.set_physics_process(false)
	player.global_position = Vector2(x_mid + 40.0, float(mid_surface["y"]))
	ninja.set_physics_process(true)
	var followed := false
	for _i in range(90):
		await get_tree().physics_frame
		if absf(ninja.global_position.x - x_mid) <= 28.0:
			var expected_y := float(WildWestTheme.walk_surface_at(level, ninja.global_position.x)["y"])
			if absf(ninja.global_position.y - expected_y) <= 6.0:
				followed = true
				break
	var error: Variant = null
	if not followed:
		var expected_y := float(WildWestTheme.walk_surface_at(level, ninja.global_position.x)["y"])
		error = (
			"Ninja should follow dune height while chasing (y=%.1f, surface %.1f, x=%.1f)."
			% [ninja.global_position.y, expected_y, ninja.global_position.x]
		)
	level.queue_free()
	return error


func _test_ninja_chase_performance() -> Variant:
	## Three visible chasing ninjas used to rebuild ground strips every snap/ray.
	## Cache + gated gap scans must keep collect calls near one per physics frame.
	var slot := 0
	var trail := CustomLevelStore.trail_row(8)
	var objects: Array = []
	for x in range(0, 24):
		objects.append({"type": "ground", "x": x, "y": trail})
	objects.append({"type": "ninja", "x": 6, "y": trail})
	objects.append({"type": "ninja", "x": 10, "y": trail})
	objects.append({"type": "ninja", "x": 14, "y": trail})
	objects.append({"type": "goal", "x": 22, "y": trail})
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = objects
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	WildWestTheme.apply_to_level(level)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ninjas: Array[NinjaEnemy] = []
	for child in level.find_children("*", "AnimatableBody2D", true, false):
		if child is NinjaEnemy:
			ninjas.append(child as NinjaEnemy)
	var player := level.get_node_or_null("Player") as Player
	if ninjas.size() < 3 or player == null:
		level.queue_free()
		return "Performance fixture needs three ninjas and the cowboy."
	player.set_physics_process(false)
	player.global_position = Vector2(ninjas[1].global_position.x + 180.0, ninjas[1].global_position.y)
	for ninja in ninjas:
		ninja.set_physics_process(false)
		ninja._activated = true
		ninja._state = NinjaEnemy.State.CHASE
		ninja._set_dormant(false)
		ninja.set_physics_process(true)
	WildWestTheme.invalidate_walk_surface_cache()
	WildWestTheme.ground_collect_calls = 0
	var frames := 45
	for _i in range(frames):
		await get_tree().physics_frame
	var collects := WildWestTheme.ground_collect_calls
	var error: Variant = null
	# Allow a small cushion for decorate/setup leftovers, but never near 3×frames.
	if collects > frames + 8:
		error = (
			"Three chasing ninjas should reuse the walk-surface cache (collects=%d frames=%d)."
			% [collects, frames]
		)
	level.queue_free()
	return error


func _test_ninja_respawn_restore() -> Variant:
	## Camp respawn must cancel ambush/jump work and hide the ninja at his stamp post.
	# Prior ninja tests queue_free players; purge leftovers so dormancy is not re-armed.
	for node in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(node):
			node.free()

	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	ninja.position = Vector2(200, 400)
	ninja.set_physics_process(false)
	add_child(ninja)
	await get_tree().process_frame
	var anchor: Vector2 = ninja._anchor
	if anchor.distance_to(Vector2(200, 400)) > 1.0:
		ninja.queue_free()
		return "Ninja stamp post should match the spawn position (got %s)." % str(anchor)

	var player := Player.new()
	player.name = "Player"
	player.position = Vector2(260, 400)
	player.velocity = Vector2(120.0, 0.0)
	player.set_physics_process(false)
	if not player.is_in_group("player"):
		player.add_to_group("player")
	add_child(player)

	# Force an ambush appear in front of the cowboy.
	ninja._activated = true
	ninja._appear_in_front_of(player)
	if ninja._state != NinjaEnemy.State.APPEAR and ninja._state != NinjaEnemy.State.CHASE:
		player.queue_free()
		ninja.queue_free()
		return "Ninja should be appearing or chasing before the respawn restore."
	if ninja.global_position.distance_to(anchor) < 40.0:
		player.queue_free()
		ninja.queue_free()
		return "Ambush should move the ninja off his stamp post before restore (got %s)." % str(
			ninja.global_position
		)

	# Keep the cowboy out of ambush range so restore is not immediately re-triggered.
	player.global_position = Vector2(5000, 400)
	ninja.restore_for_respawn()
	ninja.set_physics_process(true)
	# Let the old appear tween finish if it was not cancelled.
	await get_tree().create_timer(0.35).timeout

	var error: Variant = null
	if ninja._state != NinjaEnemy.State.DORMANT:
		error = "Ninja should be dormant after respawn restore (state=%s)." % str(ninja._state)
	elif ninja._activated:
		error = "Ninja ambush flag should clear on respawn restore."
	elif ninja.global_position.distance_to(anchor) > 1.0:
		error = "Ninja should return to his stamp post (got %s, want %s)." % [
			str(ninja.global_position), str(anchor)
		]
	elif ninja.modulate.a > 0.05:
		error = "Dormant ninja should be hidden after respawn (a=%.2f)." % ninja.modulate.a
	elif ninja._area != null and ninja._area.monitoring:
		error = "Dormant ninja hurt area should not monitor after respawn."

	# Mid-jump restore also snaps home and ignores a finishing jump tween.
	if error == null:
		ninja.set_physics_process(false)
		ninja._activated = true
		ninja._state = NinjaEnemy.State.JUMP
		ninja._set_dormant(false)
		ninja.global_position = Vector2(520, 360)
		ninja._jump_token += 1
		var jump_token := ninja._jump_token
		ninja._kill_jump_tween()
		ninja._jump_tween = ninja.create_tween()
		ninja._jump_tween.tween_interval(0.05)
		ninja._jump_tween.tween_callback(func() -> void:
			if jump_token != ninja._jump_token:
				return
			ninja.global_position = Vector2(560, 400)
			ninja._state = NinjaEnemy.State.CHASE
		)
		ninja.restore_for_respawn()
		await get_tree().create_timer(0.12).timeout
		if ninja._state != NinjaEnemy.State.DORMANT:
			error = "Jumping ninja should be dormant after respawn restore."
		elif ninja.global_position.distance_to(anchor) > 1.0:
			error = "Jumping ninja should return to his stamp post on respawn."
		elif ninja.modulate.a > 0.05:
			error = "Jumping ninja should hide after respawn restore."

	# Tied path also returns to the post.
	if error == null:
		ninja._set_dormant(false)
		ninja._state = NinjaEnemy.State.CHASE
		ninja.global_position = Vector2(500, 400)
		ninja.tie_up(false)
		ninja.untie_for_respawn()
		await get_tree().process_frame
		if ninja.is_tied():
			error = "Untie-for-respawn should clear the tied flag."
		elif ninja._state != NinjaEnemy.State.DORMANT:
			error = "Untied ninja should be dormant at camp respawn."
		elif ninja.global_position.distance_to(anchor) > 1.0:
			error = "Untied ninja should return to his stamp post."
		elif ninja.modulate.a > 0.05:
			error = "Untied dormant ninja should be hidden."

	player.queue_free()
	ninja.queue_free()
	return error


func _test_workshop_preview_shows_ninja() -> Variant:
	## Live preview must show the stamped ninja; play builds stay invisible until ambush.
	var data := CustomLevelStore.default_level(0)
	var trail := CustomLevelStore.trail_row(int(data.get("height", 8)))
	var objects: Array = data.get("objects", []).duplicate(true)
	objects.append({"type": "ninja", "x": 10, "y": trail - 1})
	data["objects"] = objects
	var preview := LevelPreview.new()
	add_child(preview)
	preview.show_level(data)
	await get_tree().process_frame
	await get_tree().process_frame
	var error: Variant = null
	var marker: NinjaEnemy = null
	if preview._world != null:
		for node in preview._world.get_children():
			if node is NinjaEnemy:
				marker = node as NinjaEnemy
				break
	if marker == null:
		error = "Workshop preview should spawn a ninja at the stamp."
	elif not marker.editor_marker:
		error = "Preview ninjas should be editor markers."
	elif marker.modulate.a < 0.9:
		error = "Preview ninjas should stay visible at the stamp (a=%.2f)." % marker.modulate.a
	elif marker._state != NinjaEnemy.State.DORMANT:
		error = "Preview ninjas must stay dormant (no ambush)."
	preview.queue_free()

	var play_level := LevelController.new()
	play_level.skip_auto_setup = true
	add_child(play_level)
	CustomLevelBuilder.build(play_level, data, false)
	await get_tree().process_frame
	var play_ninja: NinjaEnemy = null
	for node in play_level.get_children():
		if node is NinjaEnemy:
			play_ninja = node as NinjaEnemy
			break
	if error == null and play_ninja == null:
		error = "Play build should still place a ninja."
	elif error == null and play_ninja.editor_marker:
		error = "Play-test / campaign ninjas must not use the editor marker."
	elif error == null and play_ninja.modulate.a > 0.05:
		error = "Play ninjas should stay hidden until ambush (a=%.2f)." % play_ninja.modulate.a
	play_level.queue_free()
	return error


func _test_shuriken_art() -> Variant:
	var tex: Texture2D = load("res://assets/world/ninja_shuriken.png")
	if tex == null:
		return "Missing shuriken texture."
	var size := tex.get_size()
	if size.x < 20 or size.y < 20:
		return "Shuriken art should be a visible sprite (got %s)." % str(size)
	var img := tex.get_image()
	if img == null or img.is_empty():
		return "Shuriken texture image data missing."
	var filled := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.1:
				filled += 1
	if filled < 40:
		return "Shuriken art looks too empty (%d opaque pixels)." % filled
	return null


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


func _test_upward_contact_hurts() -> Variant:
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	var bandit := packed.instantiate() as Opponent
	bandit.position = Vector2(200, 400)
	add_child(bandit)
	var player := Player.new()
	player.position = Vector2(200, 360)
	player.velocity = Vector2(0.0, -120.0)
	add_child(player)
	var hurt := [false]
	bandit.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	bandit._on_body_entered(player)
	var error: Variant = null
	if bandit.is_tied():
		error = "Hitting a bandit while moving upward must not tie him."
	elif not hurt[0]:
		error = "Upward contact should send the cowboy back to camp."
	player.queue_free()
	bandit.queue_free()
	return error


func _test_standing_above_hurts() -> Variant:
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	var bandit := packed.instantiate() as Opponent
	bandit.position = Vector2(200, 400)
	add_child(bandit)
	var player := Player.new()
	player.position = Vector2(200, 360)
	player.velocity = Vector2.ZERO
	add_child(player)
	var hurt := [false]
	bandit.hurt_player.connect(func(_p: Player) -> void: hurt[0] = true)
	bandit._on_body_entered(player)
	var error: Variant = null
	if bandit.is_tied():
		error = "Standing above a bandit without falling must not tie him."
	elif not hurt[0]:
		error = "Standing overlap without a downward stomp should send the cowboy back to camp."
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


func _test_cave_trails_have_no_doors() -> Variant:
	## Ranch gates are a desert prop — cave trails route around belts, ladders and ledges.
	var trail := CustomLevelStore.trail_row(8)
	var doc := CustomLevelStore.default_level(0)
	doc["style"] = CustomLevelStore.STYLE_CAVE
	var cave_objects: Array = []
	for x in range(2, 16):
		cave_objects.append({"type": "ground", "x": x, "y": trail})
	cave_objects.append_array([
		{"type": "conveyor", "x": 6, "y": trail - 1, "push_right": true},
		{"type": "timed_door", "x": 10, "y": trail - 1},
		{"type": "goal", "x": 14, "y": trail - 1},
	])
	doc["objects"] = cave_objects
	var clean := CustomLevelStore.sanitize(doc, 0)
	for value in clean.get("objects", []):
		if str((value as Dictionary).get("type", "")) == "timed_door":
			return "Sanitizing a cave trail should drop stamped ranch gates."

	# A hand-edited document must still build (and validate) without a gate.
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, doc)
	await get_tree().process_frame
	var error: Variant = null
	if level.find_child("Door0", true, false) != null:
		error = "Cave builder should skip timed door stamps."
	elif level.find_child("Conveyor0", true, false) == null:
		error = "Cave trails should still keep their conveyor belts."
	else:
		var door := CustomLevelBuilder.TIMED_DOOR.instantiate() as TimedDoor
		door.name = "StrayGate"
		door.position = Vector2(400, float(trail) * 40.0)
		level.add_child(door)
		await get_tree().process_frame
		if LevelLayoutRules._validate_no_doors_in_caves(level).is_empty():
			error = "Layout rules must reject a ranch gate placed in a cave trail."
	level.queue_free()
	await get_tree().process_frame
	return error


func _test_wing_chasm_hands_out_wings_at_camp() -> Variant:
	## Wing Chasm is the cave flying trail: the cowboy picks up wings before the first badge.
	var data := CaveCampaignLevels.level_data(15)
	var spawn: Array = data.get("spawn", [2, 9])
	var spawn_x := int(spawn[0])
	var first_wings := -1
	var first_star := -1
	var high_stars := 0
	var bandits := 0
	var bounty_bandits := 0
	var checkpoints := 0
	for value in data.get("objects", []):
		var object := value as Dictionary
		var x := int(object.get("x", 0))
		match str(object.get("type", "")):
			"wings":
				if first_wings < 0 or x < first_wings:
					first_wings = x
			"star":
				if first_star < 0 or x < first_star:
					first_star = x
				# Badges parked in the upper cave air are the reward for flying.
				if int(object.get("y", 0)) <= 3:
					high_stars += 1
			"bandit":
				bandits += 1
			"bounty_bandit":
				bounty_bandits += 1
			"checkpoint":
				checkpoints += 1
	if first_wings < 0:
		return "Wing Chasm must stamp the wings item."
	if first_wings > spawn_x + 6:
		return "Wing Chasm wings should sit at camp (column %d, spawn %d)." % [first_wings, spawn_x]
	if first_star >= 0 and first_wings > first_star:
		return "Wing Chasm should hand out wings before the first badge."
	if high_stars < 6:
		return "Wing Chasm should hang badges in the upper cave air (found %d)." % high_stars
	if bandits < 2:
		return "Wing Chasm should stamp bow skeletons on the solid trail (found %d)." % bandits
	if bounty_bandits < 1:
		return "Wing Chasm should stamp a crystal skeleton after the late belt."
	if checkpoints < 3:
		return "Wing Chasm should offer three lantern camps along the trail (found %d)." % checkpoints

	var level := LevelController.new()
	level.level_number = 15
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	var wings_at_camp := false
	for node in level.find_children("*", "ModeItem", true, false):
		var item := node as ModeItem
		if item.mode == ModeController.Mode.WINGS and item.global_position.x <= 320.0:
			wings_at_camp = true
	var skeleton_count := 0
	for node in level.find_children("*", "Opponent", true, false):
		skeleton_count += 1
	var errors := LevelLayoutRules.validate_level_node(level)
	level.queue_free()
	await get_tree().process_frame
	if not wings_at_camp:
		return "Built Wing Chasm should place a wings pickup within reach of the camp."
	if skeleton_count < 3:
		return "Built Wing Chasm should place cave skeletons (found %d)." % skeleton_count
	if not errors.is_empty():
		return "Wing Chasm layout errors: %s" % ", ".join(errors)
	return null


func _test_conveyors_do_not_push_into_canyons() -> Variant:
	# Rail Yard + finale share belt/door yards; belts must stop at a gate on solid ground.
	for path in ["res://scenes/levels/level_08.tscn", "res://scenes/levels/level_10.tscn"]:
		var packed: PackedScene = load(path)
		if packed == null:
			return "Missing level: %s" % path
		var level: Node = packed.instantiate()
		add_child(level)
		if level is LevelController:
			(level as LevelController).setup_level()
		var errors := LevelLayoutRules._validate_conveyors_not_pushing_into_canyons(level)
		var door_errors := LevelLayoutRules._validate_timed_doors_clear_of_canyons(level)
		level.queue_free()
		if not errors.is_empty():
			return "%s -> %s" % [path, ", ".join(errors)]
		if not door_errors.is_empty():
			return "%s -> %s" % [path, ", ".join(door_errors)]
	# Synthetic softlock: belt pushing into a ground canyon with no door must fail.
	var probe := Node2D.new()
	add_child(probe)
	var ground_a := StaticBody2D.new()
	ground_a.name = "GroundA"
	ground_a.position = Vector2(200, 352)
	var shape_a := CollisionShape2D.new()
	shape_a.name = "CollisionShape2D"
	var rect_a := RectangleShape2D.new()
	rect_a.size = Vector2(400, 64)
	shape_a.shape = rect_a
	ground_a.add_child(shape_a)
	probe.add_child(ground_a)
	var ground_b := StaticBody2D.new()
	ground_b.name = "GroundB"
	ground_b.position = Vector2(800, 352)
	var shape_b := CollisionShape2D.new()
	shape_b.name = "CollisionShape2D"
	var rect_b := RectangleShape2D.new()
	rect_b.size = Vector2(400, 64)
	shape_b.shape = rect_b
	ground_b.add_child(shape_b)
	probe.add_child(ground_b)
	var belt_packed: PackedScene = load("res://scenes/world/conveyor_belt.tscn")
	if belt_packed == null:
		probe.queue_free()
		return "Missing conveyor belt scene."
	var belt := belt_packed.instantiate() as ConveyorBelt
	belt.name = "SoftlockBelt"
	belt.position = Vector2(350, 320)
	belt.push_right = true
	probe.add_child(belt)
	await get_tree().process_frame
	var bad := LevelLayoutRules._validate_conveyors_not_pushing_into_canyons(probe)
	probe.queue_free()
	if bad.is_empty():
		return "Layout rules must reject a conveyor that pushes into an open canyon."
	return null


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


func _test_bandits_stand_on_desert() -> Variant:
	## Bandit / kingpin-guard feet must sit on the desert top (root at trail floor Y).
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	if packed == null:
		return "Missing opponent scene."
	var desert_top := 320.0
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	floor.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(800, 64)
	shape.shape = rect
	shape.position = Vector2(0, 32)
	floor.add_child(shape)
	floor.position = Vector2(400.0, desert_top)
	add_child(floor)
	var bandit := packed.instantiate() as Opponent
	bandit.position = Vector2(400.0, desert_top)
	add_child(bandit)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not bandit.has_method("foot_contact_y"):
		bandit.queue_free()
		floor.queue_free()
		return "Opponent must expose foot_contact_y for desert grounding checks."
	var stand_feet: float = bandit.call("foot_contact_y")
	if absf(stand_feet - desert_top) > 2.5:
		bandit.queue_free()
		floor.queue_free()
		return "Standing bandits must stand on the desert (feet y=%.1f, floor=%.1f)." % [stand_feet, desert_top]
	var walk := bandit.get_node_or_null("WalkSprite") as AnimatedSprite2D
	if walk == null or walk.offset != Opponent.STAND_FOOT_OFFSET:
		bandit.queue_free()
		floor.queue_free()
		return "Standing bandits must use the desert foot offset."
	bandit.tie_up(false)
	# Wait out the short tying flourish before measuring the seated pose.
	await get_tree().create_timer(0.5).timeout
	var tied_feet: float = bandit.call("foot_contact_y")
	if walk.offset != Opponent.TIED_FOOT_OFFSET:
		bandit.queue_free()
		floor.queue_free()
		return "Tied bandits must keep the desert seat offset."
	bandit.queue_free()
	floor.queue_free()
	if absf(tied_feet - desert_top) > 2.5:
		return "Tied bandits must sit on the desert (feet y=%.1f, floor=%.1f)." % [tied_feet, desert_top]
	# Kingpin arena guards share the Opponent scene on the same desert line.
	var king_packed: PackedScene = load("res://scenes/bosses/boss_outlaw_kingpin.tscn")
	if king_packed == null:
		return "Missing kingpin arena."
	var king := king_packed.instantiate()
	add_child(king)
	await get_tree().process_frame
	for guard_name in ["Guard0", "Guard1"]:
		var guard := king.get_node_or_null(guard_name) as Opponent
		if guard == null:
			king.queue_free()
			return "Kingpin arena missing %s." % guard_name
		if absf(guard.position.y - desert_top) > 0.5:
			king.queue_free()
			return "%s root must sit on the desert surface Y." % guard_name
		var guard_feet: float = guard.call("foot_contact_y")
		if absf(guard_feet - desert_top) > 2.5:
			king.queue_free()
			return "%s must stand on the desert (feet y=%.1f, floor=%.1f)." % [guard_name, guard_feet, desert_top]
	king.queue_free()
	return null


func _test_cactus_aligns_to_desert_slope() -> Variant:
	var slot := 0
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = [
		{"type": "ground", "x": 3, "y": trail},
		{"type": "ground", "x": 3, "y": trail - 1},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "cactus", "x": 3, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var level := LevelController.new()
	CustomLevelBuilder.build(level, data)
	WildWestTheme.apply_to_level(level)
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	if merged.size() < 2:
		level.free()
		return "Height-step workshop trail should build adjacent dirt banks."
	var span := WildWestTheme._slope_span(merged[0], merged[1])
	if span.is_empty():
		level.free()
		return "Expected a walkable dune between stacked dirt banks."
	var cactus := level.find_child("Cactus0", true, false) as Hazard
	if cactus == null:
		level.free()
		return "Height-step workshop trail should spawn a cactus."
	var sample_x := (float(span["x_start"]) + float(span["x_end"])) * 0.5
	cactus.global_position.x = sample_x
	var surface := WildWestTheme.walk_surface_at(level, sample_x)
	cactus.align_to_walk_surface(
		float(surface["y"]),
		float(surface["angle"]),
		WildWestTheme.CACTUS_DESERT_SINK,
		WildWestTheme.CACTUS_TILT_BLEND,
		WildWestTheme.CACTUS_MAX_TILT
	)
	var expected_y := float(surface["y"]) + WildWestTheme.CACTUS_DESERT_SINK
	if absf(cactus.ground_contact_y() - expected_y) > 2.5:
		level.free()
		return (
			"Cactus on a dune should follow the walk surface (feet y=%.1f, expected %.1f)."
			% [cactus.ground_contact_y(), expected_y]
		)
	if absf(float(surface["angle"])) < 0.02:
		level.free()
		return "Mid-slope sample should expose a non-flat desert angle."
	if absf(cactus.rotation) > WildWestTheme.CACTUS_MAX_TILT + 0.01:
		level.free()
		return "Cactus slope tilt should stay subtle for the hand-drawn look."
	level.free()
	return null


func _test_slope_crest_walkable() -> Variant:
	var slot := 0
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = [
		{"type": "ground", "x": 3, "y": trail},
		{"type": "ground", "x": 3, "y": trail - 1},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	WildWestTheme.apply_to_level(level)
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	if merged.size() < 2:
		level.queue_free()
		return "Height-step workshop trail should build adjacent dirt banks."
	var span := WildWestTheme._slope_span(merged[0], merged[1])
	if span.is_empty():
		level.queue_free()
		return "Expected a walkable dune between stacked dirt banks."
	var crest_x := float(span["x_end"])
	var expected_y := float(span["y_end"])
	var slope_body := level.find_child("FloorSlopeBody0", true, false) as StaticBody2D
	if slope_body == null:
		level.queue_free()
		return "Desert height slopes need walkable collision."
	var col := slope_body.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if col == null or col.polygon.is_empty():
		level.queue_free()
		return "Desert slopes should use a curved collision polygon."
	var half := int(col.polygon.size() * 0.5)
	var crest_hit_y := expected_y
	var best_dx := INF
	for idx in range(half):
		var pt := col.polygon[idx]
		var dx := absf(pt.x - crest_x)
		if dx < best_dx:
			best_dx = dx
			crest_hit_y = pt.y
	if best_dx > 36.0:
		level.queue_free()
		return "Slope crest should expose walkable collision."
	if absf(crest_hit_y - expected_y) > 4.0:
		level.queue_free()
		return (
			"Slope crest collision should match walk surface (hit y=%.1f, expected %.1f)."
			% [crest_hit_y, expected_y]
		)
	var player := level.get_node_or_null("Player") as Player
	if player == null:
		level.queue_free()
		return "Slope crest walk test needs the player."
	var start_x := float(span["x_start"]) + 24.0
	var start_surface := WildWestTheme.walk_surface_at(level, start_x)
	player.global_position = Vector2(start_x, float(start_surface["y"]) - 28.0)
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	for _step in range(180):
		player.velocity = Vector2(140.0, player.velocity.y)
		await get_tree().physics_frame
		if player.global_position.x >= float(span["x_end"]) + 20.0:
			break
	if player.global_position.x < float(span["x_end"]) + 8.0:
		level.queue_free()
		return "Cowboy should walk over the dune crest onto the upper bank."
	if not player.is_on_floor():
		level.queue_free()
		return "Cowboy should stay on the floor while crossing the dune crest."

	var left_start_x := float(span["x_end"]) + 12.0
	var left_surface := WildWestTheme.walk_surface_at(level, left_start_x)
	player.global_position = Vector2(left_start_x, float(left_surface["y"]) - 28.0)
	player.velocity = Vector2.ZERO
	await get_tree().physics_frame
	await get_tree().physics_frame
	for _step in range(180):
		player.velocity = Vector2(-140.0, player.velocity.y)
		await get_tree().physics_frame
		if player.global_position.x <= float(span["x_start"]) - 20.0:
			break
	if player.global_position.x > float(span["x_start"]) - 8.0:
		level.queue_free()
		return "Cowboy should walk left over the dune crest onto the lower bank."
	if not player.is_on_floor():
		level.queue_free()
		return "Cowboy should stay on the floor while walking left over the dune crest."
	level.queue_free()
	return null


func _test_slope_dirt_below_crust() -> Variant:
	var slot := 0
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = [
		{"type": "ground", "x": 3, "y": trail},
		{"type": "ground", "x": 3, "y": trail - 1},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var level := LevelController.new()
	CustomLevelBuilder.build(level, data)
	WildWestTheme.apply_to_level(level)
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	if merged.size() < 2:
		level.free()
		return "Height-step workshop trail should build adjacent dirt banks."
	var span := WildWestTheme._slope_span(merged[0], merged[1])
	if span.is_empty():
		level.free()
		return "Expected a walkable dune between stacked dirt banks."
	var x_start := float(span["x_start"])
	var x_end := float(span["x_end"])
	var y_start := float(span["y_start"])
	var y_end := float(span["y_end"])
	var curved := bool(span.get("curved", true))
	var trail_floor := level.get_node_or_null("TrailFloor") as Node2D
	if trail_floor == null:
		level.free()
		return "Theme should build TrailFloor for slope dirt checks."
	for node in trail_floor.find_children("FloorDirt*", "Sprite2D", false, false):
		var sprite := node as Sprite2D
		var sample_x := sprite.global_position.x + sprite.texture.get_size().x * sprite.scale.x * 0.5
		if sample_x < x_start - 4.0 or sample_x > x_end + 4.0:
			continue
		var surface_y := WildWestTheme._slope_y_at(
			sample_x, x_start, y_start, x_end, y_end, curved
		)
		var dirt_top := sprite.global_position.y
		if dirt_top + 4.0 < surface_y:
			continue
		if dirt_top > surface_y + 6.0:
			level.free()
			return "Flat FloorDirt must not paint above the dune crust line."
	for node in trail_floor.find_children("FloorSlopeDirt*", "Sprite2D", false, false):
		var slope_dirt := node as Sprite2D
		var sample_x := slope_dirt.global_position.x + slope_dirt.texture.get_size().x * slope_dirt.scale.x * 0.5
		if sample_x < x_start - 4.0 or sample_x > x_end + 4.0:
			continue
		var surface_y := WildWestTheme._slope_y_at(
			sample_x, x_start, y_start, x_end, y_end, curved
		)
		# Slope earth fills UNDER the crust (the upper wedge is the FloorSlopeUnderfill
		# polygon). Dirt tiles must never poke above the sand crust line.
		if slope_dirt.global_position.y < surface_y - 6.0:
			level.free()
			return "FloorSlopeDirt must not paint above the dune crust line."
		if slope_dirt.z_index >= 3:
			level.free()
			return "Slope dirt must stay below the sand crust and the cowboy."
	for node in trail_floor.find_children("FloorAbyss*", "Polygon2D", false, false):
		var abyss := node as Polygon2D
		var abyss_left := abyss.position.x
		var abyss_right := abyss.position.x
		for point in abyss.polygon:
			abyss_left = minf(abyss_left, abyss.position.x + point.x)
			abyss_right = maxf(abyss_right, abyss.position.x + point.x)
		if abyss_left < x_end - 1.0 and abyss_right > x_start + 1.0:
			level.free()
			return "FloorAbyss should stay clipped out of dune slope columns."
	level.free()
	return null


func _test_slope_underfill_covers_wedge() -> Variant:
	var slot := 0
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = [
		{"type": "ground", "x": 3, "y": trail},
		{"type": "ground", "x": 3, "y": trail - 1},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var level := LevelController.new()
	CustomLevelBuilder.build(level, data)
	WildWestTheme.apply_to_level(level)
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	if merged.size() < 2:
		level.free()
		return "Height-step workshop trail should build adjacent dirt banks."
	var span := WildWestTheme._slope_span(merged[0], merged[1])
	if span.is_empty():
		level.free()
		return "Expected a walkable dune between stacked dirt banks."
	var x_start := float(span["x_start"])
	var x_end := float(span["x_end"])
	var y_start := float(span["y_start"])
	var y_end := float(span["y_end"])
	var curved := bool(span.get("curved", true))
	var trail_floor := level.get_node_or_null("TrailFloor") as Node2D
	if trail_floor == null:
		level.free()
		return "Theme should build TrailFloor for slope underfill checks."
	var underfill := trail_floor.get_node_or_null("FloorSlopeUnderfill0") as Polygon2D
	if underfill == null:
		level.free()
		return "Desert slopes need a solid FloorSlopeUnderfill wedge."
	var poly := underfill.polygon
	var upper_dirt := 0
	for node in trail_floor.find_children("FloorSlopeDirt*", "Sprite2D", false, false):
		var dirt_sprite := node as Sprite2D
		var sample_x := (
			dirt_sprite.global_position.x
			+ dirt_sprite.texture.get_size().x * dirt_sprite.scale.x * 0.5
		)
		var surface_y := WildWestTheme._slope_y_at(
			sample_x, x_start, y_start, x_end, y_end, curved
		)
		if dirt_sprite.global_position.y < surface_y + 40.0:
			upper_dirt += 1
	if upper_dirt < 3:
		level.free()
		return "Slope dirt tiles must pack the upper wedge under the crust (found %d)." % upper_dirt
	for sample_t in [0.2, 0.5, 0.8]:
		var x := lerpf(x_start, x_end, sample_t)
		var surface_y := WildWestTheme._slope_y_at(
			x, x_start, y_start, x_end, y_end, curved
		)
		for depth in [8.0, 20.0, 40.0, 80.0, 220.0]:
			var pt := Vector2(x, surface_y + depth)
			if not Geometry2D.is_point_in_polygon(pt, poly):
				level.free()
				return "FloorSlopeUnderfill must cover earth under the dune face (no sky gaps)."
	level.free()
	return null


func _test_slope_ground_bridge_clear() -> Variant:
	var slot := 0
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = [
		{"type": "ground", "x": 3, "y": trail},
		{"type": "ground", "x": 3, "y": trail - 1},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	WildWestTheme.apply_to_level(level)
	await get_tree().physics_frame
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	if merged.size() < 2:
		level.queue_free()
		return "Height-step workshop trail should build adjacent dirt banks."
	var span := WildWestTheme._slope_span(merged[0], merged[1])
	if span.is_empty():
		level.queue_free()
		return "Expected a walkable dune between stacked dirt banks."
	var x_start := float(span["x_start"])
	var x_end := float(span["x_end"])
	const BANK_EXTEND := 36.0
	var bridge_left := minf(x_start, x_end) - BANK_EXTEND
	var bridge_right := maxf(x_start, x_end) + BANK_EXTEND
	var space := level.get_world_2d().direct_space_state
	for ground in level.find_children("Ground*", "StaticBody2D", true, false):
		if String(ground.name).ends_with("Fill"):
			continue
		var shape_node := ground.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node == null or shape_node.disabled:
			continue
		var center := shape_node.global_position
		var half := (shape_node.shape as RectangleShape2D).size * 0.5
		var left := center.x - half.x
		var right := center.x + half.x
		if right < bridge_left or left > bridge_right:
			continue
		if left >= bridge_left - 1.0 and right <= bridge_right + 1.0:
			level.queue_free()
			return "Ground collision must leave the dune bridge to FloorSlopeBody."
		for sample_x in [bridge_left + 20.0, (x_start + x_end) * 0.5, bridge_right - 20.0]:
			var surface := WildWestTheme.walk_surface_at(level, sample_x)
			var foot_y := float(surface["y"]) - 2.0
			var query := PhysicsRayQueryParameters2D.create(
				Vector2(sample_x, foot_y - 24.0),
				Vector2(sample_x, foot_y + 40.0)
			)
			query.collision_mask = 1
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				level.queue_free()
				return "Dune bridge should expose floor collision for walking."
			var hit_y := float(hit.get("position", Vector2.ZERO).y)
			if absf(hit_y - float(surface["y"])) > 8.0:
				level.queue_free()
				return (
					"Dune collision should match walk surface (hit y=%.1f, expected %.1f)."
					% [hit_y, float(surface["y"])]
				)
	level.queue_free()
	return null


func _test_slope_underfill_earth_color() -> Variant:
	var slot := 0
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(slot)
	data["objects"] = [
		{"type": "ground", "x": 3, "y": trail},
		{"type": "ground", "x": 3, "y": trail - 1},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var level := LevelController.new()
	CustomLevelBuilder.build(level, data)
	WildWestTheme.apply_to_level(level)
	var trail_floor := level.get_node_or_null("TrailFloor") as Node2D
	if trail_floor == null:
		level.free()
		return "Theme should build TrailFloor for slope underfill checks."
	var underfill := trail_floor.get_node_or_null("FloorSlopeUnderfill0") as Polygon2D
	if underfill == null:
		level.free()
		return "Desert slopes need a solid FloorSlopeUnderfill wedge."
	var expected := Color(0.42, 0.22, 0.14, 1.0)
	if not underfill.color.is_equal_approx(expected):
		if underfill.color.b > expected.b + 0.05:
			level.free()
			return "Slope underfill should use warm bank earth, not blue-tinted fill."
		level.free()
		return "Slope underfill should use warm bank earth (got %s)." % underfill.color
	var abyss := trail_floor.get_node_or_null("FloorAbyss") as Polygon2D
	if abyss != null and not abyss.color.is_equal_approx(expected):
		level.free()
		return "FloorAbyss should match warm bank earth under flat dirt."
	# Far below the dune must stay packed with earth tiles (not a black void).
	var deep_dirt := 0
	var merged := WildWestTheme._merge_segments(WildWestTheme._collect_ground_segments(level))
	var span := WildWestTheme._slope_span(merged[0], merged[1])
	var surface_y := minf(float(span.get("y_start", 0.0)), float(span.get("y_end", 0.0)))
	for node in trail_floor.find_children("FloorSlopeDirt*", "Sprite2D", false, false):
		if (node as Sprite2D).position.y > surface_y + 400.0:
			deep_dirt += 1
	level.free()
	if deep_dirt < 4:
		return "Slope dirt tiles should continue far below the dune face (got %d deep)." % deep_dirt
	return null


func _test_cave_floor_tiles_solid() -> Variant:
	## Cave crust + dirt must be fully opaque so tiled banks never show sky holes.
	for path in [
		"res://assets/world/cave_floor_tile.png",
		"res://assets/world/cave_dirt_tile.png",
	]:
		var tex := load(path) as Texture2D
		if tex == null:
			return "Missing cave floor asset: %s" % path
		var img := tex.get_image()
		if img == null:
			return "Could not read pixels for %s" % path
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		var clear := 0
		var empty_cols := 0
		for x in range(img.get_width()):
			var col_opaque := 0
			for y in range(img.get_height()):
				if img.get_pixel(x, y).a < 0.98:
					clear += 1
				else:
					col_opaque += 1
			if col_opaque == 0:
				empty_cols += 1
		var total := img.get_width() * img.get_height()
		if clear > 0:
			return (
				"%s must be fully opaque (clear pixels=%d / %d)."
				% [path.get_file(), clear, total]
			)
		if empty_cols > 0:
			return "%s has empty columns that open sky holes when tiled." % path.get_file()

	# Built cave trail must stack crust + dirt + abyss underfill.
	var data := CaveCampaignLevels.level_data(11)
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	WildWestTheme.apply_to_level(level)
	await get_tree().process_frame
	var trail_floor := level.get_node_or_null("TrailFloor") as Node2D
	if trail_floor == null:
		level.queue_free()
		return "Cave level should dress a TrailFloor."
	var has_surface := false
	var has_dirt := false
	for child in trail_floor.get_children():
		var child_name := String(child.name)
		if child_name.begins_with("FloorSurface"):
			has_surface = true
		if child_name.begins_with("FloorDirt"):
			has_dirt = true
	if not has_surface:
		level.queue_free()
		return "Cave TrailFloor needs FloorSurface crust."
	if not has_dirt:
		level.queue_free()
		return "Cave TrailFloor needs FloorDirt underfill tiles."
	var abyss := trail_floor.get_node_or_null("FloorAbyss") as Polygon2D
	if abyss == null:
		level.queue_free()
		return "Cave TrailFloor needs FloorAbyss underfill."
	level.queue_free()
	return null


func _test_cave_sky_meets_floor() -> Variant:
	## Cave wash must reach past the trail crust so no Background gap shows above dirt.
	var tex := load("res://assets/world/cave_sky.png") as Texture2D
	if tex == null:
		return "Missing cave_sky.png."
	var img := tex.get_image()
	if img == null:
		return "Could not read cave_sky pixels."
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var clear := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a < 0.98:
				clear += 1
	if clear > 0:
		return "cave_sky.png must be opaque edge-to-edge (clear=%d)." % clear

	var data := CaveCampaignLevels.level_data(11)
	var level := LevelController.new()
	level.set_meta("level_style", LevelStyle.CAVE)
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	WildWestTheme.apply_to_level(level)
	await get_tree().process_frame
	var sky := level.get_node_or_null("SkyArt") as Node2D
	if sky == null:
		level.queue_free()
		return "Cave level should dress SkyArt."
	if str(level.get_meta("level_style", "")) != LevelStyle.CAVE:
		level.queue_free()
		return "Cave sky test level must keep cave style meta."
	var sky_bottom := -INF
	for child in sky.get_children():
		if not (child is Sprite2D):
			continue
		if not String(child.name).begins_with("SkyTile"):
			continue
		var spr := child as Sprite2D
		var spr_tex := spr.texture
		if spr_tex == null:
			continue
		sky_bottom = maxf(sky_bottom, spr.position.y + spr_tex.get_size().y * spr.scale.y)
	var floor_top := float(sky.get_meta("floor_top_y", WildWestTheme._typical_floor_top(level)))
	if sky_bottom < floor_top + 60.0:
		level.queue_free()
		return (
			"Cave sky wash must tuck under the floor (bottom=%.1f, floor=%.1f, tiles=%d)."
			% [sky_bottom, floor_top, sky.get_child_count()]
		)
	level.queue_free()
	return null


func _test_cave_camp_transparent() -> Variant:
	## Lantern camp art must be a cutout — no mid-gray background plate.
	for path in [
		"res://assets/world/checkpoint_cave_active.png",
		"res://assets/world/checkpoint_cave_inactive.png",
	]:
		var tex := load(path) as Texture2D
		if tex == null:
			return "Missing camp asset: %s" % path
		var img := tex.get_image()
		if img == null:
			return "Could not read pixels for %s" % path
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		var clear := 0
		var opaque := 0
		var gray_plate := 0
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var c := img.get_pixel(x, y)
				if c.a < 0.05:
					clear += 1
					continue
				opaque += 1
				var mn := minf(c.r, minf(c.g, c.b))
				var mx := maxf(c.r, maxf(c.g, c.b))
				# Mid-gray matte (~0.55–0.82) with near-zero chroma — the concept plate.
				if mx - mn <= 0.08 and mn >= 0.55 and mn <= 0.82:
					gray_plate += 1
		var total := img.get_width() * img.get_height()
		if clear < int(total * 0.35):
			return "%s should be mostly transparent around the camp (clear=%d/%d)." % [
				path.get_file(), clear, total
			]
		if opaque > 0 and float(gray_plate) / float(opaque) > 0.05:
			return "%s still has a gray background plate (%d/%d opaque)." % [
				path.get_file(), gray_plate, opaque
			]
	return null


func _test_filled_slot_advanced_mode_select() -> Variant:
	GameManager.active_slot_index = -1
	GameManager.erase_slot(0)
	var previous := bool(GameManager.get_settings().get("advanced_mode", false))
	var slot := GameManager.get_slot(0)
	slot["empty"] = false
	slot["advanced_mode"] = false
	slot["current_level"] = 3
	slot["stars"] = 12
	slot["lives"] = 0
	GameManager.debug_set_slot(0, slot)
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	scene._index = 0
	## Focusing a Classic save restores Classic; switch to Advanced after that sync.
	GameManager.set_setting("advanced_mode", true)
	var dropdown := scene.get_node_or_null("SettingsPanel/Margin/VBox/TrailModeDropdown") as OptionButton
	if dropdown == null or dropdown.disabled:
		scene.queue_free()
		GameManager.set_setting("advanced_mode", previous)
		GameManager.erase_slot(0)
		return "Filled saves should allow choosing Advanced Mode in Settings."
	GameManager.prepare_slot_for_start(0)
	GameManager.active_slot_index = 0
	if not GameManager.slot_is_advanced(0):
		scene.queue_free()
		GameManager.erase_slot(0)
		return "Advanced Mode should apply when continuing an existing save."
	if GameManager.get_lives() != 3:
		scene.queue_free()
		GameManager.erase_slot(0)
		return "Switching a Classic save to Advanced should grant three lives."
	GameManager.active_slot_index = 0
	var level_packed: PackedScene = load(GameManager.LEVEL_SCENES[0])
	var level := level_packed.instantiate()
	add_child(level)
	if level is LevelController:
		(level as LevelController).setup_level()
	await get_tree().process_frame
	await get_tree().process_frame
	var hud := level.get_node_or_null("Hud") as Hud
	if hud == null:
		level.queue_free()
		scene.queue_free()
		GameManager.erase_slot(0)
		return "Campaign level should include HUD after Advanced switch."
	hud.set_lives(GameManager.get_lives(), true)
	var panel := hud.get_node_or_null("LivesPanel") as Control
	var hearts := hud.get_node_or_null("LivesPanel/LivesHeartsLabel") as Label
	if hearts == null:
		hearts = hud.get_node_or_null("LivesHeartsLabel") as Label
	if panel == null or not panel.visible:
		level.queue_free()
		scene.queue_free()
		GameManager.erase_slot(0)
		return (
			"Advanced hearts panel should show after switching an existing save (advanced=%s lives=%d)."
			% [str(GameManager.is_advanced_mode()), GameManager.get_lives()]
		)
	if hearts == null or not hearts.text.contains("♥"):
		level.queue_free()
		scene.queue_free()
		GameManager.erase_slot(0)
		return "Advanced hearts should display filled glyphs after switching saves."
	level.queue_free()
	scene.queue_free()
	GameManager.set_setting("advanced_mode", previous)
	GameManager.erase_slot(0)
	return null


func _test_settings_player_character() -> Variant:
	GameManager.active_slot_index = -1
	var previous := String(GameManager.get_settings().get("player_character", GameManager.PLAYER_COWBOY))
	GameManager.set_setting("player_character", GameManager.PLAYER_COWGIRL)
	if GameManager.get_player_character() != GameManager.PLAYER_COWGIRL:
		GameManager.set_setting("player_character", previous)
		return "Settings should store Cowgirl as the active player character."
	GameManager.save_to_disk()
	GameManager.flush_save_to_disk()
	var save_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(GameManager.save_path()))
	if typeof(save_json) != TYPE_DICTIONARY:
		GameManager.set_setting("player_character", previous)
		return "Settings save file should remain valid JSON."
	if String((save_json as Dictionary).get("settings", {}).get("player_character", "")) != GameManager.PLAYER_COWGIRL:
		GameManager.set_setting("player_character", previous)
		return "Persisted settings should contain the selected player character."
	GameManager.load_from_disk()
	GameManager.active_slot_index = -1
	if GameManager.get_player_character() != GameManager.PLAYER_COWGIRL:
		GameManager.set_setting("player_character", previous)
		return "Reloading settings should restore the selected player character."
	GameManager.set_setting("player_character", previous)
	return null


func _test_slot_remembers_character_and_trail_mode() -> Variant:
	GameManager.active_slot_index = -1
	GameManager.erase_slot(0)
	GameManager.erase_slot(1)
	var previous_character := String(
		GameManager.get_settings().get("player_character", GameManager.PLAYER_COWBOY)
	)
	var previous_advanced := bool(GameManager.get_settings().get("advanced_mode", false))
	GameManager.set_setting("player_character", GameManager.PLAYER_COWGIRL)
	GameManager.set_setting("advanced_mode", true)
	GameManager.prepare_slot_for_start(0)
	var started := GameManager.get_slot(0)
	started["empty"] = false
	started["current_level"] = 1
	GameManager.debug_set_slot(0, started)
	GameManager.active_slot_index = 0
	if GameManager.slot_player_character(0) != GameManager.PLAYER_COWGIRL:
		GameManager.active_slot_index = -1
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		return "Starting a save should store the chosen rider on that slot."
	if not GameManager.slot_is_advanced(0):
		GameManager.active_slot_index = -1
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		return "Starting a save should store Advanced Mode on that slot."
	if GameManager.get_player_character() != GameManager.PLAYER_COWGIRL:
		GameManager.active_slot_index = -1
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		return "An active save should play as the rider stored on that slot."
	GameManager.active_slot_index = -1
	if GameManager.slot_player_character(0) != GameManager.PLAYER_COWGIRL:
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		return "Slot 0 should still remember Cowgirl before the second save is prepared."
	GameManager.set_setting("player_character", GameManager.PLAYER_COWBOY)
	GameManager.set_setting("advanced_mode", false)
	GameManager.prepare_slot_for_start(1)
	if GameManager.slot_player_character(1) != GameManager.PLAYER_COWBOY:
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		GameManager.erase_slot(1)
		return "A second save should keep its own cowboy pick."
	if GameManager.slot_player_character(0) != GameManager.PLAYER_COWGIRL:
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		GameManager.erase_slot(1)
		return "Preparing another save must not overwrite slot 0's rider."
	GameManager.apply_play_settings_from_slot(0)
	GameManager.active_slot_index = -1
	if GameManager.get_player_character() != GameManager.PLAYER_COWGIRL:
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		GameManager.erase_slot(1)
		return "Focusing a filled save should restore its rider into Settings."
	if not GameManager.is_advanced_mode_setting():
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		GameManager.erase_slot(1)
		return "Focusing a filled save should restore its trail mode into Settings."
	var packed: PackedScene = load("res://scenes/ui/save_select.tscn")
	if packed == null:
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		GameManager.erase_slot(1)
		return "Missing save select scene."
	var scene := packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	var cowboy_btn := scene.get_node_or_null("Mascots/Cowboy") as Button
	if cowboy_btn == null:
		scene.queue_free()
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		GameManager.erase_slot(1)
		return "Missing cowboy mascot button."
	var normal_style := cowboy_btn.get_theme_stylebox("normal")
	if normal_style is StyleBoxFlat and (normal_style as StyleBoxFlat).border_color.r > 0.7:
		scene.queue_free()
		GameManager.set_setting("player_character", previous_character)
		GameManager.set_setting("advanced_mode", previous_advanced)
		GameManager.erase_slot(0)
		GameManager.erase_slot(1)
		return "Chosen rider should not use a red selection border."
	scene.queue_free()
	GameManager.set_setting("player_character", previous_character)
	GameManager.set_setting("advanced_mode", previous_advanced)
	GameManager.erase_slot(0)
	GameManager.erase_slot(1)
	return null


func _test_bandit_walk_animation() -> Variant:
	## Patrol movement must play the walk cycle; standing still uses idle.
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	if packed == null:
		return "Missing opponent scene."
	# Flat ground so edge-turn rays do not cancel the patrol.
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	ground.collision_mask = 0
	var ground_shape := CollisionShape2D.new()
	var ground_rect := RectangleShape2D.new()
	ground_rect.size = Vector2(600.0, 40.0)
	ground_shape.shape = ground_rect
	ground_shape.position = Vector2(400.0, 340.0)
	ground.add_child(ground_shape)
	add_child(ground)
	var bandit := packed.instantiate() as Opponent
	bandit.position = Vector2(400.0, 320.0)
	bandit.point_a = Vector2(-80.0, 0.0)
	bandit.point_b = Vector2(80.0, 0.0)
	bandit.move_speed = 80.0
	add_child(bandit)
	await get_tree().process_frame
	var walk := bandit.get_node_or_null("WalkSprite") as AnimatedSprite2D
	if walk == null or walk.sprite_frames == null:
		bandit.queue_free()
		ground.queue_free()
		return "Bandit WalkSprite frames were not set up."
	for anim_name in [&"idle", &"walk"]:
		if not walk.sprite_frames.has_animation(anim_name):
			bandit.queue_free()
			ground.queue_free()
			return "Missing bandit animation: %s" % String(anim_name)
		if walk.sprite_frames.get_frame_count(anim_name) < 1:
			bandit.queue_free()
			ground.queue_free()
			return "Bandit animation has no frames: %s" % String(anim_name)
	if walk.sprite_frames.get_frame_count(&"walk") < 2:
		bandit.queue_free()
		ground.queue_free()
		return "Bandit walk needs at least two frames."
	# Let patrol move for a short stretch.
	var start_x := bandit.global_position.x
	for _i in range(12):
		await get_tree().physics_frame
	if absf(bandit.global_position.x - start_x) < 1.0:
		bandit.queue_free()
		ground.queue_free()
		return "Bandit did not patrol, so walk animation could not be verified."
	if walk.animation != &"walk" or not walk.is_playing():
		bandit.queue_free()
		ground.queue_free()
		return "Moving bandits must play the walk animation."
	# Park at the current spot so the next physics tick reports no travel.
	bandit.point_a = Vector2.ZERO
	bandit.point_b = Vector2.ZERO
	bandit._origin = bandit.global_position
	bandit._going_to_b = true
	for _i in range(4):
		await get_tree().physics_frame
	if walk.animation != &"idle":
		bandit.queue_free()
		ground.queue_free()
		return "Stationary bandits must return to the idle pose."
	bandit.queue_free()
	ground.queue_free()
	return null


func _test_skeleton_feet_on_ground() -> Variant:
	## Idle/walk frames must paint boots on the bottom row so STAND_FOOT_OFFSET lands on dirt.
	for path in [
		"res://assets/world/skeleton.png",
		"res://assets/world/skeleton_walk_0.png",
		"res://assets/world/skeleton_crystal.png",
	]:
		var tex := load(path) as Texture2D
		if tex == null:
			return "Missing skeleton asset: %s" % path
		var img := tex.get_image()
		if img == null:
			return "Could not read pixels for %s" % path
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		var bottom := img.get_height() - 1
		var solid_on_bottom := 0
		for x in range(img.get_width()):
			if img.get_pixel(x, bottom).a > 0.35:
				solid_on_bottom += 1
		if solid_on_bottom < 3:
			return "%s boots should reach the bottom row (found %d solid pixels)." % [
				path.get_file(), solid_on_bottom
			]
	return null


func _test_skeleton_tied_bow_transparent() -> Variant:
	## The pocket between boots and bow must stay see-through (no white/gray plate).
	for path in [
		"res://assets/world/skeleton_tied.png",
		"res://assets/world/skeleton_crystal_tied.png",
	]:
		var tex := load(path) as Texture2D
		if tex == null:
			return "Missing tied skeleton asset: %s" % path
		var img := tex.get_image()
		if img == null:
			return "Could not read pixels for %s" % path
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		var bright_fill := 0
		var probes := [
			Vector2i(40, 72), Vector2i(42, 71), Vector2i(38, 72), Vector2i(34, 71), Vector2i(44, 70),
		]
		for probe in probes:
			if probe.x >= img.get_width() or probe.y >= img.get_height():
				continue
			var c := img.get_pixel(probe.x, probe.y)
			if c.a < 0.2:
				continue
			var avg := (c.r + c.g + c.b) / 3.0
			var chroma := maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
			if avg >= 0.55 and chroma <= 0.12:
				bright_fill += 1
		if bright_fill > 0:
			return "%s still has a bright fill between boots and bow (%d probe hits)." % [
				path.get_file(), bright_fill
			]
	return null


func _test_skeleton_shoots_up_at_flyer() -> Variant:
	## Cave skeletons play shoot_up and fire angled arrows when Wings flyer is above.
	for path in [
		"res://assets/world/skeleton_shoot_up_0.png",
		"res://assets/world/skeleton_shoot_up_1.png",
		"res://assets/world/skeleton_crystal_shoot_up_0.png",
		"res://assets/world/skeleton_crystal_shoot_up_1.png",
	]:
		if load(path) == null:
			return "Missing skeleton shoot-up art: %s" % path
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	if packed == null:
		return "Missing opponent scene."
	var ground := StaticBody2D.new()
	ground.collision_layer = 1
	var ground_shape := CollisionShape2D.new()
	var ground_rect := RectangleShape2D.new()
	ground_rect.size = Vector2(600.0, 40.0)
	ground_shape.shape = ground_rect
	ground_shape.position = Vector2(400.0, 420.0)
	ground.add_child(ground_shape)
	add_child(ground)
	var skeleton := packed.instantiate() as Opponent
	skeleton.position = Vector2(400.0, 400.0)
	skeleton.point_a = Vector2.ZERO
	skeleton.point_b = Vector2.ZERO
	skeleton.apply_level_style(LevelStyle.CAVE)
	add_child(skeleton)
	await get_tree().process_frame
	var walk := skeleton.get_node_or_null("WalkSprite") as AnimatedSprite2D
	if walk == null or walk.sprite_frames == null or not walk.sprite_frames.has_animation(&"shoot_up"):
		skeleton.queue_free()
		ground.queue_free()
		return "Cave skeleton needs a shoot_up animation."
	if walk.sprite_frames.get_frame_count(&"shoot_up") < 2:
		skeleton.queue_free()
		ground.queue_free()
		return "shoot_up needs draw + release frames."
	var player := Player.new()
	player.name = "Player"
	player.position = Vector2(420.0, 180.0)
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	if not player.is_in_group("player"):
		player.add_to_group("player")
	player.activate_mode(ModeController.Mode.WINGS, 30.0)
	if not skeleton._can_shoot_at(player):
		player.queue_free()
		skeleton.queue_free()
		ground.queue_free()
		return "Skeleton should target a Wings flyer above it."
	if not skeleton._aim_up_at(player):
		player.queue_free()
		skeleton.queue_free()
		ground.queue_free()
		return "Flyer above should use upward aim."
	skeleton._shot_timer = 0.0
	skeleton._shoot_at(player)
	await get_tree().process_frame
	if walk.animation != &"shoot_up":
		player.queue_free()
		skeleton.queue_free()
		ground.queue_free()
		return "Upward shot should play the shoot_up pose."
	await get_tree().create_timer(0.55).timeout
	var arrow: BanditBullet = null
	for child in skeleton.get_parent().get_children():
		if child is BanditBullet:
			arrow = child as BanditBullet
			break
	var error: Variant = null
	if arrow == null:
		error = "Cave skeleton should spawn an arrow toward the flyer."
	elif arrow._aim.y >= -0.35:
		error = "Arrow at a flyer should travel upward (aim.y=%.2f)." % arrow._aim.y
	if arrow != null:
		arrow.queue_free()
	player.queue_free()
	skeleton.queue_free()
	ground.queue_free()
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
	WildWestTheme.apply_to_level(level)
	if (
		boarding.get_node_or_null("HandArt") == null
		or reward.get_node_or_null("HandArt") == null
	):
		level.free()
		return "Boots hop/reward ledges must use handcrafted plank art, not bare ColorRects."
	var boarding_visual := boarding.get_node_or_null("Visual") as CanvasItem
	if boarding_visual != null and boarding_visual.visible:
		level.free()
		return "BootsHopLedge ColorRect visual should be hidden under HandArt."

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


func _test_level_09_workshop_parity() -> Variant:
	var imported := CustomLevelStore.import_builtin(9)
	var objects: Array = imported.get("objects", [])
	var platforms := 0
	var diagonal_movers := 0
	var canyon_cells := 0
	var springs := 0
	var winds := 0
	for value in objects:
		var object := value as Dictionary
		var type_name := str(object.get("type", ""))
		match type_name:
			"platform":
				platforms += 1
			"mover", "moving_cloud":
				if absf(float(object.get("point_ay", 0.0))) > 1.0 \
					or absf(float(object.get("point_by", 0.0))) > 1.0:
					diagonal_movers += 1
			"canyon":
				canyon_cells += 1
			"spring":
				springs += 1
			"wind":
				winds += 1
	if platforms < 8:
		return "Level 9 workshop import should keep spring/hop ledges as platforms (got %d)." % platforms
	if diagonal_movers < 4:
		return "Level 9 workshop import should keep diagonal hop movers (got %d)." % diagonal_movers
	if canyon_cells < 8:
		return "Level 9 workshop import should fill canyon mouths across the gap (got %d cells)." % canyon_cells
	if springs < 5:
		return "Level 9 workshop import should keep gulch springs (got %d)." % springs
	if winds < 2:
		return "Level 9 workshop import should keep wind zones (got %d)." % winds
	# Rebuild must restore diagonal travel on movers.
	var level := LevelController.new()
	level.is_custom_level = true
	level.skip_auto_setup = true
	add_child(level)
	CustomLevelBuilder.build(level, imported, true)
	var rebuilt_diagonal := 0
	for node in level.find_children("*", "AnimatableBody2D", true, false):
		if not (node is MovingPlatform):
			continue
		var mover := node as MovingPlatform
		if absf(mover.point_a.y) > 1.0 or absf(mover.point_b.y) > 1.0:
			rebuilt_diagonal += 1
	level.queue_free()
	if rebuilt_diagonal < 4:
		return "Level 9 workshop rebuild should keep diagonal hop paths (got %d)." % rebuilt_diagonal
	return null


func _test_canyon_lips_not_walkable_over_sky() -> Variant:
	var packed: PackedScene = load("res://scenes/levels/level_09.tscn")
	if packed == null:
		return "Missing Level 09 scene."
	var level: Node = packed.instantiate()
	add_child(level)
	if level is LevelController:
		(level as LevelController).setup_level()
	await get_tree().process_frame
	await get_tree().physics_frame
	WildWestTheme.invalidate_walk_surface_cache()
	var merged := WildWestTheme._cached_merged_segments(level)
	var checked := 0
	var host := level as Node2D
	for i in range(merged.size() - 1):
		if not WildWestTheme._is_canyon_between(merged[i], merged[i + 1]):
			continue
		var left_lip := float(merged[i]["right"])
		var right_lip := float(merged[i + 1]["left"])
		if right_lip - left_lip < 40.0:
			continue
		var bank_top := minf(float(merged[i]["top"]), float(merged[i + 1]["top"]))
		for sample_x in [left_lip + 6.0, right_lip - 6.0]:
			checked += 1
			var hit_y := FloorProbe.hit_y(
				host,
				Vector2(sample_x, bank_top - 24.0),
				Vector2(sample_x, bank_top + 64.0),
				NAN
			)
			if not is_nan(hit_y) and absf(hit_y - bank_top) <= 20.0:
				level.queue_free()
				return "Canyon lip still walkable over sky at x=%.0f." % sample_x
	level.queue_free()
	if checked < 2:
		return "Level 09 should expose canyon mouths for lip checks."
	return null


func _test_ninja_walks_under_flyer() -> Variant:
	var left := StaticBody2D.new()
	left.collision_layer = 1
	left.position = Vector2(300, 420)
	var left_shape := CollisionShape2D.new()
	var left_rect := RectangleShape2D.new()
	left_rect.size = Vector2(600, 40)
	left_shape.shape = left_rect
	left.add_child(left_shape)
	add_child(left)

	var packed: PackedScene = load("res://scenes/world/ninja_enemy.tscn")
	if packed == null:
		left.queue_free()
		return "Missing ninja enemy scene."
	var ninja := packed.instantiate() as NinjaEnemy
	ninja.position = Vector2(200, 400)
	add_child(ninja)
	await get_tree().physics_frame
	ninja._state = NinjaEnemy.State.CHASE
	ninja._set_dormant(false)
	ninja._throw_timer = 1.0
	ninja._activated = true

	var player := Player.new()
	player.name = "Player"
	player.position = Vector2(420, 220)
	player.set_physics_process(false)
	add_child(player)
	player.get_modes().activate(ModeController.Mode.WINGS)
	await get_tree().physics_frame

	ninja.global_position = Vector2(200, 400)
	ninja._snap_feet_to_surface()
	var start_x := ninja.global_position.x
	for _i in range(30):
		await get_tree().physics_frame
		if ninja._state == NinjaEnemy.State.CHASE:
			ninja._handle_flying_player(player, 1.0 / 60.0)
	var moved := absf(ninja.global_position.x - start_x)
	player.queue_free()
	ninja.queue_free()
	left.queue_free()
	if moved < 8.0:
		return "Ninja should keep walking under a flying player between shuriken throws (moved %.1f)." % moved
	return null


func _test_ceiling_hangings_from_ceiling() -> Variant:
	if CustomLevelStore.placement_row("acid_drip", 4, 7) != 0:
		return "Acid drips must stamp on the ceiling row."
	if CustomLevelStore.placement_row("stalactite", 3, 7) != 0:
		return "Stalactites must stamp on the ceiling row."
	var data := {
		"width": 24,
		"height": 8,
		"grid": 40,
		"style": "cave",
		"spawn": [2, 7],
		"objects": [
			{"type": "ground", "x": 0, "y": 7},
			{"type": "ground", "x": 1, "y": 7},
			{"type": "ground", "x": 2, "y": 7},
			{"type": "ground", "x": 3, "y": 7},
			{"type": "ground", "x": 4, "y": 7},
			{"type": "ground", "x": 5, "y": 7},
			{"type": "acid_drip", "x": 3, "y": 0},
			{"type": "stalactite", "x": 4, "y": 0},
			{"type": "goal", "x": 5, "y": 6},
		],
	}
	var level := LevelController.new()
	level.is_custom_level = true
	level.skip_auto_setup = true
	add_child(level)
	CustomLevelBuilder.build(level, data, true)
	WildWestTheme.apply_to_level(level)
	await get_tree().process_frame
	await get_tree().physics_frame
	var found_drip: AcidDrip = null
	var found_spike: StalactiteHazard = null
	for node in level.find_children("*", "Area2D", true, false):
		if node is AcidDrip:
			found_drip = node as AcidDrip
		elif node is StalactiteHazard and (node as StalactiteHazard).drops:
			found_spike = node as StalactiteHazard
	if found_drip == null or found_spike == null:
		level.queue_free()
		return "Cave workshop should spawn acid drip and stalactite hangings."
	if found_drip.global_position.y > 120.0:
		level.queue_free()
		return "Acid drip should hang from the cave ceiling after theme snap."
	if found_spike.global_position.y > 120.0:
		level.queue_free()
		return "Stalactite should hang from the cave ceiling after theme snap."
	var spike_origin: Vector2 = found_spike.get("_origin")
	if absf(spike_origin.y - found_spike.global_position.y) > 1.0:
		level.queue_free()
		return "Stalactite origin must refresh after ceiling snap."
	var floor_y: float = found_spike.get("_floor_y")
	if is_nan(floor_y) or floor_y < found_spike.global_position.y + 80.0:
		level.queue_free()
		return "Stalactite floor probe must reach the trail/planks, not the flight ceiling."
	level.queue_free()
	return null


func _test_cowboy_climb_not_cowgirl() -> Variant:
	var cowboy := load("res://assets/player/climb_0.png") as Texture2D
	var cowgirl := load("res://assets/player/cowgirl/climb_0.png") as Texture2D
	if cowboy == null or cowgirl == null:
		return "Missing climb frames."
	var a := cowboy.get_image()
	var b := cowgirl.get_image()
	if a == null or b == null:
		return "Climb frames must be readable images."
	if a.get_width() != b.get_width() or a.get_height() != b.get_height():
		return null
	var diff := 0
	var samples := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			samples += 1
			if a.get_pixel(x, y) != b.get_pixel(x, y):
				diff += 1
	if float(diff) / float(maxi(samples, 1)) < 0.08:
		return "Cowboy climb_0.png still matches cowgirl climb art too closely."
	return null


func _test_level_09_gulch_clearance() -> Variant:
	var packed: PackedScene = load("res://scenes/levels/level_09.tscn")
	if packed == null:
		return "Missing Level 09 scene."
	var level: Node = packed.instantiate()
	add_child(level)
	if level is LevelController:
		(level as LevelController).setup_level()
	await get_tree().process_frame

	var floor_top := 320.0
	var min_clear := LevelLayoutRules.PLAYER_BODY_HEIGHT + LevelLayoutRules.WALK_CLEAR_PX
	var plank_bottom_max := floor_top - min_clear

	for node in level.find_children("*", "StaticBody2D", true, false):
		var name_text := String(node.name)
		if not name_text.contains("Ledge"):
			continue
		var surface := LevelLayoutRules._surface_for(node as Node2D)
		if surface.is_empty():
			continue
		var shape := (node as Node2D).get_node_or_null("CollisionShape2D") as CollisionShape2D
		var height := 32.0
		if shape != null and shape.shape is RectangleShape2D:
			height = (shape.shape as RectangleShape2D).size.y
		var center_x := (float(surface["left"]) + float(surface["right"])) * 0.5
		var plank_bottom := float(surface["top"]) + height
		if center_x < 1800.0 or center_x > 7200.0:
			continue
		if plank_bottom > plank_bottom_max + 0.5:
			level.queue_free()
			return (
				"%s blocks the gulch floor (bottom %.0f, need <= %.0f)."
				% [name_text, plank_bottom, plank_bottom_max]
			)

	# The final plank is optional: without a spring, the cowboy must have a
	# comfortable route under it on the real (possibly sloped) walk surface.
	var final_plank := level.get_node_or_null("SpringLedge5") as StaticBody2D
	if final_plank == null:
		level.queue_free()
		return "Level 09 needs its final optional plank."
	var final_surface := LevelLayoutRules._surface_for(final_plank)
	var final_shape := final_plank.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if final_surface.is_empty() or final_shape == null or not (final_shape.shape is RectangleShape2D):
		level.queue_free()
		return "Level 09 final plank needs rectangular collision."
	var final_center_x := (float(final_surface["left"]) + float(final_surface["right"])) * 0.5
	var final_walk_y := float(WildWestTheme.walk_surface_at(level, final_center_x)["y"])
	var final_bottom := (
		float(final_surface["top"])
		+ (final_shape.shape as RectangleShape2D).size.y
	)
	var final_clearance := final_walk_y - final_bottom
	if final_clearance < min_clear + 28.0:
		level.queue_free()
		return (
			"Level 09 final plank needs a clear route underneath (got %.0fpx, need %.0fpx)."
			% [final_clearance, min_clear + 28.0]
		)
	if level.get_node_or_null("Spring5") != null:
		level.queue_free()
		return "Level 09 final ground route must not force the cowboy onto Spring5."

	# Star boards SpringLedge0–4 need a spring within fair bounce reach (not stranded
	# across a slope/bull gap like the old Spring1 at x=1500 → ledge 1940).
	for index in range(5):
		var spring_node := level.get_node_or_null("Spring%d" % index) as Node2D
		var ledge_node := level.get_node_or_null("SpringLedge%d" % index) as Node2D
		if spring_node == null or ledge_node == null:
			level.queue_free()
			return "Level 09 is missing Spring%d / SpringLedge%d." % [index, index]
		var horiz := absf(ledge_node.global_position.x - spring_node.global_position.x)
		if horiz > 280.0:
			level.queue_free()
			return (
				"Spring%d is %.0fpx from SpringLedge%d — keep pads under the star boards."
				% [index, horiz, index]
			)

	for node in level.find_children("*", "Area2D", true, false):
		if not (node is SpringPad):
			continue
		var spring := node as Node2D
		var surface := WildWestTheme.walk_surface_at(level, spring.global_position.x)
		var walk_y := float(surface["y"])
		var angle := absf(float(surface["angle"]))
		if absf(spring.global_position.y - walk_y) > 10.0 or angle > 0.08:
			level.queue_free()
			return (
				"%s must sit on flat desert at x=%.0f (spring y=%.0f, walk y=%.0f, angle=%.2f)."
				% [spring.name, spring.global_position.x, spring.global_position.y, walk_y, angle]
			)

	level.queue_free()
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
		return "Canyon center must stay open sky between the ridges (no fill column)."
	if not canyon_art.rims_outside_floor():
		controller.queue_free()
		return "Canyon side walls overlap the desert floor; rims must sit outside the gap."
	if not canyon_art.rims_match_desert_height():
		controller.queue_free()
		return "Canyon rim desert top must align with the trail floor height."
	if not canyon_art.rims_reach_canyon_bottom():
		controller.queue_free()
		return "Canyon ridges must be full-height cliffs (top→bottom), not a short surface lip."
	if not canyon_art.rims_are_thin_faces():
		controller.queue_free()
		return "Canyon ridges must be thin canyon-facing faces, not full bank slabs."
	if not canyon_art.rim_bank_is_opaque_dirt():
		controller.queue_free()
		return "Canyon rim bank side must be opaque dirt so sky/abyss cannot show through."
	if not canyon_art.rim_sky_edge_is_irregular():
		controller.queue_free()
		return "Canyon rim sky edge must be jagged/irregular, not a ruler-straight cut."
	if not canyon_art.rim_crust_has_no_sky_slit():
		controller.queue_free()
		return "Canyon rim must seal under the sand crust (no sky slits)."
	if not canyon_art.interior_stays_inside_gap():
		controller.queue_free()
		return "Canyon mouth must not paint a sky-fill column over desert banks."
	var trail := controller.get_node_or_null("TrailFloor") as Node2D
	var abyss := trail.get_node_or_null("FloorAbyss") as Polygon2D if trail != null else null
	if abyss == null:
		controller.queue_free()
		return "TrailFloor/FloorAbyss missing; canyon cover order cannot be verified."
	if canyon_art.z_index <= abyss.z_index and not canyon_art.top_level:
		controller.queue_free()
		return "Canyon art must draw above FloorAbyss."
	if not canyon_art.top_level or canyon_art.z_index <= -2:
		controller.queue_free()
		return "CanyonMouth must be top_level above FloorAbyss (z > -2)."
	# Abyss only under banks — must not span the canyon mouth as a dark/blue column.
	var gap_mid := (canyon_art.gap_left + canyon_art.gap_right) * 0.5
	for abyss_node in trail.find_children("FloorAbyss*", "Polygon2D", false, false):
		var strip := abyss_node as Polygon2D
		var strip_right := _abyss_right_edge(strip)
		if strip.position.x < gap_mid and strip_right > gap_mid:
			controller.queue_free()
			return "FloorAbyss spans the canyon mouth; leave the gap open to Background sky."
	# No mountain / depth / floor / sky-fill inside the canyon — open sky only.
	if canyon_art.get_node_or_null("SkyWash") != null:
		controller.queue_free()
		return "Canyon must not paint a sky-fill column between the ridges."
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
	if hills.find_child("SkyPatch", true, false) != null:
		controller.queue_free()
		return "Canyon mouths must not use a sky-fill patch over the hills."
	if trail.find_child("CanyonAbyssSky0", true, false) != null:
		controller.queue_free()
		return "Canyon mouths must not use an abyss sky-fill column."
	# Mesa/backdrop hill tiles must not sit inside the canyon gap column.
	var gap_left := canyon_art.gap_left
	var gap_right := canyon_art.gap_right
	for tile in hills.find_children("HillTile*", "Sprite2D", false, false):
		var sprite := tile as Sprite2D
		var tex_w := 0.0
		if sprite.texture != null:
			tex_w = sprite.texture.get_size().x * absf(sprite.scale.x)
		var tile_left := sprite.position.x
		var tile_right := tile_left + tex_w
		if tile_left < gap_right - 1.0 and tile_right > gap_left + 1.0:
			controller.queue_free()
			return "Horizon hill / Mesa backdrop overlaps canyon gap column."
	# Canyon hazard must never show its reused cactus sprite in the mouth.
	var cactus_sprite := canyon.get_node_or_null("Sprite2D") as Sprite2D
	if cactus_sprite != null and (cactus_sprite.visible or cactus_sprite.texture != null):
		controller.queue_free()
		return "Canyon hazard still shows a cactus sprite inside the mouth."
	var left_rim := canyon_art.get_node("LeftRim") as Sprite2D
	if canyon_art.z_index < 1:
		controller.queue_free()
		return "Canyon ridges must draw in front of the desert floor tiles."
	if left_rim.z_index < 1:
		controller.queue_free()
		return "Canyon rim sprites must sit above the open mouth."
	var trail_surface_z := 1
	if canyon_art.z_index <= trail_surface_z:
		controller.queue_free()
		return "CanyonMouth z_index must be above TrailFloor surface (z > %d)." % trail_surface_z
	# Widening must not stretch ridge WIDTH past the handmade max (height stays full).
	var max_rim_scale_x := ScalableCanyonArt.RIM_SIZE.x / left_rim.texture.get_size().x
	var wide_right := canyon_art.gap_right + 700.0
	canyon_art.configure(canyon_art.floor_top, canyon_art.gap_left, wide_right)
	var wide_scale := (canyon_art.get_node("LeftRim") as Sprite2D).scale
	if wide_scale.x > max_rim_scale_x + 0.01:
		controller.queue_free()
		return "Widening the canyon stretched the handmade rim."
	if not canyon_art.rims_reach_canyon_bottom():
		controller.queue_free()
		return "Wide canyon lost full-height ridge coverage."
	if not canyon_art.center_is_illustrated():
		controller.queue_free()
		return "Wide canyon lost open-sky center treatment."
	if not canyon_art.rims_outside_floor():
		controller.queue_free()
		return "Wide canyon rims drifted over the desert floor."
	if not canyon_art.interior_stays_inside_gap():
		controller.queue_free()
		return "Wide canyon gained a sky-fill column."
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


func _test_ladder_branch_upper_ledge() -> Variant:
	# Stamp math: ledge center must match climb_top so feet exit onto the plank.
	var trail := 9
	var objects: Array[Dictionary] = []
	CustomLevelStore.append_ladder_branch(objects, trail, 20)
	var ladder_obj: Dictionary = {}
	var ledge_at_ladder: Dictionary = {}
	for value in objects:
		var object := value as Dictionary
		var type_name := str(object.get("type", ""))
		if type_name == "ladder":
			ladder_obj = object
		elif type_name == "ladder_ledge" and int(object.get("x", -1)) == 20:
			ledge_at_ladder = object
	if ladder_obj.is_empty() or ledge_at_ladder.is_empty():
		return "Ladder branch must place a ladder and a ledge on the same column."
	var expected_upper := trail - CustomLevelStore.LADDER_HEIGHT_CELLS
	if int(ledge_at_ladder.get("y", -1)) != expected_upper:
		return "Ladder ledge row should be trail - LADDER_HEIGHT_CELLS (got %d, expected %d)." % [
			int(ledge_at_ladder.get("y", -1)), expected_upper
		]
	var grid := CustomLevelStore.GRID_SIZE
	var ladder_pos := CustomLevelStore.object_world_position(ladder_obj, grid, trail)
	var ledge_pos := CustomLevelStore.object_world_position(ledge_at_ladder, grid, trail)
	var climb_top := ladder_pos.y - float(CustomLevelStore.LADDER_HEIGHT_CELLS) * grid
	if absf(ledge_pos.y - climb_top) > 0.5:
		return "Ledge center (%.1f) must align with climb_top (%.1f)." % [ledge_pos.y, climb_top]
	var plank_top := ledge_pos.y - 12.0
	var exit_y := climb_top - 14.0
	if exit_y > plank_top + 0.5:
		return "Climb exit (%.1f) must land at or above plank top (%.1f)." % [exit_y, plank_top]

	# Legacy packs: one-cell-too-high ledges realign on sanitize.
	var legacy: Array = [
		{"type": "ground", "x": 0, "y": trail},
		{"type": "ladder", "x": 10, "y": trail - 1},
		{"type": "ladder_ledge", "x": 10, "y": trail - 1 - CustomLevelStore.LADDER_HEIGHT_CELLS},
		{"type": "goal", "x": 20, "y": trail - 1},
	]
	var pack := {
		"version": CustomLevelStore.VERSION,
		"height": trail + 1,
		"width": 24,
		"objects": legacy,
		"spawn": [2, trail],
	}
	var cleaned := CustomLevelStore.sanitize(pack, CustomLevelStore.EXTRA_SLOT_START)
	var fixed_y := -1
	for value in cleaned.get("objects", []):
		var object := value as Dictionary
		if str(object.get("type", "")) == "ladder_ledge" and int(object.get("x", -1)) == 10:
			fixed_y = int(object.get("y", -1))
	if fixed_y != expected_upper:
		return "Sanitize should realign legacy ladder ledges to row %d (got %d)." % [expected_upper, fixed_y]

	# Cave campaign levels and default trails must pass ladder-top layout rules.
	for level_number in [11, 12, 13, 14, 15]:
		var data := CaveCampaignLevels.level_data(level_number)
		var level := LevelController.new()
		add_child(level)
		CustomLevelBuilder.build(level, data)
		await get_tree().process_frame
		var errors := LevelLayoutRules._validate_ladder_tops(level)
		level.queue_free()
		await get_tree().process_frame
		if not errors.is_empty():
			return "Cave level %d: %s" % [level_number, errors[0]]

	var default_data := CustomLevelStore.default_level(CustomLevelStore.EXTRA_SLOT_START)
	var default_level := LevelController.new()
	add_child(default_level)
	CustomLevelBuilder.build(default_level, default_data)
	await get_tree().process_frame
	var default_errors := LevelLayoutRules._validate_ladder_tops(default_level)
	default_level.queue_free()
	if not default_errors.is_empty():
		return "Default workshop trail: %s" % default_errors[0]
	return null


func _test_cave_levels_belts_fences_ladders() -> Variant:
	## Cave arc should keep extra climb routes and ranch props kids already know — but no gates.
	var expected := {
		11: {"ladders": 2, "platforms": 3, "fences": 3, "conveyors": 0, "doors": 0, "drips": 3, "springs": 2, "stars": 10},
		12: {"ladders": 2, "platforms": 3, "fences": 2, "conveyors": 1, "doors": 0, "drips": 5, "springs": 3, "stars": 10},
		13: {"ladders": 1, "platforms": 5, "fences": 2, "conveyors": 1, "doors": 0, "drips": 6, "springs": 3, "stars": 10},
		14: {"ladders": 3, "platforms": 6, "fences": 3, "conveyors": 1, "doors": 0, "drips": 5, "springs": 4, "stars": 12},
		15: {"ladders": 1, "platforms": 8, "fences": 2, "conveyors": 1, "doors": 0, "drips": 4, "springs": 3, "stars": 14},
		16: {"ladders": 2, "platforms": 6, "fences": 3, "conveyors": 1, "doors": 0, "drips": 5, "springs": 4, "stars": 12},
	}
	for level_number in expected.keys():
		var data := CaveCampaignLevels.level_data(int(level_number))
		var counts := {
			"ladders": 0,
			"platforms": 0,
			"fences": 0,
			"conveyors": 0,
			"doors": 0,
			"drips": 0,
			"springs": 0,
			"stars": 0,
		}
		for value in data.get("objects", []):
			var type_name := str((value as Dictionary).get("type", ""))
			match type_name:
				"ladder":
					counts["ladders"] += 1
				"platform", "ladder_ledge":
					counts["platforms"] += 1
				"fence":
					counts["fences"] += 1
				"conveyor":
					counts["conveyors"] += 1
				"timed_door":
					counts["doors"] += 1
				"acid_drip":
					counts["drips"] += 1
				"spring":
					counts["springs"] += 1
				"star":
					counts["stars"] += 1
		var want: Dictionary = expected[level_number]
		for key in want.keys():
			if int(counts[key]) < int(want[key]):
				return "Cave level %d expected >= %d %s (got %d)." % [
					int(level_number), int(want[key]), key, int(counts[key])
				]
		if int(counts["doors"]) > 0:
			return "Cave level %d should carry no ranch gates (found %d)." % [
				int(level_number), int(counts["doors"])
			]
		var level := LevelController.new()
		add_child(level)
		CustomLevelBuilder.build(level, data)
		await get_tree().process_frame
		WildWestTheme.apply_to_level(level)
		await get_tree().process_frame
		var fence := level.find_child("FenceDecor0", true, false) as CanvasItem
		if fence == null or not fence.visible:
			level.queue_free()
			await get_tree().process_frame
			return "Cave level %d should keep stamped fence décor visible." % int(level_number)
		var layout_errors: PackedStringArray = []
		layout_errors.append_array(LevelLayoutRules._validate_ladder_tops(level))
		layout_errors.append_array(LevelLayoutRules._validate_stars(level))
		layout_errors.append_array(LevelLayoutRules._validate_no_doors_in_caves(level))
		layout_errors.append_array(LevelLayoutRules._validate_conveyors_not_pushing_into_canyons(level))
		layout_errors.append_array(LevelLayoutRules._validate_cactus_clear_of_springs(level))
		layout_errors.append_array(LevelLayoutRules._validate_canyon_up_needs_spring(level))
		level.queue_free()
		await get_tree().process_frame
		if not layout_errors.is_empty():
			return "Cave level %d layout: %s" % [int(level_number), layout_errors[0]]
	return null


func _test_horse_theme_bans_items_and_chests() -> Variant:
	## Horse play theme mounts the cowboy and strips chests / mode pickups.
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(CustomLevelStore.EXTRA_SLOT_START)
	data["start_mounted"] = true
	data["style"] = CustomLevelStore.STYLE_DESERT
	var horse_objects: Array = []
	for x in range(0, 16):
		horse_objects.append({"type": "ground", "x": x, "y": trail})
	horse_objects.append_array([
		{"type": "chest", "x": 4, "y": trail - 1},
		{"type": "wings", "x": 5, "y": trail - 1},
		{"type": "boots", "x": 6, "y": trail - 1},
		{"type": "speed", "x": 7, "y": trail - 1},
		{"type": "shield", "x": 8, "y": trail - 1},
		{"type": "star", "x": 9, "y": trail - 1},
		{"type": "checkpoint", "x": 10, "y": trail - 1},
		{"type": "goal", "x": 12, "y": trail - 1},
	])
	data["objects"] = horse_objects
	var cleaned := CustomLevelStore.sanitize(data, CustomLevelStore.EXTRA_SLOT_START)
	if not bool(cleaned.get("start_mounted", false)):
		return "Horse theme sanitize should keep start_mounted."
	var kept_star := false
	var kept_camp := false
	for value in cleaned.get("objects", []):
		var type_name := str((value as Dictionary).get("type", ""))
		if CustomLevelStore.is_mounted_banned(type_name):
			return "Sanitize should strip %s from horse trails." % type_name
		if type_name == "star":
			kept_star = true
		elif type_name == "checkpoint":
			kept_camp = true
	if not kept_star or not kept_camp:
		return "Horse trails should keep badges and camps."

	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, cleaned)
	await get_tree().process_frame
	var player := level.find_child("Player", true, false) as Player
	var error: Variant = null
	if player == null or not player.start_mounted:
		error = "Horse theme builds should spawn the cowboy mounted."
	elif level.find_child("CustomChest0", true, false) != null:
		error = "Horse theme builds must not spawn treasure chests."
	elif not level.find_children("*", "ModeItem", true, false).is_empty():
		error = "Horse theme builds must not spawn power-up items."
	level.queue_free()
	return error


func _test_workshop_default_width() -> Variant:
	var builtin := CustomLevelStore.import_builtin(1)
	var draft := CustomLevelStore.default_level(CustomLevelStore.EXTRA_SLOT_START)
	var extra := CustomLevelStore.new_extra_draft(5)
	if int(builtin.get("width", 0)) != CustomLevelStore.DEFAULT_WIDTH:
		return "Imported built-in trails should resolve to the workshop default width."
	if int(draft.get("width", 0)) != int(builtin.get("width", 0)):
		return "Default workshop trails should match built-in campaign width."
	if extra.is_empty() or int(extra.get("width", 0)) != int(builtin.get("width", 0)):
		return "New extra drafts should match built-in campaign width."
	return null


func _test_workshop_trail_length_resize() -> Variant:
	var slot := CustomLevelStore.SLOT_COUNT - 4
	var data := CustomLevelStore.default_level(slot)
	var start_width := int(data.get("width", 0)) - CustomLevelStore.WIDTH_STEP
	data = CustomLevelStore.resize_width(data, start_width, slot)
	start_width = int(data.get("width", 0))
	var widened := CustomLevelStore.resize_width(data, start_width + CustomLevelStore.WIDTH_STEP, slot)
	if int(widened.get("width", 0)) != start_width + CustomLevelStore.WIDTH_STEP:
		return "Adding length should extend the trail width."
	var trail := CustomLevelStore.trail_row(int(widened.get("height", 8)))
	var has_new_ground := false
	for value in widened.get("objects", []):
		var object := value as Dictionary
		if str(object.get("type", "")) == "ground" and int(object.get("x", -1)) == start_width:
			has_new_ground = true
			if int(object.get("y", -1)) != trail:
				return "New length columns should fill with trail-row dirt."
	if not has_new_ground:
		return "Adding length should stamp dirt on new columns."
	var narrowed := CustomLevelStore.resize_width(widened, start_width, slot)
	if int(narrowed.get("width", 0)) != start_width:
		return "Removing length should shrink the trail width."
	for value in narrowed.get("objects", []):
		var object := value as Dictionary
		if int(object.get("x", -1)) >= start_width:
			return "Removing length should clear trailing columns."
	if CustomLevelStore.resize_width(data, CustomLevelStore.MIN_WIDTH - 1, slot).get("width", 0) != CustomLevelStore.MIN_WIDTH:
		return "Trail width should clamp to the documented minimum."
	if CustomLevelStore.resize_width(data, CustomLevelStore.MAX_WIDTH + 1, slot).get("width", 0) != CustomLevelStore.MAX_WIDTH:
		return "Trail width should clamp to the documented maximum."
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
	var trail_floor := level.get_node_or_null("TrailFloor") as Node2D
	if trail_floor != null:
		for abyss_node in trail_floor.find_children("FloorAbyss*", "ColorRect", false, false):
			level.free()
			return "FloorAbyss must use Polygon2D, not ColorRect (Controls draw over slopes)."
		var abyss_poly := trail_floor.get_node_or_null("FloorAbyss") as Polygon2D
		var crust := level.find_child("FloorSlope0_0", true, false) as Sprite2D
		if abyss_poly != null and crust != null and crust.z_index <= abyss_poly.z_index:
			level.free()
			return "Desert slope crust must draw above FloorAbyss earth fill."
	# Curved dune collision (smoothstep) — more than a 4-point linear ramp.
	var slope_body := level.find_child("FloorSlopeBody0", true, false) as StaticBody2D
	if slope_body != null:
		var col := slope_body.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
		if col == null or col.polygon.size() < 8:
			level.free()
			return "Desert slopes should use a curved collision polygon, not a straight ramp."
		# Ends must sit on the flat desert tops (zero-ish end grade via smoothstep).
		var first: Vector2 = col.polygon[0]
		var mid_i := int(col.polygon.size() / 4)
		var mid: Vector2 = col.polygon[mid_i]
		var last_top: Vector2 = col.polygon[int(col.polygon.size() / 2) - 1]
		var end_run := absf(last_top.x - first.x)
		if end_run < 40.0:
			level.free()
			return "Walkable dunes need a gentle run (start/end on desert level)."
		var total_drop := absf(last_top.y - first.y)
		if total_drop > 1.0:
			var peak_grade := total_drop / end_run
			# Smoothstep dunes peak ~1.5× average; linear dunes use average.
			if col.polygon.size() >= 12:
				peak_grade *= 1.5
			if peak_grade > tan(deg_to_rad(55.0)):
				level.free()
				return "Desert dunes are too steep to walk — lengthen the run."
		var mid_drop := absf(mid.y - first.y)
		if total_drop > 1.0 and mid_drop < total_drop * 0.15:
			level.free()
			return "Desert slope mid-point should follow a curved dune profile."
		# High-bank Ground cliff must be carved so the dune is not blocked.
		var high_y := minf(first.y, last_top.y)
		var rising_right := first.y > last_top.y
		var carved := false
		for ground_body in level.find_children("Ground*", "StaticBody2D", true, false):
			var shape_node := (ground_body as Node).get_node_or_null("CollisionShape2D") as CollisionShape2D
			if shape_node == null:
				continue
			if shape_node.disabled:
				carved = true
				continue
			if not (shape_node.shape is RectangleShape2D):
				continue
			var rect := shape_node.shape as RectangleShape2D
			var center := shape_node.global_position
			var top := center.y - rect.size.y * 0.5
			if absf(top - high_y) > 18.0:
				continue
			var left := center.x - rect.size.x * 0.5
			var right := center.x + rect.size.x * 0.5
			if rising_right and left >= last_top.x - 8.0:
				carved = true
			elif (not rising_right) and right <= first.x + 8.0:
				carved = true
		if not carved and total_drop > 20.0:
			level.free()
			return "Ground cliff walls must be carved open so dunes are walkable."
	level.free()
	# Height difference across a canyon must NOT get a bridging slope — canyon is the step.
	var canyon_step := CustomLevelStore.default_level(slot)
	canyon_step["objects"] = [
		{"type": "ground", "x": 2, "y": trail},
		{"type": "ground", "x": 2, "y": trail - 1},
		{"type": "canyon", "x": 3, "y": trail},
		{"type": "ground", "x": 4, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var canyon_level := LevelController.new()
	CustomLevelBuilder.build(canyon_level, canyon_step)
	WildWestTheme.apply_to_level(canyon_level)
	var canyon_slope_errors := LevelLayoutRules._validate_no_slopes_across_canyons(canyon_level)
	var canyon_has_slope := false
	for node in canyon_level.find_children("FloorSlope*", "Node", true, false):
		canyon_has_slope = true
		break
	if canyon_has_slope or not canyon_slope_errors.is_empty():
		var detail := canyon_slope_errors[0] if not canyon_slope_errors.is_empty() else "FloorSlope* present across canyon"
		canyon_level.free()
		return "Canyon-separated banks must not paint a desert slope: %s" % detail
	canyon_level.free()
	# Adjacent canyon stamps on the trail row merge into one wider hazard gap.
	var merged_canyon := CustomLevelStore.default_level(slot)
	merged_canyon["objects"] = [
		{"type": "ground", "x": 0, "y": trail},
		{"type": "ground", "x": 6, "y": trail},
		{"type": "canyon", "x": 1, "y": trail},
		{"type": "canyon", "x": 2, "y": trail},
		{"type": "canyon", "x": 3, "y": trail},
		{"type": "goal", "x": 5, "y": trail},
	]
	var merged_level := LevelController.new()
	CustomLevelBuilder.build(merged_level, merged_canyon)
	WildWestTheme.apply_to_level(merged_level)
	var canyon_hazards := 0
	for node in merged_level.find_children("*", "Area2D", true, false):
		if node is Hazard and (node as Hazard).is_canyon():
			canyon_hazards += 1
	if canyon_hazards != 1:
		merged_level.free()
		return "Adjacent canyon stamps should merge into one hazard, got %d." % canyon_hazards
	var merged_segments := WildWestTheme._merge_segments(
		WildWestTheme._collect_ground_segments(merged_level)
	)
	if merged_segments.size() < 2:
		merged_level.free()
		return "Merged canyon run should leave two dirt banks."
	var gap_w := float(merged_segments[1]["left"]) - float(merged_segments[0]["right"])
	if gap_w < 100.0:
		merged_level.free()
		return "Adjacent canyon stamps should widen the gap (got %.0fpx)." % gap_w
	merged_level.free()
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
	var level2_abyss := level2_trail.get_node_or_null("FloorAbyss") as Polygon2D if level2_trail != null else null
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
	# FloorAbyss must stay a CanvasItem so slope crust z_index wins over earth fill.
	for abyss_node in level2_trail.find_children("FloorAbyss*", "ColorRect", false, false):
		level2_controller.queue_free()
		return "FloorAbyss must use Polygon2D, not ColorRect (Controls draw over slopes)."
	var slope_crust := level2_controller.find_child("FloorSlope0_0", true, false) as Sprite2D
	if slope_crust != null and slope_crust.z_index <= level2_abyss.z_index:
		level2_controller.queue_free()
		return "Desert slope crust must draw above FloorAbyss earth fill."
	# Canyon beside the raised plateau should match each bank lip height.
	var pit6 := level2_controller.find_child("Pit6", true, false) as Hazard
	if pit6 != null:
		var pit6_art := pit6.get_node_or_null("CanyonMouth") as ScalableCanyonArt
		if pit6_art == null:
			pit6_art = pit6.get_node_or_null("PitMouth") as ScalableCanyonArt
		if pit6_art != null and not pit6_art.rims_match_desert_height():
			level2_controller.queue_free()
			return "Level 2 Pit6 canyon rims must match adjacent desert bank heights."
		# Raised left plateau (~280) must lift the left ridge — no abyss band above it.
		if pit6_art != null and float(pit6_art.left_floor_top) > 300.0:
			level2_controller.queue_free()
			return (
				"Level 2 Pit6 left ridge should start at the raised bank top (got y=%.1f)."
				% float(pit6_art.left_floor_top)
			)
	# Height steps should use trail tiles, not flat polygon fills.
	for node in level2_controller.find_children("FloorSlopeFill*", "Polygon2D", true, false):
		level2_controller.queue_free()
		return "Desert slopes must not use flat Polygon2D fills."
	level2_controller.queue_free()
	return null


func _test_workshop_ground_prop_offset() -> Variant:
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(0)
	data["objects"] = [
		{"type": "ground", "x": 4, "y": trail},
		{"type": "bandit", "x": 4, "y": trail},
	]
	var cleaned := CustomLevelStore.sanitize(data, 0)
	var stored_y := -1
	for value in cleaned.get("objects", []):
		var object := value as Dictionary
		if str(object.get("type", "")) == "bandit" and int(object.get("x", -1)) == 4:
			stored_y = int(object.get("y", -1))
	if stored_y != trail - 1:
		return "Ground props clicked on dirt should store one row above the trail (got y=%d)." % stored_y
	var level := LevelController.new()
	CustomLevelBuilder.build(level, cleaned)
	var bandit := level.find_child("Opponent0", true, false) as Opponent
	if bandit == null:
		level.free()
		return "Workshop builder should spawn the bandit."
	var expected_floor := float(trail) * 40.0
	if absf(bandit.global_position.y - expected_floor) > 2.5:
		level.free()
		return "Bandit feet should sit on the trail surface (y=%.1f, expected %.1f)." % [
			bandit.global_position.y, expected_floor
		]
	level.free()
	return null


func _test_workshop_stamp_catalog() -> Variant:
	GameManager.active_custom_slot = CustomLevelStore.EXTRA_SLOT_START
	var editor_packed: PackedScene = load("res://scenes/ui/level_editor.tscn")
	if editor_packed == null:
		return "Missing level editor scene."
	var editor := editor_packed.instantiate()
	add_child(editor)
	await get_tree().process_frame
	var palette_types: PackedStringArray = []
	var categories: Array = editor.get("_tool_categories") as Array
	if categories.is_empty():
		categories = LevelStyle.tool_categories(LevelStyle.DESERT)
	for category in categories:
		for tool in (category as Dictionary).get("tools", []) as Array:
			palette_types.append(str((tool as Array)[0]))
	var style_dropdown := editor.find_child("LevelStyle", true, false) as OptionButton
	editor.queue_free()
	if style_dropdown == null or style_dropdown.item_count < 3:
		return "Workshop editor needs a Desert/Cave/Horse level style picker."
	var required_desert := [
		"ground", "canyon", "platform", "ladder", "spring", "conveyor", "timed_door", "fence",
		"mover", "moving_cloud", "blink_cloud", "wind",
		"star", "chest", "checkpoint",
		"cactus", "pit", "rattlesnake",
		"bandit", "bounty_bandit", "bull", "ninja", "carrion",
		"wings", "boots", "shield",
		"goal", "erase",
	]
	for type_name in required_desert:
		if type_name not in palette_types:
			return "Workshop palette missing %s stamp." % type_name
	for unused_type in ["scorpion", "speed", "stalactite_static", "ladder_ledge"]:
		if unused_type in palette_types:
			return "Workshop should not offer unused stamp %s." % unused_type
	var desert_categories := LevelStyle.tool_categories(LevelStyle.DESERT)
	var desert_hazard_types: PackedStringArray = []
	var desert_enemy_types: PackedStringArray = []
	var desert_trail_types: PackedStringArray = []
	var desert_powerup_types: PackedStringArray = []
	for category in desert_categories:
		var category_id := str((category as Dictionary).get("id", ""))
		for tool in (category as Dictionary).get("tools", []) as Array:
			var type_name := str((tool as Array)[0])
			if category_id == "hazards":
				desert_hazard_types.append(type_name)
			elif category_id == "enemies":
				desert_enemy_types.append(type_name)
			elif category_id == "trail":
				desert_trail_types.append(type_name)
			elif category_id == "powerups":
				desert_powerup_types.append(type_name)
	for type_name in ["cactus", "pit", "rattlesnake"]:
		if type_name not in desert_hazard_types:
			return "Stationary threat %s should be in the Hazards category." % type_name
	for type_name in ["bandit", "bounty_bandit", "bull", "ninja", "carrion"]:
		if type_name not in desert_enemy_types:
			return "Moving enemy %s should be in the Enemies category." % type_name
	if "spring" in desert_hazard_types or "spring" not in desert_trail_types:
		return "Helpful springs belong with trail traversal, not Hazards."
	if "rattlesnake" in desert_enemy_types:
		return "Stationary rattlesnakes belong in Hazards, not Enemies."
	for type_name in ["wings", "boots", "shield"]:
		if type_name not in desert_powerup_types:
			return "Campaign power-up %s should stay in the Power-ups palette." % type_name
	if "speed" in desert_powerup_types:
		return "Speed Stars are chest/boss loot only — omit the unused trail stamp."
	var cave_categories := LevelStyle.tool_categories(LevelStyle.CAVE)
	var cave_hazard_types: PackedStringArray = []
	var cave_enemy_types: PackedStringArray = []
	for category in cave_categories:
		var category_id := str((category as Dictionary).get("id", ""))
		for tool in (category as Dictionary).get("tools", []) as Array:
			var type_name := str((tool as Array)[0])
			if category_id == "hazards":
				cave_hazard_types.append(type_name)
			elif category_id == "enemies":
				cave_enemy_types.append(type_name)
	if "scorpion" in cave_enemy_types or "scorpion" in cave_hazard_types:
		return "Cave palette should keep the remapped rattlesnake stamp instead of a duplicate scorpion tool."
	for type_name in ["acid_drip", "stalactite"]:
		if type_name not in cave_hazard_types:
			return "Cave environmental threat %s should be in Hazards." % type_name
	if "stalactite_static" in cave_hazard_types or "stalactite_static" in cave_enemy_types:
		return "Static ceiling spikes are auto décor, not a workshop stamp."
	if "bat" not in cave_enemy_types:
		return "Cave bats are roaming enemies and belong under Enemies."
	for type_name in ["conveyor", "timed_door", "fence", "mover", "moving_cloud", "blink_cloud", "wind"]:
		if type_name not in palette_types:
			return "Workshop palette missing %s stamp." % type_name
	var cave_palette: PackedStringArray = []
	for category in LevelStyle.tool_categories(LevelStyle.CAVE):
		for tool in (category as Dictionary).get("tools", []) as Array:
			cave_palette.append(str((tool as Array)[0]))
	for type_name in ["acid_drip", "stalactite", "bat", "conveyor", "fence", "mover", "wind"]:
		if type_name not in cave_palette:
			return "Cave style palette missing %s stamp." % type_name
	if "timed_door" in cave_palette:
		return "Cave palette must not offer ranch gates; caves have no doors."
	if "stalactite_static" in cave_palette or "speed" in cave_palette:
		return "Cave palette must not expose unused static-spike or Speed Star stamps."
	var horse_palette: PackedStringArray = []
	for category in LevelStyle.tool_categories(LevelStyle.DESERT, true):
		for tool in (category as Dictionary).get("tools", []) as Array:
			horse_palette.append(str((tool as Array)[0]))
	for banned in ["chest", "wings", "boots", "speed", "shield"]:
		if banned in horse_palette:
			return "Horse theme palette must not offer %s." % banned
	if "star" not in horse_palette or "checkpoint" not in horse_palette:
		return "Horse theme should still allow badges and camps."
	if "mover" not in horse_palette or "wind" not in horse_palette:
		return "Horse theme should still allow motion stamps."
	var trail := CustomLevelStore.trail_row(8)
	for type_name in [
		"bounty_bandit", "carrion", "chest", "bull", "ninja", "acid_drip", "stalactite",
		"stalactite_static", "bat", "conveyor", "timed_door", "fence", "mover", "moving_cloud",
		"blink_cloud", "wind", "scorpion", "speed",
	]:
		if not CustomLevelStore._valid_object({"type": type_name, "x": 1, "y": trail - 1}, trail):
			return "%s should remain accepted by CustomLevelStore for imports." % type_name
	# Motion stamps must build into real gameplay nodes (ceiling height stays automated).
	var motion_data := CustomLevelStore.default_level(0)
	motion_data["objects"] = [
		{"type": "ground", "x": 2, "y": trail},
		{"type": "mover", "x": 8, "y": trail - 3},
		{"type": "moving_cloud", "x": 14, "y": trail - 3},
		{"type": "blink_cloud", "x": 20, "y": trail - 3},
		{"type": "wind", "x": 26, "y": trail - 2},
		{"type": "goal", "x": 30, "y": trail - 1},
	]
	var motion_level := LevelController.new()
	add_child(motion_level)
	CustomLevelBuilder.build(motion_level, motion_data)
	await get_tree().process_frame
	var motion_error: Variant = null
	if motion_level.find_child("Mover0", true, false) == null:
		motion_error = "Builder should spawn a moving plank from the mover stamp."
	elif motion_level.find_child("MovingCloud0", true, false) == null:
		motion_error = "Builder should spawn a moving cloud from the moving_cloud stamp."
	elif motion_level.find_child("BlinkCloud0", true, false) == null:
		motion_error = "Builder should spawn a blink cloud from the blink_cloud stamp."
	elif motion_level.find_child("Wind0", true, false) == null:
		motion_error = "Builder should spawn a wind zone from the wind stamp."
	motion_level.queue_free()
	await get_tree().process_frame
	if motion_error != null:
		return motion_error
	var data := CustomLevelStore.default_level(0)
	var catalog_objects: Array = []
	for x in range(0, 32):
		catalog_objects.append({"type": "ground", "x": x, "y": trail})
	catalog_objects.append_array([
		{"type": "bounty_bandit", "x": 2, "y": trail - 1},
		{"type": "carrion", "x": 6, "y": trail - 3},
		{"type": "chest", "x": 10, "y": trail - 1},
		{"type": "bull", "x": 12, "y": trail - 1},
		{"type": "ninja", "x": 14, "y": trail - 1},
		{"type": "conveyor", "x": 18, "y": trail - 1, "push_right": true},
		{"type": "timed_door", "x": 22, "y": trail - 1},
		{"type": "fence", "x": 26, "y": trail - 1},
	])
	data["objects"] = catalog_objects
	var level := LevelController.new()
	CustomLevelBuilder.build(level, data)
	var bounty := level.find_child("Opponent0", true, false) as Opponent
	if bounty == null or not bounty.bounty_bandit:
		level.free()
		return "Builder should spawn a bounty bandit from the bounty stamp."
	if level.find_child("Carrion0", true, false) == null:
		level.free()
		return "Builder should spawn carrion birds from the carrion stamp."
	if level.find_child("Conveyor0", true, false) == null:
		level.free()
		return "Builder should spawn a conveyor from the belt stamp."
	if level.find_child("Door0", true, false) == null:
		level.free()
		return "Builder should spawn a timed door from the gate stamp."
	if level.find_child("FenceDecor0", true, false) == null:
		level.free()
		return "Builder should spawn fence décor from the fence stamp."
	var chest := level.find_child("CustomChest0", true, false) as TreasureChest
	if chest == null:
		level.free()
		return "Builder should spawn a treasure chest from the chest stamp."
	var expected_floor := float(trail) * 40.0
	if absf(chest.global_position.y - expected_floor) > 2.5:
		level.free()
		return "Workshop chest should stand on the trail surface (y=%.1f, expected %.1f)." % [
			chest.global_position.y, expected_floor
		]
	if level.find_child("Bull0", true, false) as BullEnemy == null:
		level.free()
		return "Builder should spawn a bull from the bull stamp."
	if level.find_child("Ninja0", true, false) as NinjaEnemy == null:
		level.free()
		return "Builder should spawn a ninja from the ninja stamp."
	level.free()
	return null


func _test_fixed_pit_art() -> Variant:
	var slot := CustomLevelStore.EXTRA_SLOT_START + 1
	var data := CustomLevelStore.default_level(slot)
	var trail := CustomLevelStore.trail_row(int(data.get("height", 8)))
	data["objects"].append({"type": "pit", "x": 20, "y": trail})
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	var pit: Hazard = null
	for node in level.find_children("*", "Area2D", true, false):
		if node is Hazard and (node as Hazard).is_pit():
			pit = node as Hazard
			break
	if pit == null:
		level.free()
		return "Builder should spawn a fixed pit hazard."
	var pit_sprite := pit.get_node_or_null("PitVisual") as Sprite2D
	if pit_sprite == null or not pit_sprite.visible:
		level.free()
		return "Fixed pit should show PitVisual."
	if pit_sprite.texture != preload("res://assets/world/pit.png"):
		level.free()
		return "Fixed pit should use pit.png."
	if pit_sprite.scale != Vector2.ONE:
		level.free()
		return "Fixed pit must stay at native 1:1 scale (got %s)." % str(pit_sprite.scale)
	var tex_size := Vector2(float(pit_sprite.texture.get_width()), float(pit_sprite.texture.get_height()))
	if tex_size != Hazard.PIT_PIXEL_SIZE:
		level.free()
		return "pit.png should be %s pixels (got %s)." % [str(Hazard.PIT_PIXEL_SIZE), str(tex_size)]
	level.free()
	return null


func _test_pit_dirt_placement() -> Variant:
	var data := CustomLevelStore.default_level(CustomLevelStore.EXTRA_SLOT_START + 2)
	var trail := CustomLevelStore.trail_row(int(data.get("height", 8)))
	var objects: Array = data.get("objects", [])
	for i in range(objects.size() - 1, -1, -1):
		var object := objects[i] as Dictionary
		if int(object.get("x", -1)) == 20 and str(object.get("type", "")) == "ground":
			objects.remove_at(i)
	if CustomLevelStore.pit_fits_on_dirt(objects, 20, trail):
		return "Pit placement should require dirt under the full footprint."
	for col in [19, 20, 21, 22]:
		objects.append({"type": "ground", "x": col, "y": trail})
	if not CustomLevelStore.pit_fits_on_dirt(objects, 20, trail):
		return "Pit should fit when trail dirt spans its footprint."
	return null


func _test_pit_canyon_parity() -> Variant:
	var player := Player.new()
	add_child(player)
	player.activate_mode(ModeController.Mode.BUBBLE_SHIELD)
	var pit := Hazard.new()
	pit.set_meta("fixed_pit", true)
	add_child(pit)
	pit._configure_visual()
	if not pit.is_fatal_fall():
		pit.queue_free()
		player.queue_free()
		return "Fixed pit should count as a fatal fall hazard."
	if pit.is_canyon():
		pit.queue_free()
		player.queue_free()
		return "Fixed pit must not register as a scaled canyon."
	var emitted := {"hit": false}
	pit.hurt.connect(func(_p: Player) -> void: emitted["hit"] = true)
	pit._on_body_entered(player)
	var hit: bool = emitted["hit"]
	player.queue_free()
	pit.queue_free()
	if not hit:
		return "Pit fall should hurt even with Bubble Shield (same as canyon)."
	return null


func _test_workshop_preview_stamp() -> Variant:
	var preview := LevelPreview.new()
	add_child(preview)
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(0)
	preview.show_level(data)
	preview.set_selected_type("cactus")
	await get_tree().process_frame
	var requested: Array = []
	preview.stamp_requested.connect(func(column: int, row: int) -> void: requested.append([column, row]))
	preview.set_hover_cell(8, trail)
	preview.set_view_center_column(8)
	preview.size = Vector2(420, 320)
	await get_tree().process_frame
	var display := preview._preview_display_rect()
	if display.size.x <= 1.0:
		preview.queue_free()
		return "Preview display rect should be usable for click mapping."
	var local := display.position + Vector2(display.size.x * 0.5, display.size.y * 0.6)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = local
	preview._gui_input(click)
	if requested.is_empty():
		preview.queue_free()
		return "Preview click should request stamp placement."
	if int((requested[0] as Array)[0]) != 8:
		preview.queue_free()
		return "Preview click should map to the hovered column."
	var ghost := preview._ghost_rect_screen()
	if ghost.size.x <= 1.0:
		preview.queue_free()
		return "Preview should draw a stamp footprint ghost while hovering."
	if not display.encloses(ghost):
		preview.queue_free()
		return "Preview hover ghost should track the hovered stamp footprint."
	preview.queue_free()
	return null


func _test_workshop_preview_ghost() -> Variant:
	var preview := LevelPreview.new()
	add_child(preview)
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(0)
	preview.show_level(data)
	preview.set_selected_type("spring")
	await get_tree().process_frame
	preview.set_hover_cell(12, trail)
	preview.set_view_center_column(12)
	preview.size = Vector2(420, 320)
	await get_tree().process_frame
	var display := preview._preview_display_rect()
	var ghost := preview._ghost_rect_screen()
	if ghost.size.x <= 1.0:
		preview.queue_free()
		return "Hovering a dirt row should show a spring ghost in the preview."
	if not display.encloses(ghost):
		preview.queue_free()
		return "Spring ghost should render inside the live preview pane."
	preview.queue_free()
	return null


func _test_workshop_preview_ghost_size() -> Variant:
	var preview := LevelPreview.new()
	add_child(preview)
	var trail := CustomLevelStore.trail_row(8)
	var data := CustomLevelStore.default_level(0)
	preview.show_level(data)
	preview.set_selected_type("platform")
	await get_tree().process_frame
	preview.set_hover_cell(12, trail)
	preview.set_view_center_column(12)
	preview.size = Vector2(420, 320)
	await get_tree().process_frame
	var ghost := preview._ghost_rect_screen()
	var metrics := preview._view_metrics()
	var zoom := float(metrics["zoom"])
	var expected_world := CustomLevelStore.stamp_visual_world_rect(
		"platform",
		12,
		trail,
		trail,
		int(data.get("width", CustomLevelStore.DEFAULT_WIDTH)),
		float(metrics["grid"])
	)
	var expected := expected_world.size * zoom
	if absf(ghost.size.x - expected.x) > 1.5 or absf(ghost.size.y - expected.y) > 1.5:
		preview.queue_free()
		return (
			"Platform ghost should match builder plank size (expected %s, got %s)."
			% [str(expected), str(ghost.size)]
		)
	var cells := preview._ghost_cell_rects_screen()
	if cells.size() != 4:
		preview.queue_free()
		return "Platform ghost should outline four grid cells (campaign plank width)."
	preview.set_selected_type("spring")
	preview.set_hover_cell(12, trail)
	await get_tree().process_frame
	cells = preview._ghost_cell_rects_screen()
	if cells.size() != 1:
		preview.queue_free()
		return "Single-cell stamps should outline one grid cell."
	var cell := cells[0]
	if absf(cell.size.x - 40.0 * zoom) > 1.5 or absf(cell.size.y - 40.0 * zoom) > 1.5:
		preview.queue_free()
		return "Grid cell outlines should match stamp grid size in screen space."
	preview.queue_free()
	return null


func _test_workshop_grid_collapse() -> Variant:
	GameManager.workshop_grid_collapsed = false
	var editor_packed: PackedScene = load("res://scenes/ui/level_editor.tscn")
	if editor_packed == null:
		return "Missing level editor scene."
	var editor := editor_packed.instantiate()
	add_child(editor)
	await get_tree().process_frame
	var toggle := editor.find_child("GridCollapseToggle", true, false) as Button
	var grid_scroll := editor.find_child("GridScroll", true, false) as ScrollContainer
	var h_scroll := editor.find_child("TrailScrollBar", true, false) as HScrollBar
	var preview := editor.find_child("LevelPreview", true, false) as LevelPreview
	if toggle == null or grid_scroll == null or h_scroll == null or preview == null:
		editor.queue_free()
		return "Editor should expose grid collapse controls."
	if not grid_scroll.visible or not h_scroll.visible:
		editor.queue_free()
		return "Stamp grid should start expanded."
	if toggle.text != "▼":
		editor.queue_free()
		return "Expanded stamp grid should show a down chevron toggle."
	editor._toggle_grid_collapsed()
	await get_tree().process_frame
	if grid_scroll.visible or h_scroll.visible:
		editor.queue_free()
		return "Collapsing the stamp grid should hide the grid and slide bar."
	if toggle.text != "▶":
		editor.queue_free()
		return "Collapsed stamp grid should show a right chevron toggle."
	if not GameManager.workshop_grid_collapsed:
		editor.queue_free()
		return "Grid collapse should persist for the session."
	if preview.size_flags_stretch_ratio < 2.0:
		editor.queue_free()
		return "Collapsing the grid should give the live preview more vertical space."
	editor._toggle_grid_collapsed()
	await get_tree().process_frame
	if not grid_scroll.visible or not h_scroll.visible:
		editor.queue_free()
		return "Expanding the stamp grid should restore the grid and slide bar."
	editor.queue_free()
	return null


func _test_workshop_right_click_remove() -> Variant:
	var editor_packed: PackedScene = load("res://scenes/ui/level_editor.tscn")
	if editor_packed == null:
		return "Missing level editor scene."
	var editor := editor_packed.instantiate()
	add_child(editor)
	await get_tree().process_frame
	var trail: int = editor._trail_y()
	editor._select_tool("cactus")
	editor._place(10, trail - 1)
	await get_tree().process_frame
	var objects: Array = editor._objects()
	var had_cactus := false
	for value in objects:
		var object := value as Dictionary
		if str(object.get("type", "")) == "cactus" and int(object.get("x", -1)) == 10:
			had_cactus = true
			break
	if not had_cactus:
		editor.queue_free()
		return "Workshop should place a cactus before right-click remove test."
	editor._remove_at(10, trail - 1)
	await get_tree().process_frame
	for value in editor._objects():
		var object := value as Dictionary
		if str(object.get("type", "")) == "cactus" and int(object.get("x", -1)) == 10:
			editor.queue_free()
			return "Right click remove should delete the stamped cactus."
	editor.queue_free()
	return null


func _test_workshop_preview_places_stamp() -> Variant:
	var editor := load("res://scenes/ui/level_editor.tscn")
	if editor == null:
		return "Missing level editor scene."
	var node := (editor as PackedScene).instantiate()
	if not (node is Control):
		node.queue_free()
		return "Level editor root should be a Control."
	add_child(node)
	for _wait in range(20):
		await get_tree().process_frame
		if node.get("_preview") != null:
			break
	if node.get("_preview") == null:
		node.queue_free()
		return "Level editor preview should finish building."
	var trail: int = node._trail_y()
	var stamp_column := 50
	node._selected_type = "cactus"
	node._on_preview_stamp(stamp_column, trail)
	await get_tree().process_frame
	var stored_y := -1
	for value in node._data.get("objects", []):
		var object := value as Dictionary
		if str(object.get("type", "")) == "cactus" and int(object.get("x", -1)) == stamp_column:
			stored_y = int(object.get("y", -1))
			break
	node.queue_free()
	if stored_y < 0:
		return "Preview stamp request should append a cactus to the trail data."
	if stored_y != trail - 1:
		return "Preview-placed ground props should store one row above dirt (got y=%d)." % stored_y
	return null


func _test_airborne_bandit_falls() -> Variant:
	var floor := StaticBody2D.new()
	floor.name = "TestFloor"
	floor.collision_layer = 1
	floor.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(400, 40)
	shape.shape = rect
	shape.position = Vector2(0, 20)
	floor.add_child(shape)
	floor.position = Vector2(200, 300)
	add_child(floor)
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	if packed == null:
		floor.queue_free()
		return "Missing opponent scene."
	var bandit := packed.instantiate() as Opponent
	bandit.global_position = Vector2(200, 120)
	add_child(bandit)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for _i in range(120):
		await get_tree().physics_frame
		if not bandit._falling:
			break
	if bandit._falling:
		bandit.queue_free()
		floor.queue_free()
		return "Airborne bandit should finish falling onto walkable ground."
	if absf(bandit.global_position.y - 300.0) > 6.0:
		bandit.queue_free()
		floor.queue_free()
		return "Bandit should land on the floor surface (y=%.1f)." % bandit.global_position.y
	bandit.queue_free()
	floor.queue_free()
	return null


func _test_buried_bandit_lifts() -> Variant:
	var floor := StaticBody2D.new()
	floor.collision_layer = 1
	floor.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(400, 80)
	shape.shape = rect
	shape.position = Vector2(0, 40)
	floor.add_child(shape)
	## Collision top at y=300.
	floor.position = Vector2(200, 300)
	add_child(floor)
	var packed: PackedScene = load("res://scenes/world/opponent.tscn")
	if packed == null:
		floor.queue_free()
		return "Missing opponent scene."
	var bandit := packed.instantiate() as Opponent
	## Start inside the dirt block, below the walk crust.
	bandit.global_position = Vector2(200, 340)
	add_child(bandit)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	if bandit._falling:
		bandit.queue_free()
		floor.queue_free()
		return "A buried bandit should lift onto the floor, not keep falling."
	if absf(bandit.global_position.y - 300.0) > 6.0:
		bandit.queue_free()
		floor.queue_free()
		return "Buried bandit should stand on the floor surface (y=%.1f)." % bandit.global_position.y
	bandit.queue_free()
	floor.queue_free()
	return null


func _test_level_10_bandits_on_floor() -> Variant:
	var packed: PackedScene = load("res://scenes/levels/level_10.tscn")
	if packed == null:
		return "Missing level 10 scene."
	var level := packed.instantiate() as LevelController
	add_child(level)
	await get_tree().process_frame
	await get_tree().physics_frame
	var error: Variant = null
	for node in level.find_children("*", "AnimatableBody2D", true, false):
		if not (node is Opponent):
			continue
		var bandit := node as Opponent
		var surface := WildWestTheme.walk_surface_at(level, bandit.global_position.x)
		var floor_y := float(surface.get("y", bandit.global_position.y))
		if absf(bandit.global_position.y - floor_y) > 8.0:
			error = "%s should stand on the walk surface (y=%.1f, floor=%.1f)." % [
				bandit.name, bandit.global_position.y, floor_y
			]
			break
	level.queue_free()
	return error


func _editor_tool_count(editor: Node) -> int:
	var total := 0
	var categories: Array = editor.get("_tool_categories") as Array
	if categories.is_empty():
		categories = LevelStyle.tool_categories(LevelStyle.DESERT)
	for category in categories:
		for tool in (category as Dictionary).get("tools", []) as Array:
			total += 1
	return total


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
			else:
				# Hub must list the campaign in play order with marks and Add-before on extras.
				var hub_packed: PackedScene = load("res://scenes/ui/custom_level_hub.tscn")
				var hub := hub_packed.instantiate() as Control
				add_child(hub)
				await get_tree().process_frame
				var trail_rows := hub.find_child("TrailRows", true, false) as VBoxContainer
				if trail_rows == null:
					error = "Campaign workshop needs a TrailRows list."
				else:
					var labels: PackedStringArray = []
					var saw_extra_add_before := false
					var extra_row_index := -1
					var five_row_index := -1
					for child in trail_rows.get_children():
						if not (child is HBoxContainer):
							continue
						var row := child as HBoxContainer
						var kind := str(row.get_meta("entry_kind", ""))
						var title_label: Label = null
						for node in row.get_children():
							if node is Label:
								title_label = node as Label
								break
						if title_label != null:
							labels.append(title_label.text)
						if kind == "extra":
							extra_row_index = labels.size() - 1
							for button_node in row.get_children():
								if button_node is Button and (button_node as Button).text == tr("Add before"):
									saw_extra_add_before = true
						elif int(row.get_meta("source_level", 0)) == 5:
							five_row_index = labels.size() - 1
					var joined := " | ".join(labels)
					if extra_row_index < 0 or five_row_index < 0 or extra_row_index >= five_row_index:
						error = "Workshop list must place self-made trails before their target campaign level (saw: %s)." % joined
					elif not saw_extra_add_before:
						error = "Self-made trails need an Add before action."
					else:
						var marked_extra := false
						var marked_changed := false
						for child in trail_rows.get_children():
							if not (child is HBoxContainer):
								continue
							var kind := str((child as HBoxContainer).get_meta("entry_kind", ""))
							var badge_text := ""
							for node in (child as HBoxContainer).get_children():
								if node is PanelContainer:
									var badge_label := (node as PanelContainer).get_child(0) as Label
									if badge_label != null:
										badge_text = badge_label.text
										break
							if kind == "extra":
								if (
									"Homemade" in badge_text
									or "Eigenbau" in badge_text
									or "self-made" in badge_text
									or "selbst gemacht" in badge_text
								):
									marked_extra = true
							elif kind == "override":
								if (
									"Changed" in badge_text
									or "Geändert" in badge_text
									or "changed" in badge_text
									or "geändert" in badge_text
								):
									marked_changed = true
						if not marked_extra:
							error = "Self-made trails should show a Homemade/Eigenbau badge."
						elif not marked_changed:
							error = "Changed campaign trails should show a Changed/Geändert badge."
						else:
							# Adding before an existing self-made trail must land immediately before it.
							var first_extra_slot := extra_slot
							var draft := CustomLevelStore.new_extra_draft(5, first_extra_slot)
							if draft.is_empty():
								error = "Workshop should still have a free slot to add before a self-made trail."
							elif not CustomLevelStore.save(int(draft["slot"]), draft):
								error = "Could not save a trail inserted before another self-made trail."
							else:
								var ordered := CustomLevelStore.campaign_entries()
								var first_idx := -1
								var second_idx := -1
								for i in range(ordered.size()):
									var slot := int(ordered[i].get("custom_slot", -1))
									if slot == int(draft["slot"]):
										first_idx = i
									elif slot == first_extra_slot:
										second_idx = i
								if first_idx < 0 or second_idx < 0 or first_idx >= second_idx:
									error = "Add before a self-made trail should place the new trail immediately ahead of it."
								CustomLevelStore.erase(int(draft["slot"]))
				hub.queue_free()
				await get_tree().process_frame
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
	await get_tree().process_frame
	var embedded_preview := editor.find_child("LevelPreview", true, false) as LevelPreview
	var category_dropdown := editor.find_child("StampCategory", true, false) as OptionButton
	var tool_dropdown := editor.find_child("StampTool", true, false) as OptionButton
	var trail_tools := editor.find_child("TrailPathTools", true, false) as HBoxContainer
	var category_example := editor.find_child("CategoryExample", true, false) as TextureRect
	var trail_bar := editor.find_child("TrailScrollBar", true, false) as HScrollBar
	if error == null and embedded_preview == null:
		error = "The editor needs a live gameplay preview."
	elif error == null and embedded_preview.custom_minimum_size.y < 160.0:
		error = "The editor preview should keep a usable minimum height."
	elif error == null and (category_dropdown == null or tool_dropdown == null):
		error = "The stamp palette should expose category and tool pickers."
	elif error == null and trail_tools == null:
		error = "The trail category should expose direct path stamp buttons."
	elif error == null and _editor_tool_count(editor) < 15:
		error = "Every stamp tool should remain reachable from the editor UI."
	elif error == null and trail_bar == null:
		error = "The trail editor needs a horizontal slide bar to scroll to the end."
	elif error == null:
		var preview_index := embedded_preview.get_index()
		var grid_scroll := editor.find_child("GridScroll", true, false) as ScrollContainer
		var editor_pane := editor.find_child("EditorPane", true, false) as VBoxContainer
		if grid_scroll == null or preview_index < grid_scroll.get_index():
			error = "The live preview should sit below the stamp grid in the editor."
		elif grid_scroll.custom_minimum_size.y < 80.0:
			error = "The stamp grid should reserve enough vertical space to stay editable."
		elif editor_pane == null or editor_pane.custom_minimum_size.y < 100.0:
			error = "The editor pane should keep the stamp grid from collapsing."
		elif editor._cells.is_empty() or editor._cells[0].custom_minimum_size.y < 10.0:
			error = "Stamp grid cells should stay tall enough to tap."
		elif category_example == null or category_example.custom_minimum_size.y < 14.0:
			error = "Each stamp category should show an example thumbnail."
		elif category_example.custom_minimum_size.y > 18.0:
			error = "Stamp palette icons should stay compact enough for the grid and preview."
		elif category_dropdown.custom_minimum_size.y > 20.0 or tool_dropdown.custom_minimum_size.y > 20.0:
			error = "Stamp dropdowns should stay compact to leave room for the grid and preview."
		elif grid_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS:
			error = "The stamp grid should hide its built-in horizontal scrollbar."
		else:
			var icon_tools := 0
			for category_index in range(category_dropdown.item_count):
				if category_dropdown.get_item_icon(category_index) != null:
					icon_tools += 1
				editor._populate_tool_dropdown(category_index)
				for i in range(tool_dropdown.item_count):
					if tool_dropdown.get_item_icon(i) != null:
						icon_tools += 1
			for child in trail_tools.get_children():
				if child is Button and (child as Button).icon != null:
					icon_tools += 1
			if icon_tools < 10:
				error = "Stamp tools should include example images kids can recognize."
			else:
				editor._sync_tool_dropdowns()
				if not trail_tools.visible:
					error = "The trail category should show direct path stamp buttons."
				elif tool_dropdown.visible:
					error = "The trail category should hide the tool dropdown."
				else:
					embedded_preview.show_level(imported)
					var metrics := embedded_preview._view_metrics()
					var grid := float(metrics["grid"])
					if float(metrics["top_y"]) > grid * 0.5:
						error = "The live preview should include sky above the top stamp row."
					elif float(metrics["bottom_y"]) < float(metrics["trail"]) * grid:
						error = "The live preview should show ground through the trail row."
					else:
						embedded_preview.size = Vector2(400.0, 300.0)
						await get_tree().process_frame
						var display := embedded_preview._preview_display_rect()
						var insets := embedded_preview._frame_insets()
						var expected_width := 400.0 - insets.x
						var expected_height := 300.0 - insets.y
						if absf(display.size.y - expected_height) > 1.0:
							error = "The live preview should scale to fill the pane height."
						elif absf(display.size.x - expected_width) > 1.0:
							error = "The live preview should fill the pane width."
						else:
							var live_container := embedded_preview.find_child(
								"LivePreviewContainer", true, false
							) as SubViewportContainer
							var live_viewport := embedded_preview.find_child(
								"LivePreviewViewport", true, false
							) as SubViewport
							if live_container == null or live_viewport == null:
								error = "The live preview viewport should match the fitted display size."
							elif (
								absf(float(live_viewport.size.x) - display.size.x) > 1.0
								or absf(float(live_viewport.size.y) - display.size.y) > 1.0
							):
								error = "The live preview viewport should match the fitted display size."
							else:
								var fitted_metrics := embedded_preview._view_metrics()
								var expected_zoom := minf(
									0.84,
									float(fitted_metrics["viewport_height"])
									/ float(fitted_metrics["world_height"])
								)
								if absf(float(fitted_metrics["zoom"]) - expected_zoom) > 0.02:
									error = (
										"The live preview should match gameplay camera zoom when the pane is tall enough."
									)
								else:
									var visible_height := (
										float(fitted_metrics["viewport_height"])
										/ float(fitted_metrics["zoom"])
									)
									if visible_height + 0.5 < float(fitted_metrics["world_height"]):
										error = "The live preview should frame the full vertical level slice."
									else:
										embedded_preview.size = Vector2(400.0, 520.0)
										await get_tree().process_frame
										var tall_metrics := embedded_preview._view_metrics()
										if absf(float(tall_metrics["zoom"]) - 0.84) > 0.02:
											error = (
												"Tall preview panes should keep normal gameplay camera zoom."
											)
					if error == null:
						grid_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
						grid_scroll.custom_minimum_size = Vector2(180.0, grid_scroll.custom_minimum_size.y)
						grid_scroll.size = Vector2(180.0, grid_scroll.size.y)
						await get_tree().process_frame
						editor._sync_scroll_range()
						var max_scroll: float = editor._horizontal_scroll_max()
						if max_scroll <= 0.0:
							error = (
								"The stamp grid should allow sideways scrolling on narrow panes (pane=%s)."
								% str(grid_scroll.size)
							)
						else:
							var before := float(grid_scroll.scroll_horizontal)
							trail_bar.value = before + minf(48.0, max_scroll)
							if float(grid_scroll.scroll_horizontal) <= before:
								error = "The horizontal slide bar should scroll the stamp grid sideways."
							else:
								trail_bar.value = before
								var wheel := InputEventMouseButton.new()
								wheel.button_index = MOUSE_BUTTON_WHEEL_LEFT
								wheel.pressed = true
								wheel.position = grid_scroll.get_global_rect().get_center()
								grid_scroll.get_viewport().push_input(wheel)
								await get_tree().process_frame
								if float(grid_scroll.scroll_horizontal) != before:
									error = "Horizontal wheel scrolling over the grid should stay disabled."
			editor._sync_tool_dropdowns()
	editor.queue_free()
	for i in range(paths.size()):
		if FileAccess.file_exists(paths[i]):
			DirAccess.remove_absolute(paths[i])
		if existed[i]:
			var restore := FileAccess.open(paths[i], FileAccess.WRITE)
			if restore != null:
				restore.store_buffer(backups[i])
	return error


func _test_workshop_back_navigation() -> Variant:
	var hub_packed: PackedScene = load("res://scenes/ui/custom_level_hub.tscn")
	var hub := hub_packed.instantiate() as Control
	add_child(hub)
	await get_tree().process_frame
	var viewport := Vector2(1280.0, 720.0)
	hub.size = viewport
	await get_tree().process_frame

	var scroll: ScrollContainer = null
	for child in hub.get_children():
		if child is ScrollContainer:
			scroll = child
			break
		if child is VBoxContainer:
			for grandchild in (child as VBoxContainer).get_children():
				if grandchild is ScrollContainer:
					scroll = grandchild
					break

	var back_top: Button = null
	for node in hub.find_children("*", "Button", true, false):
		var button := node as Button
		if button.get_index() == 0 or button.name == "BackButtonTop":
			back_top = button
			break
	if back_top == null:
		for node in hub.find_children("*", "Button", true, false):
			back_top = node as Button
			break

	if back_top == null:
		hub.queue_free()
		return "Campaign workshop should expose a back button."
	if not back_top.pressed.is_connected(GameManager.return_to_save_select):
		hub.queue_free()
		return "Campaign workshop back button should return to save select."
	if scroll != null and scroll.get_combined_minimum_size().y > viewport.y * 0.85:
		hub.queue_free()
		return "Campaign workshop list scroll should not push the back button off-screen."
	var back_rect := back_top.get_global_rect()
	if back_rect.position.y + back_rect.size.y > viewport.y + 1.0:
		hub.queue_free()
		return "Campaign workshop back button should stay visible on a 720p screen."

	hub.queue_free()

	GameManager.active_custom_slot = CustomLevelStore.override_slot_for(1)
	var editor_packed: PackedScene = load("res://scenes/ui/level_editor.tscn")
	var editor := editor_packed.instantiate() as Control
	add_child(editor)
	await get_tree().process_frame
	editor.size = viewport
	await get_tree().process_frame

	var editor_back := editor.find_child("BackButtonTop", true, false) as Button
	if editor_back == null:
		editor.queue_free()
		return "Trail editor should expose a top back button."
	if not editor_back.pressed.is_connected(editor._return_to_hub):
		editor.queue_free()
		return "Trail editor back button should return to the campaign workshop."
	var save_btn := editor.find_child("SaveButton", true, false) as Button
	var play_btn := editor.find_child("PlayTestButton", true, false) as Button
	var length_plus := editor.find_child("LengthPlusButton", true, false) as Button
	if (
		editor_back.icon == null
		or save_btn == null
		or save_btn.icon == null
		or play_btn == null
		or play_btn.icon == null
		or length_plus == null
		or length_plus.icon == null
	):
		editor.queue_free()
		return "Trail editor chrome buttons should show kid-readable icons."
	editor.queue_free()
	return null


func _test_trail_share_pack() -> Variant:
	var override_slot := CustomLevelStore.override_slot_for(2)
	var extra_slot := CustomLevelStore.SLOT_COUNT - 2
	var override_path := CustomLevelStore.SavePaths.custom_level_path(override_slot)
	var override_existed := FileAccess.file_exists(override_path)
	var override_backup := (
		FileAccess.get_file_as_bytes(override_path) if override_existed else PackedByteArray()
	)
	var backups: Array[PackedByteArray] = []
	var existed: Array[bool] = []
	for slot in range(CustomLevelStore.EXTRA_SLOT_START, CustomLevelStore.SLOT_COUNT):
		var path := CustomLevelStore.SavePaths.custom_level_path(slot)
		existed.append(FileAccess.file_exists(path))
		backups.append(FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray())
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if override_existed:
		DirAccess.remove_absolute(override_path)
	var pack_path := CustomLevelStore.SavePaths.root_dir().path_join("test_share_pack.cowboytrail")
	if FileAccess.file_exists(pack_path):
		DirAccess.remove_absolute(pack_path)
	var override := CustomLevelStore.import_builtin(2)
	override["title"] = "Share Pack Override"
	var extra := CustomLevelStore.default_level(extra_slot)
	extra["kind"] = "extra"
	extra["insert_position"] = 3
	extra["title"] = "Share Pack Extra"
	var error: Variant = null
	if not CustomLevelStore.save(override_slot, override):
		error = "Could not save override trail for share pack test."
	elif not CustomLevelStore.save(extra_slot, extra):
		error = "Could not save extra trail for share pack test."
	elif not CustomLevelStore.exists(override_slot) or not CustomLevelStore.exists(extra_slot):
		error = "Share pack test trails were not written to disk."
	elif not CustomLevelStore.export_share_pack(pack_path, [override_slot, extra_slot]):
		error = "Share pack export failed."
	elif not FileAccess.file_exists(pack_path):
		error = "Share pack file was not written."
	else:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(pack_path))
		if typeof(parsed) != TYPE_DICTIONARY:
			error = "Share pack is not valid JSON."
		elif str((parsed as Dictionary).get("format", "")) != CustomLevelStore.SHARE_PACK_FORMAT:
			error = "Share pack format marker is wrong."
		elif ((parsed as Dictionary).get("trails", []) as Array).size() != 2:
			error = "Share pack should contain both exported trails."
		else:
			if FileAccess.file_exists(override_path):
				DirAccess.remove_absolute(override_path)
			if FileAccess.file_exists(CustomLevelStore.SavePaths.custom_level_path(extra_slot)):
				DirAccess.remove_absolute(CustomLevelStore.SavePaths.custom_level_path(extra_slot))
			var result := CustomLevelStore.import_share_pack(pack_path)
			if not bool(result.get("ok", false)):
				error = "Share pack import failed: %s" % str(result.get("message", ""))
			elif int(result.get("imported_count", 0)) != 2:
				error = "Share pack should import both exported trails."
			else:
				var saw_override_title := false
				var saw_extra_title := false
				for slot in range(CustomLevelStore.EXTRA_SLOT_START, CustomLevelStore.SLOT_COUNT):
					if not CustomLevelStore.exists(slot):
						continue
					var imported := CustomLevelStore.load_level(slot)
					if str(imported.get("kind", "")) != "extra":
						error = "Imported trails should become extra campaign entries."
						break
					var title := str(imported.get("title", ""))
					saw_override_title = saw_override_title or title == "Share Pack Override"
					saw_extra_title = saw_extra_title or title == "Share Pack Extra"
				if error == null and (not saw_override_title or not saw_extra_title):
					error = "Imported trail titles should survive the round trip."
	if FileAccess.file_exists(pack_path):
		DirAccess.remove_absolute(pack_path)
	for slot in range(CustomLevelStore.EXTRA_SLOT_START, CustomLevelStore.SLOT_COUNT):
		var path := CustomLevelStore.SavePaths.custom_level_path(slot)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		if existed[slot - CustomLevelStore.EXTRA_SLOT_START]:
			var restore := FileAccess.open(path, FileAccess.WRITE)
			if restore != null:
				restore.store_buffer(backups[slot - CustomLevelStore.EXTRA_SLOT_START])
	if FileAccess.file_exists(override_path):
		DirAccess.remove_absolute(override_path)
	if override_existed:
		var restore_override := FileAccess.open(override_path, FileAccess.WRITE)
		if restore_override != null:
			restore_override.store_buffer(override_backup)
	return error


func _test_trail_editor_single_share() -> Variant:
	var slot := CustomLevelStore.SLOT_COUNT - 3
	var path := CustomLevelStore.SavePaths.custom_level_path(slot)
	var existed := FileAccess.file_exists(path)
	var backup := FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
	if existed:
		DirAccess.remove_absolute(path)
	var pack_path := CustomLevelStore.SavePaths.root_dir().path_join("test_editor_single.cowboytrail")
	if FileAccess.file_exists(pack_path):
		DirAccess.remove_absolute(pack_path)

	var current := CustomLevelStore.default_level(slot)
	current["kind"] = "extra"
	current["insert_position"] = 6
	current["title"] = "Before Import"
	var exported := current.duplicate(true)
	exported["title"] = "Shared Single Trail"
	exported["objects"].append({"type": "star", "x": 5, "y": CustomLevelStore.trail_row(int(exported["height"])) - 1})

	var error: Variant = null
	if not CustomLevelStore.write_share_pack(pack_path, [exported]):
		error = "Single-trail export failed."
	else:
		var read := CustomLevelStore.read_share_pack(pack_path)
		if not bool(read.get("ok", false)):
			error = "Single-trail read failed: %s" % str(read.get("message", ""))
		elif int(read.get("trail_count", 0)) != 1:
			error = "Single-trail pack should contain exactly one trail."
		else:
			var merged := CustomLevelStore.merge_imported_trail(current, (read["trails"] as Array)[0], slot)
			if str(merged.get("title", "")) != "Shared Single Trail":
				error = "Merged import should take the shared trail layout."
			elif str(merged.get("kind", "")) != "extra" or int(merged.get("insert_position", 0)) != 6:
				error = "Editor import should keep the current slot campaign metadata."
			elif int(merged.get("slot", -1)) != slot:
				error = "Editor import should stay on the active custom slot."
			else:
				GameManager.active_custom_slot = slot
				GameManager.custom_level_draft = {}
				if not CustomLevelStore.save(slot, current):
					error = "Could not seed the editor slot before import."
				else:
					var packed: PackedScene = load("res://scenes/ui/level_editor.tscn")
					var editor = packed.instantiate()
					add_child(editor)
					editor._on_import_selected(pack_path)
					if str(editor._data.get("title", "")) != "Shared Single Trail":
						error = "Import Trail should load the shared document into the editor."
					elif not editor._dirty:
						error = "Import Trail should mark the working document dirty for Save."
					elif str(editor._data.get("kind", "")) != "extra":
						error = "Import Trail should not overwrite the current trail kind."
					elif editor.find_child("ImportTrailButton", true, false) == null:
						error = "The trail editor should expose an Import Trail button."
					editor.queue_free()

	if FileAccess.file_exists(pack_path):
		DirAccess.remove_absolute(pack_path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if existed:
		var restore := FileAccess.open(path, FileAccess.WRITE)
		if restore != null:
			restore.store_buffer(backup)
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
		"res://assets/world/cave_canyon_rim_left.png",
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
	if load("res://assets/audio/trail_lasso_lady.ogg") == null:
		return "Lasso Lady trail music did not load."
	if load("res://assets/audio/trail_spaghetti_western.ogg") == null:
		return "Spaghetti Western trail music did not load."
	if AudioManager.trail_track_count() < 3:
		return "AudioManager should expose three rotating trail tracks."
	if AudioManager.trail_track_index_for_level(1) != 0:
		return "Level 1 should use trail track 0."
	if AudioManager.trail_track_index_for_level(2) != 1:
		return "Level 2 should use trail track 1."
	if AudioManager.trail_track_index_for_level(3) != 2:
		return "Level 3 should use trail track 2."
	if AudioManager.trail_track_index_for_level(4) != 0:
		return "Level 4 should wrap back to trail track 0."
	AudioManager.play_trail_music(2)
	if AudioManager.current_trail_track_index() != 1:
		return "play_trail_music should select the level's rotated track."
	var country: AudioStream = load("res://assets/audio/country_version.mp3")
	if country == null:
		return "Country start/finale theme did not load."
	if load("res://scenes/ui/startup_loading.tscn") == null:
		return "Game needs a visible startup loading scene."
	var loading_packed: PackedScene = load("res://scenes/ui/startup_loading.tscn")
	var loading := loading_packed.instantiate() as Control
	add_child(loading)
	await get_tree().process_frame
	var track := loading.get_node_or_null("ProgressTrack") as Control
	var fill := loading.get_node_or_null("ProgressTrack/ProgressFill") as ColorRect
	if track == null or fill == null:
		loading.queue_free()
		return "Startup loading needs a ProgressTrack with ProgressFill."
	## Advance a bit without waiting for the full boot handoff.
	loading.set_process(false)
	loading._elapsed = 0.6
	loading._set_progress(0.55)
	await get_tree().process_frame
	if fill.size.x < 40.0:
		loading.queue_free()
		return "Startup progress bar should visibly fill while saddling up."
	loading.queue_free()
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
		var max_rim_scale_x := (
			ScalableCanyonArt.RIM_SIZE.x
			/ (canyon_art.get_node("LeftRim") as Sprite2D).texture.get_size().x
		)
		canyon_art.configure(floor_top, gap_left, gap_right + 600.0)
		var wide_scale := (canyon_art.get_node("LeftRim") as Sprite2D).scale
		if (
			canyon_art.opening_width() < gap_right - gap_left + 590.0
			or wide_scale.x > max_rim_scale_x + 0.01
		):
			controller.queue_free()
			return "Canyon center should widen without stretching its handmade rims."
		if not canyon_art.rims_reach_canyon_bottom():
			controller.queue_free()
			return "Canyon ridges must stay full-height after widening."
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
		"Panel/Margin/VBox/RestartLevelButton",
		"Panel/Margin/VBox/RestartButton",
		"Panel/Margin/VBox/SaveSelectButton",
		"Panel/Margin/VBox/QuitButton",
	]:
		if menu.get_node_or_null(path) == null:
			error = "Pause menu missing %s." % path
			break
	var restart_level := menu.get_node_or_null("Panel/Margin/VBox/RestartLevelButton") as Button
	if error == null and restart_level != null and restart_level.text != "Restart Level":
		error = "Pause menu should offer Restart Level for the open trail."
	var restart := menu.get_node_or_null("Panel/Margin/VBox/RestartButton") as Button
	if error == null and restart != null and restart.text != "Restart Trail at Level 1":
		error = "Restart action should clearly say it returns to Level 1."
	var start_screen := menu.get_node_or_null("Panel/Margin/VBox/SaveSelectButton") as Button
	if error == null and start_screen != null and start_screen.text != "Back to Start Screen":
		error = "Pause menu should offer a clear return to the start screen."
	var quit_button := menu.get_node_or_null("Panel/Margin/VBox/QuitButton") as Button
	if error == null and quit_button != null and quit_button.text not in ["Quit", "Beenden"]:
		error = "Pause menu should offer Quit/Beenden."
	if error == null:
		(menu as PauseMenu).set_save_options(false, false)
		if restart != null and restart.visible:
			error = "Workshop playtests should hide Restart Trail at Level 1."
		elif restart_level != null and not restart_level.visible:
			error = "Restart Level should stay available during workshop playtests."
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
	GameManager.debug_set_slot(0, {
		"empty": false,
		"current_level": 8,
		"stars": 12,
		"completed": false,
		"resume": {"level_number": 8, "checkpoint_name": "CheckpointB"},
	})
	GameManager.active_slot_index = 0
	## Prepare the same save mutations Restart Level uses, without swapping the test scene.
	GameManager.clear_run_state()
	var restarted := GameManager.get_slot(0)
	if error == null and int(restarted.get("current_level", -1)) != 8:
		error = "Restart Level must keep campaign progress on the open trail."
	elif error == null and not (restarted.get("resume", {}) as Dictionary).is_empty():
		error = "Restart Level must clear the mid-run camp save."
	elif error == null and int(restarted.get("stars", 0)) != 12:
		error = "Restart Level should keep previously earned badges."
	elif error == null and not GameManager.has_method("restart_current_level"):
		error = "GameManager needs restart_current_level for the pause action."
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
	if one_tick < 39.0:
		error = "Wind should be stronger than the old barely noticeable 20 px/s nudge."
	elif one_tick > 42.0:
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
	var expected_ride_y := floor_y + LevelTransition.MOUNTED_SPRITE_OFFSET_Y * screen_scale
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
	elif absf(horse.position.y - expected_ride_y) > 3.0:
		error = (
			"Arrival horse should sit on the trail floor (horse y=%.1f, want %.1f)."
			% [horse.position.y, expected_ride_y]
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
	elif transition.visible:
		error = "Arrival overlay must hide when the horse arrival finishes."
	elif transition.get_node_or_null("Banner") != null and not String((transition.get_node("Banner") as Label).text).is_empty():
		error = "Arrival must clear the banner text so it does not linger."
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


func _test_transition_gallop_frame_size() -> Variant:
	## Canvas size alone is not enough: edge-filled gallops looked oversized next to ride art.
	var standing: Texture2D = LevelTransition.HORSE_TEXTURE
	var gallop0: Texture2D = LevelTransition.HORSE_GALLOP_0
	var gallop1: Texture2D = LevelTransition.HORSE_GALLOP_1
	var ride: Texture2D = GameManager.get_mounted_horse_texture("ride_0")
	if standing == null or gallop0 == null or gallop1 == null or ride == null:
		return "Transition horse textures failed to load."
	if gallop0.get_width() != standing.get_width() or gallop0.get_height() != standing.get_height():
		return (
			"Gallop frame 0 must match trail_horse size (%dx%d), got %dx%d."
			% [standing.get_width(), standing.get_height(), gallop0.get_width(), gallop0.get_height()]
		)
	if gallop1.get_width() != standing.get_width() or gallop1.get_height() != standing.get_height():
		return (
			"Gallop frame 1 must match trail_horse size (%dx%d), got %dx%d."
			% [standing.get_width(), standing.get_height(), gallop1.get_width(), gallop1.get_height()]
		)
	var ride_dist := _texture_lower_body_foot_dist(ride)
	var g0_dist := _texture_lower_body_foot_dist(gallop0)
	var g1_dist := _texture_lower_body_foot_dist(gallop1)
	if ride_dist <= 0.0 or g0_dist <= 0.0 or g1_dist <= 0.0:
		return "Could not measure horse body size from transition textures."
	# Empty gallop body mass must stay within ~8% of the mounted ride horse.
	var max_ratio := 1.08
	if g0_dist > ride_dist * max_ratio:
		return (
			"Gallop frame 0 body is oversized vs ride art (foot-dist %.1f vs %.1f)."
			% [g0_dist, ride_dist]
		)
	if g1_dist > ride_dist * max_ratio:
		return (
			"Gallop frame 1 body is oversized vs ride art (foot-dist %.1f vs %.1f)."
			% [g1_dist, ride_dist]
		)
	return null


func _texture_lower_body_foot_dist(tex: Texture2D) -> float:
	## Distance from lower-body opacity centroid to the content foot line.
	var img: Image = tex.get_image()
	if img == null:
		return -1.0
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var used := img.get_used_rect()
	if used.size.y <= 0:
		return -1.0
	var y0 := used.position.y + int(used.size.y * 0.4)
	var sum_y := 0.0
	var count := 0
	for y in range(y0, used.end.y):
		for x in range(used.position.x, used.end.x):
			if img.get_pixel(x, y).a > 0.15:
				sum_y += float(y)
				count += 1
	if count == 0:
		return -1.0
	return float(used.end.y) - sum_y / float(count)


func _test_arrival_uses_ground_under_spawn() -> Variant:
	## Spawn markers sit above the plank; arrival floor must use the ground surface.
	for path in ["res://scenes/levels/level_01.tscn", "res://scenes/levels/level_02.tscn"]:
		var level: Variant = _instantiate_level(path)
		if level is String:
			return level
		var controller := level as LevelController
		await get_tree().physics_frame
		await get_tree().physics_frame
		if controller.spawn_point == null:
			_free_level(controller)
			return "Level is missing SpawnPoint."
		var spawn := controller.spawn_point.global_position
		var floor_y := controller._ground_surface_y_at(spawn)
		if floor_y <= spawn.y + 8.0:
			_free_level(controller)
			return (
				"%s ground under spawn should be below the marker (spawn=%.1f, floor=%.1f)."
				% [path.get_file(), spawn.y, floor_y]
			)
		var canvas := controller.get_viewport().get_canvas_transform()
		var floor_screen := canvas * Vector2(spawn.x, floor_y)
		var scale := controller._world_to_screen_scale()
		controller.transition.play_arrival(floor_screen, floor_screen.y, scale)
		await get_tree().process_frame
		var expected_ride_y := floor_screen.y + LevelTransition.MOUNTED_SPRITE_OFFSET_Y * scale
		var rider := controller.transition.get_node_or_null("CowboyHorse") as Sprite2D
		var error: Variant = null
		if rider == null or not rider.visible:
			error = "Arrival should show the mounted cowboy riding in."
		elif absf(rider.position.y - expected_ride_y) > 3.0:
			error = (
				"Arrival ride-in must use ground Y, not the floating spawn marker (got %.1f, want %.1f)."
				% [rider.position.y, expected_ride_y]
			)
		_free_level(controller)
		if error != null:
			return error
	return null


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


func _test_cave_ceiling_sparse_flight_guard() -> Variant:
	## Crystal Mouth dresses low/high-edge rock panels with matching seams and fused teeth.
	var data := CaveCampaignLevels.level_data(11)
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	WildWestTheme.apply_to_level(level)
	await get_tree().process_frame

	var ceiling := level.get_node_or_null("CaveCeiling") as Node2D
	if ceiling == null:
		level.queue_free()
		return "Cave level 11 should dress a CaveCeiling after theme."
	if ceiling.get_node_or_null("FlightCeilingCave") == null:
		level.queue_free()
		return "CaveCeiling should include FlightCeilingCave solid band."
	if ceiling.get_node_or_null("CaveCeilingHazard") == null:
		level.queue_free()
		return "CaveCeiling should include CaveCeilingHazard for flying touch."
	if ceiling.get_node_or_null("CeilingFill_0") == null:
		level.queue_free()
		return "CaveCeiling should fill the sky gap above the lip with CeilingFill art."
	var segment_top := float(ceiling.get_meta("segment_top_y", 999.0))
	if segment_top > -100.0:
		level.queue_free()
		return "Ceiling segments should start near the camera top (got y=%.1f)." % segment_top
	# Fill sprites must end at/above the segment tops (no fill below the painted lip).
	for child in ceiling.get_children():
		if child is Sprite2D and String(child.name).begins_with("CeilingFill"):
			var fill := child as Sprite2D
			var fill_bottom := fill.position.y + fill.texture.get_height() * fill.scale.y
			if fill_bottom > segment_top + 1.0:
				level.queue_free()
				return "Ceiling fill must not extend below the ceiling segment art."
	var rocks: Array[Sprite2D] = []
	for child in ceiling.get_children():
		if child is Sprite2D and String(child.name).begins_with("CeilingRock"):
			rocks.append(child as Sprite2D)
	if rocks.size() < 3:
		level.queue_free()
		return "Cave ceiling should place multiple rock segment arts (got %d)." % rocks.size()
	# Adjacent panels must share matching edge heights (prev.end == next.start).
	for i in range(1, rocks.size()):
		var prev_end := str(rocks[i - 1].get_meta("end", ""))
		var next_start := str(rocks[i].get_meta("start", ""))
		if prev_end.is_empty() or next_start.is_empty():
			level.queue_free()
			return "Ceiling panels must store start/end height metas."
		if prev_end != next_start:
			level.queue_free()
			return "Adjacent ceiling panels must match edge heights (%s→%s at %d)." % [
				prev_end, next_start, i
			]
	var attach_points: Array = ceiling.get_meta("attach_points", [])
	if attach_points.size() < 4:
		level.queue_free()
		return "Ceiling segments should expose several stalactite attach seats."
	var seat_ys: Array[float] = []
	for seat_v in attach_points:
		if seat_v is Dictionary:
			seat_ys.append(float((seat_v as Dictionary).get("y", 0.0)))
	seat_ys.sort()
	if seat_ys[seat_ys.size() - 1] - seat_ys[0] < 20.0:
		level.queue_free()
		return "Ceiling attach seats should vary in height across segments."

	var decor_count := 0
	var tooth_ys: Array[float] = []
	for child in ceiling.get_children():
		if child is StalactiteHazard and String(child.name).begins_with("CeilingStalactite"):
			decor_count += 1
			var tooth := child as StalactiteHazard
			tooth_ys.append(tooth.position.y)
			if not tooth.fuse_with_ceiling:
				level.queue_free()
				return "Ceiling décor stalactites should fuse with the rock until release."
			var near_seat := false
			for seat_v in attach_points:
				if not (seat_v is Dictionary):
					continue
				var seat := seat_v as Dictionary
				if absf(tooth.position.x - float(seat.get("x", 0.0))) < 8.0 \
						and absf(tooth.position.y - (float(seat.get("y", 0.0)) - 2.0)) < 10.0:
					near_seat = true
					break
			if not near_seat:
				level.queue_free()
				return "Ceiling stalactites must attach on a segment seat."
	# Stamped hangings snap onto nearest seat.
	var static_count := 0
	var drop_count := 0
	for child in ceiling.get_children():
		if child is StalactiteHazard and String(child.name).begins_with("CeilingStalactite"):
			var tooth := child as StalactiteHazard
			if tooth.drops:
				drop_count += 1
			else:
				static_count += 1
	for node in level.find_children("*", "StalactiteHazard", true, false):
		var spike := node as Node2D
		if spike.get_parent() == ceiling:
			continue
		var expected := WildWestTheme._nearest_ceiling_attach_y(
			attach_points, spike.global_position.x, float(ceiling.get_meta("underside_y", 0.0))
		) - 6.0
		if absf(spike.global_position.y - expected) > 2.0:
			level.queue_free()
			return "Stamped stalactites must snap onto the nearest ceiling seat."
	level.queue_free()
	if decor_count >= 20:
		return (
			"Cave décor stalactites should stay sparse on a 100-wide trail (got %d, want < 20)."
			% decor_count
		)
	if decor_count < 1:
		return "Cave ceiling should place at least one décor stalactite."
	if drop_count < 1:
		return "Cave ceiling should place at least one droppable stalactite."
	if static_count < 1:
		return "Cave ceiling should place at least one fake static stalactite."
	if tooth_ys.size() >= 2:
		tooth_ys.sort()
		if tooth_ys[tooth_ys.size() - 1] - tooth_ys[0] < 8.0:
			return "Decor stalactites should hang at more than one ceiling height."
	return null


func _test_dragon_levels_have_no_stalactites() -> Variant:
	## Dragon Gate + Cave Dragon keep a clean ceiling (no stamped or décor teeth).
	var data := CaveCampaignLevels.level_data(16)
	for obj in data.get("objects", []):
		if not (obj is Dictionary):
			continue
		var type_name := str(obj.get("type", ""))
		if type_name == "stalactite" or type_name == "stalactite_static":
			return "Dragon Gate must not stamp stalactites."
	var level := LevelController.new()
	level.level_number = 16
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	WildWestTheme.apply_to_level(level)
	await get_tree().process_frame
	var stamped := level.find_children("*", "StalactiteHazard", true, false)
	level.queue_free()
	if not stamped.is_empty():
		return "Dragon Gate must not dress décor/hazard stalactites (found %d)." % stamped.size()

	var packed: PackedScene = load("res://scenes/bosses/boss_cave_dragon.tscn")
	if packed == null:
		return "Failed to load Cave Dragon boss scene."
	var boss: Node = packed.instantiate()
	add_child(boss)
	await get_tree().process_frame
	await get_tree().process_frame
	var boss_teeth := boss.find_children("*", "StalactiteHazard", true, false)
	boss.queue_free()
	if not boss_teeth.is_empty():
		return "Cave Dragon arena must not dress décor stalactites (found %d)." % boss_teeth.size()
	return null


func _test_cave_canyon_uses_cave_rim() -> Variant:
	## Acid Veins cave gaps must use cool-slate canyon ridges, not desert sandstone.
	var data := CaveCampaignLevels.level_data(13)
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	WildWestTheme.apply_to_level(level)
	await get_tree().process_frame
	var found := 0
	for node in level.find_children("*", "Area2D", true, false):
		if not (node is Hazard):
			continue
		var hazard := node as Hazard
		if not hazard.is_canyon():
			continue
		var art := hazard.get_node_or_null("CanyonMouth") as ScalableCanyonArt
		if art == null:
			level.queue_free()
			return "Cave canyon is missing CanyonMouth art."
		var left := art.get_node_or_null("LeftRim") as Sprite2D
		if left == null or left.texture == null:
			level.queue_free()
			return "Cave canyon left rim sprite missing."
		if left.texture.resource_path.find("cave_canyon_rim_left") < 0:
			level.queue_free()
			return "Cave canyon must use cave_canyon_rim_left.png (got %s)." % left.texture.resource_path
		if not art.rim_bank_is_opaque_dirt():
			level.queue_free()
			return "Cave canyon rim bank must stay opaque slate."
		found += 1
	level.queue_free()
	if found < 1:
		return "Acid Veins should dress at least one canyon with cave rim art."
	return null


func _test_poison_fungus_spore_animation() -> Variant:
	## Cave cactus stamps become poison fungus with a looping spore-puff cycle.
	for path in [
		"res://assets/world/poison_fungus_0.png",
		"res://assets/world/poison_fungus_1.png",
		"res://assets/world/poison_fungus_2.png",
		"res://assets/world/poison_fungus_3.png",
	]:
		if load(path) == null:
			return "Missing fungus spore frame: %s" % path
	var data := CaveCampaignLevels.level_data(13)
	var level := LevelController.new()
	add_child(level)
	CustomLevelBuilder.build(level, data)
	await get_tree().process_frame
	WildWestTheme.apply_to_level(level)
	await get_tree().process_frame
	var fungus: Hazard = null
	for node in level.find_children("*", "Area2D", true, false):
		if node is Hazard and (node as Hazard).is_cactus():
			fungus = node as Hazard
			break
	if fungus == null:
		level.queue_free()
		return "Acid Veins should place at least one poison fungus."
	var anim := fungus.get_node_or_null("FungusAnim") as AnimatedSprite2D
	if anim == null or not anim.visible:
		level.queue_free()
		return "Cave fungus should show FungusAnim spore cycle."
	if anim.sprite_frames == null or not anim.sprite_frames.has_animation(&"spore"):
		level.queue_free()
		return "FungusAnim needs a looping spore animation."
	if anim.sprite_frames.get_frame_count(&"spore") < 4:
		level.queue_free()
		return "Spore animation should include idle/gather/burst/drift frames."
	if not anim.is_playing() or anim.animation != &"spore":
		level.queue_free()
		return "Poison fungus should be playing the spore animation."
	var sprite := fungus.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null and sprite.visible:
		level.queue_free()
		return "Static fungus Sprite2D should hide while the spore anim plays."
	level.queue_free()
	return null


func _abyss_right_edge(abyss: Polygon2D) -> float:
	var max_x := 0.0
	for point in abyss.polygon:
		max_x = maxf(max_x, point.x)
	return abyss.position.x + max_x


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
