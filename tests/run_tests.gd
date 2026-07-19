extends SceneTree

## Headless test runner for pure gameplay helpers.
## Run with: godot --headless --path . -s res://tests/run_tests.gd


func _initialize() -> void:
	var failures := 0
	failures += _run("JumpAssist coyote allows brief airborne jump", _test_coyote_jump)
	failures += _run("JumpAssist buffer remembers early jump press", _test_jump_buffer)
	failures += _run("JumpAssist consume clears coyote and buffer", _test_consume_clears_state)
	failures += _run("InputBindings registers required actions", _test_input_bindings_actions)
	failures += _run("Main scene loads with a Player", _test_main_scene_has_player)
	failures += _run("LevelCompletionFlow finishes after duration", _test_completion_flow)
	failures += _run("Level 01 wires checkpoint, hazard, and goal", _test_level_01_world_objects)
	failures += _run("LevelController respawns at active checkpoint", _test_respawn_uses_checkpoint)
	failures += _run("Goal completion disables player input", _test_goal_disables_input)

	if failures == 0:
		print("All tests passed.")
		quit(0)
	else:
		printerr("Tests failed: %d" % failures)
		quit(1)


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
		return "Expected coyote jump to remain available shortly after leaving the floor."
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
		return "Expected buffered jump to trigger on landing."
	return null


func _test_consume_clears_state() -> Variant:
	var assist := JumpAssist.new(0.12, 0.12)
	assist.notify_grounded(true)
	assist.notify_jump_pressed()
	assist.consume_jump()
	if assist.coyote_remaining() != 0.0 or assist.buffer_remaining() != 0.0:
		return "Expected consume_jump to clear coyote and buffer timers."
	if assist.should_consume_buffered_jump(false):
		return "Expected no buffered jump after consume."
	return null


func _test_input_bindings_actions() -> Variant:
	var required: Array[StringName] = [
		&"move_left",
		&"move_right",
		&"jump",
		&"pause",
		&"confirm",
		&"back",
	]
	var bindings_script: GDScript = load("res://scripts/autoload/input_bindings.gd")
	var bindings: Node = bindings_script.new()
	bindings._ready()
	for action in required:
		if not InputMap.has_action(action):
			bindings.free()
			return "Missing input action: %s" % String(action)
		if InputMap.action_get_events(action).is_empty():
			bindings.free()
			return "Action has no events: %s" % String(action)
	bindings.free()
	return null


func _test_main_scene_has_player() -> Variant:
	var packed: PackedScene = load("res://scenes/main.tscn")
	if packed == null:
		return "Failed to load main scene."
	var root: Node = packed.instantiate()
	root.name = "TestMain"
	root.set_process(false)
	root.set_physics_process(false)
	var player := root.find_child("Player", true, false)
	if player == null:
		root.free()
		return "Main scene does not contain a Player node."
	if not (player is Player):
		root.free()
		return "Player node is not using the Player script."
	root.free()
	return null


func _test_completion_flow() -> Variant:
	var flow := LevelCompletionFlow.new(1.0)
	flow.start()
	if not flow.is_active:
		return "Expected flow to be active after start."
	if flow.tick(0.4):
		return "Expected flow to remain active before duration elapses."
	if not is_equal_approx(flow.progress(), 0.4):
		return "Unexpected progress value: %s" % str(flow.progress())
	if not flow.tick(0.7):
		return "Expected flow to finish after full duration."
	if flow.is_active:
		return "Expected flow to become inactive after finishing."
	return null


func _test_level_01_world_objects() -> Variant:
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		return level
	var node := level as LevelController
	var checkpoint := node.find_child("Checkpoint", true, false)
	var hazard := node.find_child("PitHazard", true, false)
	var goal := node.find_child("Goal", true, false)
	var transition := node.find_child("LevelTransition", true, false)
	var error: Variant = null
	if checkpoint == null or not (checkpoint is Checkpoint):
		error = "Level 01 is missing a Checkpoint."
	elif hazard == null or not (hazard is Hazard):
		error = "Level 01 is missing a Hazard."
	elif goal == null or not (goal is Goal):
		error = "Level 01 is missing a Goal."
	elif transition == null or not (transition is LevelTransition):
		error = "Level 01 is missing LevelTransition."
	elif node.next_level_scene != "res://scenes/levels/level_02.tscn":
		error = "Level 01 next_level_scene should point to Level 02."
	_free_level(node)
	return error


func _test_respawn_uses_checkpoint() -> Variant:
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		return level
	var controller := level as LevelController
	if controller.player == null:
		_free_level(controller)
		return "LevelController.player was not resolved."
	var checkpoint := controller.find_child("Checkpoint", true, false) as Checkpoint
	checkpoint.activate()
	controller.respawn_player()
	var player := controller.player
	var error: Variant = null
	if player.global_position.distance_to(checkpoint.get_respawn_position()) > 0.1:
		error = "Player did not respawn at the active checkpoint."
	elif not player.is_invulnerable():
		error = "Expected brief invulnerability after respawn."
	_free_level(controller)
	return error


func _test_goal_disables_input() -> Variant:
	var level: Variant = _instantiate_level("res://scenes/levels/level_01.tscn")
	if level is String:
		return level
	var controller := level as LevelController
	if controller.player == null:
		_free_level(controller)
		return "LevelController.player was not resolved."
	controller.begin_completion()
	var error: Variant = null
	if controller.player.input_enabled:
		error = "Expected player input to be disabled during celebration."
	elif controller.get_node_or_null("LevelTransition") == null:
		error = "Expected transition overlay to exist."
	_free_level(controller)
	return error


func _instantiate_level(path: String) -> Variant:
	var packed: PackedScene = load(path)
	if packed == null:
		return "Failed to load scene: %s" % path
	var level: Node = packed.instantiate()
	if not (level is LevelController):
		level.free()
		return "Scene root is not a LevelController: %s" % path
	root.add_child(level)
	var controller := level as LevelController
	controller.setup_level()
	if controller.player == null:
		var player_node := controller.get_node_or_null("Player")
		_free_level(controller)
		return "Failed to resolve Player node (found=%s)." % str(player_node)
	return level


func _free_level(level: Node) -> void:
	if level.get_parent() != null:
		level.get_parent().remove_child(level)
	level.free()
