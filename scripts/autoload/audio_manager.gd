extends Node

## Persistent music player with independent Music and SFX volume buses.
## Plays the country theme once at boot, then loops the trail tune.
## The finale theme reuses the country song for the sunset ride.

const TRAIL_PATH := "res://assets/audio/cheerful_cowboy_trail.wav"
const COUNTRY_PATH := "res://assets/audio/country_version.mp3"

var _music_player: AudioStreamPlayer
var _trail_stream: AudioStream
var _country_stream: AudioStream
var _mode: StringName = &"none"
var _intro_played: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "GameMusic"
	_music_player.bus = &"Music"
	add_child(_music_player)
	_trail_stream = load(TRAIL_PATH) as AudioStream
	_country_stream = load(COUNTRY_PATH) as AudioStream
	if _trail_stream is AudioStreamWAV:
		var wav := _trail_stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / 2
	if _country_stream is AudioStreamMP3:
		(_country_stream as AudioStreamMP3).loop = false
	_music_player.finished.connect(_on_music_finished)
	GameManager.settings_changed.connect(_apply_volumes)
	_apply_volumes()
	play_boot_intro()


func play_boot_intro() -> void:
	## Once per launch: country theme, then trail loop.
	if _intro_played or _country_stream == null:
		play_trail_music()
		return
	_intro_played = true
	_mode = &"intro"
	_music_player.stream = _country_stream
	_music_player.play()


func play_trail_music() -> void:
	if _trail_stream == null:
		return
	if _mode == &"trail" and _music_player.playing:
		return
	_mode = &"trail"
	_music_player.stream = _trail_stream
	_music_player.play()


func play_finale_theme() -> void:
	## Sunset victory ride — country theme once (no loop).
	if _country_stream == null:
		return
	_mode = &"finale"
	_music_player.stream = _country_stream
	_music_player.play()


func is_finale_playing() -> bool:
	return _mode == &"finale" and _music_player.playing


func ensure_gameplay_music() -> void:
	## Leave the boot intro early when the player starts a trail.
	if _mode == &"intro":
		play_trail_music()


func _on_music_finished() -> void:
	if _mode == &"intro":
		play_trail_music()


func _ensure_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _apply_volumes() -> void:
	var settings := GameManager.get_settings()
	_set_bus_linear(&"Music", float(settings.get("music_volume", 0.8)))
	_set_bus_linear(&"SFX", float(settings.get("sfx_volume", 0.8)))


func _set_bus_linear(bus_name: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var linear := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.001)))
