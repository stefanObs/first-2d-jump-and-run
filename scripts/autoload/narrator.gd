extends Node

## Reads instructions with the operating system's installed voice.
## A lower pitch and male-name preference keep the voice cowboy-like where possible.
##
## Voice selection is deliberately forgiving: many systems (especially a default
## Windows install) only ship an English SAPI voice, so a German trail would fall
## silent if we insisted on a German voice. We therefore fall back English -> any
## installed voice, and only stay silent when the system has no voices at all.

const MALE_VOICE_HINTS: PackedStringArray = [
	"male", "david", "mark", "george", "stefan", "hans", "klaus", "thomas",
]

var _warned_no_voices := false


func speak(text: String, interrupt: bool = true) -> void:
	if not bool(GameManager.get_settings().get("narration", true)):
		return
	var spoken := text.strip_edges()
	if spoken.is_empty():
		return
	var voice := _pick_voice()
	if voice.is_empty():
		_warn_no_voices_once()
		return
	# tts_speak(text, voice, volume 0-100, pitch, rate, utterance_id, interrupt).
	DisplayServer.tts_speak(spoken, voice, 70, 0.85, 1.0, 0, interrupt)


func stop() -> void:
	DisplayServer.tts_stop()


func _pick_voice() -> String:
	var locale := String(GameManager.get_settings().get("language", "en"))
	var chosen := select_voice(DisplayServer.tts_get_voices(), locale)
	if not chosen.is_empty():
		return chosen
	# Last-resort platform lookup for systems that only report voices per language
	# (tts_get_voices() empty but a language-specific query still succeeds).
	for fallback_locale in [locale, "en"]:
		var ids := DisplayServer.tts_get_voices_for_language(String(fallback_locale))
		if not ids.is_empty():
			return String(ids[0])
	return ""


## Chooses the best voice id from an installed-voice list with graceful fallback,
## so narration is never silent when *any* voice exists:
##   1) a voice in the requested language (male-sounding when possible),
##   2) otherwise any English voice (Windows ships en-US by default),
##   3) otherwise the first installed voice of any language.
## Returns "" only when no usable voice is installed at all.
## Kept static and list-driven so the fallback order is unit-testable headless.
static func select_voice(voices: Array, locale: String) -> String:
	var by_locale := _match_locale(voices, locale)
	if not by_locale.is_empty():
		return by_locale
	if not locale.strip_edges().to_lower().begins_with("en"):
		var english := _match_locale(voices, "en")
		if not english.is_empty():
			return english
	return _first_voice_id(voices)


static func _match_locale(voices: Array, locale: String) -> String:
	var needle := locale.strip_edges().to_lower()
	if needle.is_empty():
		return ""
	var candidates: Array[Dictionary] = []
	for value in voices:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var voice := value as Dictionary
		if String(voice.get("language", "")).to_lower().begins_with(needle):
			candidates.append(voice)
	for hint in MALE_VOICE_HINTS:
		for voice in candidates:
			if hint in String(voice.get("name", "")).to_lower():
				return String(voice.get("id", ""))
	if not candidates.is_empty():
		return String(candidates[0].get("id", ""))
	return ""


static func _first_voice_id(voices: Array) -> String:
	for value in voices:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var id := String((value as Dictionary).get("id", ""))
		if not id.is_empty():
			return id
	return ""


func _warn_no_voices_once() -> void:
	if _warned_no_voices:
		return
	_warned_no_voices = true
	push_warning(
		"Narrator: no text-to-speech voices are installed, so spoken instructions "
		+ "are silent. On Windows, add a voice under Settings > Time & Language > "
		+ "Speech; on Linux install speech-dispatcher."
	)
