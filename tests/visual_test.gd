extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene := load("res://app/game.tscn") as PackedScene
	var game := scene.instantiate()
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
	for frame in 100:
		await process_frame
	game.set_physics_process(false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/combat.png")
	game.battle.pending_levels = 1
	game._show_upgrades()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/upgrades.png")
	print("VISUAL_TEST_OK")
	quit()
