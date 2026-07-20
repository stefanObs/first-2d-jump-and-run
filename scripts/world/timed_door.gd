class_name TimedDoor
extends StaticBody2D

## Ranch fence gate that swings open and shut on a timer.
## Fixed posts stay put; only the gate leaves swing so open/closed is obvious.

signal first_warn

@export var open_time: float = 2.8
@export var closed_time: float = 1.6
@export var start_open: bool = false
@export var warn_time: float = 0.85

const POST_TEX := preload("res://assets/world/fence_post.png")
const FENCE_TEX := preload("res://assets/world/fence.png")
const OPEN_DEG := 98.0
const ANIM_SEC := 0.55

var _open: bool = false
var _timer: float = 0.0
var _shape: CollisionShape2D
var _visual: Node2D
var _left_gate: Node2D
var _right_gate: Node2D
var _label: Label
var _blink_phase: float = 0.0
var _warned: bool = false
var _gate_tween: Tween
var _status_bg: ColorRect


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
	for child_name in ["FenceGates", "FenceFrame", "StatusPlate"]:
		var existing := get_node_or_null(child_name)
		if existing != null:
			existing.queue_free()

	var frame := Node2D.new()
	frame.name = "FenceFrame"
	add_child(frame)

	# Outer fence wings + four upright posts (not just two ColorRects).
	_add_fence_wing(frame, Vector2(-148, -40), false)
	_add_fence_wing(frame, Vector2(148, -40), true)
	_add_post(frame, Vector2(-118, -48), 1.15)
	_add_post(frame, Vector2(-58, -48), 1.25)
	_add_post(frame, Vector2(58, -48), 1.25)
	_add_post(frame, Vector2(118, -48), 1.15)

	_visual = Node2D.new()
	_visual.name = "FenceGates"
	_visual.position = Vector2(0, -56)
	add_child(_visual)

	_left_gate = _make_gate_leaf(true)
	_left_gate.name = "LeftGate"
	_left_gate.position = Vector2(-52, 0)
	_visual.add_child(_left_gate)

	_right_gate = _make_gate_leaf(false)
	_right_gate.name = "RightGate"
	_right_gate.position = Vector2(52, 0)
	_visual.add_child(_right_gate)

	_status_bg = ColorRect.new()
	_status_bg.name = "StatusPlate"
	_status_bg.size = Vector2(110, 28)
	_status_bg.position = Vector2(-55, -148)
	_status_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_bg.z_index = 2
	add_child(_status_bg)

	if _shape != null:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(96, 112)
		_shape.shape = rect
		_shape.position = Vector2(0, -56)
	if _label != null:
		_label.position = Vector2(-52, -146)
		_label.size = Vector2(104, 28)
		_label.z_index = 3
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _add_post(parent: Node2D, at: Vector2, scale_mul: float) -> void:
	var post := Sprite2D.new()
	post.texture = POST_TEX
	post.centered = true
	post.position = at
	post.scale = Vector2(scale_mul, scale_mul)
	post.z_index = 1
	parent.add_child(post)


func _add_fence_wing(parent: Node2D, at: Vector2, flip: bool) -> void:
	var wing := Sprite2D.new()
	wing.texture = FENCE_TEX
	wing.centered = true
	wing.position = at
	wing.scale = Vector2(-0.72 if flip else 0.72, 0.85)
	wing.z_index = 0
	wing.modulate = Color(0.95, 0.92, 0.88, 1.0)
	parent.add_child(wing)


