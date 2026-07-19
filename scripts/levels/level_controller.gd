class_name LevelController
extends Node2D

## Owns spawn, checkpoints, hazards, goal completion, HUD, and pause.

signal level_completed
signal player_respawned(position: Vector2)

@export var level_number: int = 1
@export var celebration_duration: float = 3.5
@export var level_title: String = "Level"
@export var is_final_level: bool = false

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


func _ready() -> void:
	setup_level()


func _process(delta: float) -> void:
	if _paused or _is_completing:
		if _completion != null and _completion.is_active:
			_completion.tick(delta)
			if transition != null:
				transition.set_progress(_completion.progress())
		return

	_play_time += delta
	_update_trail_progress()
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
	WildWestTheme.apply_to_level(self)
	WildWestTheme.configure_player_camera(self, player)
	_animate_sun()
	if hud != null:
		hud.set_level_title(level_title)
		hud.set_prompt(_gameplay_prompt())
		var hint := get_node_or_null("HintLabel") as Label
		var tip := hint.text if hint != null and not String(hint.text).is_empty() else "Let's go: %s!" % level_title
		hud.show_toast(tip, 4.5)
		if hint != null:
			hint.visible = false
		_setup_camp_marks()
		InputManager.device_changed.connect(_on_device_changed)


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
	if player != null:
		player.set_input_enabled(false)
	if transition != null:
		var stars := player.stars_collected if player != null else 0
		var message := "Trail complete!" if is_final_level else "Yeehaw!"
		if stars > 0:
			message = "%s  %d badges!" % [message, stars]
		transition.play_celebration(message, stars)
	_completion.start()
	level_completed.emit()


func respawn_player() -> void:
	if player == null or _is_completing:
		return
	var destination := get_active_respawn_position()
	player.respawn_at(destination)
	for node in find_children("*", "Area2D", true, false):
		if node is ModeItem:
			(node as ModeItem).restore_if_needed()
	if hud != null:
		hud.show_toast("Oops! Back to camp!", 2.0)
	player_respawned.emit(destination)


func _wire_ui() -> void:
	if pause_menu != null:
		pause_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		pause_menu.visible = false
		pause_menu.continue_pressed.connect(func() -> void: set_paused(false))
		pause_menu.restart_pressed.connect(_on_restart_pressed)
		pause_menu.save_select_pressed.connect(_on_save_select_pressed)
		pause_menu.settings_pressed.connect(_on_settings_pressed)
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
		elif node is Hazard:
			var hazard := node as Hazard
			if not hazard.hurt.is_connected(_on_hazard_hurt):
				hazard.hurt.connect(_on_hazard_hurt)
		elif node is ModeItem:
			var item := node as ModeItem
			if not item.collected.is_connected(_on_mode_item_collected):
				item.collected.connect(_on_mode_item_collected)
		elif node is WindZone:
			var wind := node as WindZone
			if not wind.first_touch.is_connected(_on_wind_first_touch):
				wind.first_touch.connect(_on_wind_first_touch)
	for node in find_children("*", "AnimatableBody2D", true, false):
		if node is Opponent:
			var opponent := node as Opponent
			if not opponent.hurt_player.is_connected(_on_hazard_hurt):
				opponent.hurt_player.connect(_on_hazard_hurt)


func _on_checkpoint_activated(checkpoint: Checkpoint) -> void:
	if _active_checkpoint != null and _active_checkpoint != checkpoint:
		_active_checkpoint.deactivate()
	_active_checkpoint = checkpoint
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


func _on_player_mode_changed(mode_name: String, remaining: float) -> void:
	if hud != null:
		hud.set_mode(mode_name, remaining)


func _on_star_collected(total: int) -> void:
	if hud != null:
		hud.set_stars(total)
		if total > 0 and total % 5 == 0:
			hud.show_toast("Nice! %d badges!" % total, 1.8)


func _on_goal_reached(_goal: Goal) -> void:
	begin_completion()


func _on_hazard_hurt(_hurt_player: Player) -> void:
	respawn_player()


func _on_celebration_finished() -> void:
	GameManager.add_play_time(_play_time)
	var stars := player.stars_collected if player != null else 0
	GameManager.complete_level(level_number, stars)
	if is_final_level:
		GameManager.return_to_save_select()
	else:
		GameManager.load_level(level_number + 1)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	GameManager.restart_current_level()


func _on_save_select_pressed() -> void:
	get_tree().paused = false
	GameManager.add_play_time(_play_time)
	GameManager.save_to_disk()
	GameManager.return_to_save_select()


func _on_settings_pressed() -> void:
	if pause_menu != null:
		pause_menu.show_settings()


func _on_device_changed(_device: Variant) -> void:
	if hud != null:
		hud.set_prompt(_gameplay_prompt())


func _gameplay_prompt() -> String:
	return "Move: %s   Jump: %s   Pause: %s" % [
		InputManager.prompt_for(&"move_left"),
		InputManager.prompt_for(&"jump"),
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
