class_name MovingPlatform
extends AnimatableBody2D

enum VisualStyle {
	## Handmade wooden plank (default). Kept as RAFT for scene compatibility.
	RAFT,
	CLOUD,
}

@export var point_a: Vector2 = Vector2(-100, 0)
@export var point_b: Vector2 = Vector2(100, 0)
@export var move_speed: float = 60.0
@export var visual_style: VisualStyle = VisualStyle.RAFT
## Starts at point B and travels toward point A. Useful for paired platforms
## that share a period but begin at opposite endpoints.
@export var start_at_point_b: bool = false
## One-way platform: the cowboy jumps up through the plank/cloud from below and
## lands on top. Turn off only for platforms that must act as solid walls.
@export var one_way: bool = true
@export var one_way_margin: float = 8.0
## Reverse before the platform's collision box would sink into static terrain
## or another moving platform. Riders (player/bandits) never cause a turn.
@export var obstruction_turnaround: bool = true
## When false, other MovingPlatforms are ignored by obstruction sweeps so
## paired endpoint handoffs stay in sync (clouds approach by route, not bounce).
@export var obstruction_include_movers: bool = true

const PLANK_TEXTURE := preload("res://assets/world/wood_plank.png")
const CLOUD_TEXTURE := preload("res://assets/world/moving_cloud.svg")
## "world" physics layer holding floor/terrain and other moving platforms.
## The player is on the "player" layer and bandit bodies collide on no solid
## layer, so a layer-1 sweep naturally ignores every rider we must not turn on.
const OBSTRUCTION_MASK := 1
## Keep a small gap so shapes stop short of contact instead of overlapping.
const CONTACT_SEPARATION := 2.0
## Debounce so a platform cannot flip direction twice within a couple of frames.
const REVERSE_COOLDOWN := 0.12

var _origin: Vector2
var _to_b: bool = true
var _label: Label
var _shape: CollisionShape2D
var _raft_visual: Sprite2D
var _cloud_visual: Sprite2D
var _reverse_cooldown: float = 0.0


func _ready() -> void:
	add_to_group("moving_platforms")
	# We drive the transform every physics tick. Leaving sync_to_physics on
	# makes Godot discard non-physics (and some physics-frame) pose writes,
	# which silently broke start_at_point_b for paired clouds.
	sync_to_physics = false
	_origin = global_position
	if start_at_point_b:
		global_position = _origin + point_b
		_to_b = false
	_label = get_node_or_null("Label") as Label
	if _label != null:
		_label.visible = false
	_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	_raft_visual = get_node_or_null("Visual") as Sprite2D
	_cloud_visual = get_node_or_null("CloudVisual") as Sprite2D
	_configure_visual_style()
	_configure_one_way()
	_update_label()


func _configure_visual_style() -> void:
	if _raft_visual == null:
		_raft_visual = get_node_or_null("Visual") as Sprite2D
	if _cloud_visual == null:
		_cloud_visual = get_node_or_null("CloudVisual") as Sprite2D
	var cloud_style := visual_style == VisualStyle.CLOUD
	if _raft_visual != null:
		# Never leave the old ferry/raft cloud graphic on plank movers.
		if _raft_visual.texture == null or not _is_plank_texture(_raft_visual.texture):
			_raft_visual.texture = PLANK_TEXTURE
		_raft_visual.visible = not cloud_style
	if _cloud_visual != null:
		if _cloud_visual.texture == null:
			_cloud_visual.texture = CLOUD_TEXTURE
		_cloud_visual.visible = cloud_style


func _is_plank_texture(texture: Texture2D) -> bool:
	var path := texture.resource_path
	return path.ends_with("wood_plank.png") or path.ends_with("wood_plank.tres")


func _configure_one_way() -> void:
	# Enforce jump-through-from-below / land-on-top in code so the behaviour is
	# guaranteed even if the scene resource is edited or not reimported.
	if _shape == null:
		return
	_shape.one_way_collision = one_way
	_shape.one_way_collision_margin = one_way_margin


