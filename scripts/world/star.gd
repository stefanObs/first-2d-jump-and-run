class_name Star
extends Area2D

## Optional collectible star with a gentle bob so kids spot it easily.

signal collected

var _taken: bool = false
var _base_y: float = 0.0
var _phase: float = 0.0
var _sprite_base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_base_y = position.y
	_phase = randf() * TAU
	var sprite := get_node_or_null("Sprite2D") as Node2D
	if sprite != null:
		_sprite_base_scale = sprite.scale
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _taken:
		return
	_phase += delta * 3.2
	position.y = _base_y + sin(_phase) * 5.0
	rotation = sin(_phase * 0.5) * 0.12


func is_taken() -> bool:
	return _taken


func _on_body_entered(body: Node2D) -> void:
	if _taken or not (body is Player):
		return
	_taken = true
	monitoring = false
	AudioManager.play_sfx(&"collect")
	(body as Player).collect_star()
	collected.emit()
	var sprite := get_node_or_null("Sprite2D") as Node2D
	var tween := create_tween()
	if sprite != null:
		tween.tween_property(sprite, "scale", sprite.scale * 1.6, 0.12)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.18)
	tween.tween_callback(_hide_after_collect)


func _hide_after_collect() -> void:
	visible = false
	var sprite := get_node_or_null("Sprite2D") as Node2D
	if sprite != null:
		sprite.scale = _sprite_base_scale
		sprite.modulate.a = 1.0


func restore_as_collected() -> void:
	_taken = true
	monitoring = false
	visible = false


func restore_for_respawn() -> void:
	_taken = false
	monitoring = true
	visible = true
	position.y = _base_y
	rotation = 0.0
	var sprite := get_node_or_null("Sprite2D") as Node2D
	if sprite != null:
		sprite.scale = _sprite_base_scale
		sprite.modulate.a = 1.0
