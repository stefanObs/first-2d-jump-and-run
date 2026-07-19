class_name Goal
extends Area2D

## Saloon exit that starts the celebration transition when reached.

signal reached(goal: Goal)

var _triggered: bool = false
var _sprite: CanvasItem
var _label: Label
var _phase: float = 0.0
var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as CanvasItem
	if _sprite == null:
		_sprite = get_node_or_null("Visual") as CanvasItem
	_label = get_node_or_null("Label") as Label
	if _sprite != null:
		_base_scale = _sprite.scale
	if _label != null:
		_label.text = "SALOON!"
		_label.add_theme_font_size_override(&"font_size", 20)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _triggered:
		return
	_phase += delta * 3.0
	var pulse := 1.0 + sin(_phase) * 0.06
	if _sprite != null:
		_sprite.scale = _base_scale * pulse
		_sprite.modulate = Color(1.0, 0.95 + sin(_phase) * 0.05, 0.7, 1.0)
	if _label != null:
		_label.modulate.a = 0.7 + absf(sin(_phase)) * 0.3


func reset() -> void:
	_triggered = false
	if _sprite != null:
		_sprite.modulate = Color(1, 1, 1, 1)
		_sprite.scale = _base_scale


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body is Player:
		_triggered = true
		if _sprite != null:
			_sprite.modulate = Color(1.0, 0.95, 0.55, 1.0)
			_sprite.scale = _base_scale * 1.15
		if _label != null:
			_label.text = "YEEHAW!"
		reached.emit(self)
