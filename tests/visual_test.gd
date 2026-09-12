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
	game._show_stages()
	await _capture("stage-selection")
	game.progress.memories = 20
	game.progress.furniture.assign([0, 1, 2, 3])
	game.progress.clues.assign([0, 1, 2])
	game.progress.cleared.assign([0, 1, 2])
	for tab in 3:
		game._shelter_tab(tab)
		await _capture("shelter-" + str(tab))
	game.start_run()
	game.battle.god_mode = true
	game.battle.weapons.assign([4, 4, 4, 0, 0, 0, 0, 0])
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
	game.battle.add_effect(game.battle.player + Vector2(45, -12), 10, 0.32, 5)
	game.battle.effects[-1]["damage"] = 54
	game.battle.effects[-1].life = 0.22
	game._update_chain(18, 0.01)
	game.field.queue_redraw()
	await _capture("firing-impact")
	game.battle.add_effect(game.battle.player, 115, 0.9, 6)
	game.battle.effects[-1].life = 0.45
	game.field.queue_redraw()
	await _capture("evolution-impact")
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
	for stage in 3:
		game.selected_stage = stage
		game.start_run()
		game.battle.god_mode = true
		game.battle.elapsed = NightContent.BOSS_AT[stage] + 0.1
		game.battle.weapons.assign([0, 0, 0, 6, 6, 0, 6, 6])
		game.battle.spawn_enemy(7, game.battle.player + Vector2(100, -10))
		game.battle._add_lure(game.battle.player + Vector2(60, 30), 1, 3)
		game.battle._add_lure(game.battle.player + Vector2(-60, 20), 0, 3)
		game.battle._add_lure(game.battle.player + Vector2(20, 55), 2, 3)
		game.battle._rebuild_grid()
		for frame in 30:
			game.battle.step(1.0 / 60, Vector2.ZERO)
		game._update_hud(0)
		game.field.queue_redraw()
		await _capture("region-" + str(stage))
		game._show_story()
		await _capture("story-" + str(stage))
	game._clear_save()
	game.audio.silence()
	await create_timer(0.1).timeout
	print("VISUAL_TEST_OK")
	quit()

func _capture(screen_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/" + screen_name + ".png")
