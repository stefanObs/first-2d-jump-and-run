class_name WindZone
extends Area2D

signal first_touch

## Sideways gust. The X sign sets the push direction and the magnitude is the
## sideways acceleration in px/s^2 applied while the cowboy is inside.
## Opposing movement gets a reduced push so the cowboy always retains control.
## The Y component is a gentle upward acceleration that only helps while airborne.
@export var wind_force: Vector2 = Vector2(2100, -560)

## Hard cap (px/s) on how fast the wind alone can push the cowboy sideways, so it
## can never keep accelerating forever. Player input can still push past this.
@export var max_wind_speed: float = 45.0

## Hard cap (px/s) on the upward drift the wind can add mid-jump. Keeps the gust
## helping long jumps without launching the cowboy off the screen.
@export var max_wind_lift: float = 140.0

var _gusts: Array[Node2D] = []
var _phase: float = 0.0
var _touched: bool = false
var _label: Label


func _ready() -> void:
	monitoring = true
	monitorable = false
	_label = get_node_or_null("Label") as Label
	if _label != null:
		_label.visible = false
	for child in get_children():
		if child is Node2D and String(child.name).begins_with("Gust"):
			_gusts.append(child as Node2D)
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
		gust.scale.x = absf(gust.scale.y) * direction


func _physics_process(delta: float) -> void:
	# Apply the gust as a gentle, speed-capped acceleration each physics tick
	# while overlapping. Leaving the area stops the push immediately, and the
	# cowboy's own friction decays the drift.
	for body in get_overlapping_bodies():
		if body is Player:
			_apply_wind(body as Player, delta)


func _apply_wind(player: Player, delta: float) -> void:
	# Sideways push: ramp up slowly and never drive the wind-direction speed past
	# max_wind_speed, so it stays controllable and can't runaway-accelerate.
	var dir_x := signf(wind_force.x)
	if dir_x != 0.0:
		var speed_with_wind := player.velocity.x * dir_x
		if speed_with_wind < max_wind_speed:
			var step := absf(wind_force.x) * delta
			# Full gust strength beats idle friction and settles at the cap, but
			# a cowboy already moving against it must keep making headway.
			if speed_with_wind < 0.0:
				step = minf(step, player.acceleration * delta * 0.75)
			step = minf(step, max_wind_speed - speed_with_wind)
			player.external_velocity.x += dir_x * step

	# Upward lift: only while airborne (no ground jitter) and capped so it just
	# floats long jumps a touch.
	if wind_force.y != 0.0 and not player.is_on_floor():
		var dir_y := signf(wind_force.y)
		var lift_with_wind := player.velocity.y * dir_y
		if lift_with_wind < max_wind_lift:
			var step_y := absf(wind_force.y) * delta
			step_y = minf(step_y, max_wind_lift - lift_with_wind)
			player.external_velocity.y += dir_y * step_y


func _on_body_entered(body: Node2D) -> void:
	if _touched or not (body is Player):
		return
	_touched = true
	first_touch.emit()
