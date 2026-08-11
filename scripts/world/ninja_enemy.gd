class_name NinjaEnemy
extends AnimatableBody2D

## Ambush foe: pops in ahead of the cowboy, charges with a sword, throws stars at flyers.

signal hurt_player(player: Player)
signal captured(ninja: NinjaEnemy)

enum State { DORMANT, APPEAR, CHASE, JUMP, ATTACK, THROW, TIED }

const STAND_SCALE := 1.15
## Tied art is the same 64×80 frame as idle — keep standing size so he does not shrink.
const STAND_FOOT_OFFSET := Vector2(0, -40)
const SPAWN_AHEAD := 480.0
const TRIGGER_RANGE := 1040.0
const CHASE_SPEED := 170.0
const MELEE_RANGE := 34.0
const SHURIKEN_RANGE := 640.0
const SHURIKEN_COOLDOWN := 1.35
## Clear pits (~128px) and typical canyon mouths (~320px) toward the cowboy.
const JUMP_MAX_GAP := 360.0
const JUMP_PROBE_STEP := 16.0
const JUMP_SPEED_X := 260.0
## Used only until a cowboy is in the scene to read the real jump tuning from.
const FALLBACK_JUMP_VELOCITY := -500.0
const FALLBACK_GRAVITY := 1350.0
## Height difference that reads as a real ledge rather than trail bumpiness.
const LEDGE_STEP_MIN := 24.0
## How far ahead to look for a plank lip when the cowboy is overhead.
const LEDGE_SCAN_RUN := 140.0
## Smallest arc a hop may use, so short steps still look like jumps.
const JUMP_ARC_MIN := 26.0

## Workshop live preview only: keep the idle sprite at the stamp so kids see the ambush post.
## Real levels and play-test leave this false — dormancy stays fully hidden until ambush.
@export var editor_marker: bool = false

var _anchor: Vector2
var _facing: float = 1.0
var _area: Area2D
var _label: Label
var _sprite: AnimatedSprite2D
var _hint_phase: float = 0.0
var _tied: bool = false
var _state: State = State.DORMANT
var _activated: bool = false
var _attack_token: int = 0
var _throw_token: int = 0
var _jump_token: int = 0
var _appear_token: int = 0
var _throw_timer: float = 0.0
## Vertical reach of a hop — kept equal to the cowboy's own jump apex.
var _jump_reach: float = StarReachability.max_jump_height(FALLBACK_JUMP_VELOCITY, FALLBACK_GRAVITY)
var _jump_lift: float = 0.0
var _pose_tween: Tween
var _jump_tween: Tween
var _appear_tween: Tween
var _player_ref: Player
var _hint_near: int = -1
var _ledge_scan_cooldown: float = 0.0
static var _shared_frames: SpriteFrames


func _ready() -> void:
	# Drive ambush/chase/jump teleports from script; sync_to_physics would keep the
	# old physics transform for a frame (or snap back after a brief sync toggle).
	sync_to_physics = false
	_anchor = global_position
	_area = get_node_or_null("HurtArea") as Area2D
	_label = get_node_or_null("Label") as Label
	if _label != null:
		_label.visible = false
	_setup_sprite()
	_set_dormant(true)
	if editor_marker:
		## Marker stays idle at the stamp; never ambush or take damage in the preview.
		set_physics_process(false)
		set_process(false)
		collision_layer = 0
		collision_mask = 0
	if _area != null:
		_area.body_entered.connect(_on_body_entered)


func _setup_sprite() -> void:
	# Free every prior draw node. Leaving the scene Sprite2D hidden (instead of
	# removed) sometimes showed it again beside the animated sprite — two ninjas
	# facing opposite ways when one was flipped.
	var stale: Array[Node] = []
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			if String(child.name) in ["NinjaSprite", "Sprite2D", "WalkSprite"]:
				stale.append(child)
	for child in stale:
		child.free()
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "NinjaSprite"
	_sprite.sprite_frames = _make_sprite_frames()
	_sprite.centered = true
	_sprite.offset = STAND_FOOT_OFFSET
	_sprite.scale = Vector2(STAND_SCALE, STAND_SCALE)
	_apply_facing(1.0)
	_sprite.play(&"idle")
	add_child(_sprite)


