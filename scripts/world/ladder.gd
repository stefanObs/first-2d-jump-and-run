class_name Ladder
extends Area2D

## Vertical climb zone. Space / W / Up climbs up; S / Down climbs down.

const LADDER_TEX := preload("res://assets/world/ladder.png")
const GRID := 40.0
const DEFAULT_HEIGHT_CELLS := 3


@export var height_cells: int = DEFAULT_HEIGHT_CELLS

var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = true
	add_to_group("ladder")
	_ensure_visual()
	_ensure_shape()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func climb_top_y() -> float:
	return global_position.y - float(height_cells) * GRID


func climb_bottom_y() -> float:
	return global_position.y


func center_x() -> float:
	return global_position.x


func contains_player_y(player_y: float, slack: float = 12.0) -> bool:
	return player_y <= climb_bottom_y() + slack and player_y >= climb_top_y() - slack


func _ensure_visual() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite2D"
		add_child(_sprite)
	_sprite.texture = LADDER_TEX
	_sprite.centered = false
	var tex_h := float(LADDER_TEX.get_height()) if LADDER_TEX != null else 120.0
	var tex_w := float(LADDER_TEX.get_width()) if LADDER_TEX != null else 48.0
	var target_h := float(height_cells) * GRID
	_sprite.scale = Vector2(1.0, target_h / maxf(tex_h, 1.0))
	_sprite.position = Vector2(-tex_w * 0.5, -target_h)


func _ensure_shape() -> void:
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape2D"
		add_child(shape_node)
	var rect := RectangleShape2D.new()
	var h := float(height_cells) * GRID
	rect.size = Vector2(36.0, h)
	shape_node.shape = rect
	shape_node.position = Vector2(0.0, -h * 0.5)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).register_ladder(self)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		(body as Player).unregister_ladder(self)
