extends Node

## Reads instructions with the operating system's installed voice.
## Always prefers a male voice (cowboy narrator), with language fallbacks that
## still speak when the preferred language has no installed voice.
##
## Selection order:
##   1) male voice in the requested language
##   2) any voice in the requested language
##   3) male English voice
##   4) any English voice
##   5) any male voice of any language
##   6) first installed voice
## Returns "" only when the system has no voices at all.

const MALE_VOICE_HINTS: PackedStringArray = [
	"male",
	"david",
	"mark",
	"james",
	"george",
	"richard",
	"daniel",
	"thomas",
	"stefan",
	"hans",
	"klaus",
	"ralf",
	"paul",
	"sean",
	"fred",
	"alex",
	"matthew",
	"guy",
	"eric",
	"brian",
	"andrew",
	"christopher",
]

const FEMALE_VOICE_HINTS: PackedStringArray = [
	"female",
	"woman",
	"girl",
	"zira",
	"hedda",
	"hortense",
	"hazel",
	"susan",
	"linda",
	"helena",
	"katja",
	"sabina",
	"anna",
	"jenny",
	"aria",
	"sonia",
	"emma",
	"michelle",
]

## Slightly lower pitch keeps the cowboy narrator sounding male even when the
## only available system voice is ambiguous.
const SPEAK_PITCH := 0.78
const SPEAK_RATE := 1.0
const SPEAK_VOLUME := 72

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
	DisplayServer.tts_speak(spoken, voice, SPEAK_VOLUME, SPEAK_PITCH, SPEAK_RATE, 0, interrupt)


func stop() -> void:
	DisplayServer.tts_stop()


func _pick_voice() -> String:
	var locale := String(GameManager.get_settings().get("language", "de"))
	var chosen := select_voice(DisplayServer.tts_get_voices(), locale)
	if not chosen.is_empty():
		return chosen
	# Last-resort platform lookup for systems that only report voices per language.
	for fallback_locale in [locale, "de", "en"]:
		var ids := DisplayServer.tts_get_voices_for_language(String(fallback_locale))
		if not ids.is_empty():
			return String(ids[0])
	return ""


## Chooses the best voice id from an installed-voice list.
## Kept static and list-driven so the fallback order is unit-testable headless.
static func select_voice(voices: Array, locale: String) -> String:
	var by_locale := _match_locale(voices, locale, true)
	if not by_locale.is_empty():
		return by_locale
	by_locale = _match_locale(voices, locale, false)
	if not by_locale.is_empty():
		return by_locale
	# Prefer German next (game default), then English, then any male / any voice.
	if not locale.strip_edges().to_lower().begins_with("de"):
		var german_male := _match_locale(voices, "de", true)
		if not german_male.is_empty():
			return german_male
		var german := _match_locale(voices, "de", false)
		if not german.is_empty():
			return german
	if not locale.strip_edges().to_lower().begins_with("en"):
		var english_male := _match_locale(voices, "en", true)
		if not english_male.is_empty():
			return english_male
		var english := _match_locale(voices, "en", false)
		if not english.is_empty():
			return english
	var any_male := _first_male_voice_id(voices)
	if not any_male.is_empty():
		return any_male
	return _first_voice_id(voices)


static func _match_locale(voices: Array, locale: String, male_only: bool) -> String:
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
	if candidates.is_empty():
		return ""
	var male := _first_male_among(candidates)
	if not male.is_empty():
		return male
	if male_only:
		return ""
	# Prefer a non-female voice when gender is ambiguous.
	for voice in candidates:
		if not _looks_female(voice):
			return String(voice.get("id", ""))
	return String(candidates[0].get("id", ""))


static func _first_male_among(candidates: Array) -> String:
	for hint in MALE_VOICE_HINTS:
		for voice in candidates:
			if typeof(voice) != TYPE_DICTIONARY:
				continue
			var name := String((voice as Dictionary).get("name", "")).to_lower()
			if hint in name and not _looks_female(voice):
				return String((voice as Dictionary).get("id", ""))
	return ""


static func _first_male_voice_id(voices: Array) -> String:
	var as_dicts: Array = []
	for value in voices:
		if typeof(value) == TYPE_DICTIONARY:
			as_dicts.append(value)
	return _first_male_among(as_dicts)


static func _looks_female(voice: Variant) -> bool:
	if typeof(voice) != TYPE_DICTIONARY:
		return false
	var name := String((voice as Dictionary).get("name", "")).to_lower()
	for hint in FEMALE_VOICE_HINTS:
		if hint in name:
			return true
	return false


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
