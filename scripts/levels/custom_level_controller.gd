extends LevelController

## Runtime shell for locally built trails.


func _ready() -> void:
	if skip_auto_setup:
		return
	var playtest := GameManager.custom_playtest_active
	var campaign_context := GameManager.consume_campaign_context()
	is_custom_level = playtest or campaign_context.is_empty()
	level_number = int(campaign_context.get("position", 1))
	campaign_source_level = int(campaign_context.get("source_level", 0))
	is_final_level = (
		not playtest
		and not campaign_context.is_empty()
		and level_number >= int(
			campaign_context.get("count", CustomLevelStore.BUILTIN_COUNT)
		)
	)
	var data := CustomLevelStore.load_level(GameManager.active_custom_slot)
	level_title = str(data.get("title", "Family Trail"))
	CustomLevelBuilder.build(self, data)
	_is_set_up = false
	setup_level()
