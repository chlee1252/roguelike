extends SceneTree

var failures := 0
var pulses: Array[Vector2] = []
var now := 1000

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var haptics := CombatHaptics.new()
	haptics.supported = true
	haptics.emit_pulse = func(ms: int, strength: float) -> void: pulses.append(Vector2(ms, strength))
	haptics.clock = func() -> int: return now
	check(haptics.play("hit"), "Damage must trigger a pulse")
	for i in 100:
		haptics.play("hit")
		haptics.play("paw")
		haptics.play("defeat")
	check(pulses.size() == 1, "Rapid hits and ordinary kills must not spam vibration")
	haptics.play_events(["hit", "evolve", "victory"])
	check(pulses.size() == 2 and pulses[-1].x == 160, "Strongest simultaneous event must override weaker feedback once")
	check(not haptics.play("upgrade"), "Upgrade must not interrupt a recent boss reward")
	now += 250
	check(haptics.play("upgrade") and pulses[-1].x == 35, "Short upgrade pulse must resume after cooldown")
	haptics.enabled = false
	now += 1000
	check(not haptics.play("victory"), "Disabled haptics must stay silent")
	haptics.enabled = true
	haptics.suspended = true
	check(not haptics.play("victory"), "Background requests must be dropped")
	haptics.suspended = false
	haptics.supported = false
	check(not haptics.play("preview"), "Unsupported platforms must be a no-op")
	var preset := ConfigFile.new()
	preset.load("res://export_presets.cfg")
	check(preset.get_value("preset.1.options", "permissions/vibrate", false), "Android must export the VIBRATE permission")

	var scene := load("res://app/game.tscn") as PackedScene
	var game := scene.instantiate()
	game.save_path = "user://haptics-test.dat"
	game.settings_path = "user://haptics-test.settings.cfg"
	DirAccess.remove_absolute(game.settings_path)
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.haptics = haptics
	haptics.supported = true
	game.audio.enabled = false
	game.audio.music_enabled = false
	game.start_run()
	game.battle.sound_events.assign(["hit"])
	game._update_hud(0)
	check(pulses[-1].x == 65, "Battle feedback must work independently of audio")
	now += 300
	game.battle.sound_events.assign(["evolve"])
	game._update_hud(0)
	check(pulses[-1].x == 110, "Actual evolution event must use the evolution profile")
	now += 300
	game.battle.pending_levels = 1
	game.state = "upgrading"
	game.options.assign(["w0"])
	game._choose("w0")
	check(pulses[-1].x == 35, "Level-up selection must trigger short feedback")
	now += 300
	game.battle.victory = true
	game._show_results()
	check(pulses[-1].x == 160, "Victory result must trigger reward feedback")
	var count := pulses.size()
	game._show_results()
	check(pulses.size() == count, "Reopening results must not replay victory feedback")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(haptics.suspended, "App background transition must disable new pulses")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not haptics.suspended, "Foreground transition must restore haptics")
	game._show_menu()
	game._toggle_setting("haptics")
	check(not haptics.enabled, "Settings toggle must disable haptics")
	haptics.enabled = true
	game._load_settings()
	check(not haptics.enabled, "Haptics preference must survive settings reload")
	game._clear_save()
	game.audio.silence()
	game.queue_free()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute("user://haptics-test.settings.cfg")
	print("HAPTICS_TEST_OK" if failures == 0 else "HAPTICS_TEST_FAILED")
	quit(1 if failures else 0)
