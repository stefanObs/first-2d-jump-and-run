class_name Opponent
extends AnimatableBody2D

## Slow predictable foe. Touching it hurts unless the player has a shield.
## Jumping onto its head ties it, same as a lasso catch.

signal hurt_player(player: Player)
signal captured(opponent: Opponent)
signal bounty_caught(opponent: Opponent, amount: int)

const STAND_SCALE := 1.15
const TIED_SCALE := 0.7
## Sprite offset so feet sit on local y=0 (desert surface when root is on the trail floor).
## Offset is scaled with the sprite (Godot CanvasItem), so use -half_height, not -half_height*scale.
const STAND_FOOT_OFFSET := Vector2(0, -40)
const TIED_FOOT_OFFSET := Vector2(0, -65)
## Horizontal shots only when the cowboy is near this height band.
const SHOOT_Y_BAND := 150.0
## Cave skeletons may loft arrows this far above their boots at flying cowboys.
const SHOOT_UP_REACH := 420.0
const SHOOT_UP_MIN := 80.0

@export var point_a: Vector2 = Vector2(-80, 0)
@export var point_b: Vector2 = Vector2(80, 0)
@export var move_speed: float = 40.0
@export var vertical_patrol: bool = false
@export var bounty_bandit: bool = false

const FALL_GRAVITY := 1350.0
const FALL_PROBE_DOWN := 900.0

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
var _shot_generation: int = 0
var _revolver: RevolverOverlay
var _pose_tween: Tween
var _level_style: String = LevelStyle.DESERT
var _falling: bool = false
var _fall_vel: float = 0.0


func apply_level_style(style: String) -> void:
	_level_style = LevelStyle.normalize(style)
	if _sprite != null and not _tied:
		_sprite.sprite_frames = _make_sprite_frames()
		_sprite.play(&"idle")
	if _label != null and not _tied:
		_label.text = "BOUNTY!" if bounty_bandit else ("SKELETON" if LevelStyle.is_cave(_level_style) else "BANDIT")


func _ready() -> void:
	_origin = global_position
	_area = get_node_or_null("HurtArea") as Area2D
	_label = get_node_or_null("Label") as Label
	if _label != null:
		_label.visible = false
	_setup_sprite()
	_shot_timer = randf_range(1.8, 3.0) if bounty_bandit else randf_range(3.0, 5.0)
	_revolver = RevolverOverlay.new()
	_revolver.name = "Revolver"
	_revolver.z_index = 3
	_revolver.visible = false
	add_child(_revolver)
	if _area != null:
		_area.body_entered.connect(_on_body_entered)
	## Mid-air stamps fall onto the next standable crust, then patrol.
	call_deferred("_begin_airborne_fall")


func _setup_sprite() -> void:
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			if String(child.name) in ["WalkSprite", "Sprite2D"]:
				child.queue_free()
	var frames := _make_sprite_frames()
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "WalkSprite"
	_sprite.sprite_frames = frames
	_sprite.centered = true
	# Feet on the desert top (collision bottom at local y=0).
	_sprite.offset = STAND_FOOT_OFFSET
	_sprite.scale = Vector2(STAND_SCALE, STAND_SCALE)
	_apply_facing(1.0)
	_sprite.play(&"idle")
	add_child(_sprite)
	if _label != null and bounty_bandit:
		_label.text = "BOUNTY!"
		_label.add_theme_color_override(&"font_color", Color(0.75, 0.08, 0.05, 1.0))


