extends LevelController

## Ladder Grotto — cave campaign level 14.


func _ready() -> void:
	skip_auto_setup = true
	level_number = 14
	level_title = "Ladder Grotto"
	celebration_duration = 3.8
	is_final_level = false
	var data := CaveCampaignLevels.level_data(14)
	data["source_level"] = 14
	CustomLevelBuilder.build(self, data)
	setup_level()
