extends BossArena

## Cave Dragon: fly left↔right below the ceiling spitting flameballs, then land for a lasso.
## After each lasso the dragon takes off again. Third lasso ties the mouth — win.

const DRAGON_TEX := [
	preload("res://assets/world/boss_cave_dragon_0.png"),
	preload("res://assets/world/boss_cave_dragon_1.png"),
	preload("res://assets/world/boss_cave_dragon_2.png"),
	preload("res://assets/world/boss_cave_dragon_3.png"),
]
const FLY_TEX := [
	preload("res://assets/world/boss_cave_dragon_fly_0.png"),
	preload("res://assets/world/boss_cave_dragon_fly_1.png"),
]
const LAND_TEX := preload("res://assets/world/boss_cave_dragon_land.png")

## Art faces left. flip_h=false → face left; flip_h=true → face right.
const ART_FACES_LEFT := true
const SPRITE_SCALE := 0.85 * 1.15
const FLY_Y := 140.0
const FLOOR_Y := 320.0
const PATROL_LEFT := 280.0
const PATROL_RIGHT := 1320.0
const FLY_SPEED := 210.0
const LANDING_TIME := 0.85
const TAKEOFF_TIME := 0.7

enum State { FLY, LANDING, LAND, TAKEOFF, WIN }

@export var lassos_needed: int = 3
@export var spit_rounds: int = 3
@export var spits_per_round: int = 3

var _dragon: AnimatableBody2D
var _sprite: Sprite2D
var _label: Label
var _lasso: BossLassoTarget
var _hurt: Area2D
var _lassos: int = 0
var _state: State = State.FLY
var _fly_phase: float = 0.0
var _flap_timer: float = 0.0
var _flap_frame: int = 0
var _fly_dir: float = -1.0
var _round_index: int = 0
var _spit_index: int = 0
var _spit_timer: float = 0.0
var _land_timer: float = 0.0
var _transition: float = 0.0
var _transition_from: Vector2 = Vector2.ZERO
var _origin: Vector2 = Vector2(980, 220)
var _floor_y: float = FLOOR_Y


func _ready() -> void:
	source_level = 15
	boss_title = tr("Cave Dragon — dodge flameballs, then lasso him three times!")
	set_meta("level_style", LevelStyle.CAVE)
	super._ready()
	_dragon = $Dragon as AnimatableBody2D
	_sprite = $Dragon/Sprite2D as Sprite2D
	_label = $Dragon/Label as Label
	_lasso = $Dragon/LassoTarget as BossLassoTarget
	_hurt = $Dragon/HurtArea as Area2D
	if _dragon != null:
		_origin = _dragon.position
		_floor_y = FLOOR_Y
	if _sprite != null:
		_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_apply_stage_visual()
	if _lasso != null:
		_lasso.set_lasso_active(false)
		_lasso.lassoed.connect(_on_dragon_lassoed)
	if _hurt != null:
		_hurt.body_entered.connect(_on_hurt_body)
	combat_started.connect(_on_combat_started)


func _on_combat_started() -> void:
	if _won:
		return
	_begin_fly_phase()


func get_heart_drop_position() -> Vector2:
	return Vector2(520, 180)


func _physics_process(delta: float) -> void:
	if _won or _dragon == null or not combat_ready:
		return
	match _state:
		State.FLY:
			_update_fly(delta)
		State.LANDING:
			_update_landing(delta)
		State.LAND:
			_update_land(delta)
		State.TAKEOFF:
			_update_takeoff(delta)
		State.WIN:
			pass


func _begin_fly_phase() -> void:
	_state = State.FLY
	_round_index = 0
	_spit_index = 0
	_spit_timer = 0.55
	_fly_phase = 0.0
	_flap_timer = 0.0
	_flap_frame = 0
	_fly_dir = -1.0
	if _dragon != null and _dragon.position.x < (PATROL_LEFT + PATROL_RIGHT) * 0.5:
		_fly_dir = 1.0
	if _lasso != null:
		_lasso.set_lasso_active(false)
	if _label != null:
		_label.text = "DODGE!"
		_label.modulate = Color(1.0, 0.45, 0.15, 1.0)
	_set_fly_pose()
	_face_flight_direction()
	report_progress(tr("Dodge the flameballs!"))


