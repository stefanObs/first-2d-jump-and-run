class_name BossArena
extends Node2D

## Shared boss-arena helpers: soft fail, toast, exit to next trail or victory.

@export var source_level: int = 3
@export var boss_title: String = "Boss"

var player: Player
var hud: Hud
var _won: bool = false


func _ready() -> void:
	player = find_child("Player", true, false) as Player
	hud = find_child("Hud", true, false) as Hud
	WildWestTheme.apply_to_level(self)
	if player != null:
		WildWestTheme.configure_player_camera(self, player)
	if hud != null:
		hud.show_toast(boss_title, 2.4)


func report_progress(text: String) -> void:
	if hud != null:
		hud.show_toast(text, 1.8)


func win_boss() -> void:
	if _won:
		return
	_won = true
	if player != null:
		player.set_input_enabled(false)
	if hud != null:
		hud.show_toast("Boss cleared!", 2.0)
	await get_tree().create_timer(1.4).timeout
	GameManager.finish_boss(source_level)


func fail_soft() -> void:
	if _won or player == null:
		return
	var spawn := find_child("SpawnPoint", true, false) as Marker2D
	if spawn != null:
		player.respawn_at(spawn.global_position)
	if hud != null:
		hud.show_toast("Try again!", 1.4)