func _make_sprite_frames() -> SpriteFrames:
	if _shared_frames != null:
		return _shared_frames
	var frames := SpriteFrames.new()
	for anim_data in [
		[&"idle", 1.0, true, ["res://assets/world/ninja_idle.png"]],
		[&"run", 10.0, true, [
			"res://assets/world/ninja_run_0.png",
			"res://assets/world/ninja_idle.png",
			"res://assets/world/ninja_run_1.png",
			"res://assets/world/ninja_idle.png",
		]],
		[&"sword", 12.0, false, [
			"res://assets/world/ninja_sword_0.png",
			"res://assets/world/ninja_sword_1.png",
		]],
		[&"throw", 10.0, false, [
			"res://assets/world/ninja_throw_0.png",
			"res://assets/world/ninja_throw_1.png",
		]],
		[&"jump", 10.0, true, [
			"res://assets/world/ninja_jump_0.png",
			"res://assets/world/ninja_jump_1.png",
			"res://assets/world/ninja_jump_1.png",
		]],
		[&"tied", 1.0, false, ["res://assets/world/ninja_tied.png"]],
	]:
		var anim: StringName = anim_data[0]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, anim_data[1])
		frames.set_animation_loop(anim, anim_data[2])
		for path in anim_data[3]:
			var tex: Texture2D = load(str(path))
			if tex != null:
				frames.add_frame(anim, tex)
	_shared_frames = frames
	return _shared_frames


func _set_dormant(hidden: bool) -> void:
	if hidden:
		_state = State.DORMANT
		## Editor markers stay readable; gameplay dormancy stays invisible.
		modulate.a = 1.0 if editor_marker else 0.0
		set_process(false)
		_hint_near = -1
		if _area != null:
			_area.set_deferred("monitoring", false)
			_area.set_deferred("monitorable", false)
	else:
		modulate.a = 1.0
		set_process(true)
		if _area != null:
			_area.set_deferred("monitoring", true)
			_area.set_deferred("monitorable", true)


func _process(delta: float) -> void:
	_hint_phase += delta * 4.0
	if _tied or _state == State.DORMANT:
		return
	_update_nearby_hint()


func _physics_process(delta: float) -> void:
	if _tied:
		return
	if _state == State.DORMANT:
		_try_activate()
		return
	if _state == State.ATTACK or _state == State.THROW or _state == State.APPEAR:
		return
	if _state == State.JUMP:
		return
	var player := _find_player()
	if player == null:
		if _state == State.CHASE:
			_set_move_animation(false)
		return
	# Only poll overlaps when close enough for stomp/side contact.
	if global_position.distance_squared_to(player.global_position) <= 6400.0:
		_resolve_player_overlap()
		if _tied:
			return
	_jump_reach = StarReachability.max_jump_height(player.jump_velocity, player.gravity)
	_ledge_scan_cooldown = maxf(0.0, _ledge_scan_cooldown - delta)
	if player.get_modes().is_flying():
		_handle_flying_player(player, delta)
	else:
		_handle_ground_player(player, delta)


func _try_activate() -> void:
	if editor_marker or _activated:
		return
	var player := _find_player()
	if player == null:
		return
	if global_position.distance_to(player.global_position) > TRIGGER_RANGE:
		return
	if global_position.distance_to(_anchor) > TRIGGER_RANGE + 40.0:
		return
	_activated = true
	_appear_in_front_of(player)


func _appear_in_front_of(player: Player) -> void:
	_state = State.APPEAR
	_appear_token += 1
	var token := _appear_token
	var facing := _player_facing(player)
	var spawn_x := player.global_position.x + facing * SPAWN_AHEAD
	## Prefer solid crust near the cowboy's height — theme dirt alone can drop onto a lower bank.
	var probe_from := Vector2(spawn_x, player.global_position.y - 8.0)
	var physics_y := FloorProbe.nearest_floor_y(self, probe_from, 8.0, 160.0, 80.0)
	var theme_y := _walk_surface_y(spawn_x, player.global_position.y)
	var spawn_y := theme_y
	if not is_nan(physics_y):
		spawn_y = (
			theme_y
			if absf(theme_y - physics_y) <= 28.0
			else physics_y
		)
	global_position = Vector2(spawn_x, spawn_y)
	_facing = -facing
	_apply_facing(_facing)
	_set_dormant(false)
	modulate.a = 0.0
	_kill_appear_tween()
	_appear_tween = create_tween()
	_appear_tween.tween_property(self, "modulate:a", 1.0, 0.16)
	_appear_tween.tween_callback(func() -> void:
		if token != _appear_token or _tied or _state != State.APPEAR:
			return
		_state = State.CHASE
		_set_move_animation(true)
	)


