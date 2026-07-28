class_name TreasureChestArt
extends Node2D

## Full hand-painted closed/open chest frames (not a hinged lid composite).

const TEX_CLOSED := preload("res://assets/world/treasure_chest_closed.png")
const TEX_OPEN := preload("res://assets/world/treasure_chest_open.png")

var open_amount: float = 0.0
var sparkle_phase: float = 0.0

var _closed: Sprite2D
var _open: Sprite2D
var _glow: Sprite2D


func visual_foot_local_y() -> float:
	## Painted base sits at art-local y=0; report in parent-local space.
	return position.y


func _ready() -> void:
	_closed = _make_bottom_aligned_sprite("Closed", TEX_CLOSED)
	_open = _make_bottom_aligned_sprite("Open", TEX_OPEN)
	_open.modulate.a = 0.0

	_glow = Sprite2D.new()
	_glow.name = "ClosedGlow"
	_glow.texture = TEX_CLOSED
	_glow.centered = true
	_glow.modulate = Color(1.0, 0.82, 0.18, 0.0)
	add_child(_glow)
	move_child(_glow, 0)
	_align_sprite_bottom(_glow, TEX_CLOSED)
	_glow.scale = Vector2(1.06, 1.06)

	_apply_open_visuals()


func _make_bottom_aligned_sprite(node_name: String, texture: Texture2D) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = true
	add_child(sprite)
	_align_sprite_bottom(sprite, texture)
	return sprite


func _align_sprite_bottom(sprite: Sprite2D, texture: Texture2D) -> void:
	if sprite == null or texture == null:
		return
	# Centered sprite: place so the painted bottom sits on art-local y=0.
	sprite.position = Vector2(0.0, -float(texture.get_height()) * 0.5)


func set_open_amount(value: float) -> void:
	open_amount = clampf(value, 0.0, 1.0)
	_apply_open_visuals()


func _process(delta: float) -> void:
	if open_amount < 0.08:
		sparkle_phase += delta * 3.4
		_apply_closed_glow()


func _apply_open_visuals() -> void:
	if _closed != null:
		_closed.modulate.a = 1.0 - open_amount
		_closed.visible = open_amount < 0.999
	if _open != null:
		_open.modulate.a = open_amount
		_open.visible = open_amount > 0.001
	_apply_closed_glow()


func _apply_closed_glow() -> void:
	if _closed == null or _glow == null:
		return
	if open_amount >= 0.08:
		_closed.modulate = Color(1.0, 1.0, 1.0, _closed.modulate.a)
		_glow.modulate.a = 0.0
		return
	var pulse := 0.88 + sin(sparkle_phase) * 0.1
	_closed.modulate = Color(pulse, pulse * 0.96, pulse * 0.84, 1.0)
	var glow_alpha := 0.22 + absf(sin(sparkle_phase * 1.2)) * 0.14
	_glow.modulate = Color(1.0, 0.82, 0.18, glow_alpha)
