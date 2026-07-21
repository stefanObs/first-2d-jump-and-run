class_name LevelController
extends Node2D

## Owns spawn, checkpoints, hazards, goal completion, HUD, and pause.

const BOUNTY_REWARD_EFFECT := preload("res://scripts/world/bounty_reward_effect.gd")

signal level_completed
signal player_respawned(position: Vector2)

@export var level_number: int = 1
@export var celebration_duration: float = 4.2
@export var level_title: String = "Level"
@export var is_final_level: bool = false
@export var fall_recovery_y: float = 540.0
@export var is_custom_level: bool = false
var campaign_source_level: int = 0

var spawn_point: Marker2D
var player: Player
var transition: LevelTransition
var pause_menu: PauseMenu
var hud: Hud

var _active_checkpoint: Checkpoint
var _completion: LevelCompletionFlow
var _is_completing: bool = false
var _is_set_up: bool = false
var _play_time: float = 0.0
var _paused: bool = false
var _progress_milestones: Dictionary = {}
var _collected_badge_names: Array[String] = []
var _stored_badge_names: Array[String] = []
var _tied_opponent_names: Array[String] = []
var _stored_tied_opponent_names: Array[String] = []
var _stored_mode: ModeController.Mode = ModeController.Mode.NONE
var _stored_mode_remaining: float = 0.0
var _restoring_run_state: bool = false
var _loaded_run_state: bool = false
var _next_level_tap_time_msec: int = -1000
var _next_boss_tap_time_msec: int = -1000
var _is_recovering: bool = false


func _ready() -> void:
	setup_level()


func _process(delta: float) -> void:
	if _paused or _is_completing:
		if _completion != null and _completion.is_active:
			_completion.tick(delta)
			if transition != null:
				transition.set_progress(_completion.progress())
		return

	if Input.is_action_just_pressed(&"next_level"):
		_handle_next_level_tap()
		if _is_completing:
			return
	if Input.is_action_just_pressed(&"next_boss"):
		_handle_next_boss_tap()
		return
	_play_time += delta
	_update_trail_progress()
	if (
		player != null
		and player.global_position.y > fall_recovery_y
		and not _is_recovering
		and not player.is_canyon_falling()
		and not player.has_timed_invulnerability()
	):
		_play_canyon_fall_and_respawn()
		return
	if Input.is_action_just_pressed(&"pause"):
		set_paused(true)
		return

	if _completion != null and _completion.is_active:
		_completion.tick(delta)
		if transition != null:
			transition.set_progress(_completion.progress())


func setup_level() -> void:
	if _is_set_up:
		return
	_is_set_up = true
	var campaign_context := GameManager.consume_campaign_context()
	if not campaign_context.is_empty():
		level_number = int(campaign_context.get("position", level_number))
		campaign_source_level = int(campaign_context.get("source_level", level_number))
		is_final_level = level_number >= int(campaign_context.get("count", 10))

	spawn_point = get_node_or_null("SpawnPoint") as Marker2D
	var player_node := get_node_or_null("Player")
	if player_node is Player:
		player = player_node as Player
	transition = get_node_or_null("LevelTransition") as LevelTransition
	pause_menu = get_node_or_null("PauseMenu") as PauseMenu
	hud = get_node_or_null("Hud") as Hud

	_completion = LevelCompletionFlow.new(celebration_duration)
	_completion.finished.connect(_on_celebration_finished)
	_wire_world_objects()
	_wire_ui()

	if player != null and spawn_point != null:
		player.respawn_at(spawn_point.global_position)
	_restore_run_state()
	WildWestTheme.apply_to_level(self)
	WildWestTheme.configure_player_camera(self, player)
	_animate_sun()
	if hud != null:
		var display_title := (
			level_title if is_custom_level else GameManager.level_name_for(level_number)
		)
		hud.set_level_title(display_title)
		hud.set_prompt(_gameplay_prompt())
		var hint := get_node_or_null("HintLabel") as Label
		var tip := (
			"Loaded! Back at your saved camp."
			if _loaded_run_state
			else hint.text if hint != null and not String(hint.text).is_empty()
			else tr("Let's go: %s!") % display_title
		)
		hud.show_toast(tip, 4.5)
		if hint != null:
			hint.visible = false
		_setup_camp_marks()
		InputManager.device_changed.connect(_on_device_changed)
	if not is_custom_level and GameManager.consume_horse_arrival():
		_play_horse_arrival()


