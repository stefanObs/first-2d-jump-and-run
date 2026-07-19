extends BossArena

## Stampede Bull: bounce clear of horns, lasso the back ring while stunned.

const BULL_TEX := preload("res://assets/world/boss_stampede_bull.png")

@export var hits_needed: int = 3
@export var charge_speed: float = 280.0

var _bull: AnimatableBody2D
var _ring: BossLassoTarget
var _sprite: Sprite2D
var _label: Label
var _hits: int = 0
var _dir: float = 1.0
var _stunned: bool = false
var _left_x: float = 420.0
var _right_x: float = 1180.0


func _ready() -> void:
	source_level = 3
	boss_title = "Stampede Bull — lasso the glowing ring!"
	super._ready()
	_bull = $Bull as AnimatableBody2D
	_sprite = $Bull/Sprite2D as Sprite2D
	_label = $Bull/Label as Label
	_ring = $Bull/LassoRing as BossLassoTarget
	if _sprite != null:
		_sprite.texture = BULL_TEX
	if _ring != null:
		_ring.set_lasso_active(false)
		_ring.lassoed.connect(_on_ring_lasso)
	var hurt := $Bull/HurtArea as Area2D
	if hurt != null:
		hurt.body_entered.connect(_on_bull_body)


func _physics_process(delta: float) -> void:
	if _won or _bull == null or _stunned:
		return
	_bull.position.x += _dir * charge_speed * delta
	if _sprite != null:
		_sprite.flip_h = _dir < 0.0
		# Keep the ring on the trailing flank opposite the charge.
		if _ring != null:
			_ring.position.x = 24.0 if _dir < 0.0 else -24.0
	if _bull.position.x >= _right_x:
		_bull.position.x = _right_x
		_stun()
	elif _bull.position.x <= _left_x:
		_bull.position.x = _left_x
		_stun()


func _stun() -> void:
	_stunned = true
	_dir *= -1.0
	if _ring != null:
		_ring.set_lasso_active(true)
	if _label != null:
		_label.text = "STUNNED!"
		_label.modulate = Color(0.95, 0.75, 0.15, 1)
	report_progress("Now! Lasso the ring!")
	await get_tree().create_timer(2.0).timeout
	if not _stunned:
		return
	_stunned = false
	if _ring != null:
		_ring.set_lasso_active(false)
	if _label != null and not _won:
		_label.text = "BULL"
		_label.modulate = Color(0.55, 0.2, 0.08, 1)


func _on_ring_lasso() -> void:
	if not _stunned or _won:
		return
	_hits += 1
	report_progress("Ring caught! %d / %d" % [_hits, hits_needed])
	_stunned = false
	if _ring != null:
		_ring.set_lasso_active(false)
	if _label != null:
		_label.text = "BULL"
		_label.modulate = Color(0.55, 0.2, 0.08, 1)
	if _hits >= hits_needed:
		win_boss()


func _on_bull_body(body: Node2D) -> void:
	if body is Player and not _stunned:
		fail_soft()