func _make_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	var cave := LevelStyle.is_cave(_level_style)
	var stand_path: String
	var walk0: String
	var walk1: String
	var tied_path: String
	if cave:
		var skel := "skeleton_crystal" if bounty_bandit else "skeleton"
		stand_path = "res://assets/world/%s.png" % skel
		walk0 = "res://assets/world/%s_walk_0.png" % skel
		walk1 = "res://assets/world/%s_walk_1.png" % skel
		tied_path = "res://assets/world/%s_tied.png" % skel
	else:
		var suffix := "_red" if bounty_bandit else ""
		stand_path = "res://assets/world/bandit%s.png" % suffix
		walk0 = "res://assets/world/bandit_walk_0%s.png" % suffix
		walk1 = "res://assets/world/bandit_walk_1%s.png" % suffix
		tied_path = "res://assets/world/bandit_tied%s.png" % suffix
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 1.0)
	frames.set_animation_loop(&"idle", true)
	var stand_tex: Texture2D = load(stand_path)
	if stand_tex != null:
		frames.add_frame(&"idle", stand_tex)
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 8.0)
	frames.set_animation_loop(&"walk", true)
	for path in [walk0, stand_path, walk1, stand_path]:
		var tex: Texture2D = load(path)
		if tex != null:
			frames.add_frame(&"walk", tex)
	frames.add_animation(&"tied")
	frames.set_animation_speed(&"tied", 1.0)
	frames.set_animation_loop(&"tied", true)
	var tied_tex: Texture2D = load(tied_path)
	if tied_tex != null:
		frames.add_frame(&"tied", tied_tex)
	elif stand_tex != null:
		frames.add_frame(&"tied", stand_tex)
	if cave:
		frames.add_animation(&"shoot_up")
		frames.set_animation_speed(&"shoot_up", 6.0)
		frames.set_animation_loop(&"shoot_up", false)
		var skel := "skeleton_crystal" if bounty_bandit else "skeleton"
		for path in [
			"res://assets/world/%s_shoot_up_0.png" % skel,
			"res://assets/world/%s_shoot_up_1.png" % skel,
		]:
			var tex: Texture2D = load(path)
			if tex != null:
				frames.add_frame(&"shoot_up", tex)
		if frames.get_frame_count(&"shoot_up") == 0 and stand_tex != null:
			frames.add_frame(&"shoot_up", stand_tex)
	return frames



func _set_move_animation(moving: bool) -> void:
	if _sprite == null or _tied or _shooting:
		return
	# Keep a stable on-screen size while flipping walk/idle frames.
	var face := 1.0 if _facing >= 0.0 else -1.0
	_sprite.scale = Vector2(STAND_SCALE * face, STAND_SCALE)
	_sprite.offset = STAND_FOOT_OFFSET
	if moving:
		if _sprite.animation != &"walk" or not _sprite.is_playing():
			_sprite.play(&"walk")
	elif _sprite.animation != &"idle" or not _sprite.is_playing():
		_sprite.play(&"idle")


func _process(delta: float) -> void:
	_hint_phase += delta * 4.0
	if _tied:
		return
	_update_nearby_hint()


func snap_feet_to_surface(floor_y: float) -> void:
	## Place feet on the walk crust. Used after trail floors are dressed, and when
	## a stamp lands inside/under the dirt.
	if _tied or vertical_patrol:
		return
	_kill_pose_tween()
	_falling = false
	_fall_vel = 0.0
	global_position.y = floor_y
	_origin = global_position


func _begin_airborne_fall() -> void:
	if _tied or vertical_patrol:
		_falling = false
		return
	## Prefer the trail crust under/at the feet. A tall cast alone would grab
	## movers overhead; a short cast alone misses when fully buried in dirt.
	var above_y := FloorProbe.crust_y_above(self, global_position, 220.0)
	if not is_nan(above_y) and above_y < global_position.y - 6.0:
		snap_feet_to_surface(above_y)
		return
	var floor_y := FloorProbe.nearest_floor_y(
		self, global_position, 24.0, FALL_PROBE_DOWN, INF
	)
	if is_nan(floor_y):
		if not is_nan(above_y):
			snap_feet_to_surface(above_y)
			return
		_falling = false
		_origin = global_position
		return
	if floor_y < global_position.y - 6.0:
		snap_feet_to_surface(floor_y)
		return
	if floor_y <= global_position.y + 6.0:
		snap_feet_to_surface(floor_y)
		return
	_falling = true
	_fall_vel = 0.0


