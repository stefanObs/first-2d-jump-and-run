extends BossArena

## Stampede Bull: bounce clear of horns, lasso the back ring while stunned.

const BULL_TEX := preload("res://assets/world/boss_stampede_bull.png")
const BULL_TIED_TEX := preload("res://assets/world/boss_stampede_bull_tied_legs.png")
const BULL_DOWN_TEX := preload("res://assets/world/boss_stampede_bull_down.png")
## Keep the bull body clear of the solid arena walls.
const WALL_CLEAR := 90.0
const BULL_FOOT_Y := -78.0
const TIED_SPRITE_HEIGHT := 190.0
const DOWN_SPRITE_HEIGHT := 118.0

enum State { CHARGE, STUN, HIT }

@export var hits_needed: int = 3
@export var charge_speed: float = 300.0

var _bull: AnimatableBody2D
var _ring: BossLassoTarget
var _sprite: Sprite2D
var _label: Label
var _stars: Node2D
var _hits: int = 0
var _dir: float = -1.0
var _state: State = State.CHARGE
var _left_x: float = 460.0
var _right_x: float = 1140.0
var _charge_bob: float = 0.0
var _stun_token: int = 0
var _charge_grace: float = 0.0


func _ready() -> void:
	source_level = 3
	boss_title = "Stampede Bull — bounce, then lasso the ring while stunned!"
	super._ready()
	_bull = $Bull as AnimatableBody2D
	_sprite = $Bull/Sprite2D as Sprite2D
	_label = $Bull/Label as Label
	_ring = $Bull/LassoRing as BossLassoTarget
	_stars = $Bull/StunStars as Node2D
	if _sprite != null:
		_sprite.texture = BULL_TEX
	if _ring != null:
		_ring.set_lasso_active(false)
		_ring.lassoed.connect(_on_ring_lasso)
	if _stars != null:
		_stars.visible = false
	var hurt := $Bull/HurtArea as Area2D
	if hurt != null:
		hurt.body_entered.connect(_on_bull_body)
	# Start beside the right wall, facing the cowboy for the opening charge.
	_place_at_right_wall()
	_aim_at_player()
	combat_started.connect(_on_combat_started)


func _on_combat_started() -> void:
	if _won or _bull == null:
		return
	_place_at_right_wall()
	_aim_at_player()
	_state = State.CHARGE
	_charge_grace = 0.35


func _place_at_right_wall() -> void:
	if _bull == null:
		return
	_bull.position.x = _right_x - WALL_CLEAR
	_bull.position.y = 320.0


func get_heart_drop_position() -> Vector2:
	var mid_x := (_left_x + _right_x) * 0.5
	var drop_y := 200.0
	if _bull != null:
		drop_y = _bull.global_position.y - 170.0
	return Vector2(mid_x, drop_y)


func _physics_process(delta: float) -> void:
	if _won or _bull == null or not combat_ready:
		return
	if _charge_grace > 0.0:
		_charge_grace = maxf(_charge_grace - delta, 0.0)
	match _state:
		State.CHARGE:
			_charge_bob += delta * 14.0
			_bull.position.x += _dir * charge_speed * delta
			if _sprite != null:
				_sprite.position.y = BULL_FOOT_Y + sin(_charge_bob) * 4.0
				_sprite.rotation = sin(_charge_bob * 0.5) * 0.04 * _dir
			_apply_facing()
			if _charge_grace > 0.0:
				_bull.position.x = clampf(
					_bull.position.x,
					_left_x + WALL_CLEAR * 0.35,
					_right_x - WALL_CLEAR * 0.35
				)
			elif _bull.position.x >= _right_x:
				_bull.position.x = _right_x
				_begin_stun()
			elif _bull.position.x <= _left_x:
				_bull.position.x = _left_x
				_begin_stun()
		State.STUN:
			_animate_stun_idle(delta)
		State.HIT:
			pass


func _apply_facing() -> void:
	if _sprite != null:
		_sprite.flip_h = _dir < 0.0
	if _ring != null:
		_ring.position.x = 24.0 if _dir < 0.0 else -24.0


func _pull_clear_of_walls() -> void:
	if _bull == null:
		return
	_bull.position.x = clampf(
		_bull.position.x,
		_left_x + WALL_CLEAR,
		_right_x - WALL_CLEAR
	)


