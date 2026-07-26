class_name TreasureChestLoot
extends RefCounted

## Random loot rolled when a treasure chest opens.

enum Type { WINGS, MAGIC_BOOTS, SPEED_STAR, BUBBLE_SHIELD, BADGE }

const POOL: Array[Type] = [
	Type.WINGS,
	Type.MAGIC_BOOTS,
	Type.SPEED_STAR,
	Type.BUBBLE_SHIELD,
	Type.BADGE,
]

const TEX_WINGS := preload("res://assets/world/chest_loot/wings_reveal.png")
const TEX_BOOTS := preload("res://assets/world/chest_loot/boots_reveal.png")
const TEX_SPEED := preload("res://assets/world/chest_loot/speed_reveal.png")
const TEX_SHIELD := preload("res://assets/world/chest_loot/shield_reveal.png")
const TEX_BADGE := preload("res://assets/world/chest_loot/badge_reveal.png")


static func pick_random() -> Type:
	return POOL[randi() % POOL.size()]


static func to_mode(loot: Type) -> ModeController.Mode:
	match loot:
		Type.WINGS:
			return ModeController.Mode.WINGS
		Type.MAGIC_BOOTS:
			return ModeController.Mode.MAGIC_BOOTS
		Type.SPEED_STAR:
			return ModeController.Mode.SPEED_STAR
		Type.BUBBLE_SHIELD:
			return ModeController.Mode.BUBBLE_SHIELD
		_:
			return ModeController.Mode.NONE


static func is_badge(loot: Type) -> bool:
	return loot == Type.BADGE


static func open_storage_key(chest_name: String) -> String:
	return "ChestOpen_%s" % chest_name


static func badge_storage_key(chest_name: String) -> String:
	return "ChestBadge_%s" % chest_name


static func texture_for(loot: Type) -> Texture2D:
	match loot:
		Type.WINGS:
			return TEX_WINGS
		Type.MAGIC_BOOTS:
			return TEX_BOOTS
		Type.SPEED_STAR:
			return TEX_SPEED
		Type.BUBBLE_SHIELD:
			return TEX_SHIELD
		Type.BADGE:
			return TEX_BADGE
		_:
			return TEX_WINGS


static func toast_key(loot: Type) -> String:
	match loot:
		Type.WINGS:
			return "Treasure chest! Fly high! Hold Jump to rise!"
		Type.MAGIC_BOOTS:
			return "Treasure chest! Super jump! Leap farther!"
		Type.SPEED_STAR:
			return "Treasure chest! Zoom! Run like the wind!"
		Type.BUBBLE_SHIELD:
			return "Treasure chest! Safe bubble! Bounce off cacti!"
		Type.BADGE:
			return "Treasure chest! +1 badge!"
		_:
			return "Treasure chest opened!"


static func loot_name(loot: Type) -> String:
	match loot:
		Type.WINGS:
			return "Wings"
		Type.MAGIC_BOOTS:
			return "Magic Boots"
		Type.SPEED_STAR:
			return "Speed Star"
		Type.BUBBLE_SHIELD:
			return "Bubble Shield"
		Type.BADGE:
			return "Badge"
		_:
			return "Unknown"
