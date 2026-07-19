extends Node

## Tracks the active input device and provides child-friendly prompt text.

enum Device { KEYBOARD, CONTROLLER }

signal device_changed(device: Device)

var active_device: Device = Device.KEYBOARD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		_set_device(Device.KEYBOARD)
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) < 0.5:
			return
		_set_device(Device.CONTROLLER)


func is_controller() -> bool:
	return active_device == Device.CONTROLLER


func prompt_for(action: StringName) -> String:
	match String(action):
		"jump", "confirm":
			return "A" if is_controller() else "Space / Enter"
		"lasso":
			return "X" if is_controller() else "Alt / F / L"
		"back", "pause":
			return "B / Menu" if is_controller() else "Esc"
		"move_left", "move_right":
			return "Left stick / D-pad" if is_controller() else "A/D or Arrows"
		_:
			return String(action)


func menu_prompt_line() -> String:
	if is_controller():
		return "Move: D-pad / stick   Confirm: A   Back: B"
	return "Move: Arrows   Confirm: Enter   Back: Esc"


func _set_device(device: Device) -> void:
	if active_device == device:
		return
	active_device = device
	device_changed.emit(device)
