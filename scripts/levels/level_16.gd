extends LevelController

## Dragon Gate — cave campaign level 16 (finale trail before the dragon).


func _ready() -> void:
	skip_auto_setup = true
	level_number = 16
	level_title = "Dragon Gate"
	celebration_duration = 4.5
	is_final_level = true
	var data := CaveCampaignLevels.level_data(16)
	data["source_level"] = 16
	CustomLevelBuilder.build(self, data)
	setup_level()