func _player_facing(player: Player) -> float:
	if absf(player.velocity.x) > 8.0:
		return 1.0 if player.velocity.x >= 0.0 else -1.0
	var sprite := player.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		return -1.0 if sprite.flip_h else 1.0
	return 1.0 if player.global_position.x >= _anchor.x else -1.0


func _walk_surface_y(world_x: float, fallback_y: float) -> float:
	var level := _theme_level()
	if level != null:
		var surface := WildWestTheme.walk_surface_at(level, world_x)
		if surface.has("y"):
			return float(surface["y"])
	return fallback_y


func _theme_level() -> Node:
	## Prefer the owning level so slope height works in tests and nested scenes.
	var node: Node = self
	while node != null:
		if node is LevelController:
			return node
		node = node.get_parent()
	return get_tree().current_scene if get_tree() != null else null


func _snap_feet_to_surface() -> void:
	## Keep boots on dune crust / flat dirt — chase used to only move in X.
	if _tied or _state == State.JUMP or _state == State.APPEAR:
		return
	var hit_y := _floor_hit_y(global_position.x, global_position.y)
	if not is_inf(hit_y):
		# Prefer the physics hit; only blend theme slope when it stays close.
		var theme_y := _walk_surface_y(global_position.x, hit_y)
		global_position.y = theme_y if absf(theme_y - hit_y) <= 28.0 else hit_y
		return
	## No nearby physics floor — do not yank onto a distant lower bank via theme.
	var theme_y := _walk_surface_y(global_position.x, global_position.y)
	if absf(theme_y - global_position.y) <= 40.0:
		global_position.y = theme_y


func _handle_ground_player(player: Player, delta: float) -> void:
	_facing = 1.0 if player.global_position.x >= global_position.x else -1.0
	var dist := global_position.distance_to(player.global_position)
	if dist <= MELEE_RANGE:
		_begin_sword_attack(player)
		_snap_feet_to_surface()
		return
	# Only run the expensive multi-ray gap scan when the lip is near.
	if (
		_gap_is_imminent(_facing)
		and signf(player.global_position.x - global_position.x) == _facing
	):
		var landing := _find_gap_landing(_facing)
		if not landing.is_empty():
			_begin_gap_jump(landing)
			return
	if (
		player.global_position.y < global_position.y - LEDGE_STEP_MIN
		and _ledge_scan_cooldown <= 0.0
	):
		_ledge_scan_cooldown = 0.12
		var ledge := _find_ledge_landing(_facing)
		if not ledge.is_empty():
			_begin_gap_jump(ledge)
			return
	if FloorProbe.has_floor_ahead(self, _facing):
		_chase_along_trail(player, delta)
		return
	if player.global_position.y > global_position.y + LEDGE_STEP_MIN:
		var drop := _find_drop_landing(_facing)
		if not drop.is_empty():
			_begin_gap_jump(drop)
			return
	_snap_feet_to_surface()
	_set_move_animation(false)


func _gap_is_imminent(direction: float) -> bool:
	## True when open air starts within about one chase stride (lip of pit/canyon).
	if not FloorProbe.has_floor_ahead(self, direction):
		return true
	var dir := signf(direction)
	var stride_x := global_position.x + dir * 32.0
	return is_inf(_floor_hit_y(stride_x, global_position.y))


func _floor_hit_y(world_x: float, from_y: float, max_drop: float = FloorProbe.SAME_BANK_DROP) -> float:
	## Default drop stays on the current plank/bank. Pass a larger max_drop when
	## scanning for a jump landing on a lower ledge or far canyon bank.
	var hit := FloorProbe.nearest_floor_y(
		self,
		Vector2(world_x, from_y),
		48.0,
		maxf(96.0, max_drop + 8.0),
		max_drop
	)
	return INF if is_nan(hit) else hit


func _find_gap_landing(direction: float) -> Dictionary:
	## Scan ahead for open air, then the first solid bank within jump reach.
	var dir := signf(direction)
	if is_zero_approx(dir):
		return {}
	var start_x := global_position.x
	var start_y := global_position.y
	var found_gap := false
	var x := start_x + dir * JUMP_PROBE_STEP
	var end_x := start_x + dir * JUMP_MAX_GAP
	while (dir > 0.0 and x <= end_x) or (dir < 0.0 and x >= end_x):
		var hit_y := _floor_hit_y(x, start_y, _jump_reach)
		if is_inf(hit_y):
			found_gap = true
		elif found_gap:
			# Physics hit is enough for gap landings; avoid theme scans per probe.
			if start_y - hit_y <= _jump_reach:
				return {"x": x, "y": hit_y}
			return {}
		x += dir * JUMP_PROBE_STEP
	return {}


