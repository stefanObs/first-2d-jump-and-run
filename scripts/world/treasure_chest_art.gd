class_name TreasureChestArt
extends Node2D

## Hand-painted western treasure chest sprites with a rotating lid.

const TEX_BODY := preload("res://assets/world/treasure_chest_body.png")
const TEX_LID := preload("res://assets/world/treasure_chest_lid.png")
const TEX_INTERIOR := preload("res://assets/world/treasure_chest_interior.png")

const LID_OPEN_ANGLE := -1.35

var open_amount: float = 0.0
var sparkle_phase: float = 0.0

var _body: Sprite2D
var _interior: Sprite2D
var _lid_pivot: Node2D
var _lid: Sprite2D
var _glow: Sprite2D


func visual_foot_local_y() -> float:
	## Painted chest base (shadow on dirt) in parent-local space.
	if _body == null or _body.texture == null:
		return 0.0
	return position.y + _body.position.y + float(_body.texture.get_height()) * 0.5


func _ready() -> void:
	_body = Sprite2D.new()
	_body.name = "Body"
	_body.texture = TEX_BODY
	_body.position = Vector2(0.0, 2.0)
	add_child(_body)

	_interior = Sprite2D.new()
	_interior.name = "Interior"
	_interior.texture = TEX_INTERIOR
	_interior.position = _body.position
	_interior.modulate.a = 0.0
	add_child(_interior)

	_lid_pivot = Node2D.new()
	_lid_pivot.name = "LidPivot"
	add_child(_lid_pivot)

	_lid = Sprite2D.new()
	_lid.name = "Lid"
	_lid.texture = TEX_LID
	_lid_pivot.add_child(_lid)

	_configure_lid_hinge()

	_glow = Sprite2D.new()
	_glow.name = "ClosedGlow"
	_glow.texture = TEX_INTERIOR
	_glow.modulate = Color(1.0, 0.82, 0.18, 0.0)
	add_child(_glow)
	move_child(_glow, 0)
	_configure_glow_position()

	_apply_open_visuals()


func _configure_lid_hinge() -> void:
	if _body == null or _body.texture == null or _lid == null or _lid.texture == null:
		return
	var body_w := float(_body.texture.get_width())
	var body_h := float(_body.texture.get_height())
	_lid_pivot.position = Vector2(-body_w * 0.24, -body_h * 0.24)
	_lid.position = Vector2(body_w * 0.24, -body_h * 0.12)


func _configure_glow_position() -> void:
	if _body == null or _body.texture == null or _glow == null:
		return
	var body_h := float(_body.texture.get_height())
	_glow.position = _body.position + Vector2(0.0, -body_h * 0.14)
	_glow.scale = Vector2(0.72, 0.55)


func set_open_amount(value: float) -> void:
	open_amount = clampf(value, 0.0, 1.0)
	_apply_open_visuals()


func _process(delta: float) -> void:
	if open_amount < 0.08:
		sparkle_phase += delta * 3.4
		_apply_closed_glow()


func _apply_open_visuals() -> void:
	if _lid_pivot != null:
		_lid_pivot.rotation = lerpf(0.0, LID_OPEN_ANGLE, open_amount)
	if _interior != null:
		_interior.modulate.a = clampf((open_amount - 0.12) / 0.88, 0.0, 1.0)
	_apply_closed_glow()


func _apply_closed_glow() -> void:
	if _body == null or _glow == null:
		return
	if open_amount >= 0.08:
		_body.modulate = Color.WHITE
		_glow.modulate.a = 0.0
		return
	var pulse := 0.88 + sin(sparkle_phase) * 0.1
	_body.modulate = Color(pulse, pulse * 0.96, pulse * 0.84, 1.0)
	var glow_alpha := 0.28 + absf(sin(sparkle_phase * 1.2)) * 0.18
	_glow.modulate = Color(1.0, 0.82, 0.18, glow_alpha)
