extends BossArena

## Outlaw Kingpin: tie bodyguards first, then lasso the boss during telegraph.

const KING_TEX := preload("res://assets/world/boss_outlaw_kingpin.png")

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


func _ready() -> void:
	source_level = 10
	boss_title = "Outlaw Kingpin — tie the guards, then the boss!"
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
	_revolver.z_index = 3
	_revolver.visible = false
	_king.add_child(_revolver)
	for name in ["Guard0", "Guard1"]:
		var guard := get_node_or_null(name) as Opponent
		if guard != null:
			guard.captured.connect(_on_guard_captured)
	_apply_facing()
	_start_telegraph_loop()


func _physics_process(delta: float) -> void:
	if _won or _king == null:
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
		report_progress("Now wait for LOOK OUT!")


func _start_telegraph_loop() -> void:
	while not _won and is_instance_valid(self):
		await get_tree().create_timer(2.4).timeout
		if _won or _guards_left > 0:
			continue
		_vulnerable = true
		if _king_target != null:
			_king_target.set_lasso_active(true)
		if _label != null:
			_label.text = "LOOK OUT!"
			_label.modulate = Color(0.95, 0.2, 0.1, 1)
		await get_tree().create_timer(1.6).timeout
		_vulnerable = false
		if _king_target != null and not _won:
			_king_target.set_lasso_active(false)
		if _label != null and not _won and not _shooting:
			_label.text = "KINGPIN"
			_label.modulate = Color(0.7, 0.15, 0.1, 1)


func _shoot_at_player() -> void:
	if _won or _king == null or player == null:
		_shot_timer = 0.8
		return
	_shooting = true
	_shot_generation += 1
	var shot_id := _shot_generation
	_walk_dir = 1.0 if player.global_position.x >= _king.global_position.x else -1.0
	_apply_facing()
	if _revolver != null:
		_revolver.show_aim(_walk_dir)
	if _label != null and not _vulnerable:
		_label.text = "BANG!"
		_label.modulate = Color(0.9, 0.2, 0.1, 1)
	await get_tree().create_timer(0.35).timeout
	if shot_id != _shot_generation or _won:
		_shooting = false
		return
	if _revolver != null:
		_revolver.show_flash()
	var bullet := BanditBullet.new()
	bullet.name = "KingpinBullet"
	bullet.setup(_walk_dir)
	bullet.speed = 175.0
	bullet.hurt_player.connect(func(hit_player: Player) -> void:
		if hit_player != null and not hit_player.is_invulnerable():
			fail_soft()
	)
	add_child(bullet)
	bullet.global_position = _king.global_position + Vector2(40.0 * _walk_dir, -48.0)
	await get_tree().create_timer(0.2).timeout
	if shot_id != _shot_generation:
		_shooting = false
		return
	if _revolver != null:
		_revolver.hide_gun()
	_shooting = false
	# Faster than trail bandits (those use ~5–8s / bounty ~3–5s).
	_shot_timer = randf_range(1.1, 1.9)
	if _label != null and not _vulnerable and not _won:
		_label.text = "KINGPIN"
		_label.modulate = Color(0.7, 0.15, 0.1, 1)


func lasso_kingpin() -> void:
	if _won:
		return
	if _guards_left > 0:
		report_progress("Tie the bodyguards first!")
		return
	if not _vulnerable:
		report_progress("Wait for LOOK OUT!")
		return
	_shot_generation += 1
	_shooting = false
	win_boss()
