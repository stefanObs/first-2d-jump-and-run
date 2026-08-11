extends Node

## Persistent music player with independent Music and SFX volume buses.
## Boot plays the country theme once, then levels loop one of three trail tunes
## (rotating by campaign level for variety). Finale reuses the country song.

const TRAIL_PATHS: PackedStringArray = [
	"res://assets/audio/cheerful_cowboy_trail.wav",
	"res://assets/audio/trail_lasso_lady.ogg",
	"res://assets/audio/trail_spaghetti_western.ogg",
]
const COUNTRY_PATH := "res://assets/audio/country_version.mp3"

var _music_player: AudioStreamPlayer
var _trail_streams: Array[AudioStream] = []
var _country_stream: AudioStream
var _trail_index: int = -1
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
	_load_trail_streams()
	_country_stream = load(COUNTRY_PATH) as AudioStream
	if _country_stream is AudioStreamMP3:
		(_country_stream as AudioStreamMP3).loop = false
	_music_player.finished.connect(_on_music_finished)
	GameManager.settings_changed.connect(_apply_volumes)
	_apply_volumes()
	play_boot_intro()


func _load_trail_streams() -> void:
	_trail_streams.clear()
	for path in TRAIL_PATHS:
		var stream := load(path) as AudioStream
		if stream == null:
			push_warning("Missing trail music: %s" % path)
			continue
		_configure_trail_loop(stream)
		_trail_streams.append(stream)


func _configure_trail_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() / (4 if wav.stereo else 2)
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func trail_track_count() -> int:
	return _trail_streams.size()


func trail_track_index_for_level(level_number: int) -> int:
	var count := trail_track_count()
	if count <= 0:
		return 0
	return posmod(maxi(level_number, 1) - 1, count)


func current_trail_track_index() -> int:
	return _trail_index


func play_boot_intro() -> void:
	## Once per launch: country theme, then first trail loop.
	if _intro_played:
		return
	if _country_stream == null:
		play_trail_music(1)
		return
	_intro_played = true
	_mode = &"intro"
	_trail_index = -1
	_music_player.stream = _country_stream
	_music_player.play()


func play_trail_music(level_number: int = 1) -> void:
	if _trail_streams.is_empty():
		return
	var index := trail_track_index_for_level(level_number)
	if _mode == &"trail" and _music_player.playing and _trail_index == index:
		return
	_mode = &"trail"
	_trail_index = index
	_music_player.stream = _trail_streams[index]
	_music_player.play()


func play_finale_theme() -> void:
	## Sunset victory ride — country theme once (no loop).
	if _country_stream == null:
		return
	_mode = &"finale"
	_trail_index = -1
	_music_player.stream = _country_stream
	_music_player.play()


func is_finale_playing() -> bool:
	return _mode == &"finale" and _music_player.playing


func ensure_gameplay_music(level_number: int = -1) -> void:
	## Leave the boot intro early when the player starts a trail.
	var level := level_number
	if level < 1:
		level = GameManager.get_current_level_number() if GameManager.active_slot_index >= 0 else 1
	if _mode == &"intro" or _mode == &"none" or _mode == &"finale":
		play_trail_music(level)
		return
	if _mode == &"trail":
		play_trail_music(level)


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
	_mode = &"none"
	_trail_index = -1


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
		&"ui_click":
			frequency = 240.0
			end_frequency = 110.0
			duration = 0.07
			noise_amount = 0.16
		&"dragon_roar":
			frequency = 110.0
			end_frequency = 55.0
			duration = 0.62
			noise_amount = 0.55
		&"dragon_spit":
			frequency = 480.0
			end_frequency = 160.0
			duration = 0.2
			noise_amount = 0.42
		&"dragon_land":
			frequency = 95.0
			end_frequency = 38.0
			duration = 0.34
			noise_amount = 0.48
		&"dragon_takeoff":
			frequency = 150.0
			end_frequency = 340.0
			duration = 0.3
			noise_amount = 0.28
		&"dragon_tied":
			frequency = 340.0
			end_frequency = 140.0
			duration = 0.28
			noise_amount = 0.22
		&"dragon_win":
			frequency = 300.0
			end_frequency = 720.0
			duration = 0.58
			noise_amount = 0.12
	var rate := 22050
	var frame_count := maxi(1, int(duration * rate))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase := 0.0
	var growl_phase := 0.0
	var random := RandomNumberGenerator.new()
	random.seed = int(effect.hash())
	var dragon_growl := (
		effect == &"dragon_roar"
		or effect == &"dragon_land"
		or effect == &"dragon_spit"
	)
	for frame in range(frame_count):
		var progress := float(frame) / float(frame_count)
		var hz := lerpf(frequency, end_frequency, progress)
		phase += TAU * hz / float(rate)
		growl_phase += TAU * (hz * 0.45) / float(rate)
		var envelope := pow(1.0 - progress, 1.7) * minf(progress * 18.0, 1.0)
		var tone := sin(phase) * (1.0 - noise_amount)
		if dragon_growl:
			tone = tone * 0.7 + sin(growl_phase) * 0.3 * (1.0 - noise_amount)
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
		play_trail_music(1)


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
