class_name ModeItem
extends Area2D

## Collectible that activates a temporary player mode.

signal collected(mode: ModeController.Mode)

@export var mode: ModeController.Mode = ModeController.Mode.WINGS
@export var respawns_on_checkpoint: bool = true

var _collected: bool = false
var _visual: ColorRect
var _label: Label
var _base_y: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_visual = get_node_or_null("Visual") as ColorRect
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
	(body as Player).activate_mode(mode)
	collected.emit(mode)


func _update_visual() -> void:
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
	if _visual == null:
		return
	match mode:
		ModeController.Mode.WINGS:
			_visual.color = Color(0.55, 0.85, 1.0, 1.0)
		ModeController.Mode.MAGIC_BOOTS:
			_visual.color = Color(0.75, 0.4, 0.95, 1.0)
		ModeController.Mode.SPEED_STAR:
			_visual.color = Color(1.0, 0.82, 0.15, 1.0)
		ModeController.Mode.BUBBLE_SHIELD:
			_visual.color = Color(0.25, 0.9, 0.95, 1.0)
		_:
			_visual.color = Color(1, 1, 1, 1)
