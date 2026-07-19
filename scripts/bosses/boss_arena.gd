class_name BossArena
extends Node2D

## Shared boss-arena helpers: countdown, soft fail, toast, exit.

@export var source_level: int = 3
@export var boss_title: String = "Boss"

signal combat_started

var player: Player
var hud: Hud
var _won: bool = false
var combat_ready: bool = false
var _next_boss_tap_time_msec: int = -1000
var _countdown_layer: CanvasLayer


func _ready() -> void:
	player = find_child("Player", true, false) as Player
	hud = find_child("Hud", true, false) as Hud
	WildWestTheme.apply_to_level(self)
	if player != null:
		WildWestTheme.configure_player_camera(self, player)
		player.set_input_enabled(false)
	if hud != null:
		hud.show_toast(boss_title, 2.4)
	_run_countdown()


func _process(_delta: float) -> void:
	if _won:
		return
	if Input.is_action_just_pressed(&"next_boss"):
		_handle_next_boss_tap()


func _run_countdown() -> void:
	combat_ready = false
	_countdown_layer = CanvasLayer.new()
	_countdown_layer.layer = 80
	add_child(_countdown_layer)
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -160.0
	label.offset_top = -80.0
	label.offset_right = 160.0
	label.offset_bottom = 80.0
	label.add_theme_font_size_override(&"font_size", 96)
	label.add_theme_color_override(&"font_color", Color(0.95, 0.85, 0.35, 1))
	label.add_theme_color_override(&"font_outline_color", Color(0.25, 0.1, 0.05, 1))
	label.add_theme_constant_override(&"outline_size", 8)
	_countdown_layer.add_child(label)
	for n in ["3", "2", "1", "GO!"]:
		label.text = n
		label.modulate = Color(1, 1, 1, 1)
		label.scale = Vector2(0.7, 0.7)
		var tween := create_tween()
		tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3).set_trans(Tween.TRANS_BACK)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.5)
		await get_tree().create_timer(0.85).timeout
	if is_instance_valid(_countdown_layer):
		_countdown_layer.queue_free()
	combat_ready = true
	if player != null and not _won:
		player.set_input_enabled(true)
	combat_started.emit()


func _handle_next_boss_tap() -> void:
	var now := Time.get_ticks_msec()
	if now - _next_boss_tap_time_msec <= 450:
		GameManager.load_next_boss(source_level)
		return
	_next_boss_tap_time_msec = now
	if hud != null:
		hud.show_toast("Press numpad - again for next boss", 1.0)


func report_progress(text: String) -> void:
	if hud != null:
		hud.show_toast(text, 1.8)


func win_boss() -> void:
	if _won:
		return
	_won = true
	combat_ready = false
	if player != null:
		player.set_input_enabled(false)
	if hud != null:
		hud.show_toast("Boss cleared!", 2.0)
	await get_tree().create_timer(1.4).timeout
	GameManager.finish_boss(source_level)


func fail_soft() -> void:
	if _won or player == null or not combat_ready:
		return
	var spawn := find_child("SpawnPoint", true, false) as Marker2D
	if spawn != null:
		player.respawn_at(spawn.global_position)
	if hud != null:
		hud.show_toast("Try again!", 1.4)


func restart_boss() -> void:
	get_tree().reload_current_scene()
