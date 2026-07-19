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
