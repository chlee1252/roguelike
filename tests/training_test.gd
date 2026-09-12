extends SceneTree

var failures := 0
var progress_path := "user://training-unit.cfg"

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for suffix in ["", ".tmp", ".pending", ".pending.tmp"]:
		DirAccess.remove_absolute(progress_path + suffix)
	_collect_and_train()
	_limits_and_healing()
	_persistence()
	await _ui()
	for suffix in ["", ".tmp", ".pending", ".pending.tmp"]:
		DirAccess.remove_absolute(progress_path + suffix)
	print("TRAINING_TEST_OK" if failures == 0 else "TRAINING_TEST_FAILED")
	quit(1 if failures else 0)

func _collect_and_train() -> void:
	var sim := Battle.new(12)
	sim.elapsed = 180.0
	sim._night_events(0)
	check(sim.training_drops.size() == 3, "Three churu bundles must exist at three minutes")
	check(sim.training_churu == 0, "Spawning does not bank materials")
	for drop in sim.training_drops:
		check(not sim._building_at(drop.at), "Material must spawn outside walls")
		drop.at = sim.player
	sim._collect(0)
	check(sim.training_churu == 6 and sim.save_requested, "Pickup must count exact materials and request a save")
	sim._night_events(0)
	check(sim.training_drops.is_empty(), "Material event cannot repeat")
	sim._spawn(0.01)
	for id in sim.enemies.capacity:
		if sim.enemies.alive[id] and sim.elite_ids.has(id):
			sim._hurt_enemy(id, 100000, 0)
	check(sim.training_drops.size() == 1 and sim.caches.size() == 1, "Scheduled elite drops a can independently of its evolution cache")
	sim.training_drops[0].at = sim.player
	sim._collect(0)
	var progress := NightProgress.new()
	progress.open(progress_path)
	check(progress.record_result("loss", 0, false, 180.0, true, sim.training_churu, sim.training_can), "Loss must settle collected materials")
	check(progress.training_churu == 6 and progress.training_can == 1 and not progress.stage_open(1) and progress.clues.has(0), "Loss preserves materials and clues but cannot open next stage")
	check(progress.buy_training(0) and progress.buy_training(1), "First loss can fund both first exercises")
	check(progress.training_churu == 2 and progress.training_can == 0, "Exercise must charge exact cost")
	check(not progress.buy_training(1), "Unaffordable repeat purchase must fail")
	check(progress.record_result("loss", 0, false, 180.0, true, 6, 1) and progress.training_churu == 2, "Repeated results cannot duplicate materials")
	var fresh := Battle.new(12)
	fresh.configure(0, 0, [0, 1, 2, 3], 0, progress.whisker_level, progress.body_level)
	check(fresh.hp == 105 and fresh.max_hp == 105 and is_equal_approx(fresh.xp_radius(), 59.16), "Next run must apply exact level-one values")
	check(fresh.xp == 0 and fresh.level == 1 and fresh.supports[4] == 0, "Run upgrades must reset independently of training")
	check(progress.record_result("win", 0, true, 600.0, true, 18, 4), "Victory must settle")
	check(progress.training_churu == 24 and progress.training_can == 6 and progress.stage_open(1), "Victory adds collected amounts and exactly four churu / two cans")
	for stage in 3:
		var level := Battle.new(3)
		level.configure(stage, 0, [0], 0)
		level.elapsed = NightContent.DURATIONS[stage] + 1000.0
		level._night_events(0)
		check(level.training_drops.size() == 9 + stage * 2, "Each stage must cap scheduled churu")
		level._night_events(0)
		check(level.training_drops.size() == 9 + stage * 2, "Overtime cannot farm new material events")

