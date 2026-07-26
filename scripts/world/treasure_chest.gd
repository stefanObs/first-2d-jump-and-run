class_name TreasureChest
extends Area2D

## One-shot treasure chest: opens on touch, rolls random loot, activates it on the player.

signal opened(chest: TreasureChest, loot: TreasureChestLoot.Type)

## Player collision body height from player.tscn (44 px).
const PLAYER_HEIGHT := 44.0
## Handcrafted prop scale — roughly torso height, clearly larger than the old 2/3 rule.
const HEIGHT_RATIO := 0.92
const TARGET_HEIGHT := PLAYER_HEIGHT * HEIGHT_RATIO
## Unscaled collision height from treasure_chest.tscn.
const BASE_COLLISION_HEIGHT := 36.0
const SIZE_SCALE := TARGET_HEIGHT / BASE_COLLISION_HEIGHT
## World Y from root to painted base / dirt contact (matches collision bottom).
const BASE_FOOT_OFFSET := 8.0
const FOOT_OFFSET := BASE_FOOT_OFFSET * SIZE_SCALE

static var test_loot_override: int = -1

var _opened: bool = false
var _rolled_loot: TreasureChestLoot.Type = TreasureChestLoot.Type.WINGS
var _art: TreasureChestArt
var _loot_reveal: TreasureChestLootReveal
var _collision: CollisionShape2D


func _ready() -> void:
	_art = get_node_or_null("ChestArt") as TreasureChestArt
	_loot_reveal = get_node_or_null("ChestArt/LootReveal") as TreasureChestLootReveal
	_collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_apply_size_scale()
	body_entered.connect(_on_body_entered)


func is_opened() -> bool:
	return _opened


func rolled_loot() -> TreasureChestLoot.Type:
	return _rolled_loot


func ground_contact_y() -> float:
	return global_position.y + _foot_local_y()


func align_to_walk_surface(
	floor_y: float,
	slope_angle: float = 0.0,
	sink: float = 0.0,
	tilt_blend: float = 0.2,
	max_tilt: float = 0.12
) -> void:
	var foot_local := _foot_local_y()
	global_position.y = floor_y + sink - foot_local
	rotation = clampf(slope_angle * tilt_blend, -max_tilt, max_tilt)


func _foot_local_y() -> float:
	if _art != null:
		return _art.visual_foot_local_y()
	return FOOT_OFFSET


func _apply_size_scale() -> void:
	if _collision != null and _collision.shape is RectangleShape2D:
		var shape := _collision.shape as RectangleShape2D
		shape.size = Vector2(48.0, BASE_COLLISION_HEIGHT) * SIZE_SCALE
		_collision.position = Vector2(0.0, -10.0 * SIZE_SCALE)
	if _art != null:
		_art.position = Vector2(0.0, -8.0 * SIZE_SCALE)
		var target_foot := FOOT_OFFSET
		var painted_foot := _art.visual_foot_local_y()
		_art.position.y += target_foot - painted_foot
		if _loot_reveal != null:
			_loot_reveal.position.y = -10.0 * SIZE_SCALE


func _on_body_entered(body: Node2D) -> void:
	if _opened or not (body is Player):
		return
	_opened = true
	_rolled_loot = _roll_loot()
	monitoring = false
	if _collision != null:
		_collision.set_deferred("disabled", true)
	if TreasureChestLoot.is_badge(_rolled_loot):
		AudioManager.play_sfx(&"collect")
	else:
		AudioManager.play_sfx(&"powerup")
	_play_open_animation(body as Player)
	opened.emit(self, _rolled_loot)


func _roll_loot() -> TreasureChestLoot.Type:
	if test_loot_override >= 0 and test_loot_override < TreasureChestLoot.POOL.size():
		return TreasureChestLoot.POOL[test_loot_override]
	return TreasureChestLoot.pick_random()


func _play_open_animation(player: Player) -> void:
	if _art == null:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(_art.set_open_amount, 0.0, 1.0, 0.42)
	tween.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), 0.16)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)
	if _loot_reveal != null:
		tween.parallel().tween_callback(
			func() -> void: _loot_reveal.play(_rolled_loot, player.global_position)
		).set_delay(0.14)


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