func _find_ledge_landing(direction: float) -> Dictionary:
	## Nearest plank/ledge lip ahead that sits inside the cowboy's own jump apex,
	## so any plank he can hop onto the ninja can follow him onto.
	var dir := signf(direction)
	if is_zero_approx(dir):
		return {}
	var x := global_position.x
	var end_x := x + dir * LEDGE_SCAN_RUN
	while (dir > 0.0 and x <= end_x) or (dir < 0.0 and x >= end_x):
		var top_y := _ledge_top_y(x)
		if not is_inf(top_y):
			return {"x": x, "y": top_y}
		x += dir * JUMP_PROBE_STEP
	return {}


func _ledge_top_y(world_x: float) -> float:
	## Top of the first surface standing above the ninja's boots but within reach.
	var world := get_world_2d()
	if world == null:
		return INF
	var from := Vector2(world_x, global_position.y - _jump_reach)
	var to := Vector2(world_x, global_position.y - LEDGE_STEP_MIN)
	if from.y >= to.y:
		return INF
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	query.exclude = [get_rid()]
	var hit := world.direct_space_state.intersect_ray(query)
	# Only a top face is standable; a wall flank would drop him back off.
	if hit.is_empty() or float(hit["normal"].y) > -0.5:
		return INF
	return float(hit["position"].y)


func _find_drop_landing(direction: float) -> Dictionary:
	## Step off a plank lip onto the surface below instead of stalling up there.
	var dir := signf(direction)
	if is_zero_approx(dir):
		return {}
	var start_y := global_position.y
	var x := global_position.x + dir * JUMP_PROBE_STEP
	var end_x := global_position.x + dir * JUMP_MAX_GAP
	while (dir > 0.0 and x <= end_x) or (dir < 0.0 and x >= end_x):
		var hit_y := _floor_hit_y(x, start_y, _jump_reach)
		if not is_inf(hit_y) and hit_y - start_y >= LEDGE_STEP_MIN:
			return {"x": x, "y": hit_y}
		x += dir * JUMP_PROBE_STEP
	return {}


func _begin_gap_jump(landing: Dictionary) -> void:
	if _state == State.JUMP:
		return
	_state = State.JUMP
	_jump_token += 1
	var token := _jump_token
	_kill_jump_tween()
	_apply_facing(_facing)
	if _sprite != null:
		_sprite.play(&"jump")
	var start := global_position
	var land := Vector2(float(landing["x"]), float(landing["y"]))
	# Arc peaks one cowboy-jump above take-off, whatever the lip height.
	_jump_lift = maxf(_jump_reach - maxf(start.y - land.y, 0.0) * 0.5, JUMP_ARC_MIN)
	var dist := absf(land.x - start.x)
	var duration := clampf(dist / JUMP_SPEED_X, 0.32, 1.2)
	_jump_tween = create_tween()
	_jump_tween.tween_method(_jump_arc.bind(token, start, land), 0.0, 1.0, duration)
	_jump_tween.tween_callback(_finish_gap_jump.bind(token, land))


func _jump_arc(t: float, token: int, start: Vector2, land: Vector2) -> void:
	if token != _jump_token or _tied or _state != State.JUMP:
		return
	var x := lerpf(start.x, land.x, t)
	var base_y := lerpf(start.y, land.y, t)
	var lift := 4.0 * _jump_lift * t * (1.0 - t)
	global_position = Vector2(x, base_y - lift)


func _finish_gap_jump(token: int, land: Vector2) -> void:
	if token != _jump_token or _tied or _state != State.JUMP:
		return
	global_position = land
	_snap_feet_to_surface()
	_state = State.CHASE
	_set_move_animation(true)


func _handle_flying_player(player: Player, delta: float) -> void:
	## Keep chasing under a winged cowboy between throws — never freeze in place.
	_throw_timer -= delta
	var dx := player.global_position.x - global_position.x
	_facing = 1.0 if dx >= 0.0 else -1.0
	if _throw_timer > 0.0 or absf(dx) > 28.0:
		_chase_along_trail(player, delta)
	else:
		_apply_facing(_facing)
		_snap_feet_to_surface()
		_set_move_animation(false)
	if _throw_timer > 0.0:
		return
	if global_position.distance_to(player.global_position) > SHURIKEN_RANGE:
		return
	if absf(player.global_position.y - global_position.y) > SHURIKEN_RANGE:
		return
	_begin_throw(player)


