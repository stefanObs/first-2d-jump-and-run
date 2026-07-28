class_name DoubleTapConfirm
extends RefCounted

## Shared numpad double-tap confirm (next trail / next boss).

const WINDOW_MS := 450


## Returns true when this tap confirms; always writes the latest stamp into last_tap_msec.
static func accept(last_tap_msec: int) -> Dictionary:
	var now := Time.get_ticks_msec()
	if now - last_tap_msec <= WINDOW_MS:
		return {"confirmed": true, "stamp": now}
	return {"confirmed": false, "stamp": now}
