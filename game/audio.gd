class_name CombatAudio
extends Node

var enabled := true
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0

func _ready() -> void:
	for i in 8:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -20
		add_child(voice)
		voices.append(voice)
	for name in ["gun", "blast", "hit", "pickup", "evolve"]:
		sounds[name] = _synthesize(name)

func play(name: String) -> void:
	if not enabled or not sounds.has(name):
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = sounds[name]
	voice.volume_db = -26 if name == "gun" or name == "pickup" else -17
	voice.play()

func silence() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null

func _synthesize(name: String) -> AudioStreamWAV:
	var duration := 0.06 if name == "gun" else 0.3 if name == "blast" else 0.4 if name == "evolve" else 0.09
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
		if name == "gun":
			sample = rng.randf_range(-1, 1) * 0.6 + sin(t * 180 * TAU) * 0.4
		elif name == "blast" or name == "hit":
			sample = rng.randf_range(-1, 1) * 0.45 + sin(t * 60 * TAU) * 0.55
		else:
			var frequency := 900.0 if name == "pickup" else 440.0 * pow(2.0, floor(phase * 4) / 3.0)
			sample = sin(t * frequency * TAU) * 0.55
		data.encode_s16(i * 2, int(sample * pow(1 - phase, 2) * minf(t * 1000, 1) * 25000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
