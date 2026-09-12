extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_weapons()
	_passives()
	_stages()
	_progress()
	await _ui()
	print("ADVENTURE_TEST_OK" if failures == 0 else "ADVENTURE_TEST_FAILED")
	quit(1 if failures else 0)

func only_weapon(index: int) -> Battle:
	var sim := Battle.new(17)
	sim.weapons.fill(0)
	sim.weapons[index] = 1
	return sim

func _weapons() -> void:
	var hiss := only_weapon(3)
	var foe := hiss.spawn_enemy(0, hiss.player + Vector2(50, 0))
	hiss.enemies.health[foe] = 100
	hiss._rebuild_grid()
	hiss._weapons(0.01)
	check(hiss.enemies.health[foe] < 100 and hiss.enemies.fear[foe] > 0, "Hiss must damage and frighten even an edge target")
	check(hiss.enemies.position[foe].distance_to(hiss.player) > 50, "Hiss must open an escape gap")
	var bag := only_weapon(4)
	bag._weapons(1)
	check(bag.lures.is_empty(), "Bag must not appear without travel")
	bag.bag_distance = 90
	bag._weapons(0.01)
	check(bag.lures.size() == 1 and bag.lures[0].kind == 0, "Distance must produce a decoy")
	bag._lure_effects(10)
	check(bag.lures.is_empty() and not bag.blasts.is_empty(), "Bag must pop after its decoy expires")
	var bottle := only_weapon(5)
	var shot := bottle.shots.spawn(Vector2(325, 30), 5, 20, Vector2(280, 0), 3)
	bottle.shots.mode[shot] = 1
	bottle.shots.aux[shot] = 6
	bottle._bottle_reflect(shot, Vector2(315, 30))
	check(bottle.shots.velocity[shot].x < 0 and bottle.shots.health[shot] > 20 and bottle.shots.mode[shot] == 0, "Wall reflection must reverse and strengthen the bottle cap")
	bottle.shots.position[shot] = Vector2(325, 30)
	bottle._bottle_reflect(shot, Vector2(315, 30))
	check(not bottle.shots.alive[shot], "Bottle must expire when reflection budget is exhausted")
	var box := only_weapon(6)
	box._weapons(1.31)
	check(box.blasts.is_empty(), "Box must charge without attacking while stationary")
	box.moving = true
	box._weapons(0.01)
	check(box.blasts.size() == 1 and box.ambush_charge == 0, "Moving after charging must release exactly one ambush")
	box._weapons(0.1)
	check(box.blasts.size() == 1, "Ambush cannot repeat without another charge")
	var bell := only_weapon(7)
	var target := bell.spawn_enemy(0, bell.player + Vector2(65, 0))
	bell._rebuild_grid()
	bell._add_lure(bell.player, 1, 3)
	bell._lure_effects(0.1)
	check(bell.enemies.position[target].distance_to(bell.player) < 65 and not bell.blasts.is_empty(), "Bell must pull and pulse")
	var slots := Battle.new(5)
	slots.weapons.assign([1, 1, 1, 1, 0, 0, 0, 0])
	check(not slots.can_upgrade("w4") and slots.can_upgrade("w0"), "Four weapon slots must still permit owned upgrades")
	slots.supports.assign([1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0])
	check(not slots.can_upgrade("s10") and slots.can_upgrade("s0"), "Four passive slots must constrain acquisition")
	var evolutions := 0
	for weapon in 8:
		var sim := only_weapon(weapon)
		sim.weapons[weapon] = 6
		var partner: int = NightContent.EVO_SUPPORT[weapon]
		if partner >= 0:
			sim.supports[partner] = 2
			sim.caches.append(sim.player)
			sim._collect(0)
			check(sim.evolved[weapon], "Evolution must consume the correct passive and cache")
			evolutions += 1
		else:
			check(sim.eligible_evolutions().is_empty(), "Non-evolving weapons must not advertise an evolution")
	check(evolutions == 6, "Six real evolution paths must exist")

