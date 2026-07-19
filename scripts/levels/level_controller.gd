class_name LevelController
extends Node2D

## Owns spawn, checkpoints, hazards, goal completion, and next-level loading.

signal level_completed
signal player_respawned(position: Vector2)

@export_file("*.tscn") var next_level_scene: String = ""
@export var celebration_duration: float = 3.5
@export var level_title: String = "Level"

var spawn_point: Marker2D
var player: Player
var transition: LevelTransition

var _active_checkpoint: Checkpoint
var _completion: LevelCompletionFlow
var _is_completing: bool = false
var _is_set_up: bool = false


func _ready() -> void:
	setup_level()


func setup_level() -> void:
	if _is_set_up:
		return
	_is_set_up = true

	spawn_point = get_node_or_null("SpawnPoint") as Marker2D
	var player_node := get_node_or_null("Player")
	if player_node is Player:
		player = player_node as Player
	transition = get_node_or_null("LevelTransition") as LevelTransition

	_completion = LevelCompletionFlow.new(celebration_duration)
	_completion.finished.connect(_on_celebration_finished)
	_wire_world_objects()
	if player != null and spawn_point != null:
		player.respawn_at(spawn_point.global_position)


func _process(delta: float) -> void:
	if _completion == null or not _completion.is_active:
		return
	_completion.tick(delta)
	if transition != null:
		transition.set_progress(_completion.progress())


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
		transition.play_celebration()
	_completion.start()
	level_completed.emit()


func respawn_player() -> void:
	if player == null or _is_completing:
		return
	var destination := get_active_respawn_position()
	player.respawn_at(destination)
	player_respawned.emit(destination)


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


func _on_checkpoint_activated(checkpoint: Checkpoint) -> void:
	if _active_checkpoint != null and _active_checkpoint != checkpoint:
		_active_checkpoint.deactivate()
	_active_checkpoint = checkpoint


func _on_goal_reached(_goal: Goal) -> void:
	begin_completion()


func _on_hazard_hurt(_hurt_player: Player) -> void:
	respawn_player()


func _on_celebration_finished() -> void:
	if next_level_scene.is_empty():
		push_warning("Level '%s' has no next_level_scene configured." % level_title)
		return
	get_tree().change_scene_to_file(next_level_scene)
