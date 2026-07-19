class_name Rattlesnake
extends Area2D

## Low, wide desert hazard with a clearly telegraphed bite.

signal hurt_player(player: Player)

const IDLE_TEXTURE := preload("res://assets/world/rattlesnake_idle.png")
const BITE_TEXTURE := preload("res://assets/world/rattlesnake_bite.png")

var _sprite: Sprite2D
var _label: Label
var _biting: bool = false
var _phase: float = 0.0


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_label = get_node_or_null("Label") as Label
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_phase += delta
	if not _biting and _sprite != null:
		_sprite.rotation = sin(_phase * 8.0) * 0.018


func _on_body_entered(body: Node2D) -> void:
	if _biting or not (body is Player):
		return
	_bite(body as Player)


func _bite(player: Player) -> void:
	_biting = true
	if _sprite != null:
		_sprite.texture = BITE_TEXTURE
		var tween := create_tween()
		tween.tween_property(_sprite, "scale", Vector2(0.82, 0.66), 0.1)
		tween.tween_property(_sprite, "scale", Vector2(0.75, 0.58), 0.12)
	if _label != null:
		_label.text = "HISS!"
		_label.visible = true
	await get_tree().create_timer(0.24).timeout
	if is_instance_valid(player) and player in get_overlapping_bodies() and not player.is_invulnerable():
		hurt_player.emit(player)
	await get_tree().create_timer(0.45).timeout
	if _sprite != null:
		_sprite.texture = IDLE_TEXTURE
	if _label != null:
		_label.visible = false
	_biting = false