func is_one_way() -> bool:
	return _shape != null and _shape.one_way_collision


func is_cloud_style() -> bool:
	return visual_style == VisualStyle.CLOUD and _cloud_visual != null and _cloud_visual.visible


func travel_origin() -> Vector2:
	return _origin


func is_moving_toward_b() -> bool:
	return _to_b


func start_world_position() -> Vector2:
	return _origin + (point_b if start_at_point_b else point_a)


func _physics_process(delta: float) -> void:
	if _reverse_cooldown > 0.0:
		_reverse_cooldown = maxf(_reverse_cooldown - delta, 0.0)

	var target := _origin + (point_b if _to_b else point_a)
	var desired := global_position.move_toward(target, move_speed * delta)
	var motion := desired - global_position

	if obstruction_turnaround and _shape != null and motion.length_squared() > 0.0001:
		var step := _clip_motion(motion)
		global_position += step.motion
		# Blocked short of the intended step: we stopped before the overlap, so
		# turn back and let the next frames carry us away from the obstacle.
		if step.blocked:
			if _reverse_cooldown <= 0.0:
				_reverse()
			return
	else:
		global_position = desired

	if global_position.distance_to(target) < 2.0:
		_reverse()


## Sweep the platform's own collision box along the intended step against static
## terrain and other moving platforms (physics layer 1 only, so the player and
## bandit riders are ignored). Returns how far we may safely travel plus whether
## an obstruction cut the step short. We leave a real-world gap (not just a query
## margin) so the next frame is never "already touching", which would otherwise
## make Godot's cast_motion report a stuck [0, 0] and cause flip-flop jitter.
func _clip_motion(motion: Vector2) -> Dictionary:
	var world := get_world_2d()
	if world == null:
		return {"motion": motion, "blocked": false}
	var space := world.direct_space_state
	if space == null:
		return {"motion": motion, "blocked": false}
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = _shape.shape
	params.transform = _shape.global_transform
	params.motion = motion
	params.collision_mask = OBSTRUCTION_MASK
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.margin = 0.0
	params.exclude = _obstruction_exclude_rids()
	var fractions := space.cast_motion(params)
	# fractions[0] is the safe fraction of the motion before first contact.
	var safe := fractions[0] if fractions.size() > 0 else 1.0
	if safe >= 1.0:
		return {"motion": motion, "blocked": false}
	var distance := motion.length()
	var allowed := maxf(distance * safe - CONTACT_SEPARATION, 0.0)
	return {"motion": motion.normalized() * allowed, "blocked": true}


func _obstruction_exclude_rids() -> Array[RID]:
	var excluded: Array[RID] = [get_rid()]
	if obstruction_include_movers:
		return excluded
	# Paired clouds reverse at authored endpoints; bouncing off the partner
	# would desync the handoff.
	var tree := get_tree()
	if tree == null:
		return excluded
	for node in tree.get_nodes_in_group("moving_platforms"):
		if node == self or not (node is CollisionObject2D):
			continue
		excluded.append((node as CollisionObject2D).get_rid())
	return excluded


func _reverse() -> void:
	_to_b = not _to_b
	_reverse_cooldown = REVERSE_COOLDOWN
	_update_label()


func _update_label() -> void:
	if _label == null:
		return
	if visual_style == VisualStyle.CLOUD:
		_label.text = "CLOUD"
		return
	var delta := point_b - point_a
	if absf(delta.x) >= absf(delta.y):
		_label.text = "PLANK >>" if (_to_b and delta.x >= 0.0) or (not _to_b and delta.x < 0.0) else "<< PLANK"
	else:
		_label.text = "PLANK"

func is_plank_style() -> bool:
	return visual_style != VisualStyle.CLOUD and _raft_visual != null and _raft_visual.visible and _is_plank_texture(_raft_visual.texture)