func _physics_process(delta: float) -> void:
	if _tied:
		return
	if _falling:
		_fall_vel += FALL_GRAVITY * delta
		global_position.y += _fall_vel * delta
		var floor_y := FloorProbe.nearest_floor_y(
			self, global_position, 8.0, 96.0 + _fall_vel * delta, INF
		)
		if not is_nan(floor_y) and global_position.y >= floor_y:
			global_position.y = floor_y
			_falling = false
			_fall_vel = 0.0
			_origin = global_position
		return
	_resolve_player_overlap()
	if _tied:
		return
	_shot_timer -= delta
	if _shooting:
		return
	if _shot_timer <= 0.0:
		var player := _find_nearby_player(580.0)
		if player != null and _can_shoot_at(player):
			_shoot_at(player)
			_shot_timer = randf_range(3.0, 5.0) if bounty_bandit else randf_range(5.0, 8.0)
			return
		_shot_timer = 1.0
	var target := _origin + (point_b if _going_to_b else point_a)
	var travel_x := target.x - global_position.x
	if (
		not vertical_patrol
		and absf(travel_x) > 0.5
		and not FloorProbe.has_floor_ahead(self, signf(travel_x))
	):
		_going_to_b = not _going_to_b
		_apply_facing(1.0 if _going_to_b else -1.0)
		return
	var previous := global_position
	var next := previous.move_toward(target, move_speed * delta)
	# AnimatableBody2D defers transform writes, so do not infer motion by
	# reading global_position back in the same frame.
	var dx := next.x - previous.x
	var dy := next.y - previous.y
	var moving := absf(dx) > 0.01 or absf(dy) > 0.01
	global_position = next
	if absf(dx) > 0.01:
		_facing = 1.0 if dx > 0.0 else -1.0
		_apply_facing(_facing)
	_set_move_animation(moving)
	if next.distance_to(target) < 2.0:
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


func get_stand_scale() -> float:
	return STAND_SCALE


func foot_contact_y() -> float:
	## World Y of the standing (or tied) sprite feet for desert-surface checks.
	## Sprite offset is in local (pre-scale) space; scale applies to offset + half-height.
	if _sprite == null or _sprite.sprite_frames == null:
		return INF
	var anim := _sprite.animation
	if not _sprite.sprite_frames.has_animation(anim):
		return INF
	var tex: Texture2D = _sprite.sprite_frames.get_frame_texture(anim, _sprite.frame)
	if tex == null:
		return INF
	var from_center := float(tex.get_height()) * 0.5
	return global_position.y + (_sprite.offset.y + from_center) * absf(_sprite.scale.y)


func tie_up(award_bounty: bool = true) -> void:
	if _tied:
		return
	_tied = true
	_shot_generation += 1
	_shooting = false
	collision_layer = 0
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", false)
		_area.set_deferred("monitorable", false)
	if _revolver != null:
		_revolver.hide_gun()
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", true)
	# Instantly safe/pass-through, then play a short rope flourish.
	_show_floor_bound_pose()
	TiedBanditOverlay.ensure_attached(self, self)
	z_index = -1
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.55, 0.25, 0.06, 1.0)
		_label.position.y = -78.0
	_play_tying_flourish()
	captured.emit(self)
	if bounty_bandit and award_bounty:
		bounty_caught.emit(self, 2)


