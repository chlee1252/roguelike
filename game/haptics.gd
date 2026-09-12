class_name CombatHaptics
extends RefCounted

# Short, one-shot pulses: duration (ms), intensity, priority.
const PROFILES := {
	"upgrade": [35, 0.30, 1],
	"hit": [65, 0.55, 2],
	"evolve": [110, 0.70, 3],
	"victory": [160, 0.85, 4],
	"preview": [65, 0.55, 2],
}
const MIN_INTERVAL_MS := 250
var enabled := true
var suspended := false
var supported := OS.get_name() in ["Android", "iOS"]
var emit_pulse: Callable = Input.vibrate_handheld
var clock: Callable = Time.get_ticks_msec
var last_pulse_ms := -100000
var last_priority := 0

func play(event: String) -> bool:
	if not enabled or suspended or not supported or not PROFILES.has(event):
		return false
	var profile: Array = PROFILES[event]
	var now: int = clock.call()
	if now - last_pulse_ms < MIN_INTERVAL_MS and profile[2] <= last_priority:
		return false
	last_pulse_ms = now
	last_priority = profile[2]
	emit_pulse.call(profile[0], profile[1])
	return true

func play_events(events: Array[String]) -> void:
	var strongest := ""
	for event in events:
		if PROFILES.has(event) and (strongest.is_empty() or PROFILES[event][2] > PROFILES[strongest][2]):
			strongest = event
	if not strongest.is_empty():
		play(strongest)
