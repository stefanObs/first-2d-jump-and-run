class_name CustomLevelBuilder
extends RefCounted

## Turns a constrained editor document into a normal playable LevelController.

const PLAYER := preload("res://scenes/player/player.tscn")
const CHECKPOINT := preload("res://scenes/world/checkpoint.tscn")
const GOAL := preload("res://scenes/world/goal.tscn")
const HAZARD := preload("res://scenes/world/hazard.tscn")
const CHEST := preload("res://scenes/world/treasure_chest.tscn")
const STAR := preload("res://scenes/world/star.tscn")
const SPRING := preload("res://scenes/world/spring_pad.tscn")
const BANDIT := preload("res://scenes/world/opponent.tscn")
const BULL := preload("res://scenes/world/bull_enemy.tscn")
const NINJA := preload("res://scenes/world/ninja_enemy.tscn")
const RATTLESNAKE := preload("res://scenes/world/rattlesnake.tscn")
const CARRION := preload("res://scenes/world/carrion.tscn")
const MODE_ITEM := preload("res://scenes/world/mode_item.tscn")
const CONVEYOR := preload("res://scenes/world/conveyor_belt.tscn")
const TIMED_DOOR := preload("res://scenes/world/timed_door.tscn")
const FENCE_TEX := preload("res://assets/world/fence.png")
const HUD := preload("res://scenes/ui/hud.tscn")
const PAUSE := preload("res://scenes/ui/pause_menu.tscn")
const TRANSITION := preload("res://scenes/ui/level_transition.tscn")


static func build(level: LevelController, data: Dictionary, preview: bool = false) -> void:
	var grid := float(data.get("grid", 40))
	var width := int(data.get("width", 24))
	var height := int(data.get("height", 8))
	var trail := CustomLevelStore.trail_row(height)
	var style := CustomLevelStore.normalize_style(data.get("style", CustomLevelStore.STYLE_DESERT))
	var start_mounted := (
		bool(data.get("start_mounted", false)) or int(data.get("source_level", 0)) == 1
	)
	level.set_meta("level_style", style)
	_add_background(level, width * grid, style)

	var spawn_data: Array = data.get("spawn", [2, trail])
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(float(spawn_data[0]) * grid, float(spawn_data[1]) * grid)
	level.add_child(spawn)

	_add_ground_columns(level, data, grid, trail)

	var canyon_runs := _canyon_runs(data, trail)
	var counters: Dictionary = {}
	var has_goal := false
	for value in data.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		var type_name := str(object.get("type", ""))
		if type_name == "ground" or type_name == "canyon":
			continue
		if type_name == "goal" and has_goal:
			continue
		if start_mounted and CustomLevelStore.is_mounted_banned(type_name):
			continue
		if (
			type_name == "bull"
			and not CustomLevelStore.bull_stamp_allowed(
				data.get("objects", []) as Array, int(object.get("x", 0)), trail
			)
		):
			continue
		var index := int(counters.get(type_name, 0))
		counters[type_name] = index + 1
		var position := CustomLevelStore.object_world_position(object, grid, trail)
		if _spawn_object(level, type_name, index, position, object, grid, trail, style):
			has_goal = true

	for run_index in range(canyon_runs.size()):
		var run: Dictionary = canyon_runs[run_index]
		var center_x := (float(run["start_x"]) + float(run["end_x"])) * 0.5 + 0.5
		var position := Vector2(center_x * grid, float(trail) * grid + 40.0)
		var canyon := _add_scene(level, HAZARD, "Canyon%d" % run_index, position)
		canyon.scale = Vector2(1.8, 1.8)

	if not has_goal:
		_add_styled(level, GOAL, "Goal", Vector2((width - 2) * grid, float(trail) * grid), style)
	_finalize_player_and_ui(level, data, spawn, preview)


