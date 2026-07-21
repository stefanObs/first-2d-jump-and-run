class_name TimedDoor
extends StaticBody2D

## Ranch gate that swings open and shut on a timer.
## The blocking gate matches the collision box exactly and is boldly colored:
## a red barred gate when CLOSED, a clear green passage when OPEN.

signal first_warn

@export var open_time: float = 2.8
@export var closed_time: float = 1.6
@export var start_open: bool = false
@export var warn_time: float = 0.85

const OPEN_DEG := 104.0
const ANIM_SEC := 0.5
const OPENING_HALF := 32.0
const GATE_TOP := -104.0

const CLOSED_WOOD := Color(0.66, 0.24, 0.14, 1.0)
const CLOSED_WOOD_DARK := Color(0.46, 0.14, 0.08, 1.0)
const OPEN_WOOD := Color(0.4, 0.62, 0.3, 1.0)
const POST_COLOR := Color(0.4, 0.26, 0.13, 1.0)
const POST_CAP := Color(0.52, 0.36, 0.2, 1.0)

var _open: bool = false
var _timer: float = 0.0
var _shape: CollisionShape2D
var _gates: Node2D
var _left_gate: Node2D
var _right_gate: Node2D
var _barrier: ColorRect
var _label: Label
var _status_bg: ColorRect
var _blink_phase: float = 0.0
var _warned: bool = false
var _gate_tween: Tween


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_label = get_node_or_null("Label") as Label
	_setup_visual()
	_open = start_open
	_timer = open_time if _open else closed_time
	_apply_state(false)
	z_index = 4


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


func _setup_visual() -> void:
	for child_name in ["Visual", "FenceGates", "FenceFrame", "StatusPlate", "GateRoot", "Posts"]:
		var existing := get_node_or_null(child_name)
		if existing != null:
			existing.queue_free()

	# Two stout posts flanking the opening (just outside the collision box).
	var posts := Node2D.new()
	posts.name = "Posts"
	add_child(posts)
	_add_post(posts, -OPENING_HALF - 9.0)
	_add_post(posts, OPENING_HALF + 9.0)

	# Colored barrier that fills the opening — the clearest open/closed cue.
	_barrier = ColorRect.new()
	_barrier.name = "Barrier"
	_barrier.position = Vector2(-OPENING_HALF, GATE_TOP)
	_barrier.size = Vector2(OPENING_HALF * 2.0, -GATE_TOP)
	_barrier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barrier.z_index = 0
	add_child(_barrier)

	# Two swinging gate leaves that meet in the middle when closed.
	_gates = Node2D.new()
	_gates.name = "GateRoot"
	add_child(_gates)
	_left_gate = _make_gate_leaf(true)
	_left_gate.name = "LeftGate"
	_left_gate.position = Vector2(-OPENING_HALF, 0.0)
	_gates.add_child(_left_gate)
	_right_gate = _make_gate_leaf(false)
	_right_gate.name = "RightGate"
	_right_gate.position = Vector2(OPENING_HALF, 0.0)
	_gates.add_child(_right_gate)

	# Status plate + label sit above the gate.
	_status_bg = ColorRect.new()
	_status_bg.name = "StatusPlate"
	_status_bg.size = Vector2(104, 30)
	_status_bg.position = Vector2(-52, GATE_TOP - 44.0)
	_status_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_bg.z_index = 5
	add_child(_status_bg)

	# Collision matches the visible opening exactly.
	if _shape != null:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(OPENING_HALF * 2.0, -GATE_TOP)
		_shape.shape = rect
		_shape.position = Vector2(0, GATE_TOP * 0.5)
	if _label != null:
		_label.position = Vector2(-52, GATE_TOP - 43.0)
		_label.size = Vector2(104, 28)
		_label.z_index = 6
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _add_post(parent: Node2D, at_x: float) -> void:
	var post := ColorRect.new()
	post.size = Vector2(14, -GATE_TOP + 10.0)
	post.position = Vector2(at_x - 7.0, GATE_TOP - 6.0)
	post.color = POST_COLOR
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.z_index = 3
	parent.add_child(post)
	var cap := ColorRect.new()
	cap.size = Vector2(20, 10)
	cap.position = Vector2(at_x - 10.0, GATE_TOP - 8.0)
	cap.color = POST_CAP
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.z_index = 3
	parent.add_child(cap)


