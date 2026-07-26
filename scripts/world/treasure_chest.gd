class_name TreasureChest
extends Area2D

## One-shot treasure chest: opens on touch, awards badges via LevelController.

signal opened(chest: TreasureChest)

const BADGE_COUNT := 5

var _opened: bool = false
var _art: TreasureChestArt
var _collision: CollisionShape2D


func _ready() -> void:
	_art = get_node_or_null("ChestArt") as TreasureChestArt
	_collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	body_entered.connect(_on_body_entered)


func is_opened() -> bool:
	return _opened


func _on_body_entered(body: Node2D) -> void:
	if _opened or not (body is Player):
		return
	_opened = true
	monitoring = false
	if _collision != null:
		_collision.set_deferred("disabled", true)
	AudioManager.play_sfx(&"collect")
	_play_open_animation()
	opened.emit(self)


func _play_open_animation() -> void:
	if _art == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_art.set_open_amount, 0.0, 1.0, 0.42)
	tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), 0.16)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)


func restore_as_opened() -> void:
	_opened = true
	monitoring = false
	if _collision != null:
		_collision.disabled = true
	if _art != null:
		_art.set_open_amount(1.0)


func restore_for_respawn() -> void:
	_opened = false
	monitoring = true
	if _collision != null:
		_collision.disabled = false
	scale = Vector2.ONE
	if _art != null:
		_art.set_open_amount(0.0)
