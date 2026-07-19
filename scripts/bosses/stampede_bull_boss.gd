extends BossArena

## Stampede Bull: bounce clear of horns, lasso the back ring while stunned.

const BULL_TEX := preload("res://assets/world/boss_stampede_bull.png")

enum State { CHARGE, STUN, HIT }

@export var hits_needed: int = 3
@export var charge_speed: float = 300.0
@export var max_hearts: int = 5

var _bull: AnimatableBody2D
var _ring: BossLassoTarget
var _sprite: Sprite2D
var _label: Label
var _stars: Node2D
var _hearts_label: Label
var _hits: int = 0
var _hearts: int = 5
var _dir: float = 1.0
var _state: State = State.CHARGE
var _left_x: float = 460.0
var _right_x: float = 1140.0
var _charge_bob: float = 0.0
var _stun_token: int = 0
var _hit_cooldown: float = 0.0


func _ready() -> void:
	source_level = 3
	boss_title = "Stampede Bull — bounce, then lasso the ring while stunned!"
	super._ready()
	_hearts = max_hearts
	_bull = $Bull as AnimatableBody2D
	_sprite = $Bull/Sprite2D as Sprite2D
	_label = $Bull/Label as Label
	_ring = $Bull/LassoRing as BossLassoTarget
	_stars = $Bull/StunStars as Node2D
	_build_hearts_ui()
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
	_apply_facing()
	_refresh_hearts()


func _build_hearts_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HeartsLayer"
	layer.layer = 40
	add_child(layer)
	_hearts_label = Label.new()
	_hearts_label.name = "HeartsLabel"
	_hearts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hearts_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hearts_label.offset_top = 16.0
	_hearts_label.offset_bottom = 64.0
	_hearts_label.add_theme_font_size_override(&"font_size", 36)
	_hearts_label.add_theme_color_override(&"font_color", Color(0.9, 0.2, 0.25, 1))
	_hearts_label.add_theme_color_override(&"font_outline_color", Color(0.2, 0.05, 0.05, 1))
	_hearts_label.add_theme_constant_override(&"outline_size", 6)
	layer.add_child(_hearts_label)


func _refresh_hearts() -> void:
	if _hearts_label == null:
		return
	var filled := ""
	for i in range(max_hearts):
		filled += "♥" if i < _hearts else "♡"
		if i < max_hearts - 1:
			filled += " "
	_hearts_label.text = filled


func _physics_process(delta: float) -> void:
	if _won or _bull == null or not combat_ready:
		return
	if _hit_cooldown > 0.0:
		_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	match _state:
		State.CHARGE:
			_charge_bob += delta * 14.0
			_bull.position.x += _dir * charge_speed * delta
			if _sprite != null:
				_sprite.position.y = -55.0 + sin(_charge_bob) * 4.0
				_sprite.rotation = sin(_charge_bob * 0.5) * 0.04 * _dir
			_apply_facing()
			if _bull.position.x >= _right_x:
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


func _begin_stun() -> void:
	if _state != State.CHARGE:
		return
	_state = State.STUN
	_stun_token += 1
	var token := _stun_token
	_dir *= -1.0
	_apply_facing()
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
	_sprite.position.y = -55.0 + sin(_charge_bob) * 2.0
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
	_bull.position.x = clampf(_bull.position.x + _dir * 18.0, _left_x + 8.0, _right_x - 8.0)
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
	_stun_token += 1
	report_progress("Ring caught! %d / %d" % [_hits, hits_needed])
	if _hits >= hits_needed:
		_state = State.HIT
		_play_hit_reaction()
		if _ring != null:
			_ring.set_lasso_active(false)
		if _stars != null:
			_stars.visible = false
		win_boss()
		return
	await _end_stun(true)


func _on_bull_body(body: Node2D) -> void:
	if not (body is Player) or _state != State.CHARGE or not combat_ready or _won:
		return
	if _hit_cooldown > 0.0:
		return
	_hit_cooldown = 1.1
	_hearts = maxi(_hearts - 1, 0)
	_refresh_hearts()
	if player != null:
		# Blink + drop into the arena middle from above the bull.
		var mid_x := (_left_x + _right_x) * 0.5
		var drop_y := _bull.global_position.y - 170.0
		player.respawn_at(Vector2(mid_x, drop_y))
		player.velocity = Vector2.ZERO
	if _hearts_label != null:
		var tw := create_tween()
		tw.tween_property(_hearts_label, "modulate", Color(1.5, 0.4, 0.4, 1), 0.08)
		tw.tween_property(_hearts_label, "modulate", Color.WHITE, 0.2)
	report_progress("%d heart%s left!" % [_hearts, "" if _hearts == 1 else "s"])
	if _hearts <= 0:
		report_progress("Out of hearts — restarting!")
		await get_tree().create_timer(0.85).timeout
		restart_boss()
