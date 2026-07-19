class_name Opponent
extends AnimatableBody2D

## Slow predictable foe. Touching it hurts unless the player has a shield.

signal hurt_player(player: Player)
signal bounty_caught(opponent: Opponent, amount: int)

@export var point_a: Vector2 = Vector2(-80, 0)
@export var point_b: Vector2 = Vector2(80, 0)
@export var move_speed: float = 40.0
@export var vertical_patrol: bool = false
@export var bounty_bandit: bool = false

var _origin: Vector2
var _going_to_b: bool = true
var _area: Area2D
var _label: Label
var _sprite: AnimatedSprite2D
var _hint_phase: float = 0.0
var _facing: float = 1.0
var _tied: bool = false
var _shooting: bool = false
var _shot_timer: float = 0.0
var _revolver: RevolverOverlay


func _ready() -> void:
	_origin = global_position
	_area = get_node_or_null("HurtArea") as Area2D
	_label = get_node_or_null("Label") as Label
	_setup_sprite()
	_shot_timer = randf_range(1.8, 3.0) if bounty_bandit else randf_range(3.0, 5.0)
	_revolver = RevolverOverlay.new()
	_revolver.name = "Revolver"
	_revolver.z_index = 3
	_revolver.visible = false
	add_child(_revolver)
	if _area != null:
		_area.body_entered.connect(_on_body_entered)


func _setup_sprite() -> void:
	var old := get_node_or_null("Sprite2D") as Node
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 6.0)
	frames.set_animation_loop(&"walk", true)
	var suffix := "_red" if bounty_bandit else ""
	for path in [
		"res://assets/world/bandit_walk_0%s.png" % suffix,
		"res://assets/world/bandit%s.png" % suffix,
		"res://assets/world/bandit_walk_1%s.png" % suffix,
		"res://assets/world/bandit%s.png" % suffix,
	]:
		var tex: Texture2D = load(path)
		if tex != null:
			frames.add_frame(&"walk", tex)
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "WalkSprite"
	_sprite.sprite_frames = frames
	_sprite.centered = true
	# Feet on the desert top (collision bottom at local y=0).
	_sprite.offset = Vector2(0, -35)
	_sprite.scale = Vector2(1.15, 1.15)
	_apply_facing(1.0)
	_sprite.play(&"walk")
	add_child(_sprite)
	if old != null:
		old.visible = false
	if _label != null and bounty_bandit:
		_label.text = "BOUNTY!"
		_label.add_theme_color_override(&"font_color", Color(0.75, 0.08, 0.05, 1.0))


func _process(delta: float) -> void:
	_hint_phase += delta * 4.0
	if _tied:
		return
	_update_nearby_hint()


func _physics_process(delta: float) -> void:
	if _tied:
		return
	_shot_timer -= delta
	if _shooting:
		return
	if _shot_timer <= 0.0:
		var player := _find_nearby_player(580.0)
		if player != null and absf(player.global_position.y - global_position.y) <= 150.0:
			_shoot_at(player)
			_shot_timer = randf_range(3.0, 5.0) if bounty_bandit else randf_range(5.0, 8.0)
			return
		_shot_timer = 1.0
	var target := _origin + (point_b if _going_to_b else point_a)
	var previous := global_position
	global_position = global_position.move_toward(target, move_speed * delta)
	var dx := global_position.x - previous.x
	if absf(dx) > 0.01:
		_facing = 1.0 if dx > 0.0 else -1.0
		if _sprite != null:
			_apply_facing(_facing)
			if not _sprite.is_playing():
				_sprite.play(&"walk")
	elif _sprite != null and _sprite.is_playing():
		_sprite.pause()
	if global_position.distance_to(target) < 2.0:
		_going_to_b = not _going_to_b
		_apply_facing(1.0 if _going_to_b else -1.0)


func _apply_facing(direction: float) -> void:
	if _sprite == null:
		return
	# A signed scale makes the turnaround explicit and reliable for all frames.
	_sprite.flip_h = false
	_sprite.scale.x = absf(_sprite.scale.x) * (1.0 if direction >= 0.0 else -1.0)


