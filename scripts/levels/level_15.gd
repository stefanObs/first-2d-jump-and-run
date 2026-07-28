extends LevelController

## Dragon Gate — cave campaign level 15 (finale trail before the dragon).


func _ready() -> void:
	skip_auto_setup = true
	level_number = 15
	level_title = "Dragon Gate"
	celebration_duration = 4.5
	is_final_level = true
	var data := CaveCampaignLevels.level_data(15)
	data["source_level"] = 15
	CustomLevelBuilder.build(self, data)
	setup_level()
