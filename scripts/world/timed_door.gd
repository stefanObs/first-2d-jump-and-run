class_name TimedDoor
extends StaticBody2D

## Hand-painted ranch gate that opens and shuts on a timer.

signal first_warn

@export var open_time: float = 2.8
@export var closed_time: float = 1.6
@export var start_open: bool = false
@export var warn_time: float = 0.85

const ANIM_SEC := 0.5
const OPENING_HALF := 40.0
const GATE_TOP := -104.0
const GATE_TEX := preload("res://assets/world/fence_gate.png")
const CLOSED_GATE_SCALE := Vector2(0.62, 0.62)
const OPEN_GATE_SCALE := Vector2(0.12, 0.62)

var _open: bool = false
var _timer: float = 0.0
var _shape: CollisionShape2D
var _gate_art: Sprite2D
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
	for child_name in ["Visual", "FenceGates", "FenceFrame", "StatusPlate", "GateRoot", "Posts", "HandmadeGate"]:
		var existing := get_node_or_null(child_name)
		if existing != null:
			existing.queue_free()

	# Colored barrier that fills the opening — the clearest open/closed cue.
	_barrier = ColorRect.new()
	_barrier.name = "Barrier"
	_barrier.position = Vector2(-OPENING_HALF, GATE_TOP)
	_barrier.size = Vector2(OPENING_HALF * 2.0, -GATE_TOP)
	_barrier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barrier.z_index = 0
	add_child(_barrier)

	# Use the same outlined, hand-painted artwork as the rest of the ranch.
	# Scaling only its width makes it read as turning edge-on when open while
	# keeping the painted posts and ironwork recognizable.
	_gate_art = Sprite2D.new()
	_gate_art.name = "HandmadeGate"
	_gate_art.texture = GATE_TEX
	_gate_art.position = Vector2(0, GATE_TOP * 0.5)
	_gate_art.scale = CLOSED_GATE_SCALE
	_gate_art.z_index = 3
	add_child(_gate_art)

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
	if _gate_art == null:
		return
	_gate_art.scale = OPEN_GATE_SCALE if _open else CLOSED_GATE_SCALE
	_gate_art.modulate = Color(0.68, 1.0, 0.62, 1.0) if _open else Color.WHITE


func _animate_gates() -> void:
	if _gate_art == null:
		_snap_gates()
		return
	if _gate_tween != null:
		_gate_tween.kill()
		_gate_tween = null
	var target_scale := OPEN_GATE_SCALE if _open else CLOSED_GATE_SCALE
	var target_color := Color(0.68, 1.0, 0.62, 1.0) if _open else Color.WHITE
	_gate_tween = create_tween()
	_gate_tween.set_parallel(true)
	_gate_tween.tween_property(_gate_art, "scale", target_scale, ANIM_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gate_tween.tween_property(_gate_art, "modulate", target_color, ANIM_SEC * 0.7)


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