func _limits_and_healing() -> void:
	var sim := Battle.new(7)
	sim.configure(0, 0, [0], 0, 20, 20)
	sim.supports[4] = 2
	check(sim.max_hp == 200 and is_equal_approx(sim.xp_radius(), 117.2), "Maximum training must use additive base-radius bonuses")
	sim.supports[4] = 0
	var xp := sim.pickups.spawn(sim.player + Vector2(70, 0), 0, 1)
	var food := sim.pickups.spawn(sim.player + Vector2(70, 0), 1, 1, Vector2.ZERO, 22)
	sim.training_drops.append({"at": sim.player + Vector2(70, 0), "kind": 0, "amount": 2})
	sim._collect(0.1)
	check(sim.pickups.position[xp].distance_to(sim.player) < 70, "Training attracts XP")
	check(sim.pickups.position[food].distance_to(sim.player) == 70 and sim.training_drops[0].at.distance_to(sim.player) == 70, "Training does not extend food/material attraction")
	for kind in [1, 2, 3, 4, 8]:
		sim.hp = 199
		sim._take_item(kind)
		check(sim.hp == 200, "Food must heal past 100 and clamp at trained maximum")
	sim.hp = 150
	for landmark in sim.landmarks:
		if landmark.kind == 1:
			sim.player = landmark.at
			sim._city_objects(1)
			check(sim.hp == 152, "Bowl must heal above 100")
			break
	sim.hp = 199
	sim._take_item(7)
	sim._lure_effects(0.6)
	check(sim.hp == 200, "Blanket must use trained health cap")
	sim.hp = 199
	sim.food_regen = 3
	sim.step(0.5, Vector2.ZERO)
	check(sim.hp == 200, "Regeneration must use trained health cap")
	var boss := sim.spawn_enemy(7, sim.player + Vector2(100, 0))
	sim._hurt_enemy(boss, 100000, 0)
	sim.invulnerable = 0
	sim.hurt_player(999)
	check(sim.victory and sim.hp == 200, "A defeated boss must stop subsequent hostile damage")

func _persistence() -> void:
	var progress := NightProgress.new()
	progress.open(progress_path)
	check(progress.whisker_level == 1 and progress.body_level == 1 and progress.training_churu == 24, "Training and balances survive reload")
	var original_path := progress.path
	progress.path = "user://training-missing-dir/save.cfg"
	var balance := progress.training_churu
	check(not progress.buy_training(0) and progress.training_churu == balance and progress.whisker_level == 1, "Failed save rolls back both balance and rank")
	progress.path = original_path
	progress.whisker_level = 20
	check(not progress.buy_training(0) and progress.training_churu == balance, "Maximum rank must not charge")
	check(not progress.buy_training(-1), "Invalid exercise must be rejected")
	check(not progress.record_result("invalid", 0, false, 180.0, false, -1, 0) and not FileAccess.file_exists(progress_path + ".pending"), "Invalid result must not poison the recovery journal")
	var journal := ConfigFile.new()
	journal.set_value("claim", "data", ["legacy", 1, true, 720.0, true])
	journal.save(progress_path + ".pending")
	check(progress.recover_pending() and progress.training_churu == balance, "Legacy pending settlement must not invent training rewards")
	journal.set_value("claim", "data", ["recovery", 0, false, 180.0, true, 6, 1, 0, 0])
	journal.save(progress_path + ".pending")
	check(progress.recover_pending() and progress.training_churu == balance + 6, "New pending materials recover")
	check(progress.recover_pending() and progress.training_churu == balance + 6, "Recovery must be idempotent")
	var sim := Battle.new(21)
	sim.configure(1, 0, [0], 0, 3, 4)
	sim.elapsed = 100.0
	sim._night_events(0)
	sim.training_churu = 2
	var data: Dictionary = bytes_to_var(var_to_bytes(sim.snapshot()))
	var restored := Battle.new(1)
	check(restored.restore(data), "Trained run snapshot must restore")
	check(var_to_bytes(restored.snapshot()) == var_to_bytes(sim.snapshot()), "Restore must preserve trained stats, materials, events and RNG exactly")
	restored._night_events(0)
	check(restored.training_drops.size() == 2, "Resume cannot regenerate material events")
	data.body_level = 21
	check(not Battle.new(1).restore(data), "Malformed training rank must be rejected")
	data = sim.snapshot().duplicate(true)
	data.version = 4
	data.hp = 100.0
	for key in ["max_hp", "whisker_level", "body_level", "training_churu", "training_can", "training_drops", "next_training"]:
		data.erase(key)
	check(restored.restore(data) and restored.max_hp == 100 and restored.whisker_level == 0, "Legacy run keeps baseline stats")
	restored._night_events(0)
	check(restored.training_drops.is_empty(), "Legacy migration must not backfill elapsed material events")
	var legacy := ConfigFile.new()
	legacy.set_value("progress", "data", {"memories": 9, "cleared": [0], "furniture": [0], "clues": [0], "settled": ["old"], "starter": 4})
	legacy.save(progress_path)
	var migrated := NightProgress.new()
	migrated.open(progress_path)
	check(migrated.memories == 9 and migrated.furniture.has(0) and migrated.stage_open(1) and migrated.training_churu == 0 and migrated.body_level == 0, "Legacy progress must preserve unlocks and start exercise at zero")
	legacy.set_value("progress", "data", {"memories": 9, "training_churu": -1})
	legacy.save(progress_path)
	var corrupt := NightProgress.new()
	corrupt.open(progress_path)
	check(not corrupt.load_ok and not corrupt.record_result("new", 0, true, 600.0, true) and not corrupt.buy_training(0), "Malformed permanent data must be preserved instead of overwritten")
	for stage in 3:
		var level := Battle.new(2)
		level.configure(stage, 0, [0])
		level.elapsed = NightContent.BOSS_AT[stage] - 10.0
		level._night_events(0)
		check(level.fired_events.has("boss_warning"), "Each boss must give ten seconds of warning")
		var at := level.boss_position()
		for obstacle in level.obstacles:
			check(not obstacle.grow(96).has_point(at), "Boss must have a clear space around its spawn")
		for spot in [Vector2(30, 30), Vector2(2350, 1550), Vector2(640, 540), Vector2(1100, 1120), Vector2(1720, 900)]:
			level.fired_events.erase("boss_at")
			level.player = level.open_position(spot)
			at = level.boss_position()
			check(level.fired_events.has("boss_at"), "Boss warning marker must exist even when angular search misses an aisle")
			for obstacle in level.obstacles:
				check(not obstacle.grow(96).has_point(at), "Boss spawn must retain clearance across the map")

