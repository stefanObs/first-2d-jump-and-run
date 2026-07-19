extends BossArena

## Outlaw Kingpin: tie bodyguards first, then lasso the boss during telegraph.

const KING_TEX := preload("res://assets/world/boss_outlaw_kingpin.png")
const TIED_TEX := preload("res://assets/world/bandit_tied_red.png")

var _king: Node2D
var _king_sprite: Sprite2D
var _king_target: BossLassoTarget
var _label: Label
var _revolver: RevolverOverlay
var _guards_left: int = 2
var _vulnerable: bool = false
var _walk_dir: float = -1.0
var _walk_speed: float = 70.0
var _left_x: float = 780.0
var _right_x: float = 1180.0
var _shot_timer: float = 1.2
var _shooting: bool = false
var _shot_generation: int = 0
var _capturing: bool = false


func _ready() -> void:
	source_level = 10
	boss_title = "Outlaw Kingpin — tie the guards, then lasso the boss once!"
	super._ready()
	_king = $Kingpin as Node2D
	_label = $Kingpin/Label as Label
	_king_target = $Kingpin/LassoTarget as BossLassoTarget
	_king_sprite = $Kingpin/Sprite2D as Sprite2D
	if _king_sprite != null:
		_king_sprite.texture = KING_TEX
	if _king_target != null:
		_king_target.set_lasso_active(false)
	_revolver = RevolverOverlay.new()
	_revolver.name = "Revolver"
	_revolver.z_index = 4
	_revolver.aim_style = RevolverOverlay.AimStyle.HIP
	_revolver.position = Vector2(0, -6)
	_revolver.scale = Vector2(1.25, 1.25)
	_revolver.visible = false
	_king.add_child(_revolver)
	for name in ["Guard0", "Guard1"]:
		var guard := get_node_or_null(name) as Opponent
		if guard != null:
			guard.captured.connect(_on_guard_captured)
	_apply_facing()
	_start_telegraph_loop()


func _physics_process(delta: float) -> void:
	if _won or _king == null or _capturing or not combat_ready:
		return
	if not _shooting:
		_king.position.x += _walk_dir * _walk_speed * delta
		if _king.position.x <= _left_x:
			_king.position.x = _left_x
			_walk_dir = 1.0
			_apply_facing()
		elif _king.position.x >= _right_x:
			_king.position.x = _right_x
			_walk_dir = -1.0
			_apply_facing()
		elif absf(_walk_dir) > 0.01:
			_apply_facing()
	_shot_timer -= delta
	if _shot_timer <= 0.0 and not _shooting:
		_shoot_at_player()


func _apply_facing() -> void:
	if _king_sprite != null:
		_king_sprite.flip_h = _walk_dir < 0.0


func _on_guard_captured(_opp: Opponent) -> void:
	_guards_left = maxi(_guards_left - 1, 0)
	report_progress("Guard tied! %d left" % _guards_left)
	if _guards_left <= 0:
		report_progress("Now lasso the Kingpin!")
		_vulnerable = true
		if _king_target != null:
			_king_target.set_lasso_active(true)
		if _label != null:
			_label.text = "LASSO ME!"
			_label.modulate = Color(0.95, 0.75, 0.2, 1)


func _start_telegraph_loop() -> void:
	## Flavor flashes after guards fall — the kingpin stays lassoable with one hit.
	while not _won and is_instance_valid(self):
		await get_tree().create_timer(2.8).timeout
		if _won or _guards_left > 0 or _capturing:
			continue
		if _label != null and not _shooting:
			_label.text = "LOOK OUT!"
			_label.modulate = Color(0.95, 0.2, 0.1, 1)
		await get_tree().create_timer(1.2).timeout
		if _capturing or _won or _guards_left > 0:
			continue
		if _label != null and not _shooting and not _capturing:
			_label.text = "LASSO ME!"
			_label.modulate = Color(0.95, 0.75, 0.2, 1)


