extends LevelController

## Runtime shell for locally built trails.


func _ready() -> void:
	is_custom_level = true
	level_number = 1
	var data := CustomLevelStore.load_level(GameManager.active_custom_slot)
	level_title = str(data.get("title", "Family Trail"))
	CustomLevelBuilder.build(self, data)
	setup_level()
