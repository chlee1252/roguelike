extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://app/game.tscn") as PackedScene
	var game := scene.instantiate()
	game.save_path = "user://visual-test.dat"
	root.add_child(game)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/menu.png")
	game.start_run()
	game.battle.god_mode = true
	game.battle.weapons.assign([4, 4, 4])
	game.battle.elapsed = 365
	for i in 65:
		game.battle.spawn_enemy(i % 6, game.battle.player + Vector2.from_angle(i * 2.4) * (50 + i * 3))
	game.set_physics_process(false)
	for frame in 300:
		game.battle.pending_levels = 0
		game.battle.step(1.0 / 60.0, Vector2.from_angle(frame * 0.012))
	game._update_hud(0)
	game.field.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/combat.png")
	game.battle.pending_levels = 1
	game._show_upgrades()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/upgrades.png")
	game._clear_save()
	game.audio.silence()
	await create_timer(0.1).timeout
	print("VISUAL_TEST_OK")
	quit()