func _begin_landing() -> void:
	_state = State.LANDING
	_transition = 0.0
	_transition_from = _dragon.position
	if _lasso != null:
		_lasso.set_lasso_active(false)
	if _sprite != null:
		_sprite.texture = LAND_TEX
		_sprite.rotation = 0.12 * _fly_dir
	if _label != null:
		_label.text = "LANDING!"


func _begin_land_phase() -> void:
	_state = State.LAND
	_land_timer = 0.0
	_dragon.position = Vector2(_clamp_land_x(_dragon.position.x), _floor_y)
	_apply_stage_visual()
	_face_toward_player()
	if _sprite != null:
		_sprite.position.y = -90.0
		_sprite.rotation = 0.0
	if _lasso != null:
		_lasso.set_lasso_active(true)
	if _label != null:
		_label.text = "LASSO!"
		_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	report_progress(tr("Lasso the dragon! (%d / %d)") % [_lassos, lassos_needed])


func _begin_takeoff() -> void:
	_state = State.TAKEOFF
	_transition = 0.0
	_transition_from = _dragon.position
	if _lasso != null:
		_lasso.set_lasso_active(false)
	_set_fly_pose()
	_face_flight_direction()
	if _label != null:
		_label.text = "TAKE OFF!"


func _update_fly(delta: float) -> void:
	_fly_phase += delta
	_flap_timer += delta
	if _flap_timer >= 0.18:
		_flap_timer = 0.0
		_flap_frame = 1 - _flap_frame
		_set_fly_pose()

	var next_x := _dragon.position.x + _fly_dir * FLY_SPEED * delta
	if next_x <= PATROL_LEFT:
		next_x = PATROL_LEFT
		_fly_dir = 1.0
		_face_flight_direction()
	elif next_x >= PATROL_RIGHT:
		next_x = PATROL_RIGHT
		_fly_dir = -1.0
		_face_flight_direction()

	var bob := sin(_fly_phase * 3.4) * 16.0
	_dragon.position = Vector2(next_x, FLY_Y + bob)
	if _sprite != null:
		_sprite.position.y = -70.0 + sin(_fly_phase * 5.0) * 3.0
		_sprite.rotation = _fly_dir * 0.06 + sin(_fly_phase * 2.2) * 0.04

	_spit_timer -= delta
	if _spit_timer > 0.0:
		return
	_spit_flameball()
	_spit_index += 1
	if _spit_index >= spits_per_round:
		_spit_index = 0
		_round_index += 1
		_spit_timer = 0.85
		if _round_index >= spit_rounds:
			_begin_landing()
		elif _label != null:
			_label.text = "ROUND %d" % (_round_index + 1)
	else:
		_spit_timer = 0.42


func _update_landing(delta: float) -> void:
	_transition += delta
	var t := clampf(_transition / LANDING_TIME, 0.0, 1.0)
	var ease := t * t * (3.0 - 2.0 * t)
	var target := Vector2(_clamp_land_x(_transition_from.x), _floor_y)
	_dragon.position = _transition_from.lerp(target, ease)
	if _sprite != null:
		_sprite.position.y = lerpf(-70.0, -90.0, ease)
		_sprite.rotation = lerpf(_fly_dir * 0.12, 0.0, ease)
		_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE * lerpf(1.0, 0.92, sin(ease * PI)))
	if t >= 1.0:
		if _sprite != null:
			_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		_begin_land_phase()


func _update_land(delta: float) -> void:
	_land_timer += delta
	if _sprite != null:
		_sprite.position.y = -90.0 + sin(_land_timer * 6.0) * 2.0
	_face_toward_player()
	# Soft timeout: if kids miss the lasso, resume flying.
	if _land_timer >= 7.5:
		_begin_takeoff()


