extends SceneTree
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var sim := Battle.new(918)
	sim.god_mode = true
	var times := PackedFloat64Array()
	var max_enemies := 0
	var max_hostile := 0
	for frame in 72001:
		# A collection-focused bot follows nearby XP and otherwise circles.
		var target := sim.player + Vector2.from_angle(sim.elapsed * 0.3) * 100
		var best := 160.0 * 160.0
		for i in sim.pickups.capacity:
			if sim.pickups.alive[i]:
				var distance := sim.pickups.position[i].distance_squared_to(sim.player)
				if distance < best:
					best = distance
					target = sim.pickups.position[i]
		for cache in sim.caches:
			if not sim.eligible_evolutions().is_empty():
				target = cache
		while sim.pending_levels > 0:
			_upgrade(sim)
			check(sim.pending_levels >= 0, "Pending levels cannot be negative")
		var start := Time.get_ticks_usec()
		sim.step(1.0 / 60.0, sim.player.direction_to(target))
		times.append((Time.get_ticks_usec() - start) / 1000.0)
		max_enemies = maxi(max_enemies, sim.enemies.count)
		max_hostile = maxi(max_hostile, sim.hostile.count)
		if frame % 3600 == 0:
			print("RUN minute=%d level=%d kills=%d enemies=%d evolved=%s" % [frame / 3600, sim.level, sim.kills, sim.enemies.count, sim.evolved])
			await process_frame
		if frame == 18000:
			var data: Dictionary = bytes_to_var(var_to_bytes(sim.snapshot()))
			var restored := Battle.new(1)
			check(restored.restore(data), "Complete save must restore")
			check(restored.rng.state == sim.rng.state and restored.enemies.count == sim.enemies.count, "Save must preserve random and pool state")
			restored.god_mode = true
			sim.step(1.0 / 60.0, Vector2.RIGHT)
			restored.step(1.0 / 60.0, Vector2.RIGHT)
			check(var_to_bytes(sim.snapshot()) == var_to_bytes(restored.snapshot()), "Restored run must continue identically")
		if sim.finished:
			break
	check(sim.finished and sim.victory and sim.fired_events.has("boss_defeated"), "Full run must defeat its stage boss")
	check(sim.fired_events.has(840), "Final boss event must occur")
	check(sim.level >= 15, "XP economy must provide substantial upgrades")
	check(sim.evolved.has(true), "Normal XP and cache progression must allow an evolution")
	check(max_enemies <= 500 and max_hostile <= 600, "Entity caps must hold across the entire run")
	times.sort()
	print("SIMULATION p95_ms=%.3f max_ms=%.3f max_enemies=%d max_hostile=%d level=%d kills=%d" % [times[int(times.size() * 0.95)], times[-1], max_enemies, max_hostile, sim.level, sim.kills])
	_stress()
	print("FULL_RUN_TEST_OK" if failures == 0 else "FULL_RUN_TEST_FAILED %d" % failures)
	quit(1 if failures else 0)

func _upgrade(sim: Battle) -> void:
	# Acquire each weapon, focus the paw swipe evolution, then others.
	var applied := false
	for i in [1, 2]:
		if sim.weapons[i] == 0:
			sim.weapons[i] = 1
			applied = true
			break
	if not applied:
		for i in 3:
			if sim.weapons[i] < 6:
				sim.weapons[i] += 1
				applied = true
				break
			if sim.supports[i] < 2:
				sim.supports[i] += 1
				applied = true
				break
	sim.pending_levels -= 1

func _stress() -> void:
	var sim := Battle.new(11)
	sim.god_mode = true
	sim.elapsed = 500
	sim.weapons.assign([6, 6, 6])
	sim.supports.assign([2, 2, 2])
	sim.evolved.assign([true, true, true])
	for i in 500:
		var id := sim.spawn_enemy(i % 6, sim.player + Vector2.from_angle(i * 2.4) * (30 + i % 260))
		sim.enemies.health[id] = 100000
	for i in 600:
		sim.hostile.spawn(sim.player + Vector2.from_angle(i) * 200, 1, 8, Vector2.from_angle(i) * 10, 60)
	var times := PackedFloat64Array()
	for frame in 600:
		var start := Time.get_ticks_usec()
		sim.step(1.0 / 60.0, Vector2.ZERO)
		times.append((Time.get_ticks_usec() - start) / 1000.0)
	times.sort()
	print("STRESS 500 enemies / 600 hostile projectiles: p95_ms=%.3f max_ms=%.3f" % [times[570], times[-1]])
	check(sim.enemies.count <= 500 and sim.hostile.count <= 600, "Stress pools must remain bounded")
