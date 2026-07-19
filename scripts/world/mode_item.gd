class_name ModeItem
extends Area2D

## Collectible that activates a temporary player mode.

signal collected(mode: ModeController.Mode)

@export var mode: ModeController.Mode = ModeController.Mode.WINGS
@export var respawns_on_checkpoint: bool = true
@export var duration_override: float = 0.0


const TEX_WINGS := preload("res://assets/world/modes/wings.png")
const TEX_BOOTS := preload("res://assets/world/modes/magic_boots.png")
const TEX_SPEED := preload("res://assets/world/modes/speed_badge.png")
const TEX_SHIELD := preload("res://assets/world/modes/bubble_shield.png")

var _collected: bool = false
var _visual: Sprite2D
var _glow: Sprite2D
var _label: Label
var _base_y: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_visual = get_node_or_null("Visual") as Sprite2D
	_glow = get_node_or_null("Glow") as Sprite2D
	_label = get_node_or_null("Label") as Label
	_base_y = position.y
	_phase = randf() * TAU
	body_entered.connect(_on_body_entered)
	_update_visual()


func _process(delta: float) -> void:
	if _collected:
		return
	_phase += delta * 2.6
	position.y = _base_y + sin(_phase) * 4.0
	if _visual != null:
		_visual.rotation = sin(_phase * 0.5) * 0.12


func restore_if_needed() -> void:
	if respawns_on_checkpoint:
		_collected = false
		visible = true
		monitoring = true
		position.y = _base_y


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return
	_collected = true
	visible = false
	monitoring = false
	(body as Player).activate_mode(mode, duration_override)
	collected.emit(mode)


func _mode_texture() -> Texture2D:
	match mode:
		ModeController.Mode.WINGS:
			return TEX_WINGS
		ModeController.Mode.MAGIC_BOOTS:
			return TEX_BOOTS
		ModeController.Mode.SPEED_STAR:
			return TEX_SPEED
		ModeController.Mode.BUBBLE_SHIELD:
			return TEX_SHIELD
		_:
			return TEX_WINGS


func _update_visual() -> void:
	var texture := _mode_texture()
	if _visual != null:
		_visual.texture = texture
	if _glow != null:
		_glow.texture = texture
	if _label != null:
		match mode:
			ModeController.Mode.WINGS:
				_label.text = "FLY!"
			ModeController.Mode.MAGIC_BOOTS:
				_label.text = "JUMP!"
			ModeController.Mode.SPEED_STAR:
				_label.text = "ZOOM!"
			ModeController.Mode.BUBBLE_SHIELD:
				_label.text = "SAFE!"
			_:
				_label.text = ModeController.mode_name(mode)
		_label.add_theme_color_override(&"font_color", Color(0.3, 0.12, 0.05, 1.0))
		_label.add_theme_font_size_override(&"font_size", 16)
