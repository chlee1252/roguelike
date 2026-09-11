extends SceneTree
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://app/game.tscn") as PackedScene
	var game := scene.instantiate()
	game.save_path = "user://ui-test.dat"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(game.state == "menu", "Game must boot into briefing")
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	check(game.state == "playing", "Enter input must deploy from briefing")
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.position = Vector2(100, 250)
	touch.pressed = true
	game._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = Vector2(140, 250)
	game._input(drag)
	check(game.movement == Vector2.RIGHT, "Touch drag must drive joystick")
	var second := InputEventScreenTouch.new()
	second.index = 4
	second.position = Vector2(200, 200)
	second.pressed = true
	game._input(second)
	check(game.joystick_finger == 3, "Second finger must not steal joystick")
	var emulated := InputEventMouseButton.new()
	emulated.device = -1
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.pressed = false
	game._input(emulated)
	check(game.movement == Vector2.RIGHT, "Emulated mouse release must not reset touch movement")
	var before: Vector2 = game.battle.player
	game._physics_process(0.1)
	check(game.battle.player.x > before.x, "Joystick must move commando")
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await process_frame
	check(game.state == "paused", "Background notification must safely pause the game")
	var paused_time: float = game.battle.elapsed
	game._physics_process(0.1)
	check(game.battle.elapsed == paused_time and game.movement == Vector2.ZERO, "Pause must freeze time and clear input")
	game._resume()
	game._physics_process(0.8)
	check(game.state == "playing", "Resume countdown must return to combat")
	game.battle.pending_levels = 1
	game.battle.level = 2
	game._show_upgrades()
	check(game.options.has("w1") and game.options.has("w2"), "Early options must offer both new weapons")
	var old_level: int = game.battle.weapons[1]
	game._choose("w1")
	check(game.battle.weapons[1] == old_level + 1 and game.battle.pending_levels == 0, "Selection must grant exactly one upgrade")
	game._choose("w1")
	check(game.battle.weapons[1] == old_level + 1, "Duplicate selection must be ignored")
	game.battle.pending_levels = 1
	game._show_upgrades()
	game._save_session()
	var original := var_to_bytes(game.battle.snapshot())
	game._show_menu()
	game._continue_run()
	check(game.state == "upgrading", "Saved pending upgrade must reopen choices")
	check(original == var_to_bytes(game.battle.snapshot()), "UI save must restore exact simulation state")
	game.battle.weapons.assign([6, 6, 6])
	game.battle.supports.assign([2, 2, 2])
	game._show_upgrades()
	check(game.options.size() == 2 and game.options.has("heal"), "Maxed build must offer finite fallback choices")
	game._clear_save()
	var broken: Dictionary = game.battle.snapshot()
	broken["weapons"] = 42
	check(not Battle.new(3).restore(broken), "Malformed save types must be rejected")
	game.audio.silence()
	await create_timer(0.1).timeout
	print("UI_TEST_OK" if failures == 0 else "UI_TEST_FAILED %d" % failures)
	quit(1 if failures else 0)
