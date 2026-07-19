class_name WindZone
extends Area2D

signal first_touch

@export var wind_force: Vector2 = Vector2(180, 0)

var _gusts: Array[ColorRect] = []
var _phase: float = 0.0
var _touched: bool = false
var _label: Label


func _ready() -> void:
	_label = get_node_or_null("Label") as Label
	for child in get_children():
		if child is ColorRect and String(child.name).begins_with("Gust"):
			_gusts.append(child as ColorRect)
	if _label != null:
		_label.text = "WIND >>>" if wind_force.x >= 0.0 else "<<< WIND"
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_phase += delta * 2.8
	var direction := 1.0 if wind_force.x >= 0.0 else -1.0
	for i in range(_gusts.size()):
		var gust := _gusts[i]
		gust.position.x = -70.0 + fmod((_phase * 40.0 * direction) + float(i) * 55.0, 140.0)
		gust.modulate.a = 0.35 + absf(sin(_phase + float(i))) * 0.45


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			(body as Player).external_velocity += wind_force * get_physics_process_delta_time()


func _on_body_entered(body: Node2D) -> void:
	if _touched or not (body is Player):
		return
	_touched = true
	first_touch.emit()