func _setup_camp_marks() -> void:
	if hud == null or spawn_point == null:
		return
	var goal := find_child("Goal", true, false) as Node2D
	if goal == null:
		return
	var start_x := spawn_point.global_position.x
	var span := maxf(goal.global_position.x - start_x, 1.0)
	var ratios: Array = []
	for node in find_children("*", "Area2D", true, false):
		if node is Checkpoint:
			ratios.append(((node as Node2D).global_position.x - start_x) / span)
	hud.mark_camps(ratios)


func set_paused(value: bool) -> void:
	_paused = value
	get_tree().paused = value
	if pause_menu != null:
		pause_menu.visible = value
		if value:
			pause_menu.focus_first()
	if player != null:
		player.set_input_enabled(not value and not _is_completing)


func get_active_respawn_position() -> Vector2:
	if _active_checkpoint != null:
		return _active_checkpoint.get_respawn_position()
	if spawn_point != null:
		return spawn_point.global_position
	return Vector2.ZERO


func begin_completion() -> void:
	if _is_completing:
		return
	_is_completing = true
	# Capture screen anchors before freezing the camera/player so the ride-off
	# keeps the live saloon position and the trail floor baseline.
	var saloon_screen := _goal_saloon_screen_position()
	var floor_screen_y := _trail_floor_screen_y()
	var screen_scale := _world_to_screen_scale()
	if player != null:
		player.set_input_enabled(false)
		player.visible = false
		# Freeze the cowboy so the camera (and saloon screen anchor) stay put
		# while the transparent ride-off plays over the finished trail.
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			camera.position_smoothing_enabled = false
	if transition != null:
		var stars := player.stars_collected if player != null else 0
		var message := tr("Trail complete!") if is_final_level else tr("Yeehaw!")
		if stars > 0:
			message = tr("%s  %d badges!") % [message, stars]
		transition.play_celebration(
			message,
			stars,
			saloon_screen,
			floor_screen_y,
			screen_scale
		)
	_completion.start()
	level_completed.emit()


func _goal_saloon_screen_position() -> Vector2:
	## Map the in-level saloon sprite center into CanvasLayer/screen space so the
	## celebration keeps the saloon where it already sits on screen.
	var goal := find_child("Goal", true, false) as Node2D
	if goal == null:
		return Vector2.INF
	var sprite := goal.get_node_or_null("Sprite2D") as Node2D
	var world_center: Vector2 = sprite.global_position if sprite != null else goal.global_position
	var canvas := get_viewport().get_canvas_transform()
	return canvas * world_center


func _trail_floor_screen_y() -> float:
	## Goal origin sits on the trail plank; prefer that over the cowboy's current
	## height so flyover completions still ride on the floor line.
	var canvas := get_viewport().get_canvas_transform()
	var goal := find_child("Goal", true, false) as Node2D
	if goal != null:
		return (canvas * goal.global_position).y
	if player != null:
		return (canvas * player.global_position).y
	return INF


func _world_to_screen_scale() -> float:
	var scale := get_viewport().get_canvas_transform().get_scale()
	if absf(scale.y) > 0.001:
		return absf(scale.y)
	if absf(scale.x) > 0.001:
		return absf(scale.x)
	return 1.0


func _handle_next_level_tap() -> void:
	if is_custom_level or is_final_level:
		return
	var now := Time.get_ticks_msec()
	if now - _next_level_tap_time_msec <= 450:
		_is_completing = true
		if player != null:
			player.set_input_enabled(false)
		GameManager.load_level(level_number + 1)
		return
	_next_level_tap_time_msec = now
	if hud != null:
		hud.show_toast("Press numpad + again for next trail", 1.0)