func _play_tying_flourish() -> void:
	if _sprite == null:
		return
	_kill_pose_tween()
	var face := 1.0 if _facing >= 0.0 else -1.0
	var end_scale := STAND_SCALE if LevelStyle.is_cave(_level_style) else TIED_SCALE
	_pose_tween = create_tween()
	_pose_tween.tween_property(_sprite, "scale", Vector2(0.9 * face, 0.55), 0.1)
	_pose_tween.tween_property(_sprite, "scale", Vector2(0.78 * face, 0.78), 0.12)
	_pose_tween.tween_property(_sprite, "scale", Vector2(end_scale * face, end_scale), 0.12)
	if _label != null:
		_label.text = "GOTCHA!"
		var label_tween := create_tween()
		label_tween.tween_interval(0.28)
		label_tween.tween_callback(func() -> void:
			if _label != null and _tied:
				_label.text = "TIED!"
		)


func untie_for_respawn() -> void:
	if not _tied:
		return
	_tied = false
	_shot_generation += 1
	_shooting = false
	_kill_pose_tween()
	collision_layer = 0
	z_index = 0
	global_position = _origin
	_going_to_b = true
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", true)
		_area.set_deferred("monitorable", true)
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", false)
	TiedBanditOverlay.remove_from(self)
	if _revolver != null:
		_revolver.hide_gun()
	if _sprite != null:
		_sprite.sprite_frames = _make_sprite_frames()
		_sprite.rotation = 0.0
		_sprite.offset = STAND_FOOT_OFFSET
		_sprite.scale = Vector2(STAND_SCALE, STAND_SCALE)
		_apply_facing(_facing)
		_sprite.play(&"idle")
	if _label != null:
		_label.position.y = 0.0
		_label.text = "BOUNTY!" if bounty_bandit else "BANDIT"
		_label.modulate = Color.WHITE
	_shot_timer = randf_range(1.8, 3.0) if bounty_bandit else randf_range(3.0, 5.0)


func restore_for_respawn() -> void:
	## Untied bandits that wandered or mid-shot return to their post at camp respawn.
	## Bullets are cleared separately by the level controller.
	if _tied:
		return
	_shot_generation += 1
	_shooting = false
	_kill_pose_tween()
	global_position = _origin
	_going_to_b = true
	if _revolver != null:
		_revolver.hide_gun()
	if _sprite != null:
		_sprite.rotation = 0.0
		_sprite.offset = STAND_FOOT_OFFSET
		_sprite.scale = Vector2(STAND_SCALE, STAND_SCALE)
		_apply_facing(_facing)
		_sprite.play(&"idle")
	_shot_timer = randf_range(1.8, 3.0) if bounty_bandit else randf_range(3.0, 5.0)


func _kill_pose_tween() -> void:
	EnemyContact.kill_tween(_pose_tween)
	_pose_tween = null


