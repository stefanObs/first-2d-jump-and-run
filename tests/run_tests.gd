extends SceneTree

## Compatibility wrapper. Prefer: godot --headless --path . res://tests/test_runner.tscn


func _initialize() -> void:
	print("Use: godot --headless --path . res://tests/test_runner.tscn")
	change_scene_to_file("res://tests/test_runner.tscn")
