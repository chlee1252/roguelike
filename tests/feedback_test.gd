extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var audio := CombatAudio.new()
	root.add_child(audio)
	await process_frame
	for track in CombatAudio.TRACKS.values():
		check(track.format == AudioStreamWAV.FORMAT_16_BITS, "Music imports must preserve PCM for seam validation")
		check(track.mix_rate == 22050 and not track.stereo, "Music format must match loop frame calculation")
		check(track.get_length() >= 20 and track.get_length() <= 31, "Music loops must contain a full phrase")
		check(abs(track.data.decode_s16(0) - track.data.decode_s16(track.data.size() - 2)) < 200, "Loop seam must not contain a large PCM jump")
	audio.set_context("menu", false)
	check(audio.current_track == "shelter", "Menu must play shelter music")
	audio.set_context("playing", false)
	check(audio.current_track == "night-walk", "Combat must change music")
	audio.set_context("upgrading", true)
	check(audio.current_track == "boss" and audio.ducked, "Upgrade overlay must duck boss music")
	var stream := audio.music_voices[audio.music_slot].stream as AudioStreamWAV
	check(stream.loop_end < stream.data.size() / 2, "Loop end must be an in-bounds sample index")
	check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_end > 400000, "Playback stream must really loop")
	audio.music_enabled = false
	audio.set_context("playing", true)
	audio._process(1)
	check(audio.current_track.is_empty() and not audio.music_voices[0].playing and not audio.music_voices[1].playing, "Music off must stop both crossfade players")
	audio.play("defeat")
	var voice_after := audio.next_voice
	audio.play("defeat")
	check(audio.next_voice == voice_after, "Crowd kills must rate-limit audio voices")
	audio.enabled = false
	audio.play("paw")
	check(audio.next_voice == voice_after, "SFX off must prevent new sounds")
	audio.music_enabled = true
	audio.suspended = true
	audio.set_context("menu", false)
	check(audio.current_track.is_empty(), "Background app must remain silent even in menus")
	audio.suspended = false
	audio.set_context("paused", false)
	check(audio.current_track.is_empty(), "Pause must not restart music")
	audio.set_context("playing", false)
	check(audio.current_track == "night-walk", "Resume must restart music independently of SFX setting")
	check(audio.sounds.evolve.get_length() > audio.sounds.upgrade.get_length(), "Evolution must have its own longer reward sound")
	audio.silence()
	audio.queue_free()
	await process_frame
	var scene := load("res://app/game.tscn") as PackedScene
	var game := scene.instantiate()
	game.save_path = "user://feedback-test.dat"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.start_run()
	game._update_chain(7, 0.01)
	game._update_chain(4, 0.01)
	check(game.chain == 11 and game.chain_label.visible, "Consecutive kills must accumulate")
	game._update_chain(0, 3.1)
	check(game.chain == 0 and not game.chain_label.visible, "Streak must expire after three seconds without kills")
	var target: int = game.battle.spawn_enemy(0, game.battle.player + Vector2(20, 0))
	game.battle._hurt_enemy(target, 100, 0)
	check(game.battle.sound_events.has("defeat"), "An actual kill must emit a death sound")
	check(game.battle.effects.size() >= 2, "Hit and death must both provide feedback")
	for i in 300:
		game.battle.add_effect(Vector2.ZERO, 10, 0.3, 5)
	check(game.battle.effects.size() == 100, "Swarm feedback must respect its fixed cap")
	game._clear_save()
	game.audio.silence()
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("FEEDBACK_TEST_OK" if failures == 0 else "FEEDBACK_TEST_FAILED")
	quit(1 if failures else 0)
