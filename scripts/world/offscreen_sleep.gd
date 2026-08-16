extends VisibleOnScreenNotifier2D

## Sleeps the parent when it is far off-camera. Headless tests without a Camera2D
## keep simulating so patrol / ambush checks still run.

const SCRIPT := preload("res://scripts/world/offscreen_sleep.gd")
const DEFAULT_MARGIN := Vector2(1200, 800)

var keep_physics: bool = false
var _sleeping := false
var _process_was := true
var _physics_was := true


static func install(
	host: Node2D,
	margin: Vector2 = DEFAULT_MARGIN,
	keep_physics_when_hidden: bool = false
) -> void:
	if host == null or host.get_node_or_null("OffscreenSleep") != null:
		return
	var node := SCRIPT.new()
	node.name = "OffscreenSleep"
	node.keep_physics = keep_physics_when_hidden
	node.rect = Rect2(-margin.x, -margin.y, margin.x * 2.0, margin.y * 2.0)
	host.add_child(node)


func _ready() -> void:
	screen_entered.connect(_on_screen_entered)
	screen_exited.connect(_on_screen_exited)


func _on_screen_entered() -> void:
	_wake()


func _on_screen_exited() -> void:
	var host := get_parent()
	if host == null:
		return
	var viewport := host.get_viewport()
	if viewport == null or viewport.get_camera_2d() == null:
		return
	_sleep()


func _sleep() -> void:
	var host := get_parent()
	if host == null or _sleeping:
		return
	_process_was = host.is_processing()
	_physics_was = host.is_physics_processing()
	_sleeping = true
	host.set_process(false)
	if not keep_physics:
		host.set_physics_process(false)


func _wake() -> void:
	var host := get_parent()
	if host == null or not _sleeping:
		return
	_sleeping = false
	host.set_process(_process_was)
	host.set_physics_process(_physics_was)
