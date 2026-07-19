class_name ConveyorBelt
extends StaticBody2D

@export var push_speed: float = 95.0
@export var push_right: bool = true

var _area: Area2D
var _stripes: Array[ColorRect] = []
var _scroll: float = 0.0


func _ready() -> void:
	_area = get_node_or_null("PushArea") as Area2D
	_ensure_stripes()
	var arrow := get_node_or_null("Arrow") as Label
	if arrow != null:
		arrow.text = ">>>" if push_right else "<<<"


func _process(delta: float) -> void:
	var direction := 1.0 if push_right else -1.0
	_scroll = fmod(_scroll + delta * 70.0 * direction, 40.0)
	for i in range(_stripes.size()):
		var stripe := _stripes[i]
		var base := -70.0 + float(i) * 40.0
		stripe.position.x = base + _scroll


func _physics_process(_delta: float) -> void:
	if _area == null:
		return
	var direction := 1.0 if push_right else -1.0
	for body in _area.get_overlapping_bodies():
		if body is Player:
			(body as Player).external_velocity.x += push_speed * direction


func _ensure_stripes() -> void:
	for child in get_children():
		if child is ColorRect and String(child.name).begins_with("Stripe"):
			_stripes.append(child as ColorRect)
	if not _stripes.is_empty():
		return
	for i in range(4):
		var stripe := ColorRect.new()
		stripe.name = "Stripe%d" % i
		stripe.size = Vector2(14, 20)
		stripe.position = Vector2(-70.0 + float(i) * 40.0, -10.0)
		stripe.color = Color(0.95, 0.8, 0.35, 0.9)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(stripe)
		_stripes.append(stripe)