func _update_takeoff(delta: float) -> void:
	_transition += delta
	_flap_timer += delta
	if _flap_timer >= 0.14:
		_flap_timer = 0.0
		_flap_frame = 1 - _flap_frame
		_set_fly_pose()
	var t := clampf(_transition / TAKEOFF_TIME, 0.0, 1.0)
	var ease := t * t
	var target := Vector2(_transition_from.x, FLY_Y)
	_dragon.position = _transition_from.lerp(target, ease)
	if _sprite != null:
		_sprite.position.y = lerpf(-90.0, -70.0, ease)
		_sprite.rotation = _fly_dir * lerpf(0.0, 0.08, ease)
	if t >= 1.0:
		_begin_fly_phase()


func _spit_flameball() -> void:
	if player == null:
		return
	var ball := DragonFlameball.new()
	ball.name = "DragonFlameball"
	var mouth := _mouth_global()
	var aim := player.global_position + Vector2(0, -24.0)
	ball.setup(mouth, aim, player)
	ball.hurt_player.connect(_on_flame_hurt)
	add_child(ball)
	ball.global_position = mouth


func _mouth_global() -> Vector2:
	# Mouth sits toward the facing direction.
	var face := _facing_sign()
	return _dragon.global_position + Vector2(face * 78.0, -78.0)


func _facing_sign() -> float:
	if _sprite == null:
		return -1.0
	# Art faces left; flipped means facing right.
	return 1.0 if _sprite.flip_h == ART_FACES_LEFT else -1.0


func _face_flight_direction() -> void:
	if _sprite == null:
		return
	# Face the way we are flying.
	_sprite.flip_h = (_fly_dir > 0.0) == ART_FACES_LEFT


func _face_toward_player() -> void:
	if _sprite == null or player == null:
		return
	var toward_right := player.global_position.x >= _dragon.global_position.x
	_sprite.flip_h = toward_right == ART_FACES_LEFT


func _clamp_land_x(x: float) -> float:
	return clampf(x, PATROL_LEFT + 40.0, PATROL_RIGHT - 40.0)


func _set_fly_pose() -> void:
	if _sprite == null:
		return
	# While ropes are on, keep stage texture but still bob as if flapping.
	if _lassos > 0:
		_sprite.texture = DRAGON_TEX[clampi(_lassos, 0, DRAGON_TEX.size() - 1)]
	else:
		_sprite.texture = FLY_TEX[clampi(_flap_frame, 0, FLY_TEX.size() - 1)]
	_sprite.centered = true


func _on_flame_hurt(_player: Player) -> void:
	if _won or not combat_ready:
		return
	fail_soft()


func _on_hurt_body(body: Node2D) -> void:
	if _won or not combat_ready:
		return
	if body is Player and _state == State.LAND:
		# Side bump while landed hurts; stomp is ignored (nonviolent lasso focus).
		var p := body as Player
		if p.global_position.y < _dragon.global_position.y - 40.0 and p.velocity.y > 80.0:
			p.velocity.y = -420.0
			return
		fail_soft()


func _on_dragon_lassoed() -> void:
	if _won or _state != State.LAND:
		return
	_lassos += 1
	_apply_stage_visual()
	if _lasso != null:
		_lasso.set_lasso_active(false)
	if _lassos >= lassos_needed:
		_finish_capture()
		return
	if _label != null:
		_label.text = "TIED %d!" % _lassos
	report_progress(tr("Nice lasso! (%d / %d) — here he comes again!") % [_lassos, lassos_needed])
	await get_tree().create_timer(0.9).timeout
	if _won:
		return
	_begin_takeoff()


func _apply_stage_visual() -> void:
	if _sprite == null:
		return
	var stage := clampi(_lassos, 0, DRAGON_TEX.size() - 1)
	_sprite.texture = DRAGON_TEX[stage]
	_sprite.centered = true
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_face_toward_player()


func _finish_capture() -> void:
	_state = State.WIN
	_apply_stage_visual()
	if _label != null:
		_label.text = "MOUTH TIED!"
		_label.modulate = Color(0.55, 0.85, 0.35, 1.0)
	report_progress(tr("Dragon's mouth is tied — you win!"))
	if _dragon != null:
		var tween := create_tween()
		tween.tween_property(_dragon, "position:y", _floor_y + 8.0, 0.35)
		if _sprite != null:
			tween.parallel().tween_property(_sprite, "rotation", 0.12, 0.35)
	await get_tree().create_timer(1.5).timeout
	await win_boss()
