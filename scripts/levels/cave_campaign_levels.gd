class_name CaveCampaignLevels
extends RefCounted

## Stamp layouts for builtin cave trails 11–15.


static func is_cave_source(level_number: int) -> bool:
	return level_number == 5 or (level_number >= 11 and level_number <= 15)


static func level_data(level_number: int) -> Dictionary:
	match clampi(level_number, 11, 15):
		11:
			return _level_11()
		12:
			return _level_12()
		13:
			return _level_13()
		14:
			return _level_14()
		_:
			return _level_15()


static func _base(title: String, width: int = 120, height: int = 10) -> Dictionary:
	var trail := CustomLevelStore.trail_row(height)
	var objects: Array[Dictionary] = []
	for x in range(width):
		objects.append({"type": "ground", "x": x, "y": trail})
	return {
		"version": CustomLevelStore.VERSION,
		"title": title,
		"kind": "standalone",
		"style": CustomLevelStore.STYLE_CAVE,
		"source_level": 0,
		"grid": 40,
		"width": width,
		"height": height,
		"spawn": [2, trail],
		"objects": objects,
		"start_mounted": false,
	}


static func _add(objects: Array[Dictionary], type_name: String, x: int, y: int) -> void:
	objects.append({"type": type_name, "x": x, "y": y})


static func _level_11() -> Dictionary:
	## Crystal Mouth — introduce cave remaps + first ladder split.
	var data := _base("Crystal Mouth", 100, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = data["objects"]
	_add(objects, "cactus", 10, trail - 1)
	_add(objects, "star", 14, trail - 2)
	_add(objects, "bandit", 20, trail - 1)
	_add(objects, "pit", 26, trail)
	CustomLevelStore.append_ladder_branch(objects, trail, 32)
	_add(objects, "rattlesnake", 55, trail - 1)
	_add(objects, "checkpoint", 60, trail - 1)
	_add(objects, "ninja", 70, trail - 1)
	_add(objects, "chest", 78, trail - 1)
	_add(objects, "spring", 85, trail - 1)
	_add(objects, "star", 90, trail - 3)
	_add(objects, "goal", 96, trail - 1)
	data["objects"] = objects
	return data


static func _level_12() -> Dictionary:
	## Bat Gallery — bats, drips, upper ledge route.
	var data := _base("Bat Gallery", 110, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = data["objects"]
	_add(objects, "bat", 12, trail - 4)
	_add(objects, "bat", 22, trail - 5)
	_add(objects, "acid_drip", 16, 0)
	_add(objects, "acid_drip", 28, 0)
	_add(objects, "cactus", 18, trail - 1)
	_add(objects, "star", 24, trail - 2)
	CustomLevelStore.append_ladder_branch(objects, trail, 34)
	_add(objects, "bat", 42, trail - 5)
	_add(objects, "bull", 58, trail - 1)
	_add(objects, "checkpoint", 64, trail - 1)
	_add(objects, "stalactite", 72, 0)
	_add(objects, "stalactite", 78, 1)
	_add(objects, "bandit", 84, trail - 1)
	_add(objects, "chest", 92, trail - 1)
	_add(objects, "goal", 104, trail - 1)
	data["objects"] = objects
	return data


static func _level_13() -> Dictionary:
	## Acid Veins — drips + fungus gauntlet + canyon hop.
	var data := _base("Acid Veins", 120, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = []
	for x in range(int(data["width"])):
		if x >= 18 and x <= 25:
			objects.append({"type": "canyon", "x": x, "y": trail})
		else:
			objects.append({"type": "ground", "x": x, "y": trail})
	_add(objects, "platform", 18, trail - 2)
	_add(objects, "platform", 20, trail - 2)
	_add(objects, "platform", 22, trail - 2)
	_add(objects, "acid_drip", 12, 0)
	_add(objects, "acid_drip", 30, 0)
	_add(objects, "acid_drip", 36, 0)
	_add(objects, "cactus", 34, trail - 1)
	_add(objects, "cactus", 40, trail - 1)
	_add(objects, "star", 38, trail - 2)
	_add(objects, "rattlesnake", 48, trail - 1)
	_add(objects, "checkpoint", 55, trail - 1)
	CustomLevelStore.append_ladder_branch(objects, trail, 62)
	_add(objects, "ninja", 85, trail - 1)
	_add(objects, "bat", 90, trail - 4)
	_add(objects, "chest", 96, trail - 1)
	_add(objects, "goal", 114, trail - 1)
	data["objects"] = objects
	return data


static func _level_14() -> Dictionary:
	## Ladder Grotto — double branch + lizards.
	var data := _base("Ladder Grotto", 130, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = data["objects"]
	CustomLevelStore.append_ladder_branch(objects, trail, 16)
	_add(objects, "bull", 40, trail - 1)
	_add(objects, "star", 44, trail - 2)
	_add(objects, "pit", 50, trail)
	CustomLevelStore.append_ladder_branch(objects, trail, 58)
	_add(objects, "checkpoint", 80, trail - 1)
	_add(objects, "bandit", 88, trail - 1)
	_add(objects, "bounty_bandit", 96, trail - 1)
	_add(objects, "stalactite", 100, 0)
	_add(objects, "ninja", 108, trail - 1)
	_add(objects, "chest", 116, trail - 1)
	_add(objects, "goal", 124, trail - 1)
	data["objects"] = objects
	return data


static func _level_15() -> Dictionary:
	## Dragon Gate — finale trail before the dragon boss.
	var data := _base("Dragon Gate", 140, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = data["objects"]
	_add(objects, "star", 8, trail - 2)
	_add(objects, "cactus", 12, trail - 1)
	_add(objects, "bat", 18, trail - 5)
	_add(objects, "acid_drip", 22, 0)
	CustomLevelStore.append_ladder_branch(objects, trail, 28)
	_add(objects, "bull", 52, trail - 1)
	_add(objects, "checkpoint", 60, trail - 1)
	_add(objects, "stalactite", 68, 0)
	_add(objects, "stalactite", 74, 0)
	_add(objects, "ninja", 80, trail - 1)
	_add(objects, "bandit", 90, trail - 1)
	_add(objects, "rattlesnake", 98, trail - 1)
	_add(objects, "chest", 108, trail - 1)
	_add(objects, "spring", 116, trail - 1)
	_add(objects, "bat", 120, trail - 4)
	_add(objects, "star", 124, trail - 3)
	_add(objects, "goal", 134, trail - 1)
	data["objects"] = objects
	return data
