extends LevelController

## Bat Gallery — cave campaign level 12.


func _ready() -> void:
	skip_auto_setup = true
	level_number = 12
	level_title = "Bat Gallery"
	celebration_duration = 3.8
	is_final_level = false
	var data := CaveCampaignLevels.level_data(12)
	data["source_level"] = 12
	CustomLevelBuilder.build(self, data)
	setup_level()
