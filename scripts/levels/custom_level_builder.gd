class_name CustomLevelBuilder
extends RefCounted

## Turns a constrained editor document into a normal playable LevelController.

const PLAYER := preload("res://scenes/player/player.tscn")
const CHECKPOINT := preload("res://scenes/world/checkpoint.tscn")
const GOAL := preload("res://scenes/world/goal.tscn")
const HAZARD := preload("res://scenes/world/hazard.tscn")
const STAR := preload("res://scenes/world/star.tscn")
const SPRING := preload("res://scenes/world/spring_pad.tscn")
const HUD := preload("res://scenes/ui/hud.tscn")
const PAUSE := preload("res://scenes/ui/pause_menu.tscn")
const TRANSITION := preload("res://scenes/ui/level_transition.tscn")


static func build(level: LevelController, data: Dictionary) -> void:
	var grid := float(data.get("grid", 40))
	var width := int(data.get("width", 24))
	_add_background(level, width * grid)

	var spawn_data: Array = data.get("spawn", [2, 8])
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(float(spawn_data[0]) * grid, float(spawn_data[1]) * grid)
	level.add_child(spawn)

	var counters: Dictionary = {}
	var has_goal := false
	for value in data.get("objects", []):
		if not (value is Dictionary):
			continue
		var object := value as Dictionary
		var type_name := str(object.get("type", ""))
		var index := int(counters.get(type_name, 0))
		counters[type_name] = index + 1
		var position := Vector2(
			(float(object.get("x", 0)) + 0.5) * grid,
			float(object.get("y", 0)) * grid
		)
		match type_name:
			"ground":
				_add_block(level, "Ground%d" % index, position, Vector2(grid, grid), Color(0.86, 0.68, 0.38))
			"platform":
				_add_block(level, "Platform%d" % index, position, Vector2(grid * 2.0, 24), Color(0.62, 0.4, 0.22))
			"star":
				_add_scene(level, STAR, "CustomStar%d" % index, position)
			"cactus":
				_add_scene(level, HAZARD, "Cactus%d" % index, position)
			"pit":
				var pit := _add_scene(level, HAZARD, "Pit%d" % index, position + Vector2(0, 40))
				pit.scale = Vector2(1.8, 1.8)
			"checkpoint":
				_add_scene(level, CHECKPOINT, "Checkpoint" if index == 0 else "Checkpoint%d" % index, position)
			"spring":
				_add_scene(level, SPRING, "Spring%d" % index, position)
			"goal":
				if not has_goal:
					_add_scene(level, GOAL, "Goal", position)
					has_goal = true

	if not has_goal:
		_add_scene(level, GOAL, "Goal", Vector2((width - 2) * grid, 8 * grid))
	var player := PLAYER.instantiate()
	player.name = "Player"
	level.add_child(player)
	player.position = spawn.position
	level.add_child(TRANSITION.instantiate())
	level.add_child(HUD.instantiate())
	level.add_child(PAUSE.instantiate())


static func _add_background(level: Node, width: float) -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.position = Vector2(-200, -300)
	background.size = Vector2(width + 400, 900)
	background.color = Color(0.98, 0.74, 0.45)
	background.z_index = -20
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level.add_child(background)
	var sky := ColorRect.new()
	sky.name = "SkyBand"
	sky.position = Vector2(-200, -300)
	sky.size = Vector2(width + 400, 360)
	sky.color = Color(0.52, 0.8, 0.98)
	sky.z_index = -19
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level.add_child(sky)


static func _add_block(
	level: Node,
	node_name: String,
	position: Vector2,
	size: Vector2,
	color: Color
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
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
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