func _chase_along_trail(player: Player, delta: float) -> void:
	## Shared ground chase step used vs grounded and flying targets.
	if (
		_gap_is_imminent(_facing)
		and signf(player.global_position.x - global_position.x) == _facing
	):
		var landing := _find_gap_landing(_facing)
		if not landing.is_empty():
			_begin_gap_jump(landing)
			return
	if FloorProbe.has_floor_ahead(self, _facing):
		_apply_facing(_facing)
		global_position.x += _facing * CHASE_SPEED * delta
		_snap_feet_to_surface()
		_set_move_animation(true)
		return
	_snap_feet_to_surface()
	_set_move_animation(false)


func _begin_sword_attack(player: Player) -> void:
	if _state == State.ATTACK:
		return
	_state = State.ATTACK
	_attack_token += 1
	var token := _attack_token
	_set_move_animation(false)
	if _sprite != null:
		_sprite.play(&"sword")
	if _label != null:
		_label.text = "SLASH!"
		_label.modulate = Color(0.95, 0.2, 0.12, 1.0)
	await get_tree().create_timer(0.12).timeout
	if token != _attack_token or _tied or _state != State.ATTACK:
		return
	if player != null and global_position.distance_to(player.global_position) <= MELEE_RANGE + 8.0:
		if not player.is_invulnerable():
			hurt_player.emit(player)
	await get_tree().create_timer(0.18).timeout
	if token != _attack_token or _tied or _state != State.ATTACK:
		return
	_state = State.CHASE
	if _label != null:
		_label.text = "NINJA"
		_label.modulate = Color.WHITE


func _begin_throw(player: Player) -> void:
	if _state == State.THROW:
		return
	_state = State.THROW
	_throw_token += 1
	var token := _throw_token
	_facing = 1.0 if player.global_position.x >= global_position.x else -1.0
	_apply_facing(_facing)
	if _sprite != null:
		_sprite.play(&"throw")
	if _label != null:
		_label.text = "STARS!"
		_label.modulate = Color(0.85, 0.9, 1.0, 1.0)
	await get_tree().create_timer(0.14).timeout
	if token != _throw_token or _tied or _state != State.THROW:
		return
	_spawn_shuriken(player)
	_throw_timer = SHURIKEN_COOLDOWN
	await get_tree().create_timer(0.16).timeout
	if token != _throw_token or _tied or _state != State.THROW:
		return
	_state = State.CHASE
	if _label != null:
		_label.text = "NINJA"
		_label.modulate = Color.WHITE


func _spawn_shuriken(player: Player) -> void:
	var star := NinjaShuriken.new()
	star.name = "NinjaShuriken"
	star.hurt_player.connect(func(hit_player: Player) -> void: hurt_player.emit(hit_player))
	var parent := get_parent()
	if parent == null:
		star.queue_free()
		return
	parent.add_child(star)
	var from := global_position + Vector2(18.0 * _facing, -36.0)
	var lead := player.velocity * 0.18
	star.global_position = from
	star.setup(player.global_position + lead, from)


func _apply_facing(direction: float) -> void:
	if _sprite == null:
		return
	# Mirror with flip_h only — never negate scale.x, or a tying squash tween can
	# leave a second mirrored silhouette beside the live pose.
	_sprite.flip_h = direction < 0.0
	_sprite.scale.x = absf(_sprite.scale.x)
	_sprite.scale.y = absf(_sprite.scale.y)


func _set_move_animation(moving: bool) -> void:
	if _sprite == null or _tied:
		return
	if _state == State.ATTACK or _state == State.THROW or _state == State.JUMP:
		return
	if moving:
		if _sprite.animation != &"run" or not _sprite.is_playing():
			_sprite.play(&"run")
	elif _sprite.animation != &"idle" or not _sprite.is_playing():
		_sprite.play(&"idle")


func is_tied() -> bool:
	return _tied


func tie_up(_award_bounty: bool = true) -> void:
	if _tied:
		return
	_tied = true
	_state = State.TIED
	_attack_token += 1
	_throw_token += 1
	_jump_token += 1
	_kill_jump_tween()
	collision_layer = 0
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", false)
		_area.set_deferred("monitorable", false)
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", true)
	_show_tied_pose()
	TiedBanditOverlay.ensure_attached(self, self)
	z_index = -1
	if _label != null:
		_label.text = "TIED!"
		_label.modulate = Color(0.55, 0.25, 0.06, 1.0)
		_label.position.y = -78.0
	_play_tying_flourish()
	captured.emit(self)


