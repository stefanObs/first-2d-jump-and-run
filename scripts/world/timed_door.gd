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
var _label: Label
var _status_lantern: Polygon2D
var _blink_phase: float = 0.0
var _warned: bool = false
var _gate_tween: Tween


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_label = get_node_or_null("Label") as Label
	if _label != null:
		_label.visible = false
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
	for child_name in [
		"Visual", "FenceGates", "FenceFrame", "StatusPlate", "GateRoot", "Posts",
		"HandmadeGate", "Barrier", "StatusLantern",
	]:
		var existing := get_node_or_null(child_name)
		if existing != null:
			existing.queue_free()

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

	# Small irregular lantern above the gate — open/closed without flat plates.
	_status_lantern = Polygon2D.new()
	_status_lantern.name = "StatusLantern"
	_status_lantern.polygon = PackedVector2Array([
		Vector2(-10, -8), Vector2(11, -6), Vector2(8, 9), Vector2(-9, 7),
	])
	_status_lantern.position = Vector2(0, GATE_TOP - 28.0)
	_status_lantern.z_index = 5
	add_child(_status_lantern)

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
		_label.visible = false


func _apply_state(animate: bool) -> void:
	if _shape != null:
		_shape.set_deferred("disabled", _open)
	_refresh_status_visual(false)
	if animate:
		_animate_gates()
	else:
		_snap_gates()


func _refresh_status_visual(warning: bool) -> void:
	if _status_lantern == null:
		return
	if warning:
		_status_lantern.color = Color(1.0, 0.82, 0.18, 0.95)
		return
	if _open:
		_status_lantern.color = Color(0.45, 0.88, 0.35, 0.92)
	else:
		_status_lantern.color = Color(0.82, 0.18, 0.10, 0.95)


func _snap_gates() -> void:
	if _gate_art == null:
		return
	_gate_art.scale = OPEN_GATE_SCALE if _open else CLOSED_GATE_SCALE
	_gate_art.modulate = Color(0.68, 1.0, 0.62, 1.0) if _open else Color(1.0, 0.82, 0.78, 1.0)


func _animate_gates() -> void:
	if _gate_art == null:
		_snap_gates()
		return
	if _gate_tween != null:
		_gate_tween.kill()
		_gate_tween = null
	var target_scale := OPEN_GATE_SCALE if _open else CLOSED_GATE_SCALE
	var target_color := Color(0.68, 1.0, 0.62, 1.0) if _open else Color(1.0, 0.82, 0.78, 1.0)
	_gate_tween = create_tween()
	_gate_tween.set_parallel(true)
	_gate_tween.tween_property(_gate_art, "scale", target_scale, ANIM_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_gate_tween.tween_property(_gate_art, "modulate", target_color, ANIM_SEC * 0.7)


func _update_warning_blink() -> void:
	if _timer > warn_time:
		if _gate_art != null:
			_gate_art.modulate.a = 1.0
		_refresh_status_visual(false)
		return
	if not _warned:
		_warned = true
		first_warn.emit()
	var pulse := 0.55 + absf(sin(_blink_phase)) * 0.45
	if _gate_art != null:
		_gate_art.modulate.a = pulse
	_refresh_status_visual(true)


func is_open() -> bool:
	return _open
