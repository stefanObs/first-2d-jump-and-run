class_name ModeItem
extends Area2D

## Collectible that activates a temporary player mode.

signal collected(mode: ModeController.Mode)

@export var mode: ModeController.Mode = ModeController.Mode.WINGS
@export var respawns_on_checkpoint: bool = true

var _collected: bool = false
var _visual: ColorRect
var _label: Label


func _ready() -> void:
	_visual = get_node_or_null("Visual") as ColorRect
	_label = get_node_or_null("Label") as Label
	body_entered.connect(_on_body_entered)
	_update_visual()


func restore_if_needed() -> void:
	if respawns_on_checkpoint:
		_collected = false
		visible = true
		monitoring = true


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
		_label.text = ModeController.mode_name(mode)
	if _visual == null:
		return
	match mode:
		ModeController.Mode.WINGS:
			_visual.color = Color(0.7, 0.9, 1.0, 1.0)
		ModeController.Mode.MAGIC_BOOTS:
			_visual.color = Color(0.7, 0.45, 1.0, 1.0)
		ModeController.Mode.SPEED_STAR:
			_visual.color = Color(1.0, 0.85, 0.2, 1.0)
		ModeController.Mode.BUBBLE_SHIELD:
			_visual.color = Color(0.35, 0.85, 1.0, 1.0)
		_:
			_visual.color = Color(1, 1, 1, 1)