func _show_tied_pose() -> void:
	if _sprite == null:
		return
	_kill_pose_tween()
	_sprite.play(&"tied")
	# Same frame size as idle — keep standing scale and foot offset so he sits on the trail.
	_sprite.offset = STAND_FOOT_OFFSET
	_sprite.scale = Vector2(STAND_SCALE, STAND_SCALE)


func _play_tying_flourish() -> void:
	if _sprite == null:
		return
	_kill_pose_tween()
	_pose_tween = create_tween()
	_pose_tween.tween_property(_sprite, "scale", Vector2(STAND_SCALE * 1.08, STAND_SCALE * 0.72), 0.1)
	_pose_tween.tween_property(_sprite, "scale", Vector2(STAND_SCALE, STAND_SCALE), 0.14)


func untie_for_respawn() -> void:
	if not _tied:
		return
	_tied = false
	TiedBanditOverlay.remove_from(self)
	_return_to_dormant_anchor()


func restore_for_respawn() -> void:
	## Untied ninjas that already ambushed (or are mid jump/slash) return to dormancy.
	## Shuriken are cleared separately by the level controller.
	if _tied:
		return
	_return_to_dormant_anchor()


func _return_to_dormant_anchor() -> void:
	## Cancel appear/chase/jump/slash work and hide back at the stamp post.
	_appear_token += 1
	_attack_token += 1
	_throw_token += 1
	_jump_token += 1
	_throw_timer = 0.0
	_activated = false
	_kill_pose_tween()
	_kill_jump_tween()
	_kill_appear_tween()
	_state = State.DORMANT
	collision_layer = 0
	z_index = 0
	visible = true
	global_position = _anchor
	_facing = 1.0
	_set_dormant(true)
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.set_deferred("disabled", true)
	if _area != null:
		_area.set_deferred("monitoring", false)
		_area.set_deferred("monitorable", false)
	var hurt_shape := get_node_or_null("HurtArea/CollisionShape2D") as CollisionShape2D
	if hurt_shape != null:
		hurt_shape.set_deferred("disabled", false)
	_setup_sprite()
	_apply_facing(_facing)
	if _label != null:
		_label.position.y = 0.0
		_label.text = "NINJA"
		_label.modulate = Color.WHITE


func _kill_pose_tween() -> void:
	EnemyContact.kill_tween(_pose_tween)
	_pose_tween = null


func _kill_jump_tween() -> void:
	EnemyContact.kill_tween(_jump_tween)
	_jump_tween = null


func _kill_appear_tween() -> void:
	EnemyContact.kill_tween(_appear_tween)
	_appear_tween = null


func _update_nearby_hint() -> void:
	if _label == null:
		return
	var player := _find_player()
	var near := player != null and global_position.distance_to(player.global_position) <= 180.0
	var mode := 1 if near else 0
	if mode != _hint_near:
		_hint_near = mode
		if near:
			_label.text = "JUMP!"
			_label.add_theme_font_size_override(&"font_size", 16)
		else:
			_label.text = "NINJA"
			_label.modulate = Color(1, 1, 1, 1)
			_label.add_theme_font_size_override(&"font_size", 13)
	if near:
		_label.modulate = Color(1.0, 0.85 + sin(_hint_phase) * 0.15, 0.2, 1.0)


func _find_player() -> Player:
	if is_instance_valid(_player_ref):
		return _player_ref
	_player_ref = PlayerLookup.find_in_tree(self)
	return _player_ref


func _resolve_player_overlap() -> void:
	if _tied or _area == null or not _area.monitoring:
		return
	for body in _area.get_overlapping_bodies():
		if body is Player:
			if _handle_player_contact(body as Player):
				return


func _handle_player_contact(player: Player) -> bool:
	if _tied or _state == State.DORMANT:
		return false
	if EnemyContact.is_head_stomp(self, player, 24.0):
		tie_up()
		EnemyContact.bounce_after_stomp(player)
		return true
	if player.is_invulnerable():
		return false
	if _state != State.ATTACK:
		hurt_player.emit(player)
	return true


func _on_body_entered(body: Node2D) -> void:
	if _tied or _state == State.DORMANT:
		return
	if body is Player:
		_handle_player_contact(body as Player)
