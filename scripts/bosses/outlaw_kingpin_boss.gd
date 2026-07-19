extends BossArena

## Outlaw Kingpin: tie bodyguards first, then lasso the boss during telegraph.

const KING_TEX := preload("res://assets/world/boss_outlaw_kingpin.png")
const GUARD_TEX := preload("res://assets/world/boss_bodyguard.png")

var _king: AnimatableBody2D
var _label: Label
var _guards_left: int = 2
var _telegraphing: bool = false
var _vulnerable: bool = false


func _ready() -> void:
	source_level = 10
	boss_title = "Outlaw Kingpin — tie the guards, then the boss!"
	super._ready()
	_king = $Kingpin as AnimatableBody2D
	_label = $Kingpin/Label as Label
	var kspr := $Kingpin/Sprite2D as Sprite2D
	if kspr != null:
		kspr.texture = KING_TEX
	for name in ["Guard0", "Guard1"]:
		var guard := get_node_or_null(name) as Opponent
		if guard != null:
			guard.captured.connect(_on_guard_captured)
			var gspr := guard.get_node_or_null("WalkSprite") as AnimatedSprite2D
			if gspr == null:
				gspr = guard.get_node_or_null("Sprite2D") as AnimatedSprite2D
	_start_telegraph_loop()


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
		_telegraphing = true
		_vulnerable = true
		if _label != null:
			_label.text = "LOOK OUT!"
			_label.modulate = Color(0.95, 0.2, 0.1, 1)
		await get_tree().create_timer(1.35).timeout
		_vulnerable = false
		_telegraphing = false
		if _label != null and not _won:
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
	win_boss()
