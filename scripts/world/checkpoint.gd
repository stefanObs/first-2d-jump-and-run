class_name Checkpoint
extends Area2D

## Safe respawn marker activated when the player touches it.

signal activated(checkpoint: Checkpoint)

@export var is_active: bool = false

var _visual: ColorRect
var _label: Label
var _flag: ColorRect
var _pulse: float = 0.0
var _pop_time: float = 0.0
var _flag_base_top: float = -64.0


func _ready() -> void:
	_visual = get_node_or_null("Visual") as ColorRect
	_label = get_node_or_null("Label") as Label
	_flag = get_node_or_null("Flag") as ColorRect
	if _flag != null:
		_flag_base_top = _flag.offset_top
	body_entered.connect(_on_body_entered)
	_update_visual()


func _process(delta: float) -> void:
	if not is_active:
		return
	_pulse += delta * 4.0
	if _flag != null:
		var bob := sin(_pulse) * 3.0
		_flag.offset_top = _flag_base_top + bob
		_flag.offset_bottom = _flag_base_top + 28.0 + bob
	if _pop_time > 0.0:
		_pop_time = maxf(_pop_time - delta, 0.0)
		var t := 1.0 - (_pop_time / 0.35)
		var s := lerpf(1.25, 1.0, t)
		scale = Vector2(s, s)


func activate() -> void:
	if is_active:
		return
	is_active = true
	_pop_time = 0.35
	_update_visual()
	activated.emit(self)


func deactivate() -> void:
	is_active = false
	scale = Vector2.ONE
	if _flag != null:
		_flag.offset_top = _flag_base_top
		_flag.offset_bottom = _flag_base_top + 28.0
	_update_visual()


func get_respawn_position() -> Vector2:
	return global_position


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		activate()


func _update_visual() -> void:
	if _visual != null:
		_visual.color = Color(0.95, 0.75, 0.2, 1.0) if is_active else Color(0.55, 0.32, 0.14, 1.0)
	if _flag != null:
		_flag.color = Color(1.0, 0.85, 0.2, 1.0) if is_active else Color(0.92, 0.22, 0.18, 1.0)
	if _label != null:
		_label.text = "SAVED!" if is_active else "CAMP"
		_label.add_theme_color_override(
			&"font_color",
			Color(0.2, 0.45, 0.12, 1.0) if is_active else Color(0.35, 0.18, 0.05, 1.0)
		)
