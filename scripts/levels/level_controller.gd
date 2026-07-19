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
	if hud != null:
		hud.set_level_title(level_title)
		hud.set_prompt(_gameplay_prompt())
		InputManager.device_changed.connect(_on_device_changed)


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
		var message := "Trail complete!" if is_final_level else "Yeehaw!"
		transition.play_celebration(message)
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
		player.star_collected.connect(hud.set_stars)
		player.mode_changed.connect(hud.set_mode)


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
	for node in find_children("*", "AnimatableBody2D", true, false):
		if node is Opponent:
			var opponent := node as Opponent
			if not opponent.hurt_player.is_connected(_on_hazard_hurt):
				opponent.hurt_player.connect(_on_hazard_hurt)


func _on_checkpoint_activated(checkpoint: Checkpoint) -> void:
	if _active_checkpoint != null and _active_checkpoint != checkpoint:
		_active_checkpoint.deactivate()
	_active_checkpoint = checkpoint
	if bool(GameManager.get_settings().get("vibration", true)) and InputManager.is_controller():
		Input.start_joy_vibration(0, 0.15, 0.0, 0.1)


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