func _passives() -> void:
	var sim := Battle.new(6)
	sim.supports[3] = 2
	var start := sim.player
	sim.step(0.1, Vector2.RIGHT)
	check(is_equal_approx(sim.player.distance_to(start), 11.6), "Clean paws must boost movement")
	sim.supports[4] = 2
	var pickup := sim.pickups.spawn(sim.player + Vector2(85, 0), 0, 1)
	sim._collect(0.1)
	check(sim.pickups.position[pickup].distance_to(sim.player) < 85, "Whiskers must extend pickup range")
	sim.hp = 40
	sim.supports[8] = 2
	sim._take_item(1)
	check(sim.hp == 75, "Kindness must increase food healing")
	sim.hp = 100
	sim.supports[9] = 2
	sim.hurt_player(10)
	check(is_equal_approx(sim.hp, 91.6), "Paw pads must reduce incoming damage")
	sim._take_item(5)
	check(sim.catnip == 8, "Catnip must grant a temporary buff")
	sim._take_item(7)
	sim._lure_effects(0.1)
	check(sim.invulnerable > 0 and sim.lures[0].kind == 2, "Blanket must create a temporary safe resting area")
	var focus := Battle.new(7)
	focus.supports[11] = 2
	focus.still_time = 1.1
	var foe := focus.spawn_enemy(0, focus.player + Vector2(30, 0))
	focus.enemies.health[foe] = 100
	focus._hurt_enemy(foe, 20, 0)
	check(is_equal_approx(focus.enemies.health[foe], 75.2), "Stillness must improve damage")

func _stages() -> void:
	var patterns: Array[int] = []
	for stage in 3:
		var sim := Battle.new(3)
		sim.configure(stage, 0, [0, 1, 2, 3], 0)
		check(not sim._building_at(sim.player), "Stage spawn must be walkable")
		for landmark in sim.landmarks:
			check(not sim._building_at(landmark.at), "Stage interactions must be reachable")
		sim.elapsed = NightContent.BOSS_AT[stage] + 0.01
		sim._spawn(0.01)
		check(sim.boss_health() > 0 and sim.fired_events.has(NightContent.BOSS_AT[stage]), "Each stage must summon its boss on time")
		for id in sim.enemies.capacity:
			if sim.enemies.alive[id] and sim.enemies.kind[id] == 7:
				sim._enemy_attack(id, 7, Vector2.RIGHT)
				patterns.append(sim.hostile.count)
				sim._hurt_enemy(id, 100000, 0)
		check(sim.finished and sim.victory and sim.clue_found, "Boss defeat must finish and reveal the stage clue")
	check(patterns == [9, 12, 13], "Bosses must use distinct fan, crossing lane, and ring patterns")
	check(NightContent.buildings(0) != NightContent.buildings(1) and NightContent.buildings(1) != NightContent.buildings(2), "Stages must have actual geometry differences")
	var challenge := Battle.new(8)
	challenge.configure(0, 1, [0], 0)
	var boss := challenge.spawn_enemy(7, challenge.player + Vector2(100, 0))
	challenge._enemy_attack(boss, 7, Vector2.RIGHT)
	check(challenge.hostile.count == 11, "Challenge must change the attack pattern")
	var clue := Battle.new(4)
	clue.elapsed = 46
	clue._night_events(0)
	clue.player = clue.clue_at
	clue._night_events(0)
	check(clue.clue_found, "Walking to an environmental clue must discover it")
	var restored := Battle.new(1)
	clue._add_lure(clue.player, 1, 3)
	clue.ambush_charge = 0.6
	check(restored.restore(bytes_to_var(var_to_bytes(clue.snapshot()))), "Expanded run must restore")
	check(var_to_bytes(restored.snapshot()) == var_to_bytes(clue.snapshot()), "Restore must preserve new weapon, story and event state")
	var legacy := clue.snapshot().duplicate(true)
	legacy.version = 3
	for key in ["weapons", "supports", "evolved", "damage_dealt"]:
		legacy[key].resize(3)
	for key in ["stage_id", "difficulty", "available", "landmarks", "extra_clocks", "still_time", "bag_distance", "ambush_charge", "catnip", "lures", "clue_at", "clue_found", "next_event", "last_damage"]:
		legacy.erase(key)
	for key in ["enemies", "shots", "hostile", "pickups"]:
		legacy[key].erase("fear")
	check(Battle.new(1).restore(legacy), "Version-three runs must migrate without losing their run")
	var broken := clue.snapshot().duplicate(true)
	broken.lures[0].at = "invalid"
	check(not Battle.new(1).restore(broken), "Malformed lure data must be rejected before restore")
	for stage in 3:
		var sim := Battle.new(8)
		sim.configure(stage, 0, [0], 0)
		var inside: Vector2 = sim.obstacles[0].get_center()
		sim._drop_xp(inside, 5)
		for id in sim.pickups.capacity:
			if sim.pickups.alive[id]:
				check(not sim._building_at(sim.pickups.position[id]), "Defeated ghosts must drop XP outside solid geometry")

