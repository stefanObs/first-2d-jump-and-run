extends LevelController

## Crystal Mouth — cave campaign level 11.


func _ready() -> void:
	skip_auto_setup = true
	level_number = 11
	level_title = "Crystal Mouth"
	celebration_duration = 3.8
	is_final_level = false
	var data := CaveCampaignLevels.level_data(11)
	data["source_level"] = 11
	CustomLevelBuilder.build(self, data)
	setup_level()
