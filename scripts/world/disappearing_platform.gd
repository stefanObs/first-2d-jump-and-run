class_name DisappearingPlatform
extends StaticBody2D

@export var visible_time: float = 2.0
@export var hidden_time: float = 1.5
@export var start_delay: float = 0.0

var _timer: float = 0.0
var _solid: bool = true
var _shape: CollisionShape2D
var _visual: ColorRect


func _ready() -> void:
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_visual = get_node_or_null("Visual") as ColorRect
	_timer = start_delay


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_solid = not _solid
	_timer = visible_time if _solid else hidden_time
	if _shape != null:
		_shape.disabled = not _solid
	if _visual != null:
		_visual.modulate.a = 1.0 if _solid else 0.25
