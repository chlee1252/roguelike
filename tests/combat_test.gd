extends SceneTree
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	var pool := EntityPool.new(2)
	var id := pool.spawn(Vector2.ONE, 1, 12)
	pool.burn[id] = 3
	var generation := pool.generation[id]
	pool.release(id)
	pool.release(id)
	check(pool.count == 0 and pool.free.size() == 2, "Pool release must be idempotent")
	var reused := pool.spawn(Vector2.ZERO, 0, 10)
	check(reused == id and pool.burn[id] == 0 and pool.generation[id] > generation, "Reused slot must reset state and advance generation")
	pool.spawn(Vector2.ZERO, 0, 10)
	check(pool.spawn(Vector2.ZERO, 0, 10) == -1, "Pool must enforce capacity")
	var sim := Battle.new(123)
	sim.god_mode = true
	var start := sim.player
	sim.step(0.1, Vector2(1, 1))
	check(is_equal_approx(start.distance_to(sim.player), 10), "Diagonal movement must be normalized")
	sim.spawn_enemy(0, sim.player + Vector2(45, 0))
	for frame in 120:
		sim.step(1.0 / 60.0, Vector2.ZERO)
	check(sim.kills > 0, "Automatic machine gun must kill a nearby enemy")
	sim.pending_levels = 0
	sim.xp = 0
	sim._drop_xp(sim.player, 30)
	sim._collect(0.016)
	check(sim.pending_levels > 0, "XP pickup must trigger level-up")
	var paused_time := sim.elapsed
	sim.step(1, Vector2.ONE)
	check(sim.elapsed == paused_time, "Level-up must freeze simulation")
	sim.pending_levels = 0
	sim.weapons = [6, 6, 6]
	sim.supports = [2, 2, 2]
	sim.caches.append(sim.player)
	sim._collect(0)
	check(sim.evolved[0] and sim.caches.is_empty(), "Eligible cache must evolve exactly one weapon")
	var health_sim := Battle.new(2)
	health_sim.hurt_player(10)
	health_sim.hurt_player(10)
	check(health_sim.hp == 90, "Invulnerability must prevent stacked same-frame hits")
	health_sim.elapsed = 599.99
	health_sim.step(0.02, Vector2.ZERO)
	check(health_sim.finished and health_sim.victory, "Extraction must resolve at ten minutes")
	print("COMBAT_TESTS_OK" if failures == 0 else "COMBAT_TESTS_FAILED %d" % failures)
	quit(1 if failures else 0)