func _shoot_at_player() -> void:
	if _won or _capturing or not combat_ready or _king == null or player == null:
		_shot_timer = 0.8
		return
	_shooting = true
	_shot_generation += 1
	var shot_id := _shot_generation
	_walk_dir = 1.0 if player.global_position.x >= _king.global_position.x else -1.0
	_apply_facing()
	# Raise the gun into his hands before the shot (hip height for standing hits).
	if _revolver != null:
		_revolver.position = Vector2(10.0 * _walk_dir, -8.0)
		_revolver.show_aim(_walk_dir)
	if _label != null and not _capturing:
		_label.text = "BANG!"
		_label.modulate = Color(0.9, 0.2, 0.1, 1)
	await get_tree().create_timer(0.4).timeout
	if shot_id != _shot_generation or _won or _capturing:
		_shooting = false
		return
	if _revolver != null:
		_revolver.show_flash()
	var bullet := BanditBullet.new()
	bullet.name = "KingpinBullet"
	bullet.setup(_walk_dir)
	bullet.speed = 105.0
	bullet.hurt_player.connect(func(hit_player: Player) -> void:
		if hit_player != null and not hit_player.is_invulnerable():
			fail_soft()
	)
	add_child(bullet)
	# Chest/belly height vs a standing cowboy (feet at kingpin y).
	var muzzle := _king.global_position + Vector2(44.0 * _walk_dir, -34.0)
	if _revolver != null:
		muzzle = _revolver.global_position + _revolver.muzzle_position()
	bullet.global_position = muzzle
	await get_tree().create_timer(0.22).timeout
	if shot_id != _shot_generation:
		_shooting = false
		return
	if _revolver != null:
		_revolver.hide_gun()
	_shooting = false
	_shot_timer = randf_range(1.1, 1.9)
	if _label != null and not _won and not _capturing and _guards_left <= 0:
		_label.text = "LASSO ME!"
		_label.modulate = Color(0.95, 0.75, 0.2, 1)
	elif _label != null and not _won and not _capturing:
		_label.text = "KINGPIN"
		_label.modulate = Color(0.7, 0.15, 0.1, 1)


func lasso_kingpin() -> void:
	if _won or _capturing or not combat_ready:
		return
	if _guards_left > 0:
		report_progress("Tie the bodyguards first!")
		return
	# One lasso hit ties the kingpin for good.
	_capturing = true
	_shot_generation += 1
	_shooting = false
	_vulnerable = false
	if _king_target != null:
		_king_target.set_lasso_active(false)
	if _revolver != null:
		_revolver.hide_gun()
	await _play_capture_animation()
	await win_boss()


func _play_capture_animation() -> void:
	_capturing = true
	report_progress("Kingpin captured!")
	if _label != null:
		_label.text = "GOTCHA!"
		_label.modulate = Color(0.2, 0.8, 0.25, 1)
	if _king_sprite == null:
		await get_tree().create_timer(0.8).timeout
		return
	var face := -1.0 if _king_sprite.flip_h else 1.0
	var tween := create_tween()
	tween.tween_property(_king_sprite, "scale", Vector2(1.15 * face, 0.75), 0.1)
	tween.tween_property(_king_sprite, "rotation", 0.25 * face, 0.12)
	tween.tween_property(_king_sprite, "scale", Vector2(0.85 * face, 0.85), 0.14)
	tween.tween_property(_king_sprite, "rotation", 0.0, 0.1)
	# Rope coils settle onto the kingpin.
	var ropes := Node2D.new()
	ropes.name = "CaptureRopes"
	ropes.z_index = 5
	_king.add_child(ropes)
	for i in range(4):
		var loop := Line2D.new()
		loop.width = 5.0
		loop.default_color = Color(0.72, 0.5, 0.22, 1.0)
		var radius := 34.0 + float(i) * 7.0
		var points := PackedVector2Array()
		for step in range(12):
			var ang := TAU * float(step) / 11.0
			points.append(Vector2(cos(ang) * radius * 0.55, -55.0 - float(i) * 9.0 + sin(ang) * radius * 0.3))
		loop.points = points
		loop.modulate.a = 0.0
		ropes.add_child(loop)
		var rt := create_tween()
		rt.tween_property(loop, "modulate:a", 1.0, 0.1).set_delay(0.06 * float(i))
	await get_tree().create_timer(0.45).timeout
	# Settle into a tied sit pose at the same on-screen size as the standing kingpin.
	_king_sprite.flip_h = face < 0.0
	_king_sprite.texture = TIED_TEX
	var stand_h := float(KING_TEX.get_height()) if KING_TEX != null else 180.0
	var tied_h := float(TIED_TEX.get_height()) if TIED_TEX != null else 130.0
	var tied_scale := stand_h / maxf(tied_h, 1.0)
	_king_sprite.position = Vector2(0, -stand_h * 0.28)
	_king_sprite.scale = Vector2(tied_scale, tied_scale)
	_king_sprite.rotation = 0.0
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.55, 0.25, 0.06, 1)
	await get_tree().create_timer(0.9).timeout
