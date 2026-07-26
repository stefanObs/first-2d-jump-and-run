class_name TreasureChest
extends Area2D

## One-shot treasure chest: opens on touch, awards badges via LevelController.

signal opened(chest: TreasureChest)

const BADGE_COUNT := 5
## CollisionShape2D bottom sits this many px below the root (feet on trail).
const FOOT_OFFSET := 8.0

var _opened: bool = false
var _art: TreasureChestArt
var _collision: CollisionShape2D


func _ready() -> void:
	_art = get_node_or_null("ChestArt") as TreasureChestArt
	_collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	body_entered.connect(_on_body_entered)


func is_opened() -> bool:
	return _opened


func ground_contact_y() -> float:
	return global_position.y + FOOT_OFFSET


func align_to_walk_surface(
	floor_y: float,
	slope_angle: float = 0.0,
	sink: float = 0.0,
	tilt_blend: float = 0.2,
	max_tilt: float = 0.12
) -> void:
	global_position.y = floor_y + sink - FOOT_OFFSET
	rotation = clampf(slope_angle * tilt_blend, -max_tilt, max_tilt)


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