func _aim_at_player() -> void:
	if player == null or _bull == null:
		return
	_dir = 1.0 if player.global_position.x >= _bull.global_position.x else -1.0
	# Never charge back into the wall we are pressed against.
	if _bull.position.x >= _right_x - WALL_CLEAR and _dir > 0.0:
		_dir = -1.0
	elif _bull.position.x <= _left_x + WALL_CLEAR and _dir < 0.0:
		_dir = 1.0
	_apply_facing()


func _begin_stun() -> void:
	if _state != State.CHARGE:
		return
	_state = State.STUN
	_stun_token += 1
	var token := _stun_token
	# Step out of the wall first so the bull is not stuck inside it.
	_pull_clear_of_walls()
	_aim_at_player()
	if _ring != null:
		_ring.set_lasso_active(true)
	if _label != null:
		_label.text = "STUNNED!"
		_label.modulate = Color(0.95, 0.75, 0.15, 1)
	if _stars != null:
		_stars.visible = true
	_play_wall_impact()
	report_progress("Now! Lasso the ring!")
	await get_tree().create_timer(3.5).timeout
	if token != _stun_token or _won:
		return
	if _state == State.STUN:
		_end_stun(false)


func _animate_stun_idle(delta: float) -> void:
	if _sprite == null:
		return
	_charge_bob += delta * 8.0
	_sprite.position.y = BULL_FOOT_Y + sin(_charge_bob) * 2.0
	_sprite.rotation = sin(_charge_bob) * 0.08
	if _stars != null:
		_stars.rotation += delta * 2.5


func _play_wall_impact() -> void:
	if _sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(0.78, 1.15), 0.08)
	tween.tween_property(_sprite, "scale", Vector2(1.12, 0.85), 0.1)
	tween.tween_property(_sprite, "scale", Vector2.ONE, 0.12)


func _play_hit_reaction() -> void:
	if _sprite == null:
		return
	var kick := 0.35 if _dir >= 0.0 else -0.35
	_sprite.modulate = Color(1.4, 1.2, 0.6, 1)
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(1.25, 0.7), 0.08)
	tween.tween_property(_sprite, "rotation", kick, 0.1)
	tween.tween_property(_sprite, "scale", Vector2(0.9, 1.15), 0.1)
	tween.tween_property(_sprite, "rotation", 0.0, 0.12)
	tween.tween_property(_sprite, "scale", Vector2.ONE, 0.1)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _end_stun(from_lasso: bool) -> void:
	if _ring != null:
		_ring.set_lasso_active(false)
	if _stars != null:
		_stars.visible = false
	_pull_clear_of_walls()
	_aim_at_player()
	if from_lasso:
		_state = State.HIT
		_play_hit_reaction()
		if _label != null:
			_label.text = "GOTCHA!"
			_label.modulate = Color(0.2, 0.75, 0.25, 1)
		await get_tree().create_timer(0.45).timeout
		if _won:
			return
	_state = State.CHARGE
	_pull_clear_of_walls()
	_aim_at_player()
	_charge_grace = 0.4
	if _label != null and not _won:
		_label.text = "BULL"
		_label.modulate = Color(0.55, 0.2, 0.08, 1)
	if _sprite != null:
		_sprite.modulate = Color.WHITE
		_sprite.rotation = 0.0


func _on_ring_lasso() -> void:
	if _state != State.STUN or _won or not combat_ready:
		return
	_hits += 1
	_stun_token += 1  # Cancel the stun timer — lasso unstuns immediately.
	report_progress("Ring caught! %d / %d" % [_hits, hits_needed])
	if _hits >= hits_needed:
		_state = State.HIT
		if _ring != null:
			_ring.set_lasso_active(false)
		if _stars != null:
			_stars.visible = false
		await _play_win_animation()
		await win_boss()
		return
	await _end_stun(true)


func _sprite_scale_for(texture: Texture2D, target_height: float) -> Vector2:
	var tex_h := float(texture.get_height()) if texture != null else target_height
	var s := target_height / maxf(tex_h, 1.0)
	return Vector2(s, s)


