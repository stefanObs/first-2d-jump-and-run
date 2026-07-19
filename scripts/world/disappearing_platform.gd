class_name DisappearingPlatform
extends StaticBody2D

@export var visible_time: float = 2.0
@export var hidden_time: float = 1.5
@export var start_delay: float = 0.0
@export var warn_time: float = 0.75
@export var always_solid: bool = false
@export var purpose_label: String = "CLOUD"

var _timer: float = 0.0
var _solid: bool = true
var _started: bool = false
var _shape: CollisionShape2D
var _visual: CanvasItem
var _label: Label
var _extras: Array[CanvasItem] = []
var _blink_phase: float = 0.0


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_visual = get_node_or_null("Visual") as CanvasItem
	_label = get_node_or_null("Label") as Label
	for child in get_children():
		if child is CanvasItem and (String(child.name).begins_with("Fluff") or child == _visual):
			_extras.append(child as CanvasItem)
	if _extras.is_empty() and _visual != null:
		_extras.append(_visual)
	_timer = start_delay
	_started = start_delay <= 0.0
	_apply_state()


func _process(delta: float) -> void:
	if always_solid:
		_solid = true
		_apply_state()
		if _label != null:
			_label.text = purpose_label if purpose_label != "" else "CLOUD"
		return
	_timer -= delta
	_blink_phase += delta * 14.0
	if not _started:
		if _timer > 0.0:
			return
		_started = true
		_solid = true
		_timer = visible_time
		_apply_state()
		return

	if _timer <= 0.0:
		_solid = not _solid
		_timer = visible_time if _solid else hidden_time
		_apply_state()
		return

	_update_warning_blink()


func _apply_state() -> void:
	if _shape != null:
		_shape.disabled = not _solid
	var alpha := 1.0 if _solid else 0.25
	for item in _extras:
		item.modulate = Color(1, 1, 1, alpha)
	if _label != null:
		var text := purpose_label if purpose_label != "" else "CLOUD"
		_label.text = text if _solid else "..."
		_label.modulate = Color(1, 1, 1, alpha)


func _update_warning_blink() -> void:
	if not _solid:
		return
	if _timer > warn_time:
		for item in _extras:
			item.modulate = Color(1, 1, 1, 1.0)
		if _label != null:
			_label.text = purpose_label if purpose_label != "" else "CLOUD"
			_label.modulate = Color(1, 1, 1, 1)
		return
	var pulse := 0.4 + absf(sin(_blink_phase)) * 0.6
	var warn := Color(1.0, 0.9, 0.35, pulse)
	for item in _extras:
		item.modulate = warn
	if _label != null:
		_label.text = "WAIT!"
		_label.modulate = Color(0.85, 0.35, 0.1, 1.0)
		_label.add_theme_font_size_override(&"font_size", 18)
		_label.scale = Vector2(1.0 + absf(sin(_blink_phase)) * 0.15, 1.0)