func _handle_next_boss_tap() -> void:
	if is_custom_level:
		return
	var now := Time.get_ticks_msec()
	if now - _next_boss_tap_time_msec <= 450:
		_is_completing = true
		if player != null:
			player.set_input_enabled(false)
		# From a trail: jump into the next boss after this level's slot
		# (or cycle starting from the first boss).
		GameManager.load_next_boss_from_level(
			campaign_source_level if campaign_source_level > 0 else level_number
		)
		return
	_next_boss_tap_time_msec = now
	if hud != null:
		hud.show_toast("Press numpad - again for next boss", 1.0)


func respawn_player() -> void:
	if player == null or _is_completing:
		return
	AudioManager.play_sfx(&"hurt")
	_clear_hostile_projectiles()
	var destination := get_active_respawn_position()
	player.respawn_at(destination)
	_reset_unstored_badges()
	_reset_unstored_opponents()
	_restore_camp_mode()
	for node in find_children("*", "Area2D", true, false):
		if node is ModeItem:
			(node as ModeItem).restore_if_needed()
	if hud != null:
		hud.show_toast("Oops! Back to camp!", 2.0)
	player_respawned.emit(destination)


func _clear_hostile_projectiles() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("hostile_projectile"):
		if is_instance_valid(node):
			node.queue_free()


func _store_badges_at_camp() -> void:
	_stored_badge_names = _collected_badge_names.duplicate()
	_stored_tied_opponent_names = _tied_opponent_names.duplicate()
	if player != null:
		var modes := player.get_modes()
		_stored_mode = modes.active_mode
		_stored_mode_remaining = modes.remaining


func _reset_unstored_badges() -> void:
	if player == null:
		return
	for node in find_children("*", "Area2D", true, false):
		if not (node is Star):
			continue
		var star := node as Star
		var badge_name := String(star.name)
		if badge_name in _stored_badge_names:
			star.restore_as_collected()
		else:
			star.restore_for_respawn()
	_collected_badge_names = _stored_badge_names.duplicate()
	player.stars_collected = _stored_badge_names.size()
	if hud != null:
		hud.set_stars(player.stars_collected)


func _reset_unstored_opponents() -> void:
	for node in find_children("*", "AnimatableBody2D", true, false):
		if not (node is Opponent):
			continue
		var opponent := node as Opponent
		var opponent_name := String(opponent.name)
		if opponent_name in _stored_tied_opponent_names:
			if not opponent.is_tied():
				opponent.tie_up(false)
		elif opponent.is_tied():
			opponent.untie_for_respawn()
	_tied_opponent_names = _stored_tied_opponent_names.duplicate()


func _restore_camp_mode() -> void:
	if player == null:
		return
	if _stored_mode == ModeController.Mode.NONE:
		player.clear_modes()
		return
	player.restore_mode(_stored_mode, _stored_mode_remaining, 20.0)


func _wire_ui() -> void:
	if pause_menu != null:
		pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		pause_menu.visible = false
		pause_menu.continue_pressed.connect(func() -> void: set_paused(false))
		pause_menu.save_pressed.connect(_on_save_pressed)
		pause_menu.load_pressed.connect(_on_load_pressed)
		pause_menu.restart_pressed.connect(_on_restart_pressed)
		pause_menu.save_select_pressed.connect(_on_save_select_pressed)
		pause_menu.settings_pressed.connect(_on_settings_pressed)
		pause_menu.set_save_options(
			not is_custom_level,
			not is_custom_level and GameManager.has_run_state(level_number)
		)
	if player != null and hud != null:
		player.star_collected.connect(_on_star_collected)
		player.mode_changed.connect(_on_player_mode_changed)


