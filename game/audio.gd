class_name CombatAudio
extends Node

const TRACKS := {
	"shelter": preload("res://assets/audio/shelter.wav"),
	"night-walk": preload("res://assets/audio/night-walk.wav"),
	"boss": preload("res://assets/audio/boss.wav"),
}
var playback_enabled := DisplayServer.get_name() != "headless"
var enabled := true
var music_enabled := true
var suspended := false
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var cooldowns: Dictionary = {}
var music_voices: Array[AudioStreamPlayer] = []
var music_gains := [0.0, 0.0]
var music_slot := 0
var current_track := ""
var ducked := false

func _ready() -> void:
	for i in 10:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	for i in 2:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -80
		add_child(voice)
		music_voices.append(voice)
	for name in ["paw", "blast", "hit", "pickup", "evolve", "upgrade", "defeat", "hiss", "bounce", "bell", "combo", "victory"]:
		sounds[name] = _synthesize(name)

func set_context(screen: String, boss: bool) -> void:
	var wanted := ""
	if music_enabled and not suspended:
		if screen in ["playing", "upgrading"]:
			wanted = "boss" if boss else "night-walk"
		elif screen in ["menu", "cats", "stages", "shelter", "story", "results"]:
			wanted = "shelter"
	ducked = screen in ["upgrading", "results"]
	if wanted == current_track:
		return
	current_track = wanted
	if wanted.is_empty():
		return
	music_slot = 1 - music_slot
	var stream: AudioStreamWAV = TRACKS[wanted].duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	# The WAV mixer expects the last valid sample index, not the sample count.
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate) - 1
	music_voices[music_slot].stream = stream
	music_voices[music_slot].volume_db = -80
	music_gains[music_slot] = 0.0
	if playback_enabled:
		music_voices[music_slot].play()

func _process(dt: float) -> void:
	for name in cooldowns.keys():
		cooldowns[name] = maxf(0, cooldowns[name] - dt)
	for i in music_voices.size():
		var target := (0.14 if ducked else 0.27) if i == music_slot and not current_track.is_empty() and music_enabled and not suspended else 0.0
		music_gains[i] = move_toward(music_gains[i], target, dt * 0.7)
		music_voices[i].volume_db = linear_to_db(maxf(0.0001, music_gains[i]))
		if target == 0 and music_gains[i] == 0:
			music_voices[i].stop()

func play(name: String) -> void:
	if not enabled or suspended or not sounds.has(name) or voices.is_empty() or cooldowns.get(name, 0.0) > 0:
		return
	cooldowns[name] = 0.14 if name in ["pickup", "blast", "bounce", "defeat"] else 0.07
	# Keep short swarm sounds from cutting off a reward or evolution melody.
	var important := name in ["evolve", "victory", "combo", "upgrade"]
	var voice := voices[8 + (1 if name == "victory" else 0)] if important else voices[next_voice]
	if not important:
		next_voice = (next_voice + 1) % 8
	voice.stream = sounds[name]
	voice.volume_db = -22 if name in ["paw", "pickup", "defeat"] else -15
	if playback_enabled:
		voice.play()

func silence() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	for voice in music_voices:
		voice.stop()
		voice.stream = null
	music_gains = [0.0, 0.0]
	current_track = ""
	cooldowns.clear()

func _synthesize(name: String) -> AudioStreamWAV:
	var duration := 0.10
	if name in ["blast", "hit", "hiss"]:
		duration = 0.24
	elif name in ["evolve", "victory"]:
		duration = 1.1
	elif name in ["upgrade", "combo", "bell"]:
		duration = 0.35
	var rate := 22050
	var count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in count:
		var t := float(i) / rate
		var phase := float(i) / count
		var sample := 0.0
		var envelope := pow(1 - phase, 2) * minf(t * 500, 1)
		match name:
			"paw": sample = sin(TAU * (850 * t - 1900 * t * t)) * 0.5 + rng.randf_range(-0.15, 0.15)
			"defeat": sample = sin(TAU * (480 * t - 1500 * t * t)) * 0.65
			"blast": sample = sin(TAU * (120 * t - 140 * t * t)) * 0.65 + rng.randf_range(-0.25, 0.25)
			"hit": sample = sin(t * 150 * TAU) * 0.5 + rng.randf_range(-0.25, 0.25)
			"hiss": sample = rng.randf_range(-0.65, 0.65) * sin(phase * PI)
			"bounce": sample = sin(TAU * (420 * t + 1400 * t * t)) * 0.65
			"bell": sample = sin(t * 1320 * TAU) * 0.5 + sin(t * 2640 * TAU) * 0.15
			"pickup": sample = sin(t * 1046.5 * TAU) * 0.45
			_:
				var notes := [0, 4, 7, 12, 16, 19, 24, 19] if name in ["evolve", "victory"] else [0, 4, 7, 12]
				var segment := phase * notes.size()
				var frequency := 523.25 * pow(2.0, notes[mini(int(segment), notes.size() - 1)] / 12.0)
				var local := fmod(segment, 1.0)
				envelope = minf(local * 15, 1) * pow(1 - local, 0.6) * (1 - phase * 0.5)
				sample = sin(t * frequency * TAU) * 0.5 + sin(t * frequency * TAU * 2) * 0.1
		data.encode_s16(i * 2, int(sample * envelope * 25000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