func _show_floor_bound_pose() -> void:
	if _sprite == null:
		return
	_kill_pose_tween()
	_sprite.pause()
	var path: String
	if LevelStyle.is_cave(_level_style):
		path = (
			"res://assets/world/skeleton_crystal_tied.png"
			if bounty_bandit
			else "res://assets/world/skeleton_tied.png"
		)
	else:
		path = (
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
	# Desert tied art is taller (~130px); cave skeletons share the 64×80 idle canvas.
	if LevelStyle.is_cave(_level_style):
		_sprite.scale = Vector2(STAND_SCALE * face, STAND_SCALE)
		_sprite.offset = STAND_FOOT_OFFSET
	else:
		_sprite.scale = Vector2(TIED_SCALE * face, TIED_SCALE)
		_sprite.offset = TIED_FOOT_OFFSET
	_sprite.play(&"tied")


func _can_shoot_at(player: Player) -> bool:
	var dy := player.global_position.y - global_position.y
	if absf(dy) <= SHOOT_Y_BAND:
		return true
	# Cave bow skeletons loft arrows at flyers / high jumpers above them.
	if not LevelStyle.is_cave(_level_style):
		return false
	if dy >= -SHOOT_UP_MIN or dy < -SHOOT_UP_REACH:
		return false
	var modes := player.get_modes()
	return modes != null and modes.is_flying()


func _aim_up_at(player: Player) -> bool:
	if not LevelStyle.is_cave(_level_style):
		return false
	if player.global_position.y >= global_position.y - SHOOT_UP_MIN:
		return false
	var modes := player.get_modes()
	return modes != null and modes.is_flying()


func _shoot_at(player: Player) -> void:
	if _tied or _shooting:
		return
	_shooting = true
	_shot_generation += 1
	var shot_id := _shot_generation
	_facing = 1.0 if player.global_position.x >= global_position.x else -1.0
	_apply_facing(_facing)
	var cave := LevelStyle.is_cave(_level_style)
	var aim_up := _aim_up_at(player)
	if _sprite != null:
		if aim_up and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(&"shoot_up"):
			_sprite.play(&"shoot_up")
		else:
			_sprite.play(&"idle")
	if _revolver != null:
		if cave:
			_revolver.hide_gun()
		else:
			_revolver.show_aim(_facing)
	if _label != null:
		_label.text = "LOOK OUT!"
		_label.modulate = Color(0.9, 0.16, 0.05, 1.0)
	await get_tree().create_timer(0.45).timeout
	if shot_id != _shot_generation or _tied:
		_shooting = false
		return
	if _revolver != null and not cave:
		_revolver.show_flash()
	var bullet := BanditBullet.new()
	bullet.name = "BanditBullet"
	var aim := Vector2(_facing, 0.0)
	var muzzle := Vector2(36.0 * _facing, -39.0)
	if aim_up:
		var to_player := player.global_position - global_position
		# Prefer lofting toward the cowboy; fall back to a steep facing-biased arc.
		if to_player.y < -20.0:
			aim = to_player.normalized()
		else:
			aim = Vector2(_facing * 0.28, -1.0).normalized()
		muzzle = Vector2(8.0 * _facing, -70.0)
	bullet.setup(_facing, cave, aim if cave else Vector2.ZERO)
	bullet.hurt_player.connect(func(hit_player: Player) -> void: hurt_player.emit(hit_player))
	get_parent().add_child(bullet)
	bullet.global_position = global_position + muzzle
	await get_tree().create_timer(0.25).timeout
	if shot_id != _shot_generation:
		_shooting = false
		return
	if _revolver != null:
		_revolver.hide_gun()
	if not _tied:
		_shooting = false
		if _sprite != null and _sprite.animation == &"shoot_up":
			_sprite.play(&"idle")
		if _label != null:
			_label.text = (
				"BOUNTY!" if bounty_bandit else ("SKELETON" if cave else "BANDIT")
			)
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
		_label.text = "BOUNTY!" if bounty_bandit else ("SKELETON" if LevelStyle.is_cave(_level_style) else "BANDIT")
		_label.modulate = Color(1, 1, 1, 1)
		_label.add_theme_font_size_override(&"font_size", 13)


func _find_nearby_player(radius: float) -> Player:
	return PlayerLookup.find_in_tree(self, radius)


func _resolve_player_overlap() -> void:
	# Runs every physics frame so ANY contact resolves, even if the player first
	# overlapped while briefly invulnerable (a body_entered check alone would miss
	# that and let the cowboy walk through the bandit unharmed).
	if _tied or _area == null:
		return
	for body in _area.get_overlapping_bodies():
		if body is Player:
			if _handle_player_contact(body as Player):
				return


func _handle_player_contact(player: Player) -> bool:
	# Top contact ties the bandit; any other contact sends the cowboy to camp.
	if _tied:
		return false
	if EnemyContact.is_head_stomp(self, player, 24.0):
		tie_up()
		EnemyContact.bounce_after_stomp(player)
		return true
	if player.is_invulnerable():
		return false
	hurt_player.emit(player)
	return true


func _on_body_entered(body: Node2D) -> void:
	# Immediate response on entry; the per-frame overlap check is the safety net.
	if _tied:
		return
	if body is Player:
		_handle_player_contact(body as Player)