func _wire_world_objects() -> void:
	for node in find_children("*", "Area2D", true, false):
		if node is Checkpoint:
			var checkpoint := node as Checkpoint
			if not checkpoint.activated.is_connected(_on_checkpoint_activated):
				checkpoint.activated.connect(_on_checkpoint_activated)
		elif node is Goal:
			var goal := node as Goal
			if not goal.reached.is_connected(_on_goal_reached):
				goal.reached.connect(_on_goal_reached)
		elif node is Carrion:
			var carrion := node as Carrion
			if not carrion.hurt_player.is_connected(_on_opponent_hurt):
				carrion.hurt_player.connect(_on_opponent_hurt)
		elif node is Rattlesnake:
			var snake := node as Rattlesnake
			if not snake.hurt_player.is_connected(_on_opponent_hurt):
				snake.hurt_player.connect(_on_opponent_hurt)
		elif node is Hazard:
			var hazard := node as Hazard
			if not hazard.hurt.is_connected(_on_hazard_hurt):
				hazard.hurt.connect(_on_hazard_hurt.bind(hazard))
		elif node is Star:
			var star := node as Star
			var badge_name := String(star.name)
			star.collected.connect(_on_badge_taken.bind(badge_name))
		elif node is ModeItem:
			var item := node as ModeItem
			if not item.collected.is_connected(_on_mode_item_collected):
				item.collected.connect(_on_mode_item_collected)
		elif node is WindZone:
			var wind := node as WindZone
			if not wind.first_touch.is_connected(_on_wind_first_touch):
				wind.first_touch.connect(_on_wind_first_touch)
		elif node is SpringPad:
			var spring := node as SpringPad
			if not spring.bounced.is_connected(_on_spring_bounced):
				spring.bounced.connect(_on_spring_bounced)
	for node in find_children("*", "AnimatableBody2D", true, false):
		if node is Opponent:
			var opponent := node as Opponent
			if not opponent.hurt_player.is_connected(_on_opponent_hurt):
				opponent.hurt_player.connect(_on_opponent_hurt)
			if not opponent.bounty_caught.is_connected(_on_bounty_caught):
				opponent.bounty_caught.connect(_on_bounty_caught)
			if not opponent.captured.is_connected(_on_opponent_captured):
				opponent.captured.connect(_on_opponent_captured)
	for node in find_children("*", "PhysicsBody2D", true, false):
		if node is ConveyorBelt:
			var belt := node as ConveyorBelt
			if not belt.first_ride.is_connected(_on_conveyor_first_ride):
				belt.first_ride.connect(_on_conveyor_first_ride)
		elif node is TimedDoor:
			var door := node as TimedDoor
			if not door.first_warn.is_connected(_on_door_first_warn):
				door.first_warn.connect(_on_door_first_warn)


func _on_checkpoint_activated(checkpoint: Checkpoint) -> void:
	if _active_checkpoint != null and _active_checkpoint != checkpoint:
		_active_checkpoint.deactivate()
	_active_checkpoint = checkpoint
	_store_badges_at_camp()
	if not _restoring_run_state and not is_custom_level:
		_save_run_state(false)
	if hud != null:
		hud.show_toast("Camp saved!", 1.8)
	if bool(GameManager.get_settings().get("vibration", true)) and InputManager.is_controller():
		Input.start_joy_vibration(0, 0.15, 0.0, 0.1)


func _on_mode_item_collected(mode: ModeController.Mode) -> void:
	if hud == null:
		return
	var toast := ModeController.mode_toast(mode)
	if not toast.is_empty():
		hud.show_toast(toast, 3.0)


func _on_wind_first_touch() -> void:
	if hud != null:
		hud.show_toast("Wind pushes you!", 2.0)


func _on_spring_bounced() -> void:
	if hud != null:
		hud.show_toast("Boing! Springs launch you up!", 2.4)


func _on_conveyor_first_ride() -> void:
	if hud != null:
		hud.show_toast("The belt pushes you along!", 2.4)


func _on_door_first_warn() -> void:
	if hud != null:
		hud.show_toast("Watch the gate! Wait or hurry!", 2.6)


func _on_player_mode_changed(mode_name: String, remaining: float) -> void:
	if hud != null:
		hud.set_mode(mode_name, remaining)


func _on_star_collected(total: int) -> void:
	if hud != null:
		hud.set_stars(total)
		if total > 0 and total % 5 == 0:
			hud.show_toast(tr("Nice! %d badges!") % total, 1.8)


func _on_badge_taken(badge_name: String) -> void:
	if badge_name not in _collected_badge_names:
		_collected_badge_names.append(badge_name)


func _on_opponent_captured(opponent: Opponent) -> void:
	var opponent_name := String(opponent.name)
	if opponent_name not in _tied_opponent_names:
		_tied_opponent_names.append(opponent_name)