func _make_gate_leaf(hinge_on_left: bool) -> Node2D:
	## Plank door hinged on one post — swings nearly flat when open.
	var leaf := Node2D.new()
	var wood := Color(0.62, 0.38, 0.18, 1.0)
	var wood_dark := Color(0.42, 0.24, 0.1, 1.0)
	var rail_x := 0.0 if hinge_on_left else -54.0
	for i in range(3):
		var rail := ColorRect.new()
		rail.size = Vector2(54, 12)
		rail.position = Vector2(rail_x, -36.0 + float(i) * 28.0)
		rail.color = wood if i != 1 else wood_dark
		rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leaf.add_child(rail)
	var brace := Line2D.new()
	brace.width = 6.0
	brace.default_color = wood_dark
	if hinge_on_left:
		brace.points = PackedVector2Array([Vector2(6, -30), Vector2(48, 28)])
	else:
		brace.points = PackedVector2Array([Vector2(-6, -30), Vector2(-48, 28)])
	leaf.add_child(brace)
	for i in range(3):
		var hinge := ColorRect.new()
		hinge.size = Vector2(8, 8)
		hinge.position = Vector2(-4.0, -34.0 + float(i) * 28.0)
		hinge.color = Color(0.35, 0.35, 0.38, 1.0)
		hinge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leaf.add_child(hinge)
	return leaf


func _apply_state(animate: bool) -> void:
	if _shape != null:
		_shape.set_deferred("disabled", _open)
	_refresh_status_label(false)
	if animate:
		_animate_gates()
	else:
		_snap_gates()


func _refresh_status_label(warning: bool) -> void:
	if _label == null:
		return
	if warning:
		_label.text = "HURRY!" if _open else "WAIT!"
		_label.add_theme_font_size_override(&"font_size", 20)
		_label.add_theme_color_override(&"font_color", Color(0.95, 0.2, 0.05, 1.0))
		if _status_bg != null:
			_status_bg.color = Color(1.0, 0.85, 0.2, 0.92)
		return
	if _open:
		_label.text = "OPEN!"
		_label.add_theme_font_size_override(&"font_size", 20)
		_label.add_theme_color_override(&"font_color", Color(0.12, 0.45, 0.12, 1.0))
		if _status_bg != null:
			_status_bg.color = Color(0.55, 0.9, 0.4, 0.9)
	else:
		_label.text = "CLOSED"
		_label.add_theme_font_size_override(&"font_size", 18)
		_label.add_theme_color_override(&"font_color", Color(0.55, 0.12, 0.05, 1.0))
		if _status_bg != null:
			_status_bg.color = Color(0.95, 0.55, 0.35, 0.9)


func _snap_gates() -> void:
	if _left_gate == null or _right_gate == null:
		return
	_left_gate.rotation_degrees = -OPEN_DEG if _open else 0.0
	_right_gate.rotation_degrees = OPEN_DEG if _open else 0.0
	_visual.modulate = Color(0.75, 1.0, 0.7, 1.0) if _open else Color(1, 1, 1, 1)


func _animate_gates() -> void:
	if _left_gate == null or _right_gate == null:
		_snap_gates()
		return
	if _gate_tween != null:
		_gate_tween.kill()
		_gate_tween = null
	var left_rot := -OPEN_DEG if _open else 0.0
	var right_rot := OPEN_DEG if _open else 0.0
	var target_mod := Color(0.75, 1.0, 0.7, 1.0) if _open else Color(1, 1, 1, 1)
	_gate_tween = create_tween()
	_gate_tween.set_parallel(true)
	_gate_tween.tween_property(_left_gate, "rotation_degrees", left_rot, ANIM_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gate_tween.tween_property(_right_gate, "rotation_degrees", right_rot, ANIM_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gate_tween.tween_property(_visual, "modulate", target_mod, ANIM_SEC * 0.7)


func _update_warning_blink() -> void:
	if _visual == null:
		return
	if _timer > warn_time:
		_visual.modulate = Color(0.75, 1.0, 0.7, 1.0) if _open else Color(1, 1, 1, 1)
		_refresh_status_label(false)
		if _label != null:
			_label.modulate = Color(1, 1, 1, 1)
		return
	if not _warned:
		_warned = true
		first_warn.emit()
	var pulse := 0.55 + absf(sin(_blink_phase)) * 0.45
	_visual.modulate = Color(1.0, 0.75, 0.2, pulse)
	_refresh_status_label(true)
	if _label != null:
		_label.modulate = Color(1, 1, 1, 0.7 + pulse * 0.3)
