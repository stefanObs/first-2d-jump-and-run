extends LevelController

## Wing Chasm — cave campaign level 15 (wings waiting at camp).


func _ready() -> void:
	skip_auto_setup = true
	level_number = 15
	level_title = "Wing Chasm"
	celebration_duration = 4.0
	is_final_level = false
	var data := CaveCampaignLevels.level_data(15)
	data["source_level"] = 15
	CustomLevelBuilder.build(self, data)
	setup_level()
