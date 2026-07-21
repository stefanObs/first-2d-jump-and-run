extends Node

## F1 toggles clear debug names above meaningful gameplay elements.
## Off by default so normal play never shows these labels.

const LABEL_NODE_NAME := &"DebugNameLabel"
const STATUS_LAYER := 120
const REFRESH_INTERVAL := 0.35
const LABEL_OFFSET := Vector2(0.0, -70.0)

var enabled: bool = false

var _status_layer: CanvasLayer
var _status_label: Label
var _refresh_left: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_status_ui()
	set_enabled(false)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"toggle_debug_names"):
		return
	set_enabled(not enabled)
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not enabled:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_INTERVAL
		_sync_labels()


func is_enabled() -> bool:
	return enabled


func set_enabled(value: bool) -> void:
	enabled = value
	_ensure_status_ui()
	if _status_label != null:
		_status_label.visible = enabled
		if enabled:
			_status_label.text = "DEBUG NAMES (F1)"
	if enabled:
		_refresh_left = 0.0
		_sync_labels()
	else:
		_clear_all_labels()


func refresh_now() -> void:
	if enabled:
		_sync_labels()
	else:
		_clear_all_labels()


func _ensure_status_ui() -> void:
	if _status_layer != null and is_instance_valid(_status_layer):
		return
	_status_layer = CanvasLayer.new()
	_status_layer.name = "DebugNamesStatus"
	_status_layer.layer = STATUS_LAYER
	_status_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_status_layer)
	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.position = Vector2(16, 160)
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.25, 1.0))
	_status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	_status_label.add_theme_constant_override("shadow_offset_x", 2)
	_status_label.add_theme_constant_override("shadow_offset_y", 2)
	_status_label.visible = false
	_status_layer.add_child(_status_label)


func _on_node_added(node: Node) -> void:
	if not enabled or node == null:
		return
	if node.name == LABEL_NODE_NAME:
		return
	if _is_meaningful(node):
		_ensure_label_for(node as Node2D)


func _sync_labels() -> void:
	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	_discover(root)


func _discover(node: Node) -> void:
	if node == null:
		return
	if _is_meaningful(node):
		_ensure_label_for(node as Node2D)
	for child in node.get_children():
		_discover(child)


func _ensure_label_for(target: Node2D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var existing := target.get_node_or_null(NodePath(String(LABEL_NODE_NAME))) as Label
	if existing != null:
		existing.text = String(target.name)
		existing.visible = true
		return
	var label := Label.new()
	label.name = String(LABEL_NODE_NAME)
	label.text = String(target.name)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 64
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.35, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.05, 1.0))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 14)
	label.size = Vector2(160.0, 22.0)
	label.position = LABEL_OFFSET + Vector2(-80.0, 0.0)
	target.add_child(label)


func _clear_all_labels() -> void:
	_remove_labels_under(get_tree().root)


func _remove_labels_under(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var children: Array = node.get_children()
	for i in range(children.size() - 1, -1, -1):
		_remove_labels_under(children[i])
	if node.name == LABEL_NODE_NAME and node is Label:
		node.free()


func _is_meaningful(node: Node) -> bool:
	if node == null or not (node is Node2D):
		return false
	if node is Camera2D or node is Label:
		return false
	if node.name == LABEL_NODE_NAME:
		return false
	if node is LevelController or node is BossArena:
		return false
	if _is_under_canvas_layer(node):
		return false

	var node_name := String(node.name)
	if _is_helper_name(node_name):
		return false

	if _is_nested_helper(node):
		return false

	if _is_scripted_gameplay(node):
		return true

	if node is Marker2D and node_name.begins_with("Spawn"):
		return true

	var script: Script = node.get_script()
	if script != null:
		var script_path := String(script.resource_path)
		if script_path.contains("/bosses/"):
			return true

	if node is StaticBody2D or node is AnimatableBody2D or node is CharacterBody2D:
		return true

	return false


func _is_scripted_gameplay(node: Node) -> bool:
	return (
		node is Player
		or node is Opponent
		or node is Rattlesnake
		or node is Carrion
		or node is Hazard
		or node is Star
		or node is ModeItem
		or node is Checkpoint
		or node is Goal
		or node is TimedDoor
		or node is WindZone
		or node is SpringPad
		or node is MovingPlatform
		or node is DisappearingPlatform
		or node is ConveyorBelt
		or node is BanditBullet
		or node is BossLassoTarget
		or node is CoachLantern
		or node is CoachDustCloud
		or node is ScalableCanyonArt
	)


func _is_nested_helper(node: Node) -> bool:
	## Skip internal children of already-meaningful gameplay roots, except projectiles/boss parts.
	if (
		node is BanditBullet
		or node is BossLassoTarget
		or node is CoachLantern
		or node is CoachDustCloud
	):
		return false
	var current := node.get_parent()
	while current != null:
		if current is LevelController or current is BossArena:
			return false
		if _is_scripted_gameplay(current):
			return true
		current = current.get_parent()
	return false


func _is_under_canvas_layer(node: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current is CanvasLayer:
			return true
		current = current.get_parent()
	return false


func _is_helper_name(node_name: String) -> bool:
	var lowered := node_name.to_lower()
	var helpers: PackedStringArray = [
		"visual",
		"topstripe",
		"collisionshape2d",
		"collisionpolygon2d",
		"sprite2d",
		"animatedsprite2d",
		"walksprite",
		"mountedsprite",
		"wingsprite",
		"shieldbubble",
		"hurtarea",
		"hitarea",
		"hitbox",
		"label",
		"pitlabel",
		"approachearrow",
		"approacharrow",
		"colorrect",
		"polygon2d",
		"line2d",
		"audiostreamplayer",
		"audiostreamplayer2d",
		"timer",
		"animationplayer",
		"cpuparticles2d",
		"gpuparticles2d",
		"particles",
		"shadow",
		"outline",
		"debugnamelabel",
		"tiedoverlay",
		"revolver",
		"lassocast",
		"rope",
		"background",
		"skyband",
		"sun",
		"hintlabel",
	]
	if lowered in helpers:
		return true
	if lowered.begins_with("mesa") or lowered.begins_with("fence"):
		return true
	if lowered.begins_with("collision"):
		return true
	return false