func _ui() -> void:
	var game := (load("res://app/game.tscn") as PackedScene).instantiate()
	game.save_path = "user://training-ui.dat"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.progress = NightProgress.new()
	game.progress.path = "user://training-ui-progress.cfg"
	game.progress.training_churu = 6
	game.progress.training_can = 1
	game._show_training()
	check(game.state == "training", "Exercise menu must open")
	game._train(0)
	game._train(1)
	for cat in 4:
		game.collection.selected = cat
		game.start_run()
		check(game.battle.max_hp == 105 and game.battle.whisker_level == 1, "All cats share exercise")
	game._update_hud(0)
	check(game.health_bar.max_value == 105, "HUD must use trained maximum")
	game._save_session()
	game.progress.body_level = 2
	game._show_menu()
	game._continue_run()
	check(game.battle.max_hp == 105, "Resuming must retain start-of-run training even if permanent training changes")
	game.progress.body_level = 1
	game.battle.training_churu = 2
	game._save_session()
	var archived := {"run_id": game.run_id, "battle": game.battle.snapshot(), "options": []}
	game._end_walk()
	check(game.result_saved and game.progress.training_churu == 4, "Explicit exit must bank collected materials")
	game._show_results()
	check(game.progress.training_churu == 4, "Results repaint must not duplicate rewards")
	var stale_save := FileAccess.open(game.save_path, FileAccess.WRITE)
	stale_save.store_var(archived)
	stale_save.close()
	game._continue_run()
	check(game.state == "shelter" and not FileAccess.file_exists(game.save_path) and game.progress.training_churu == 4, "A previously settled saved run cannot be resumed for duplicate rewards")
	game._clear_save()
	DirAccess.remove_absolute(game.progress.path)
	game.audio.silence()
	game.queue_free()
	await create_timer(0.15).timeout
