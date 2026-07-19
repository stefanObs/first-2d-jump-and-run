class_name WildWestTheme
extends RefCounted

## Applies a cheerful wild-west look to level and menu visuals.


static func desert_sky_color() -> Color:
	return Color(0.98, 0.72, 0.42, 1.0)


static func sand_color() -> Color:
	return Color(0.86, 0.68, 0.38, 1.0)


static func wood_color() -> Color:
	return Color(0.62, 0.4, 0.22, 1.0)


static func apply_to_level(level: Node) -> void:
	var background := level.get_node_or_null("Background") as ColorRect
	if background != null:
		background.color = desert_sky_color()
	for node in level.find_children("*", "ColorRect", true, false):
		var rect := node as ColorRect
		var parent_name := str(rect.get_parent().name)
		if parent_name.begins_with("Ground") or parent_name == "Ground":
			rect.color = sand_color()
		elif parent_name.begins_with("Platform") or parent_name.begins_with("StarPlatform") or parent_name.begins_with("High"):
			rect.color = wood_color()
		elif parent_name.begins_with("Gap") or parent_name.begins_with("Cloud"):
			rect.color = Color(0.95, 0.88, 0.7, 1.0)
