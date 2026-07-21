extends LevelController

## Runtime shell for locally built trails.


func _ready() -> void:
	var campaign_context := GameManager.consume_campaign_context()
	is_custom_level = campaign_context.is_empty()
	level_number = int(campaign_context.get("position", 1))
	campaign_source_level = int(campaign_context.get("source_level", 0))
	is_final_level = (
		not campaign_context.is_empty()
		and level_number >= int(campaign_context.get("count", 10))
	)
	var data := CustomLevelStore.load_level(GameManager.active_custom_slot)
	level_title = str(data.get("title", "Family Trail"))
	CustomLevelBuilder.build(self, data)
	setup_level()