func _make_gate_leaf(hinge_on_left: bool) -> Node2D:
	## A half-width plank leaf, hinged at a post, meeting its twin in the middle.
	var leaf := Node2D.new()
	var dir := 1.0 if hinge_on_left else -1.0
	for i in range(4):
		var rail := ColorRect.new()
		rail.size = Vector2(OPENING_HALF, 16)
		rail.position = Vector2(0.0 if hinge_on_left else -OPENING_HALF, GATE_TOP + 6.0 + float(i) * 26.0)
		rail.color = CLOSED_WOOD if i % 2 == 0 else CLOSED_WOOD_DARK
		rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		leaf.add_child(rail)
	var brace := Line2D.new()
	brace.width = 6.0
	brace.default_color = CLOSED_WOOD_DARK
	brace.points = PackedVector2Array([
		Vector2(dir * 2.0, GATE_TOP + 8.0),
		Vector2(dir * (OPENING_HALF - 2.0), -8.0),
	])
	leaf.add_child(brace)
	return leaf


func _apply_state(animate: bool) -> void:
	if _shape != null:
		_shape.set_deferred("disabled", _open)
	_refresh_status_label(false)
	_refresh_barrier()
	if animate:
		_animate_gates()
	else:
		_snap_gates()


func _refresh_barrier() -> void:
	if _barrier == null:
		return
	if _open:
		_barrier.color = Color(0.45, 0.85, 0.4, 0.22)
	else:
		_barrier.color = Color(0.85, 0.16, 0.1, 0.5)


func _leaf_color(leaf: Node2D, closed: bool) -> void:
	var i := 0
	for child in leaf.get_children():
		if child is ColorRect:
			var rect := child as ColorRect
			if closed:
				rect.color = CLOSED_WOOD if i % 2 == 0 else CLOSED_WOOD_DARK
			else:
				rect.color = OPEN_WOOD if i % 2 == 0 else OPEN_WOOD.darkened(0.2)
			i += 1


func _refresh_status_label(warning: bool) -> void:
	if _label == null:
		return
	if warning:
		_label.text = "HURRY!" if _open else "GET READY"
		_label.add_theme_font_size_override(&"font_size", 20)
		_label.add_theme_color_override(&"font_color", Color(0.2, 0.1, 0.02, 1.0))
		if _status_bg != null:
			_status_bg.color = Color(1.0, 0.85, 0.2, 0.95)
		return
	if _open:
		_label.text = "OPEN"
		_label.add_theme_font_size_override(&"font_size", 22)
		_label.add_theme_color_override(&"font_color", Color(0.05, 0.3, 0.05, 1.0))
		if _status_bg != null:
			_status_bg.color = Color(0.55, 0.92, 0.4, 0.95)
	else:
		_label.text = "CLOSED"
		_label.add_theme_font_size_override(&"font_size", 20)
		_label.add_theme_color_override(&"font_color", Color(1.0, 0.95, 0.9, 1.0))
		if _status_bg != null:
			_status_bg.color = Color(0.8, 0.12, 0.06, 0.95)


func _snap_gates() -> void:
	if _left_gate == null or _right_gate == null:
		return
	_left_gate.rotation_degrees = -OPEN_DEG if _open else 0.0
	_right_gate.rotation_degrees = OPEN_DEG if _open else 0.0
	_leaf_color(_left_gate, not _open)
	_leaf_color(_right_gate, not _open)


func _animate_gates() -> void:
	if _left_gate == null or _right_gate == null:
		_snap_gates()
		return
	if _gate_tween != null:
		_gate_tween.kill()
		_gate_tween = null
	_leaf_color(_left_gate, not _open)
	_leaf_color(_right_gate, not _open)
	var left_rot := -OPEN_DEG if _open else 0.0
	var right_rot := OPEN_DEG if _open else 0.0
	_gate_tween = create_tween()
	_gate_tween.set_parallel(true)
	_gate_tween.tween_property(_left_gate, "rotation_degrees", left_rot, ANIM_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gate_tween.tween_property(_right_gate, "rotation_degrees", right_rot, ANIM_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _update_warning_blink() -> void:
	if _timer > warn_time:
		if _barrier != null:
			_barrier.modulate = Color(1, 1, 1, 1)
		_refresh_status_label(false)
		return
	if not _warned:
		_warned = true
		first_warn.emit()
	var pulse := 0.55 + absf(sin(_blink_phase)) * 0.45
	if _barrier != null:
		_barrier.modulate = Color(1, 1, 1, pulse)
	_refresh_status_label(true)