func is_tied() -> bool:
	return _tied


func tie_up(award_bounty: bool = true) -> void:
	if _tied:
		return
	_tied = true
	collision_layer = 0
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", false)
	if _revolver != null:
		_revolver.hide_gun()
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", true)
	_show_floor_bound_pose()
	if get_node_or_null("TiedRopes") == null:
		var ropes := TiedBanditOverlay.new()
		ropes.name = "TiedRopes"
		ropes.z_index = 0
		add_child(ropes)
	# The whole captured bandit stays behind the cowboy.
	z_index = -1
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.55, 0.25, 0.06, 1.0)
		_label.position.y = -78.0
	if bounty_bandit and award_bounty:
		bounty_caught.emit(self, 2)


func _show_floor_bound_pose() -> void:
	if _sprite == null:
		return
	_sprite.pause()
	var path := (
		"res://assets/world/bandit_tied_red.png"
		if bounty_bandit
		else "res://assets/world/bandit_tied.png"
	)
	var tex: Texture2D = load(path)
	if tex == null:
		return
	var frames := SpriteFrames.new()
	frames.add_animation(&"tied")
	frames.set_animation_loop(&"tied", false)
	frames.add_frame(&"tied", tex)
	_sprite.sprite_frames = frames
	_sprite.rotation = 0.0
	var face := 1.0 if _facing >= 0.0 else -1.0
	_sprite.flip_h = false
	# The tied art is 130 px tall versus the 80 px standing art.
	# Scale it to the same on-screen height instead of enlarging the capture.
	_sprite.scale = Vector2(0.7 * face, 0.7)
	# Feet/seat on the desert top (collision bottom at local y=0).
	_sprite.offset = Vector2(0, -45)
	_sprite.play(&"tied")


func _shoot_at(player: Player) -> void:
	if _tied or _shooting:
		return
	_shooting = true
	_facing = 1.0 if player.global_position.x >= global_position.x else -1.0
	_apply_facing(_facing)
	if _sprite != null:
		_sprite.pause()
	if _revolver != null:
		_revolver.show_aim(_facing)
	if _label != null:
		_label.text = "LOOK OUT!"
		_label.modulate = Color(0.9, 0.16, 0.05, 1.0)
	await get_tree().create_timer(0.45).timeout
	if _tied:
		_shooting = false
		return
	if _revolver != null:
		_revolver.show_flash()
	var bullet := BanditBullet.new()
	bullet.name = "BanditBullet"
	bullet.setup(_facing)
	bullet.hurt_player.connect(func(hit_player: Player) -> void: hurt_player.emit(hit_player))
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(36.0 * _facing, -39.0)
	await get_tree().create_timer(0.25).timeout
	if _revolver != null:
		_revolver.hide_gun()
	if not _tied:
		_shooting = false
		if _sprite != null:
			_sprite.play(&"walk")
		if _label != null:
			_label.text = "BOUNTY!" if bounty_bandit else "BANDIT"
			_label.modulate = Color.WHITE


func _update_nearby_hint() -> void:
	if _label == null:
		return
	var player := _find_nearby_player(160.0)
	if player != null:
		_label.text = "JUMP!"
		_label.modulate = Color(1.0, 0.85 + sin(_hint_phase) * 0.15, 0.2, 1.0)
		_label.add_theme_font_size_override(&"font_size", 16)
	else:
		_label.text = "BANDIT"
		_label.modulate = Color(1, 1, 1, 1)
		_label.add_theme_font_size_override(&"font_size", 13)


func _find_nearby_player(radius: float) -> Player:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Player and global_position.distance_to((node as Node2D).global_position) <= radius:
			return node as Player
	var root := tree.current_scene
	if root == null:
		return null
	var player_node := root.find_child("Player", true, false)
	if player_node is Player and global_position.distance_to((player_node as Node2D).global_position) <= radius:
		return player_node as Player
	return null


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player := body as Player
		if player.is_invulnerable():
			return
		hurt_player.emit(player)