## Returns true when a goal stamp was placed.
static func _spawn_object(
	level: LevelController,
	type_name: String,
	index: int,
	position: Vector2,
	object: Dictionary,
	grid: float,
	trail: int,
	style: String
) -> bool:
	match type_name:
		"platform", "ladder_ledge":
			_add_block(
				level,
				("Platform%d" if type_name == "platform" else "LadderLedge%d") % index,
				position,
				Vector2(grid * 2.0, 24),
				Color(0.55, 0.32, 0.14),
				false,
				true
			)
		"ladder":
			var ladder := Ladder.new()
			ladder.name = "Ladder%d" % index
			ladder.height_cells = CustomLevelStore.LADDER_HEIGHT_CELLS
			ladder.position = position
			level.add_child(ladder)
		"star":
			_add_scene(level, STAR, "CustomStar%d" % index, position)
		"chest":
			_add_scene(level, CHEST, "CustomChest%d" % index, position)
		"cactus":
			_add_styled(level, HAZARD, "Cactus%d" % index, position, style)
		"pit":
			var pit := _add_styled(
				level,
				HAZARD,
				"Pit%d" % index,
				CustomLevelStore.pit_world_position(object, grid, trail),
				style
			) as Hazard
			if pit != null:
				pit.set_meta("fixed_pit", true)
				pit.scale = Vector2.ONE
				pit._configure_visual()
		"checkpoint":
			_add_styled(
				level,
				CHECKPOINT,
				"Checkpoint" if index == 0 else "Checkpoint%d" % index,
				position,
				style
			)
		"spring":
			_add_scene(level, SPRING, "Spring%d" % index, position)
		"bandit", "bounty_bandit":
			var bandit := BANDIT.instantiate() as Opponent
			if bandit != null:
				bandit.bounty_bandit = type_name == "bounty_bandit"
				bandit.name = "Opponent%d" % index
				bandit.position = position
				level.add_child(bandit)
				bandit.apply_level_style(style)
		"bull":
			_add_styled(level, BULL, "Bull%d" % index, position, style)
		"ninja":
			_add_scene(level, NINJA, "Ninja%d" % index, position)
		"rattlesnake":
			_add_styled(level, RATTLESNAKE, "Rattlesnake%d" % index, position, style)
		"carrion":
			_add_scene(level, CARRION, "Carrion%d" % index, position)
		"bat":
			var bat := BatEnemy.new()
			bat.name = "Bat%d" % index
			bat.position = position
			level.add_child(bat)
		"acid_drip":
			var drip := AcidDrip.new()
			drip.name = "AcidDrip%d" % index
			drip.position = position
			level.add_child(drip)
		"stalactite", "stalactite_static":
			var spike := StalactiteHazard.new()
			spike.name = (
				"Stalactite%d" if type_name == "stalactite" else "StalactiteStatic%d"
			) % index
			spike.drops = type_name == "stalactite"
			spike.position = position
			level.add_child(spike)
		"wings", "boots", "speed", "shield":
			var mode_item := _add_scene(level, MODE_ITEM, "ModeItem%d" % index, position) as ModeItem
			if mode_item != null:
				mode_item.mode = ModeController.mode_from_stamp(type_name)
		"conveyor":
			var belt := CONVEYOR.instantiate() as ConveyorBelt
			if belt != null:
				belt.name = "Conveyor%d" % index
				belt.position = position
				belt.push_right = bool(object.get("push_right", true))
				level.add_child(belt)
		"timed_door":
			_add_scene(level, TIMED_DOOR, "Door%d" % index, position)
		"fence":
			_add_fence_decor(level, "FenceDecor%d" % index, position)
		"goal":
			_add_styled(level, GOAL, "Goal", position, style)
			return true
	return false


