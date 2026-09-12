extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var audio := CombatAudio.new()
	audio.playback_enabled = true
	root.add_child(audio)
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2
	AudioServer.add_bus_effect(0, capture)
	var failed := false
	for context in ["menu", "playing", "boss"]:
		audio.set_context("playing" if context == "boss" else context, context == "boss")
		await create_timer(0.6).timeout
		capture.clear_buffer()
		var player := audio.music_voices[audio.music_slot]
		player.play(player.stream.get_length() - 0.1)
		audio.play("evolve" if context == "boss" else "paw")
		await create_timer(0.8).timeout
		if not player.playing or player.get_playback_position() > 2.0:
			push_error("Track must cross its loop boundary and continue playing")
			failed = true
		var frames := capture.get_buffer(capture.get_frames_available())
		var peak := 0.0
		for frame in frames:
			peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
		print("AUDIO_MIX %s frames=%d peak=%.4f" % [context, frames.size(), peak])
		if frames.size() < 1000 or peak < 0.005 or peak >= 0.95:
			push_error("Music and effects must reach the mixer without clipping")
			failed = true
	audio.silence()
	await create_timer(0.15).timeout
	capture.clear_buffer()
	await create_timer(0.2).timeout
	for frame in capture.get_buffer(capture.get_frames_available()):
		if frame.length_squared() > 0.000001:
			push_error("Silence must stop actual audio output")
			failed = true
			break
	AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	audio.queue_free()
	await create_timer(0.15).timeout
	print("AUDIO_MIX_TEST_OK" if not failed else "AUDIO_MIX_TEST_FAILED")
	quit(1 if failed else 0)