func _play_win_animation() -> void:
	report_progress("Legs tied!")
	if player != null:
		player.set_input_enabled(false)
	var hurt := $Bull/HurtArea as Area2D
	if hurt != null:
		hurt.set_deferred("monitoring", false)
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.25, 0.75, 0.3, 1)
	if _sprite == null:
		await get_tree().create_timer(1.2).timeout
		return

	var face_left := _sprite.flip_h
	# Rope coils whip around the standing bull's legs.
	var ropes := Node2D.new()
	ropes.name = "WinRopes"
	ropes.z_index = 6
	_bull.add_child(ropes)
	for i in range(5):
		var loop := Line2D.new()
		loop.width = 6.0 - float(i) * 0.35
		loop.default_color = Color(0.78, 0.58, 0.28, 1.0)
		var radius := 18.0 + float(i) * 5.5
		var points := PackedVector2Array()
		for step in range(14):
			var ang := TAU * float(step) / 13.0 + float(i) * 0.35
			points.append(Vector2(
				cos(ang) * radius * 0.7,
				-8.0 - float(i) * 5.0 + sin(ang) * radius * 0.35
			))
		loop.points = points
		loop.modulate.a = 0.0
		ropes.add_child(loop)
		var rt := create_tween()
		rt.tween_property(loop, "modulate:a", 1.0, 0.12).set_delay(0.07 * float(i))
		rt.parallel().tween_property(loop, "scale", Vector2(1.05, 1.05), 0.12).from(Vector2(0.4, 0.4)).set_delay(0.07 * float(i))

	var squash := create_tween()
	squash.tween_property(_sprite, "scale", Vector2(1.12, 0.82), 0.12)
	squash.tween_property(_sprite, "scale", Vector2(0.92, 1.08), 0.1)
	squash.tween_property(_sprite, "scale", Vector2.ONE, 0.1)
	await get_tree().create_timer(0.55).timeout

	# Standing pose with legs bound.
	if ropes != null:
		ropes.queue_free()
	_sprite.texture = BULL_TIED_TEX
	_sprite.flip_h = face_left
	_sprite.rotation = 0.0
	_sprite.position = Vector2(0, -95)
	_sprite.scale = _sprite_scale_for(BULL_TIED_TEX, TIED_SPRITE_HEIGHT)
	if _stars != null:
		_stars.visible = true
		_stars.position = Vector2(0, -130)
	var wobble := create_tween()
	wobble.tween_property(_sprite, "rotation", 0.12 if face_left else -0.12, 0.18)
	wobble.tween_property(_sprite, "rotation", -0.1 if face_left else 0.1, 0.18)
	wobble.tween_property(_sprite, "rotation", 0.0, 0.14)
	await wobble.finished
	await get_tree().create_timer(0.25).timeout

	# Tip over onto its side.
	if _stars != null:
		_stars.visible = false
	if _label != null:
		_label.text = "DOWN!"
		_label.modulate = Color(0.55, 0.3, 0.1, 1)
	var tip_dir := -1.0 if face_left else 1.0
	var tip := create_tween()
	tip.set_parallel(true)
	tip.tween_property(_sprite, "rotation", tip_dir * PI * 0.5, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tip.tween_property(_sprite, "position:y", -40.0, 0.45)
	await tip.finished

	_sprite.texture = BULL_DOWN_TEX
	_sprite.flip_h = face_left
	_sprite.rotation = 0.0
	_sprite.position = Vector2(0, -59)
	_sprite.scale = _sprite_scale_for(BULL_DOWN_TEX, DOWN_SPRITE_HEIGHT)
	# Soft dust puff when he lands.
	var dust := Polygon2D.new()
	dust.color = Color(0.82, 0.62, 0.38, 0.55)
	dust.polygon = PackedVector2Array([
		Vector2(-50, 0), Vector2(-10, -18), Vector2(30, -8), Vector2(55, 6), Vector2(10, 14), Vector2(-35, 10)
	])
	dust.position = Vector2(0, 10)
	_bull.add_child(dust)
	var dt := create_tween()
	dt.tween_property(dust, "modulate:a", 0.0, 0.55)
	dt.parallel().tween_property(dust, "scale", Vector2(1.4, 0.7), 0.55)
	dt.tween_callback(dust.queue_free)

	var settle := create_tween()
	settle.tween_property(_sprite, "scale", _sprite_scale_for(BULL_DOWN_TEX, DOWN_SPRITE_HEIGHT) * Vector2(1.08, 0.9), 0.1)
	settle.tween_property(_sprite, "scale", _sprite_scale_for(BULL_DOWN_TEX, DOWN_SPRITE_HEIGHT), 0.16)
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.2, 0.7, 0.3, 1)
	await get_tree().create_timer(1.35).timeout


func _on_bull_body(body: Node2D) -> void:
	if not (body is Player) or _state != State.CHARGE or not combat_ready or _won:
		return
	if player != null and player.is_invulnerable():
		return
	fail_soft()
