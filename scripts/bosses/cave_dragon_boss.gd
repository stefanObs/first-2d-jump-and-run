extends BossArena

## Cave Dragon: fly and spit 3 flameball rounds, then land for a lasso.
## After each lasso the dragon flies again. Third lasso ties the mouth — win.

const DRAGON_TEX := [
	preload("res://assets/world/boss_cave_dragon_0.png"),
	preload("res://assets/world/boss_cave_dragon_1.png"),
	preload("res://assets/world/boss_cave_dragon_2.png"),
	preload("res://assets/world/boss_cave_dragon_3.png"),
]

enum State { FLY, LAND, WIN }

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
var _round_index: int = 0
var _spit_index: int = 0
var _spit_timer: float = 0.0
var _land_timer: float = 0.0
var _origin: Vector2 = Vector2(980, 220)
var _floor_y: float = 320.0


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
		_floor_y = 320.0
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
		State.LAND:
			_update_land(delta)
		State.WIN:
			pass


func _begin_fly_phase() -> void:
	_state = State.FLY
	_round_index = 0
	_spit_index = 0
	_spit_timer = 0.55
	_fly_phase = 0.0
	if _lasso != null:
		_lasso.set_lasso_active(false)
	if _label != null:
		_label.text = "DODGE!"
		_label.modulate = Color(1.0, 0.45, 0.15, 1.0)
	report_progress(tr("Dodge the flameballs!"))


func _begin_land_phase() -> void:
	_state = State.LAND
	_land_timer = 0.0
	_dragon.position = Vector2(_origin.x, _floor_y)
	if _sprite != null:
		_sprite.position.y = -90.0
		_sprite.rotation = 0.0
	if _lasso != null:
		_lasso.set_lasso_active(true)
	if _label != null:
		_label.text = "LASSO!"
		_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	report_progress(tr("Lasso the dragon! (%d / %d)") % [_lassos, lassos_needed])


func _update_fly(delta: float) -> void:
	_fly_phase += delta
	var bob := sin(_fly_phase * 2.2) * 28.0
	var drift := sin(_fly_phase * 0.7) * 70.0
	_dragon.position = Vector2(_origin.x + drift, 170.0 + bob)
	if _sprite != null:
		_sprite.position.y = -70.0 + sin(_fly_phase * 5.0) * 4.0
		_sprite.rotation = sin(_fly_phase * 1.4) * 0.08
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
			_begin_land_phase()
		elif _label != null:
			_label.text = "ROUND %d" % (_round_index + 1)
	else:
		_spit_timer = 0.42


func _update_land(delta: float) -> void:
	_land_timer += delta
	if _sprite != null:
		_sprite.position.y = -90.0 + sin(_land_timer * 6.0) * 2.0
	# Soft timeout: if kids miss the lasso, resume flying.
	if _land_timer >= 7.5:
		_begin_fly_phase()


func _spit_flameball() -> void:
	if player == null:
		return
	var ball := DragonFlameball.new()
	ball.name = "DragonFlameball"
	var mouth := _dragon.global_position + Vector2(-70.0, -70.0)
	var aim := player.global_position + Vector2(0, -20.0)
	# Slight fan so consecutive shots are dodgeable.
	aim.x += float(_spit_index - 1) * 40.0
	ball.setup(mouth, aim)
	ball.hurt_player.connect(_on_flame_hurt)
	add_child(ball)
	ball.global_position = mouth


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
	_begin_fly_phase()


func _apply_stage_visual() -> void:
	if _sprite == null:
		return
	var stage := clampi(_lassos, 0, DRAGON_TEX.size() - 1)
	_sprite.texture = DRAGON_TEX[stage]
	_sprite.centered = true
	_sprite.flip_h = true  # art faces left; flip to face the cowboy on the left


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
