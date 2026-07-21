extends Node

## Reads instructions with the operating system's installed voice.
## A lower pitch and male-name preference keep the voice cowboy-like where possible.

const MALE_VOICE_HINTS: PackedStringArray = [
	"male", "david", "mark", "george", "stefan", "hans", "klaus", "thomas",
]


func speak(text: String, interrupt: bool = true) -> void:
	if not bool(GameManager.get_settings().get("narration", true)):
		return
	var spoken := text.strip_edges()
	if spoken.is_empty():
		return
	var voice := _pick_voice()
	if voice.is_empty():
		return
	DisplayServer.tts_speak(spoken, voice, 70, 0.85, 1.0, 0, interrupt)


func stop() -> void:
	DisplayServer.tts_stop()


func _pick_voice() -> String:
	var locale := String(GameManager.get_settings().get("language", "en"))
	var candidates: Array[Dictionary] = []
	for value in DisplayServer.tts_get_voices():
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var voice := value as Dictionary
		var language := String(voice.get("language", "")).to_lower()
		if language.begins_with(locale.to_lower()):
			candidates.append(voice)
	for hint in MALE_VOICE_HINTS:
		for voice in candidates:
			if hint in String(voice.get("name", "")).to_lower():
				return String(voice.get("id", ""))
	if not candidates.is_empty():
		return String(candidates[0].get("id", ""))
	var ids := DisplayServer.tts_get_voices_for_language(locale)
	return String(ids[0]) if not ids.is_empty() else ""
