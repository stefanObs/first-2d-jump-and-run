class_name CaveCampaignLevels
extends RefCounted

## Stamp layouts for builtin cave trails 11–16.


static func is_cave_source(level_number: int) -> bool:
	return level_number == 5 or (level_number >= 11 and level_number <= 16)


static func level_data(level_number: int) -> Dictionary:
	match clampi(level_number, 11, 16):
		11:
			return _level_11()
		12:
			return _level_12()
		13:
			return _level_13()
		14:
			return _level_14()
		15:
			return _level_15()
		_:
			return _level_16()


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


static func _add_badge(objects: Array[Dictionary], x: int, trail: int, height: int = 2) -> void:
	## Sheriff badge above the trail (or a short hop) — same stamp as desert meadows.
	_add(objects, "star", x, maxi(trail - height, 0))


static func _add_camps(objects: Array[Dictionary], trail: int, columns: Array) -> void:
	## Three lantern camps along the dirt — never on canyon/pit mouths or other ground stamps.
	for column in columns:
		_add(objects, "checkpoint", int(column), trail - 1)


static func _level_11() -> Dictionary:
	## Crystal Mouth — introduce cave remaps + ladder splits + ranch fence décor.
	var data := _base("Crystal Mouth", 100, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = data["objects"]
	CustomLevelStore.append_fence_run(objects, trail, 6, 2)
	_add_badge(objects, 8, trail)
	_add(objects, "cactus", 10, trail - 1)
	_add(objects, "acid_drip", 12, 0)
	_add_badge(objects, 14, trail)
	_add_badge(objects, 17, trail)
	_add(objects, "bandit", 20, trail - 1)
	_add_badge(objects, 22, trail)
	_add(objects, "spring", 23, trail - 1)
	_add(objects, "pit", 28, trail)
	CustomLevelStore.append_ladder_branch(objects, trail, 32)
	_add_badge(objects, 42, trail)
	_add(objects, "acid_drip", 48, 0)
	CustomLevelStore.append_platform_run(objects, trail, 50, 3, 2)
	_add_badge(objects, 52, trail, 3)
	_add_camps(objects, trail, [16, 60, 82])
	CustomLevelStore.append_fence_run(objects, trail, 64, 1)
	_add_badge(objects, 66, trail)
	_add(objects, "rattlesnake", 68, trail - 1)
	_add(objects, "acid_drip", 70, 1)
	_add(objects, "ninja", 72, trail - 1)
	CustomLevelStore.append_ladder_branch(objects, trail, 76)
	_add_badge(objects, 86, trail)
	_add(objects, "spring", 90, trail - 1)
	_add(objects, "chest", 92, trail - 1)
	_add_badge(objects, 94, trail, 3)
	_add(objects, "goal", 96, trail - 1)
	data["objects"] = objects
	return data


static func _level_12() -> Dictionary:
	## Bat Gallery — bats, drips, ledges + first cave conveyor belt.
	var data := _base("Bat Gallery", 110, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = data["objects"]
	CustomLevelStore.append_fence_run(objects, trail, 4, 1)
	_add_badge(objects, 8, trail)
	_add(objects, "bat", 12, trail - 4)
	_add_badge(objects, 14, trail)
	_add(objects, "bat", 22, trail - 5)
	_add(objects, "acid_drip", 16, 0)
	_add(objects, "acid_drip", 28, 0)
	_add(objects, "cactus", 18, trail - 1)
	_add_badge(objects, 24, trail)
	_add_badge(objects, 27, trail)
	_add(objects, "spring", 30, trail - 1)
	CustomLevelStore.append_ladder_branch(objects, trail, 34)
	_add(objects, "bat", 42, trail - 5)
	_add_badge(objects, 44, trail)
	_add(objects, "acid_drip", 46, 1)
	_add(objects, "spring", 50, trail - 1)
	CustomLevelStore.append_platform_run(objects, trail, 52, 3, 2)
	_add_badge(objects, 54, trail, 3)
	_add(objects, "bull", 60, trail - 1)
	_add_camps(objects, trail, [10, 64, 80])
	_add_badge(objects, 66, trail)
	CustomLevelStore.append_conveyor_belt(objects, trail, 68, true)
	_add(objects, "acid_drip", 78, 0)
	_add(objects, "stalactite", 80, 0)
	_add(objects, "stalactite", 84, 1)
	_add(objects, "bandit", 86, trail - 1)
	_add_badge(objects, 88, trail)
	CustomLevelStore.append_ladder_branch(objects, trail, 90)
	_add(objects, "acid_drip", 98, 1)
	_add(objects, "spring", 98, trail - 1)
	_add(objects, "chest", 100, trail - 1)
	CustomLevelStore.append_fence_run(objects, trail, 102, 1)
	_add_badge(objects, 104, trail)
	_add(objects, "goal", 106, trail - 1)
	data["objects"] = objects
	return data


static func _level_13() -> Dictionary:
	## Acid Veins — drips + fungus gauntlet + canyon hop + belt gate.
	var data := _base("Acid Veins", 120, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = []
	for x in range(int(data["width"])):
		if x >= 18 and x <= 25:
			objects.append({"type": "canyon", "x": x, "y": trail})
		else:
			objects.append({"type": "ground", "x": x, "y": trail})
	CustomLevelStore.append_fence_run(objects, trail, 6, 1)
	_add_badge(objects, 8, trail)
	_add_badge(objects, 12, trail)
	_add(objects, "spring", 16, trail - 1)
	## Two campaign-width planks span the canyon mouth (was four half-width stamps).
	_add(objects, "platform", 18, trail - 2)
	_add(objects, "platform", 22, trail - 2)
	_add_badge(objects, 21, trail, 3)
	_add(objects, "acid_drip", 12, 0)
	_add(objects, "acid_drip", 30, 0)
	_add(objects, "acid_drip", 36, 0)
	_add(objects, "cactus", 34, trail - 1)
	_add_badge(objects, 36, trail)
	_add(objects, "cactus", 40, trail - 1)
	_add_badge(objects, 38, trail)
	_add_badge(objects, 42, trail)
	_add(objects, "acid_drip", 44, 1)
	_add(objects, "rattlesnake", 48, trail - 1)
	_add_badge(objects, 52, trail)
	_add_camps(objects, trail, [12, 55, 76])
	CustomLevelStore.append_ladder_branch(objects, trail, 62)
	_add_badge(objects, 72, trail)
	_add(objects, "acid_drip", 78, 0)
	_add(objects, "spring", 80, trail - 1)
	CustomLevelStore.append_platform_run(objects, trail, 82, 3, 2)
	_add_badge(objects, 84, trail, 3)
	_add(objects, "ninja", 88, trail - 1)
	_add(objects, "bat", 92, trail - 4)
	_add(objects, "acid_drip", 94, 1)
	_add_badge(objects, 96, trail)
	CustomLevelStore.append_conveyor_belt(objects, trail, 98, true)
	_add(objects, "spring", 108, trail - 1)
	_add(objects, "chest", 110, trail - 1)
	CustomLevelStore.append_fence_run(objects, trail, 112, 1)
	_add_badge(objects, 113, trail)
	_add(objects, "goal", 114, trail - 1)
	data["objects"] = objects
	return data


static func _level_14() -> Dictionary:
	## Ladder Grotto — triple branch + lizards + reverse belt.
	var data := _base("Ladder Grotto", 130, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = data["objects"]
	CustomLevelStore.append_fence_run(objects, trail, 6, 2)
	_add_badge(objects, 8, trail)
	_add(objects, "acid_drip", 10, 0)
	_add_badge(objects, 12, trail)
	CustomLevelStore.append_ladder_branch(objects, trail, 16)
	_add_badge(objects, 28, trail)
	_add(objects, "acid_drip", 34, 1)
	_add(objects, "spring", 34, trail - 1)
	CustomLevelStore.append_platform_run(objects, trail, 36, 3, 2)
	_add_badge(objects, 38, trail, 3)
	_add(objects, "bull", 44, trail - 1)
	_add_badge(objects, 46, trail)
	_add(objects, "spring", 49, trail - 1)
	_add(objects, "pit", 52, trail)
	_add_badge(objects, 54, trail)
	CustomLevelStore.append_ladder_branch(objects, trail, 58)
	_add_badge(objects, 70, trail)
	_add(objects, "acid_drip", 72, 0)
	_add(objects, "spring", 74, trail - 1)
	CustomLevelStore.append_platform_run(objects, trail, 76, 3, 2)
	_add_badge(objects, 78, trail, 3)
	_add_camps(objects, trail, [24, 84, 116])
	_add_badge(objects, 86, trail)
	CustomLevelStore.append_conveyor_belt(objects, trail, 92, false)
	_add(objects, "acid_drip", 96, 1)
	_add(objects, "bandit", 100, trail - 1)
	_add_badge(objects, 103, trail)
	_add(objects, "bounty_bandit", 106, trail - 1)
	_add(objects, "stalactite", 110, 0)
	CustomLevelStore.append_ladder_branch(objects, trail, 112)
	_add(objects, "acid_drip", 118, 0)
	_add(objects, "spring", 120, trail - 1)
	_add(objects, "ninja", 122, trail - 1)
	_add(objects, "chest", 124, trail - 1)
	CustomLevelStore.append_fence_run(objects, trail, 126, 1)
	_add_badge(objects, 127, trail)
	_add(objects, "goal", 128, trail - 1)
	data["objects"] = objects
	return data


static func _level_15() -> Dictionary:
	## Wing Chasm — wings wait at camp, so the whole trail can be flown from step one.
	var data := _base("Wing Chasm", 130, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = []
	for x in range(int(data["width"])):
		if (x >= 34 and x <= 41) or (x >= 84 and x <= 91):
			objects.append({"type": "canyon", "x": x, "y": trail})
		else:
			objects.append({"type": "ground", "x": x, "y": trail})
	# Wings sit two hops from the spawn post, before the first badge.
	_add(objects, "wings", 5, trail - 1)
	## Three lantern camps: before the first chasm, mid-trail, and with the late wings.
	_add_camps(objects, trail, [31, 54, 105])
	CustomLevelStore.append_fence_run(objects, trail, 8, 1)
	_add_badge(objects, 11, trail)
	# High badge line: walkers see it, only the flying cowboy collects it.
	_add(objects, "star", 14, 3)
	_add(objects, "star", 17, 2)
	_add(objects, "bat", 20, trail - 5)
	_add(objects, "acid_drip", 22, 0)
	_add_badge(objects, 24, trail)
	# Bow skeleton on the solid approach before the first chasm.
	_add(objects, "bandit", 27, trail - 1)
	_add(objects, "spring", 30, trail - 1)
	# First chasm: planks carry the walking route, open air rewards the flight.
	CustomLevelStore.append_platform_run(objects, trail, 34, 4, 2)
	_add(objects, "star", 37, 2)
	_add_badge(objects, 44, trail)
	_add(objects, "bat", 47, trail - 6)
	_add(objects, "star", 50, 3)
	# Fresh wings before the first pair runs dry.
	_add(objects, "wings", 57, trail - 1)
	_add(objects, "acid_drip", 60, 0)
	_add_badge(objects, 62, trail)
	CustomLevelStore.append_ladder_branch(objects, trail, 64)
	# Mid-trail bow skeleton between the ladder branch and the second chasm.
	_add(objects, "bandit", 68, trail - 1)
	_add(objects, "star", 71, 2)
	_add(objects, "bat", 74, trail - 5)
	_add(objects, "acid_drip", 76, 1)
	_add(objects, "spring", 80, trail - 1)
	CustomLevelStore.append_platform_run(objects, trail, 84, 4, 2)
	_add(objects, "star", 87, 3)
	_add_badge(objects, 94, trail)
	_add(objects, "ninja", 97, trail - 1)
	_add(objects, "star", 100, 2)
	# Last pair of wings for the run to the goal, plus a late lantern camp.
	_add(objects, "wings", 103, trail - 1)
	_add(objects, "acid_drip", 106, 0)
	_add_badge(objects, 108, trail)
	CustomLevelStore.append_conveyor_belt(objects, trail, 110, true)
	_add(objects, "bat", 114, trail - 6)
	# Crystal skeleton after the belt — one last ground threat before the chest.
	_add(objects, "bounty_bandit", 116, trail - 1)
	_add(objects, "star", 117, 2)
	_add(objects, "spring", 120, trail - 1)
	_add(objects, "chest", 122, trail - 1)
	CustomLevelStore.append_fence_run(objects, trail, 124, 1)
	_add_badge(objects, 126, trail, 3)
	_add(objects, "goal", 128, trail - 1)
	data["objects"] = objects
	return data


static func _level_16() -> Dictionary:
	## Dragon Gate — finale trail before the dragon boss.
	var data := _base("Dragon Gate", 140, 10)
	var trail: int = CustomLevelStore.trail_row(int(data["height"]))
	var objects: Array[Dictionary] = data["objects"]
	CustomLevelStore.append_fence_run(objects, trail, 4, 2)
	_add_badge(objects, 8, trail)
	_add_badge(objects, 10, trail)
	_add(objects, "cactus", 12, trail - 1)
	_add_badge(objects, 14, trail)
	_add(objects, "bat", 18, trail - 5)
	_add(objects, "acid_drip", 22, 0)
	_add_badge(objects, 24, trail)
	_add(objects, "spring", 26, trail - 1)
	CustomLevelStore.append_ladder_branch(objects, trail, 28)
	_add_badge(objects, 40, trail)
	_add(objects, "acid_drip", 44, 1)
	_add(objects, "spring", 46, trail - 1)
	CustomLevelStore.append_platform_run(objects, trail, 48, 3, 2)
	_add_badge(objects, 50, trail, 3)
	_add(objects, "bull", 56, trail - 1)
	_add_badge(objects, 58, trail)
	_add_camps(objects, trail, [18, 60, 86])
	CustomLevelStore.append_conveyor_belt(objects, trail, 66, true)
	_add(objects, "acid_drip", 74, 0)
	_add_badge(objects, 76, trail)
	CustomLevelStore.append_ladder_branch(objects, trail, 78)
	_add_badge(objects, 90, trail)
	_add(objects, "acid_drip", 92, 1)
	_add(objects, "spring", 94, trail - 1)
	CustomLevelStore.append_platform_run(objects, trail, 96, 3, 2)
	_add_badge(objects, 98, trail, 3)
	_add(objects, "ninja", 104, trail - 1)
	_add_badge(objects, 107, trail)
	_add(objects, "bandit", 110, trail - 1)
	_add(objects, "acid_drip", 114, 0)
	_add(objects, "rattlesnake", 116, trail - 1)
	_add_badge(objects, 119, trail)
	_add(objects, "chest", 122, trail - 1)
	_add(objects, "bat", 124, trail - 4)
	_add(objects, "spring", 128, trail - 1)
	_add_badge(objects, 130, trail, 3)
	CustomLevelStore.append_fence_run(objects, trail, 132, 1)
	_add(objects, "goal", 134, trail - 1)
	data["objects"] = objects
	return data
