extends Node

## Persistent music player with independent Music and SFX volume buses.

const MUSIC_PATH := "res://assets/audio/cheerful_cowboy_trail.wav"

var _music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "CheerfulTrailMusic"
	_music_player.bus = &"Music"
	add_child(_music_player)
	var stream := load(MUSIC_PATH)
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		(stream as AudioStreamWAV).loop_begin = 0
		(stream as AudioStreamWAV).loop_end = (stream as AudioStreamWAV).data.size() / 2
	if stream is AudioStream:
		_music_player.stream = stream
		_music_player.play()
	GameManager.settings_changed.connect(_apply_volumes)
	_apply_volumes()


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
