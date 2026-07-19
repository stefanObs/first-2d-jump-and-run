class_name SpringPad
extends Area2D

@export var bounce_velocity: float = -820.0

var _visual: ColorRect
var _label: Label
var _base_scale: Vector2 = Vector2.ONE
var _squash_time: float = 0.0


func _ready() -> void:
	_visual = get_node_or_null("Visual") as ColorRect
	_label = get_node_or_null("Label") as Label
	if _visual != null:
		_base_scale = _visual.scale
	if _label != null:
		_label.text = "BOING!"
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _visual == null or _squash_time <= 0.0:
		return
	_squash_time = maxf(_squash_time - delta, 0.0)
	var t := 1.0 - (_squash_time / 0.28)
	# Squash then overshoot back.
	var y := lerpf(0.45, 1.15, t) if t < 0.55 else lerpf(1.15, 1.0, (t - 0.55) / 0.45)
	var x := lerpf(1.35, 0.9, t) if t < 0.55 else lerpf(0.9, 1.0, (t - 0.55) / 0.45)
	_visual.scale = Vector2(_base_scale.x * x, _base_scale.y * y)
	_visual.modulate = Color(0.55, 1.0, 0.55, 1.0).lerp(Color(1, 1, 1, 1), t)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		player.velocity.y = bounce_velocity
		_squash_time = 0.28
