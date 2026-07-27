class_name TreasureChestLootReveal
extends Node2D

## Animated pickup sprite that pops out of an opening treasure chest.

const RISE_DISTANCE := 34.0
const POP_DURATION := 0.38
const FLY_DURATION := 0.42

var _sprite: Sprite2D
var _glow: Sprite2D
var _sparkle: Sprite2D
var _phase: float = 0.0
var _playing: bool = false


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "LootSprite"
	_sprite.visible = false
	add_child(_sprite)

	_glow = Sprite2D.new()
	_glow.name = "LootGlow"
	_glow.visible = false
	_glow.modulate = Color(1.0, 0.9, 0.45, 0.55)
	_glow.z_index = -1
	add_child(_glow)
	move_child(_glow, 0)

	_sparkle = Sprite2D.new()
	_sparkle.name = "LootSparkle"
	_sparkle.visible = false
	_sparkle.modulate = Color(1.0, 0.95, 0.7, 0.0)
	add_child(_sparkle)


func play(loot: TreasureChestLoot.Type, target_world: Vector2) -> void:
	var texture := TreasureChestLoot.texture_for(loot)
	if texture == null:
		return
	_sprite.texture = texture
	_glow.texture = texture
	_sparkle.texture = texture
	_sprite.visible = true
	_glow.visible = true
	_sparkle.visible = true
	_sprite.scale = Vector2(0.2, 0.2)
	_glow.scale = Vector2(0.28, 0.28)
	_sparkle.scale = Vector2(0.5, 0.5)
	_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_glow.modulate.a = 0.0
	position = Vector2(0.0, -8.0)
	_playing = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(_sprite, "scale", Vector2(0.95, 0.95), POP_DURATION)
	tween.parallel().tween_property(_glow, "scale", Vector2(1.25, 1.25), POP_DURATION)
	tween.parallel().tween_property(_glow, "modulate:a", 0.65, POP_DURATION * 0.7)
	tween.parallel().tween_property(self, "position:y", position.y - RISE_DISTANCE, POP_DURATION)
	tween.parallel().tween_property(_sparkle, "modulate:a", 0.85, POP_DURATION * 0.45)
	tween.tween_property(_sprite, "scale", Vector2(0.72, 0.72), 0.12)
	tween.parallel().tween_property(_glow, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(_sparkle, "modulate:a", 0.0, 0.18)

	tween.tween_property(_sprite, "global_position", target_world + Vector2(0.0, -48.0), FLY_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(_sprite, "scale", Vector2(0.35, 0.35), FLY_DURATION)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.15, FLY_DURATION)
	tween.tween_callback(_finish)


func _process(delta: float) -> void:
	if not _playing or _sprite == null or not _sprite.visible:
		return
	_phase += delta * 8.0
	_sprite.rotation = sin(_phase) * 0.18
	if _sparkle != null:
		_sparkle.rotation = -_sprite.rotation * 0.6
		_sparkle.scale = Vector2(0.45, 0.45) * (1.0 + absf(sin(_phase * 1.4)) * 0.12)


func _finish() -> void:
	reset()


func reset() -> void:
	_playing = false
	_phase = 0.0
	position = Vector2(0.0, -8.0)
	if _sprite != null:
		_sprite.visible = false
		_sprite.rotation = 0.0
		_sprite.scale = Vector2.ONE
		_sprite.modulate = Color.WHITE
	if _glow != null:
		_glow.visible = false
		_glow.modulate.a = 0.0
	if _sparkle != null:
		_sparkle.visible = false
		_sparkle.modulate.a = 0.0
