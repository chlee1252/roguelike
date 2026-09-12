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
	for tab in 3:
		game._change_shop_tab(tab)
		await _capture("shop-" + str(tab))
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
	for theme_id in 4:
		game.field.theme_id = theme_id
		game.field.set_cat_variant(theme_id)
		game.field.queue_redraw()
		await _capture("theme-" + str(theme_id))
	game.field.theme_id = 0
	game.field.set_cat_variant(0)
	game.battle.aim = Vector2.RIGHT
	game.battle.paw_clock = 0.45
	game.battle.add_effect(game.battle.player + Vector2(46, -12), 14, 0.42, 2)
	game.battle.effects[-1].life = 0.32
	game.field.queue_redraw()
	await _capture("firing-impact")
	var stage_boss: int = game.battle.spawn_enemy(7, game.battle.player + Vector2(100, 15))
	game.battle.enemies.health[stage_boss] = game.battle.boss_max_hp * 0.4
	game._update_hud(0)
	game.field.queue_redraw()
	await _capture("stage-boss")
	game.battle.enemies.release(stage_boss)
	game.battle.pending_levels = 1
	game._show_upgrades()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/upgrades.png")
	game.state = "playing"
	game.pause_run()
	await _capture("pause")
	game._show_settings()
	await _capture("settings")
	game.battle.victory = true
	game._show_results()
	await _capture("victory")
	game.battle.victory = false
	game._show_results()
	await _capture("results")
	game._clear_save()
	game.audio.silence()
	await create_timer(0.1).timeout
	print("VISUAL_TEST_OK")
	quit()

func _capture(screen_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/" + screen_name + ".png")
