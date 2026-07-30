class_name LevelStyle
extends RefCounted

## Desert vs cave trail presentation. Stamp type ids stay stable; visuals swap.

const DESERT := "desert"
const CAVE := "cave"

static func normalize(value: Variant) -> String:
	var text := str(value).strip_edges().to_lower()
	if text == CAVE:
		return CAVE
	return DESERT

static func is_cave(value: Variant) -> bool:
	return normalize(value) == CAVE

static func from_level(level: Node) -> String:
	if level != null and level.has_meta("level_style"):
		return normalize(level.get_meta("level_style"))
	return DESERT

static func stamp_icon_path(type_name: String, style: String = DESERT) -> String:
	var cave := is_cave(style)
	match type_name:
		"ground":
			return "res://assets/world/cave_floor_tile.png" if cave else "res://assets/world/trail_desert_tile.png"
		"canyon":
			return "res://assets/ui/editor_canyon_stamp_icon.png"
		"platform":
			return "res://assets/world/cave_plank.png" if cave else "res://assets/world/wood_plank.png"
		"ladder":
			return "res://assets/world/ladder.png"
		"cactus":
			return "res://assets/world/poison_fungus.png" if cave else "res://assets/world/cactus.png"
		"pit":
			return "res://assets/world/cave_pit.png" if cave else "res://assets/world/pit.png"
		"bandit":
			return "res://assets/world/skeleton.png" if cave else "res://assets/world/bandit.png"
		"bounty_bandit":
			return "res://assets/world/skeleton_crystal.png" if cave else "res://assets/world/bandit_red.png"
		"bull":
			return "res://assets/world/cave_lizard.png" if cave else "res://assets/world/trail_bull.png"
		"rattlesnake":
			return "res://assets/world/scorpion_idle.png" if cave else "res://assets/world/rattlesnake_idle.png"
		"scorpion":
			return "res://assets/world/scorpion_idle.png"
		"carrion":
			return "res://assets/world/cave_bat_0.png" if cave else "res://assets/world/carrion_bird.png"
		"checkpoint":
			return (
				"res://assets/world/checkpoint_cave_active.png"
				if cave
				else "res://assets/world/checkpoint_active.png"
			)
		"goal":
			return "res://assets/world/goal_crystal_gate.png" if cave else "res://assets/world/goal_saloon.png"
		"acid_drip":
			return "res://assets/world/acid_drip.png"
		"stalactite":
			return "res://assets/world/stalactite.png"
		"stalactite_static":
			return "res://assets/world/stalactite_static.png"
		"bat":
			return "res://assets/world/cave_bat_0.png"
		"star":
			return "res://assets/world/star_badge.png"
		"chest":
			return "res://assets/world/treasure_chest_stamp.png"
		"spring":
			return "res://assets/world/spring.png"
		"ninja":
			return "res://assets/world/ninja_idle.png"
		"wings":
			return "res://assets/world/modes/wings.png"
		"boots":
			return "res://assets/world/modes/magic_boots.png"
		"speed":
			return "res://assets/world/modes/speed_badge.png"
		"shield":
			return "res://assets/world/modes/bubble_shield.png"
		"conveyor":
			return "res://assets/world/conveyor.png"
		"timed_door":
			return "res://assets/world/fence_gate.png"
		"fence":
			return "res://assets/world/fence.png"
		"mover":
			return "res://assets/world/wood_plank.png" if not cave else "res://assets/world/cave_plank.png"
		"moving_cloud":
			return "res://assets/world/moving_cloud.svg"
		"blink_cloud":
			return "res://assets/world/cloud.png"
		"wind":
			return "res://assets/world/wind_gust.png"
		_:
			return ""

static func stamp_label(type_name: String, style: String = DESERT) -> String:
	var cave := is_cave(style)
	match type_name:
		"ground":
			return "Cave Floor" if cave else "Dirt"
		"canyon":
			return "Cave Gap" if cave else "Canyon"
		"platform":
			return "Crystal Ledge" if cave else "Plank"
		"ladder":
			return "Ladder"
		"cactus":
			return "Poison Fungus" if cave else "Cactus"
		"pit":
			return "Floor Hole" if cave else "Pit"
		"bandit":
			return "Bow Skeleton" if cave else "Bandit"
		"bounty_bandit":
			return "Crystal Skeleton" if cave else "Bounty Bandit"
		"bull":
			return "Cave Lizard" if cave else "Bull"
		"rattlesnake":
			return "Scorpion" if cave else "Rattlesnake"
		"scorpion":
			return "Scorpion"
		"carrion":
			return "Bat" if cave else "Carrion Bird"
		"checkpoint":
			return "Lantern Camp" if cave else "Camp"
		"goal":
			return "Crystal Gate" if cave else "Saloon"
		"acid_drip":
			return "Pink Drop"
		"stalactite":
			return "Falling Spike"
		"stalactite_static":
			return "Ceiling Spike"
		"bat":
			return "Cave Bat"
		"star":
			return "Badge"
		"chest":
			return "Treasure Chest"
		"spring":
			return "Spring"
		"ninja":
			return "Ninja"
		"wings":
			return "Wings"
		"boots":
			return "Magic Boots"
		"speed":
			return "Speed Star"
		"shield":
			return "Bubble Shield"
		"conveyor":
			return "Conveyor"
		"timed_door":
			return "Timed Gate"
		"fence":
			return "Fence"
		"mover":
			return "Moving Plank"
		"moving_cloud":
			return "Moving Cloud"
		"blink_cloud":
			return "Blink Cloud"
		"wind":
			return "Wind"
		"erase":
			return "Erase"
		_:
			return type_name.capitalize()

