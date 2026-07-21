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
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _sfx_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music")
	_ensure_bus(&"SFX")
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "GameMusic"
	_music_player.bus = &"Music"
	add_child(_music_player)
	for i in range(4):
		var player := AudioStreamPlayer.new()
		player.name = "Effect%d" % i
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)
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
	if _intro_played:
		return
	if _country_stream == null:
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


func play_sfx(effect: StringName) -> void:
	if _sfx_players.is_empty():
		return
	if not _sfx_cache.has(effect):
		_sfx_cache[effect] = _make_effect(effect)
	var player := _sfx_players[_sfx_index % _sfx_players.size()]
	_sfx_index += 1
	player.stream = _sfx_cache[effect] as AudioStream
	player.play()


func _make_effect(effect: StringName) -> AudioStreamWAV:
	var frequency := 440.0
	var end_frequency := 660.0
	var duration := 0.16
	var noise_amount := 0.0
	match effect:
		&"jump":
			frequency = 260.0
			end_frequency = 520.0
			duration = 0.14
		&"lasso":
			frequency = 720.0
			end_frequency = 240.0
			duration = 0.19
			noise_amount = 0.18
		&"collect":
			frequency = 700.0
			end_frequency = 1180.0
			duration = 0.22
		&"checkpoint":
			frequency = 390.0
			end_frequency = 780.0
			duration = 0.34
		&"powerup":
			frequency = 480.0
			end_frequency = 1060.0
			duration = 0.42
		&"hurt":
			frequency = 210.0
			end_frequency = 90.0
			duration = 0.28
			noise_amount = 0.25
		&"goal":
			frequency = 520.0
			end_frequency = 1040.0
			duration = 0.55
	var rate := 22050
	var frame_count := maxi(1, int(duration * rate))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase := 0.0
	var random := RandomNumberGenerator.new()
	random.seed = int(effect.hash())
	for frame in range(frame_count):
		var progress := float(frame) / float(frame_count)
		var hz := lerpf(frequency, end_frequency, progress)
		phase += TAU * hz / float(rate)
		var envelope := pow(1.0 - progress, 1.7) * minf(progress * 18.0, 1.0)
		var tone := sin(phase) * (1.0 - noise_amount)
		tone += random.randf_range(-1.0, 1.0) * noise_amount
		bytes.encode_s16(frame * 2, int(clampf(tone * envelope, -1.0, 1.0) * 15000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream


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
