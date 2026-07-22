extends Control

var _elapsed: float = 0.0
var _label: Label


func _ready() -> void:
	_label = get_node_or_null("LoadingLabel") as Label
	var title := get_node_or_null("Title") as Label
	if title != null:
		title.text = tr("Cowboy Trail")
	AudioManager.play_boot_intro()


func _process(delta: float) -> void:
	_elapsed += delta
	if _label != null:
		_label.text = tr("Saddling up") + ".".repeat(int(_elapsed * 3.0) % 4)
	if _elapsed >= 0.9:
		set_process(false)
		get_tree().change_scene_to_file("res://scenes/ui/save_select.tscn")