static func _add_fence_decor(level: Node, node_name: String, feet_position: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = FENCE_TEX
	sprite.centered = true
	sprite.position = feet_position + Vector2(0.0, -float(FENCE_TEX.get_height()) * 0.5)
	sprite.z_index = 2
	level.add_child(sprite)


static func _finalize_player_and_ui(
	level: LevelController,
	data: Dictionary,
	spawn: Marker2D,
	preview: bool
) -> void:
	var player := PLAYER.instantiate() as Player
	player.name = "Player"
	# Dusty Trail (campaign source 1) teaches mounted riding — keep that when
	# workshop overrides rebuild the trail from stamp data.
	if bool(data.get("start_mounted", false)) or int(data.get("source_level", 0)) == 1:
		player.start_mounted = true
	level.add_child(player)
	player.position = spawn.position
	if preview:
		player.set_input_enabled(false)
		player.set_physics_process(false)
		player.set_process(false)
	else:
		level.add_child(TRANSITION.instantiate())
		level.add_child(HUD.instantiate())
		level.add_child(PAUSE.instantiate())


static func _add_styled(
	level: Node,
	packed: PackedScene,
	node_name: String,
	position: Vector2,
	style: String
) -> Node:
	var node := _add_scene(level, packed, node_name, position)
	if node != null and node.has_method("apply_level_style"):
		node.call("apply_level_style", style)
	return node


## Merge horizontally adjacent canyon stamps into one wider gap run.
static func _canyon_runs(data: Dictionary, trail: int) -> Array[Dictionary]:
	var xs: Array[int] = []
	for value in data.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		var type_name := str(object.get("type", ""))
		if type_name not in ["canyon"]:
			continue
		if int(object.get("y", -1)) != trail:
			continue
		xs.append(int(object.get("x", 0)))
	xs.sort()
	var runs: Array[Dictionary] = []
	var index := 0
	while index < xs.size():
		var start_x := xs[index]
		var end_x := start_x
		while index + 1 < xs.size() and xs[index + 1] == end_x + 1:
			index += 1
			end_x = xs[index]
		runs.append({"start_x": start_x, "end_x": end_x})
		index += 1
	return runs


## Merge vertically stacked dirt cells into one tall bank so steps look handpainted.
static func _add_ground_columns(level: Node, data: Dictionary, grid: float, trail: int) -> void:
	var columns: Dictionary = {}
	# Pit columns stay as dirt banks so the trail crust runs unbroken behind the
	# pit mouth (no sky/air pocket); only the mouth columns lose collision so the
	# cowboy still drops in.
	var pit_hole := CustomLevelStore.pit_hole_columns(data, trail)
	for value in data.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		if str(object.get("type", "")) != "ground":
			continue
		var x := int(object.get("x", 0))
		var y := int(object.get("y", trail))
		if not columns.has(x):
			columns[x] = {"top": y, "bottom": y}
		else:
			var col: Dictionary = columns[x]
			col["top"] = mini(int(col["top"]), y)
			col["bottom"] = maxi(int(col["bottom"]), y)
	var xs: Array = columns.keys()
	xs.sort()
	var index := 0
	for x in xs:
		var col: Dictionary = columns[x]
		var top_y := int(col["top"])
		var bottom_y := int(col["bottom"])
		var cell_count := bottom_y - top_y + 1
		var size := Vector2(grid, grid * float(cell_count))
		var position := Vector2(
			(float(x) + 0.5) * grid,
			(float(top_y) + float(cell_count) * 0.5) * grid
		)
		var block := _add_block(
			level,
			"Ground%d" % index,
			position,
			size,
			Color(0.72, 0.46, 0.22),
			true
		)
		if pit_hole.has(int(x)):
			var hole_shape := block.get_node_or_null("CollisionShape2D") as CollisionShape2D
			if hole_shape != null:
				hole_shape.disabled = true
		index += 1


static func _add_background(level: Node, width: float, style: String = CustomLevelStore.STYLE_DESERT) -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.position = Vector2(-200, -300)
	background.size = Vector2(width + 400, 900)
	background.color = LevelStyle.sky_color(style)
	background.z_index = -20
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level.add_child(background)
	var sky := ColorRect.new()
	sky.name = "SkyBand"
	sky.position = Vector2(-200, -300)
	sky.size = Vector2(width + 400, 360)
	sky.color = LevelStyle.sky_color(style).darkened(0.08)
	sky.z_index = -19
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level.add_child(sky)


static func _add_block(
	level: Node,
	node_name: String,
	position: Vector2,
	size: Vector2,
	color: Color,
	with_grass: bool = false,
	one_way: bool = false
) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = position
	var visual := ColorRect.new()
	visual.name = "Visual"
	visual.position = -size * 0.5
	visual.size = size
	visual.color = color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)
	if with_grass:
		var stripe := ColorRect.new()
		stripe.name = "TopStripe"
		stripe.position = Vector2(-size.x * 0.5, -size.y * 0.5)
		stripe.size = Vector2(size.x, mini(14.0, size.y * 0.22))
		stripe.color = Color(0.28, 0.72, 0.22)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(stripe)
		var edge := ColorRect.new()
		edge.name = "DirtEdge"
		edge.position = Vector2(-size.x * 0.5, size.y * 0.5 - 6.0)
		edge.size = Vector2(size.x, 6.0)
		edge.color = Color(0.48, 0.28, 0.12)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(edge)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.one_way_collision = one_way
	body.add_child(collision)
	level.add_child(body)
	return body


static func _add_scene(
	level: Node,
	scene: PackedScene,
	node_name: String,
	position: Vector2
) -> Node2D:
	var node := scene.instantiate() as Node2D
	node.name = node_name
	node.position = position
	level.add_child(node)
	return node