func _save_run_state(show_feedback: bool = true) -> bool:
	if is_custom_level or player == null:
		return false
	var checkpoint_name := String(_active_checkpoint.name) if _active_checkpoint != null else ""
	var saved := GameManager.save_run_state(
		level_number,
		checkpoint_name,
		_stored_badge_names,
		_stored_badge_names.size(),
		_play_time,
		_stored_tied_opponent_names,
		int(_stored_mode),
		_stored_mode_remaining
	)
	if saved:
		if pause_menu != null:
			pause_menu.set_save_options(true, true)
		if show_feedback and hud != null:
			hud.show_toast("Game saved at camp!", 2.0)
	return saved


func _restore_run_state() -> void:
	if is_custom_level or player == null:
		return
	var state := GameManager.get_run_state(level_number)
	if state.is_empty():
		return
	_restoring_run_state = true
	_loaded_run_state = true
	_play_time = maxf(float(state.get("level_play_time", 0.0)), 0.0)
	var saved_names: Variant = state.get("collected_badges", [])
	if saved_names is Array:
		for value in saved_names:
			var badge_name := str(value)
			if badge_name not in _collected_badge_names:
				_collected_badge_names.append(badge_name)
			if badge_name not in _stored_badge_names:
				_stored_badge_names.append(badge_name)
			var badge := find_child(badge_name, true, false) as Star
			if badge != null:
				badge.restore_as_collected()
	var saved_opponents: Variant = state.get("tied_opponents", [])
	if saved_opponents is Array:
		for value in saved_opponents:
			var opponent_name := str(value)
			if opponent_name not in _tied_opponent_names:
				_tied_opponent_names.append(opponent_name)
			if opponent_name not in _stored_tied_opponent_names:
				_stored_tied_opponent_names.append(opponent_name)
	for node in find_children("*", "AnimatableBody2D", true, false):
		if node is Opponent:
			var opponent := node as Opponent
			if String(opponent.name) in _stored_tied_opponent_names:
				opponent.tie_up(false)
	_stored_mode = int(state.get("active_mode", ModeController.Mode.NONE))
	_stored_mode_remaining = maxf(float(state.get("mode_remaining", 0.0)), 0.0)
	if _stored_mode != ModeController.Mode.NONE:
		player.restore_mode(_stored_mode, _stored_mode_remaining, 20.0)
	player.stars_collected = maxi(int(state.get("stars_found", 0)), _stored_badge_names.size())
	var checkpoint_name := str(state.get("checkpoint_name", ""))
	if not checkpoint_name.is_empty():
		var checkpoint := find_child(checkpoint_name, true, false) as Checkpoint
		if checkpoint != null:
			checkpoint.activate()
			player.respawn_at(checkpoint.get_respawn_position())
	if hud != null:
		hud.set_stars(player.stars_collected)
	_restoring_run_state = false


func _on_goal_reached(_goal: Goal) -> void:
	AudioManager.play_sfx(&"goal")
	begin_completion()


func _on_hazard_hurt(hurt_player: Player, hazard: Hazard) -> void:
	if hazard.is_cactus() and hurt_player.get_modes().has_shield():
		hurt_player.bounce_from_hazard(hazard.global_position)
		if hud != null:
			hud.show_toast("Bounce! Bubble safe!", 1.4)
		return
	if hazard.is_canyon():
		_play_canyon_fall_and_respawn()
		return
	if hurt_player.is_invulnerable():
		return
	respawn_player()


func _play_canyon_fall_and_respawn() -> void:
	if _is_recovering or player == null or _is_completing:
		return
	if player.is_canyon_falling():
		return
	_is_recovering = true
	await player.play_canyon_fall()
	respawn_player()
	# Keep recovering through respawn invulnerability so held move keys
	# cannot immediately restart the canyon fall.
	var grace := player.respawn_invulnerability_time if player != null else 0.85
	await get_tree().create_timer(grace).timeout
	_is_recovering = false


func _on_opponent_hurt(_hurt_player: Player) -> void:
	respawn_player()


