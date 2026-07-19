class_name TimedDoor
extends StaticBody2D

## Ranch fence gate that swings open and shut on a timer.

signal first_warn

@export var open_time: float = 2.8
@export var closed_time: float = 1.6
@export var start_open: bool = false
@export var warn_time: float = 0.85

var _open: bool = false
var _timer: float = 0.0
var _shape: CollisionShape2D
var _visual: Node2D
var _left_gate: Sprite2D
var _right_gate: Sprite2D
var _post_left: ColorRect
var _post_right: ColorRect
var _label: Label
var _blink_phase: float = 0.0
var _warned: bool = false
var _animating: bool = false


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_label = get_node_or_null("Label") as Label
	_setup_fence_visual()
	_open = start_open
	_timer = open_time if _open else closed_time
	_apply_state(false)
	z_index = 2


func _process(delta: float) -> void:
	_timer -= delta
	_blink_phase += delta * 14.0
	if _timer <= 0.0:
		_open = not _open
		_timer = open_time if _open else closed_time
		_warned = false
		_apply_state(true)
		return
	_update_warning_blink()


func _setup_fence_visual() -> void:
	var old := get_node_or_null("Visual")
	if old != null:
		old.queue_free()
	_visual = get_node_or_null("FenceGates") as Node2D
	if _visual == null:
		_visual = Node2D.new()
		_visual.name = "FenceGates"
		_visual.position = Vector2(0, -52)
		add_child(_visual)
	# Visible wooden posts so the gate is always readable.
	if _post_left == null:
		_post_left = ColorRect.new()
		_post_left.name = "PostLeft"
		_post_left.size = Vector2(14, 104)
		_post_left.position = Vector2(-40, -52)
		_post_left.color = Color(0.45, 0.26, 0.12, 1)
		_post_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_post_left)
	if _post_right == null:
		_post_right = ColorRect.new()
		_post_right.name = "PostRight"
		_post_right.size = Vector2(14, 104)
		_post_right.position = Vector2(26, -52)
		_post_right.color = Color(0.45, 0.26, 0.12, 1)
		_post_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_post_right)
	var tex: Texture2D = load("res://assets/world/fence_gate.png")
	_left_gate = _visual.get_node_or_null("LeftGate") as Sprite2D
	if _left_gate == null:
		_left_gate = Sprite2D.new()
		_left_gate.name = "LeftGate"
		_left_gate.centered = true
		_visual.add_child(_left_gate)
	_left_gate.texture = tex
	_left_gate.offset = Vector2(28, 0)
	_left_gate.position = Vector2(-28, 0)
	_left_gate.scale = Vector2(1.15, 1.05)
	_left_gate.modulate = Color(1.05, 1.0, 0.95, 1.0)
	_right_gate = _visual.get_node_or_null("RightGate") as Sprite2D
	if _right_gate == null:
		_right_gate = Sprite2D.new()
		_right_gate.name = "RightGate"
		_right_gate.centered = true
		_visual.add_child(_right_gate)
	_right_gate.texture = tex
	_right_gate.offset = Vector2(-28, 0)
	_right_gate.position = Vector2(28, 0)
	_right_gate.scale = Vector2(-1.15, 1.05)
	_right_gate.modulate = Color(1.05, 1.0, 0.95, 1.0)
	if _shape != null:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(72, 108)
		_shape.shape = rect
		_shape.position = Vector2(0, -54)
	if _label != null:
		_label.position = Vector2(-44, -130)
		_label.z_index = 3


func _apply_state(animate: bool) -> void:
	if _shape != null:
		_shape.set_deferred("disabled", _open)
	if _label != null:
		_label.text = "OPEN" if _open else "FENCE"
		_label.modulate = Color(0.2, 0.55, 0.18, 1.0) if _open else Color(0.55, 0.22, 0.08, 1.0)
		_label.add_theme_font_size_override(&"font_size", 16)
	if animate:
		_animate_gates()
	else:
		_snap_gates()


func _snap_gates() -> void:
	if _left_gate == null or _right_gate == null:
		return
	_left_gate.rotation_degrees = -82.0 if _open else 0.0
	_right_gate.rotation_degrees = 82.0 if _open else 0.0
	_visual.modulate = Color(1, 1, 1, 1)


func _animate_gates() -> void:
	if _left_gate == null or _right_gate == null:
		_snap_gates()
		return
	if _animating:
		return
	_animating = true
	var left_rot := -82.0 if _open else 0.0
	var right_rot := 82.0 if _open else 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_left_gate, "rotation_degrees", left_rot, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_right_gate, "rotation_degrees", right_rot, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	_animating = false


func _update_warning_blink() -> void:
	if _visual == null:
		return
	if _timer > warn_time:
		_visual.modulate = Color(1, 1, 1, 1)
		if _label != null:
			_label.text = "OPEN" if _open else "FENCE"
		return
	if not _warned:
		_warned = true
		first_warn.emit()
	var pulse := 0.55 + absf(sin(_blink_phase)) * 0.45
	_visual.modulate = Color(1.0, 0.88, 0.3, pulse)
	if _label != null:
		_label.text = "HURRY!" if _open else "WAIT!"
		_label.add_theme_font_size_override(&"font_size", 18)