func _progress() -> void:
	var path := "user://adventure-unit.cfg"
	for suffix in ["", ".pending", ".pending.tmp"]:
		DirAccess.remove_absolute(path + suffix)
	var progress := NightProgress.new()
	progress.open(path)
	check(progress.stage_open(0) and not progress.stage_open(1), "Only first stage must begin unlocked")
	check(progress.record_result("run-a", 0, true, 600.0, true), "Completed run must bank progress")
	var balance := progress.memories
	check(progress.record_result("run-a", 0, true, 600.0, true) and progress.memories == balance, "Results must not award twice")
	check(progress.stage_open(1) and progress.clues.has(0), "Victory must unlock next area and clue")
	check(progress.buy_furniture(0) and progress.available_weapons().has(4), "Shelter furnishing must unlock a playable weapon")
	check(not progress.buy_furniture(0), "Owned furniture must not charge twice")
	check(progress.choose_starter(4), "Unlocked weapon can become the starter")
	var reload := NightProgress.new()
	reload.open(path)
	check(reload.starter == 4 and reload.memories == balance - 3 and reload.stage_open(1), "Persistent progression must survive restart")
	var journal := ConfigFile.new()
	journal.set_value("claim", "data", ["run-b", 1, true, 720.0, true])
	journal.save(path + ".pending")
	check(reload.recover_pending() and reload.stage_open(2), "Interrupted result settlement must recover from its journal")
	var settled_balance := reload.memories
	check(reload.recover_pending() and reload.memories == settled_balance, "Journal recovery must be idempotent")
	reload.path = "user://missing-adventure-directory/save.cfg"
	var old := reload.memories
	check(not reload.buy_furniture(1) and reload.memories == old, "Failed progression save must roll back")
	DirAccess.remove_absolute(path)

func _ui() -> void:
	var game := (load("res://app/game.tscn") as PackedScene).instantiate()
	game.save_path = "user://adventure-ui.dat"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game._show_stages()
	check(game.state == "stages", "Stage selection must open")
	game._begin_stage(2)
	check(game.state == "stages", "Locked stage cannot be entered")
	game._begin_stage(0)
	game.battle.pending_levels = 1
	game.battle.level = 8
	game.battle.supports[10] = 1
	game._show_upgrades()
	check(not game._describe("s10")[0].is_empty(), "Two-digit passive IDs must render correctly")
	game._show_shelter()
	game._shelter_tab(1)
	game.progress.starter = 4 # Legacy global selection must not override cat identity.
	for cat in 4:
		game.collection.selected = cat
		game.start_run()
		check(game.battle.weapons[NightContent.CAT_STARTERS[cat]] == 1, "Each cat must use its own default weapon")
		check(game.battle.occupied_weapon_slots() == 1, "A new run starts with exactly one weapon")
	game._clear_save()
	DirAccess.remove_absolute(game.save_path + ".progress.cfg")
	game.audio.silence()
	game.queue_free()
	await create_timer(0.15).timeout