func _on_bounty_caught(opponent: Opponent, amount: int) -> void:
	if player == null or amount <= 0:
		return
	var new_badges := 0
	for index in range(amount):
		var bounty_name := "Bounty_%s_%d" % [opponent.name, index]
		if bounty_name not in _collected_badge_names:
			_collected_badge_names.append(bounty_name)
			new_badges += 1
	if new_badges <= 0:
		return
	player.collect_badges(new_badges)
	var reward_effect := BOUNTY_REWARD_EFFECT.new()
	reward_effect.name = "BountyRewardEffect"
	add_child(reward_effect)
	reward_effect.play(opponent.global_position, player.global_position, new_badges)
	if hud != null:
		hud.show_toast(tr("Bounty caught! +%d badges!") % new_badges, 2.2)


func _on_celebration_finished() -> void:
	if is_custom_level:
		GameManager.return_from_custom_level()
		return
	GameManager.add_play_time(_play_time)
	var stars := player.stars_collected if player != null else 0
	GameManager.complete_level(level_number, stars)
	if GameManager.try_load_boss_after(level_number):
		return
	if is_final_level:
		GameManager.finish_campaign()
	else:
		GameManager.request_horse_arrival()
		GameManager.load_level(level_number + 1)


func _play_horse_arrival() -> void:
	if transition == null or player == null:
		return
	player.visible = false
	player.set_input_enabled(false)
	transition.play_arrival()
	await transition.arrival_finished
	if not is_instance_valid(player):
		return
	player.visible = true
	player.set_input_enabled(true)


func _on_save_pressed() -> void:
	if _save_run_state(true):
		set_paused(false)


func _on_load_pressed() -> void:
	get_tree().paused = false
	_paused = false
	GameManager.load_saved_run(level_number)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	if is_custom_level:
		GameManager.play_custom_level(GameManager.active_custom_slot, GameManager.custom_return_to_editor)
		return
	GameManager.restart_campaign_from_start()


func _on_save_select_pressed() -> void:
	get_tree().paused = false
	if is_custom_level:
		GameManager.return_from_custom_level()
		return
	GameManager.add_play_time(_play_time)
	_play_time = 0.0
	_save_run_state(false)
	GameManager.save_to_disk()
	GameManager.return_to_save_select()


func _on_settings_pressed() -> void:
	if pause_menu != null:
		pause_menu.show_settings()


func _on_device_changed(_device: Variant) -> void:
	if hud != null:
		hud.set_prompt(_gameplay_prompt())


func _gameplay_prompt() -> String:
	return tr("Move: %s   Jump: %s   Lasso: %s   Pause: %s") % [
		InputManager.prompt_for(&"move_left"),
		InputManager.prompt_for(&"jump"),
		InputManager.prompt_for(&"lasso"),
		InputManager.prompt_for(&"pause"),
	]


func _update_trail_progress() -> void:
	if hud == null or player == null or spawn_point == null:
		return
	var goal := find_child("Goal", true, false) as Node2D
	if goal == null:
		return
	var start_x := spawn_point.global_position.x
	var end_x := goal.global_position.x
	var span := maxf(end_x - start_x, 1.0)
	var ratio := (player.global_position.x - start_x) / span
	hud.set_trail_progress(ratio)
	_maybe_progress_toast(ratio)


func _animate_sun() -> void:
	var sun := get_node_or_null("Sun") as CanvasItem
	if sun == null:
		return
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(sun, "modulate", Color(1.0, 1.0, 0.85, 1.0), 1.4)
	tween.tween_property(sun, "modulate", Color(1.0, 0.92, 0.55, 1.0), 1.4)


func _maybe_progress_toast(ratio: float) -> void:
	if hud == null:
		return
	var checks := [
		[0.25, "Nice ride! Keep going!"],
		[0.5, "Halfway to the saloon!"],
		[0.75, "Almost there, cowboy!"],
		[0.92, "The saloon is close!"],
	]
	for entry in checks:
		var mark: float = float(entry[0])
		var key := str(mark)
		if ratio >= mark and not bool(_progress_milestones.get(key, false)):
			_progress_milestones[key] = true
			hud.show_toast(str(entry[1]), 2.4)