static func tool_categories(style: String = DESERT, start_mounted: bool = false) -> Array:
	var cave := is_cave(style)
	## Hazards = stationary / environmental threats. Enemies = roaming actors.
	var hazards: Array = [
		_tool("cactus", style),
		_tool("pit", style),
		_tool("rattlesnake", style),
	]
	if cave:
		hazards.append_array([
			_tool("acid_drip", style),
			_tool("stalactite", style),
		])
	var enemies: Array = [
		_tool("bandit", style),
		_tool("bounty_bandit", style),
		_tool("bull", style),
		_tool("ninja", style),
	]
	if cave:
		enemies.append(_tool("bat", style))
	else:
		enemies.append(_tool("carrion", style))
	var pickup_tools: Array = [_tool("star", style), _tool("checkpoint", style)]
	if not start_mounted:
		pickup_tools.insert(1, _tool("chest", style))
	var trail_tools: Array = [
		_tool("ground", style),
		_tool("canyon", style),
		_tool("platform", style),
		_tool("ladder", style),
		_tool("spring", style),
		_tool("conveyor", style),
	]
	## Ranch gates are a desert prop; cave trails route around belts and ledges instead.
	if not cave:
		trail_tools.append(_tool("timed_door", style))
	trail_tools.append(_tool("fence", style))
	var categories: Array = [
		{
			"id": "trail",
			"label": "Trail",
			"tools": trail_tools,
		},
		{
			"id": "motion",
			"label": "Motion",
			"tools": [
				_tool("mover", style),
				_tool("moving_cloud", style),
				_tool("blink_cloud", style),
				_tool("wind", style),
			],
		},
		{
			"id": "pickups",
			"label": "Pickups",
			"tools": pickup_tools,
		},
		{
			"id": "hazards",
			"label": "Hazards",
			"tools": hazards,
		},
		{
			"id": "enemies",
			"label": "Enemies",
			"tools": enemies,
		},
	]
	if not start_mounted:
		categories.append({
			"id": "powerups",
			"label": "Power-ups",
			## Speed Stars only drop from chests / bosses — never stamped on campaign trails.
			"tools": [
				_tool("wings", style),
				_tool("boots", style),
				_tool("shield", style),
			],
		})
	categories.append_array([
		{
			"id": "goal",
			"label": "Goal",
			"tools": [_tool("goal", style)],
		},
		{
			"id": "tools",
			"label": "Tools",
			"tools": [["erase", stamp_label("erase", style), ""]],
		},
	])
	return categories

static func _tool(type_name: String, style: String) -> Array:
	return [type_name, stamp_label(type_name, style), stamp_icon_path(type_name, style)]

static func sky_path(style: String) -> String:
	return "res://assets/world/cave_sky.png" if is_cave(style) else "res://assets/world/sky_handdrawn.png"

static func ceiling_path(style: String) -> String:
	return "res://assets/world/cave_ceiling_tile.png" if is_cave(style) else ""

static func ceiling_fill_path(style: String) -> String:
	return "res://assets/world/cave_ceiling_fill.png" if is_cave(style) else ""

static func ceiling_segments_catalog_path(style: String = CAVE) -> String:
	return "res://assets/world/cave_ceiling_segments.json" if is_cave(style) else ""

static func floor_path(style: String) -> String:
	return (
		"res://assets/world/cave_floor_tile.png"
		if is_cave(style)
		else "res://assets/world/trail_desert_tile.png"
	)

static func dirt_path(style: String) -> String:
	return (
		"res://assets/world/cave_dirt_tile.png"
		if is_cave(style)
		else "res://assets/world/trail_dirt_tile.png"
	)

static func plank_path(style: String) -> String:
	return "res://assets/world/cave_plank.png" if is_cave(style) else "res://assets/world/wood_plank.png"

static func pit_path(style: String) -> String:
	return "res://assets/world/cave_pit.png" if is_cave(style) else "res://assets/world/pit.png"

static func canyon_rim_path(style: String) -> String:
	return (
		"res://assets/world/cave_canyon_rim_left.png"
		if is_cave(style)
		else "res://assets/world/canyon_rim_left.png"
	)

static func sky_color(style: String) -> Color:
	if is_cave(style):
		return Color(0.12, 0.14, 0.22, 1.0)
	return Color(0.58, 0.82, 0.96, 1.0)
