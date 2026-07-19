class_name Hud
extends CanvasLayer

var _level_label: Label
var _stars_label: Label
var _mode_label: Label
var _prompt_label: Label


func _ready() -> void:
	layer = 50
	_level_label = get_node_or_null("LevelLabel") as Label
	_stars_label = get_node_or_null("StarsLabel") as Label
	_mode_label = get_node_or_null("ModeLabel") as Label
	_prompt_label = get_node_or_null("PromptLabel") as Label
	set_stars(0)
	set_mode("None", 0.0)


func set_level_title(title: String) -> void:
	if _level_label != null:
		_level_label.text = title


func set_stars(count: int) -> void:
	if _stars_label != null:
		_stars_label.text = "Stars: %d" % count


func set_mode(mode_name: String, remaining: float) -> void:
	if _mode_label == null:
		return
	if mode_name == "None" or remaining <= 0.0:
		_mode_label.text = "Mode: -"
	else:
		_mode_label.text = "Mode: %s (%.0fs)" % [mode_name, remaining]


func set_prompt(text: String) -> void:
	if _prompt_label != null:
		_prompt_label.text = text
