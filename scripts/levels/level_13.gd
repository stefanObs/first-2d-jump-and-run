extends LevelController

## Acid Veins — cave campaign level 13.


func _ready() -> void:
	skip_auto_setup = true
	level_number = 13
	level_title = "Acid Veins"
	celebration_duration = 3.8
	is_final_level = false
	var data := CaveCampaignLevels.level_data(13)
	data["source_level"] = 13
	CustomLevelBuilder.build(self, data)
	setup_level()
