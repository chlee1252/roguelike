class_name Battle
extends RefCounted

const WORLD := Vector2(2400, 1600)
const VIEW := Vector2(640, 360)
const ENEMY_HP := [16.0, 26.0, 22.0, 45.0, 220.0, 160.0, 480.0, 2400.0]
const ENEMY_SPEED := [29.0, 22.0, 42.0, 19.0, 14.0, 35.0, 25.0, 12.0]
const ENEMY_RADIUS := [8.0, 8.0, 8.0, 9.0, 20.0, 22.0, 13.0, 30.0]
const WAVE_CAP := [80, 120, 170, 220, 280, 330, 380, 430, 480, 500]
const WAVE_RATE := [3.0, 5.0, 7.0, 9.0, 11.0, 13.0, 15.0, 17.0, 19.0, 14.0]
const TITLES := ["첫 교전", "엇갈리는 포화", "돌격의 시간", "중장갑 부대", "포위망 돌파", "공중 습격", "합동 공세", "고립된 전선", "마지막 저항", "탈출 작전"]
var enemies := EntityPool.new(500)
var shots := EntityPool.new(400)
var hostile := EntityPool.new(600)
var pickups := EntityPool.new(250)
var grid: Dictionary = {}
var rng := RandomNumberGenerator.new()
var player := WORLD * 0.5
var aim := Vector2.RIGHT
var hp := 100.0
var elapsed := 0.0
var kills := 0
var level := 1
var xp := 0
var pending_levels := 0
var finished := false
var victory := false
var invulnerable := 0.0
var spawn_clock := 0.0
var gun_clock := 0.0
var flame_clock := 0.0
var artillery_clock := 3.0
var weapons: Array[int] = [1, 0, 0]
var supports: Array[int] = [0, 0, 0]
var evolved: Array[bool] = [false, false, false]
var blasts: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var events: Array[String] = []
var caches: Array[Vector2] = []
var hit_flash := 0.0
var sound_events: Array[String] = []
var god_mode := false
var fired_events: Dictionary = {}
var rerolls := 1
var shot_hits: Dictionary = {}
var elite_ids: Dictionary = {}
var fires: Array[Dictionary] = []
var volley_clock := 0.0
var fire_clock := 0.0
var flame_direction := Vector2.RIGHT
var flame_active := false
var damage_dealt: Array[float] = [0.0, 0.0, 0.0]

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

func xp_needed() -> int:
	return 8 + 18 * (level - 1)

func minute() -> int:
	return mini(9, int(elapsed / 60.0))

func camera() -> Vector2:
	return player.clamp(VIEW * 0.5, WORLD - VIEW * 0.5)

func step(dt: float, movement: Vector2) -> void:
	if finished or pending_levels > 0:
		return
	elapsed = minf(600.0, elapsed + dt)
	if elapsed >= 600.0:
		finished = true
		victory = true
		return
	invulnerable = maxf(0.0, invulnerable - dt)
	hit_flash = maxf(0.0, hit_flash - dt)
	player = (player + movement.limit_length() * 100.0 * dt).clamp(Vector2(20, 20), WORLD - Vector2(20, 20))
	if movement.length_squared() > 0.01:
		aim = movement.normalized()
	volley_clock = maxf(0, volley_clock - dt)
	_spawn(dt)
	_move_enemies(dt)
	_rebuild_grid()
	_weapons(dt)
	_projectiles(dt)
	_explosions(dt)
	_tick_fires(dt)
	_collect(dt)
	for i in range(effects.size() - 1, -1, -1):
		effects[i].life -= dt
		if effects[i].life <= 0:
			effects.remove_at(i)
	if hp <= 0 and not god_mode:
		finished = true
		victory = false

func _spawn(dt: float) -> void:
	spawn_clock -= dt
	if spawn_clock <= 0:
		spawn_clock = 1.0 / WAVE_RATE[minute()]
		if enemies.count < WAVE_CAP[minute()]:
			var type := 0
			var roll := rng.randf()
			if elapsed > 40 and roll > 0.78:
				type = 1
			if elapsed > 120 and roll < 0.16:
				type = 2
			if elapsed > 220 and roll > 0.98:
				type = 3
			if elapsed > 300 and roll > 0.955 and roll <= 0.98:
				type = 4 if rng.randf() < 0.55 else 5
			if type < 3 or _type_count(type) < ([0, 0, 0, 4, 3, 2][type]):
				spawn_enemy(type, _spawn_position())
	for event in [[150, 6], [195, 4], [220, 3], [260, 4], [310, 5], [390, 5], [460, 6], [520, 4], [540, 7]]:
		if elapsed >= event[0] and not fired_events.has(event[0]):
			if enemies.count >= enemies.capacity:
				for i in enemies.capacity:
					if enemies.alive[i] and enemies.kind[i] == 0:
						enemies.release(i)
						break
			var spawned := spawn_enemy(event[1], _spawn_position())
			if event[0] in [150, 260, 390, 460, 520] and spawned >= 0:
				elite_ids[spawned] = enemies.generation[spawned]
				enemies.health[spawned] *= 1.8
			fired_events[event[0]] = true
			events.append("지휘 전차 접근 중" if event[1] == 7 else "정예 부대 출현" if event[1] == 6 else "적 증원 병력 접근")

func _type_count(type: int) -> int:
	var count := 0
	for i in enemies.capacity:
		if enemies.alive[i] and enemies.kind[i] == type:
			count += 1
	return count

func _spawn_position() -> Vector2:
	var center := camera()
	var offset := Vector2.ZERO
	var edge := rng.randi_range(0, 3)
	if edge < 2:
		offset = Vector2(rng.randf_range(-350, 350), -210 if edge == 0 else 210)
	else:
		offset = Vector2(-350 if edge == 2 else 350, rng.randf_range(-210, 210))
	return center + offset

func spawn_enemy(type: int, at: Vector2) -> int:
	var id := enemies.spawn(at, type, ENEMY_HP[type] * (1.0 + minute() * 0.1))
	if id >= 0:
		enemies.timer[id] = rng.randf_range(1.5, 4.0)
	return id

func _move_enemies(dt: float) -> void:
	for i in enemies.capacity:
		if not enemies.alive[i]:
			continue
		var type := enemies.kind[i]
		var diff := player - enemies.position[i]
		var distance := diff.length()
		var direction := diff / maxf(distance, 0.01)
		var speed: float = ENEMY_SPEED[type]
		if type == 1 or type == 3:
			if distance < 135:
				speed = 0
		if type == 5:
			direction = (direction * 0.4 + direction.orthogonal() * 0.6).normalized()
		if enemies.aux[i] > 0:
			enemies.aux[i] -= dt
			speed *= 0.85 if type != 7 else 0.95
		if type == 2 and enemies.mode[i] == 1:
			speed = 0
		elif type == 2 and enemies.mode[i] == 2:
			direction = enemies.velocity[i]
			speed = 175
		enemies.position[i] += direction * speed * dt
		if enemies.burn[i] > 0:
			enemies.burn[i] -= dt
			_hurt_enemy(i, 4.0 * dt, 1)
			if not enemies.alive[i]:
				continue
		enemies.timer[i] -= dt
		if type == 2 and enemies.mode[i] > 0 and enemies.timer[i] <= 0:
			if enemies.mode[i] == 1:
				enemies.mode[i] = 2
				enemies.velocity[i] = enemies.position[i].direction_to(enemies.target[i])
				enemies.timer[i] = 0.5
			else:
				enemies.mode[i] = 0
				enemies.timer[i] = 3.8
		elif enemies.timer[i] <= 0 and distance < 300 and (type == 0 or volley_clock <= 0) and Rect2(camera() - Vector2(300, 120), Vector2(600, 265)).has_point(enemies.position[i]):
			_enemy_attack(i, type, direction)
		if distance < ENEMY_RADIUS[type] + 6:
			hurt_player(20 if type >= 4 else 10)
		if distance > 650 and type < 6 and not elite_ids.has(i):
			enemies.release(i)

func _enemy_attack(id: int, type: int, direction: Vector2) -> void:
	enemies.timer[id] = 3.8 if type < 4 else 4.5
	if type == 0:
		return
	volley_clock = 0.22 if type < 4 else 0.5
	if type == 2:
		enemies.mode[id] = 1
		enemies.target[id] = player
		enemies.timer[id] = 0.65
		return
	if type == 5:
		if hostile.free.size() < 10:
			return
		var center := player + Vector2(0, -145 if enemies.position[id].y < player.y else 145)
		var travel := Vector2.DOWN if center.y < player.y else Vector2.UP
		for n in range(-6, 7):
			if absi(n) <= 1:
				continue
			var bullet := hostile.spawn(center + Vector2(n * 22, 0), 5, 12, travel * 65, 6)
			hostile.aux[bullet] = 1.1
		return
	if type == 3:
		_add_blast(player, 28, 20, 1.2, false, 0)
		return
	var amount := 3 if type < 4 else 5
	if type == 7:
		amount = 9
	if hostile.free.size() < amount:
		return
	# Delayed projectile activation provides a visible muzzle windup.
	for n in amount:
		var angle := (n - (amount - 1) * 0.5) * (0.20 if type != 7 else 0.28)
		var bullet := hostile.spawn(enemies.position[id], type, 8 if type < 4 else 20,
			direction.rotated(angle) * (65 if type < 4 else 55), 7.0)
		hostile.aux[bullet] = 0.65 if type < 4 else 1.0
	if type == 7:
		_add_blast(player + Vector2(45, 0), 28, 20, 1.4, false, 0)

func _rebuild_grid() -> void:
	grid.clear()
	for i in enemies.capacity:
		if enemies.alive[i]:
			var cell := Vector2i((enemies.position[i] / 64.0).floor())
			if not grid.has(cell):
				grid[cell] = []
			grid[cell].append(i)

func nearby(at: Vector2, radius: float) -> Array[int]:
	var result: Array[int] = []
	var low := Vector2i(((at - Vector2.ONE * radius) / 64.0).floor())
	var high := Vector2i(((at + Vector2.ONE * radius) / 64.0).floor())
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var cell := Vector2i(x, y)
			if grid.has(cell):
				result.append_array(grid[cell])
	return result

func nearest(at: Vector2, radius: float) -> int:
	var best := -1
	var distance := radius * radius
	for id in nearby(at, radius):
		var d := at.distance_squared_to(enemies.position[id])
		if enemies.alive[id] and d < distance:
			distance = d
			best = id
	return best

func dense_target(radius: float) -> int:
	var best := -1
	var score := -1
	for cell in grid:
		var center := Vector2(cell) * 64 + Vector2(32, 32)
		if center.distance_to(player) > radius:
			continue
		if grid[cell].size() > score:
			for id in grid[cell]:
				if enemies.alive[id] and enemies.position[id].distance_to(player) <= radius:
					score = grid[cell].size()
					best = id
					break
	return best

func _weapons(dt: float) -> void:
	gun_clock -= dt
	if gun_clock <= 0:
		var target := nearest(player, 300 if weapons[0] >= 5 else 260)
		if target >= 0:
			var direction := player.direction_to(enemies.position[target])
			aim = direction
			var count := 2 if evolved[0] else 1
			for n in count:
				var bullet := shots.spawn(player + direction.orthogonal() * (n * 5 - 2), 0,
					(17 if weapons[0] >= 5 else 13 if weapons[0] >= 2 else 10) * (1 + supports[0] * 0.1), direction * 440, 0.7)
				if bullet >= 0:
					shot_hits[bullet] = []
					shots.aux[bullet] = 3 if evolved[0] else 2 if weapons[0] >= 4 else 1
			gun_clock = 0.12 if evolved[0] else 0.16 if weapons[0] >= 6 else 0.20 if weapons[0] >= 3 else 0.25
			_sound("gun")
	flame_active = weapons[1] > 0 and (evolved[1] or fmod(elapsed, 4.5 if weapons[1] >= 6 else 3.5 if weapons[1] >= 5 else 4.0) < (3.0 if weapons[1] >= 6 else 2.0))
	flame_clock -= dt
	if flame_active and flame_clock <= 0:
		flame_clock = 0.2
		var reach := (90.0 if weapons[1] >= 3 else 70.0) * (1.0 + supports[1] * 0.1)
		var target := dense_target(reach)
		if target >= 0:
			flame_direction = player.direction_to(enemies.position[target])
		else:
			flame_direction = aim
		for id in nearby(player, reach + 22):
			var diff := enemies.position[id] - player
			if diff.length() < reach + ENEMY_RADIUS[enemies.kind[id]] and absf(flame_direction.angle_to(diff)) < deg_to_rad(45 if weapons[1] >= 5 else 30):
				if weapons[1] >= 4:
					enemies.burn[id] = 3
				_hurt_enemy(id, 9 if weapons[1] >= 6 else 7 if weapons[1] >= 2 else 5, 1)
	artillery_clock -= dt
	if weapons[2] > 0 and artillery_clock <= 0:
		var target := dense_target(300)
		if target >= 0:
			var count := 5 if evolved[2] else 2 if weapons[2] >= 4 else 1
			var center := enemies.position[target]
			for n in count:
				var offset := Vector2((n - 2) * 35, 0) if evolved[2] else Vector2(n * 22, 0)
				_add_blast(center + offset, 68 if weapons[2] >= 6 else 60 if weapons[2] >= 3 else 48,
					140 if weapons[2] >= 6 else 110 if weapons[2] >= 2 else 80, 0.8 + n * 0.25, true, 2)
			artillery_clock = (6.5 if weapons[2] >= 5 else 8.0) * (1.0 - supports[2] * 0.1)

func _projectiles(dt: float) -> void:
	for pool in [shots, hostile]:
		for i in pool.capacity:
			if not pool.alive[i]:
				continue
			if pool == hostile and pool.aux[i] > 0:
				pool.aux[i] -= dt
				continue
			var before: Vector2 = pool.position[i]
			pool.position[i] += pool.velocity[i] * dt
			pool.timer[i] -= dt
			if pool.timer[i] <= 0:
				pool.release(i)
				continue
			if pool == hostile:
				var closest := Geometry2D.get_closest_point_to_segment(player, before, pool.position[i])
				if closest.distance_squared_to(player) < 81:
					hurt_player(pool.health[i])
					pool.release(i)
			else:
				for id in nearby(pool.position[i], 40):
					if not enemies.alive[id]:
						continue
					var identity := Vector2i(id, enemies.generation[id])
					if shot_hits.get(i, []).has(identity):
						continue
					var closest := Geometry2D.get_closest_point_to_segment(enemies.position[id], before, pool.position[i])
					if closest.distance_to(enemies.position[id]) <= ENEMY_RADIUS[enemies.kind[id]] + 2:
						if not shot_hits.has(i):
							shot_hits[i] = []
						shot_hits[i].append(identity)
						if evolved[0]:
							enemies.aux[id] = 1.0
						_hurt_enemy(id, pool.health[i], 0)
						pool.aux[i] -= 1
						if pool.aux[i] <= 0:
							pool.release(i)
							break

func _add_blast(at: Vector2, radius: float, damage: float, delay: float, friendly: bool, weapon: int) -> void:
	if blasts.size() >= 32:
		return
	if not friendly:
		var hostile_count := 0
		for blast in blasts:
			if not blast.friendly:
				hostile_count += 1
		if hostile_count >= 3:
			return
	blasts.append({"at": at, "radius": radius, "damage": damage, "time": delay, "total": delay, "friendly": friendly, "weapon": weapon})

func _explosions(dt: float) -> void:
	for i in range(blasts.size() - 1, -1, -1):
		blasts[i].time -= dt
		if blasts[i].time > 0:
			continue
		var blast := blasts[i]
		if blast.friendly:
			for id in nearby(blast.at, blast.radius + 30):
				if enemies.alive[id] and enemies.position[id].distance_to(blast.at) < blast.radius + ENEMY_RADIUS[enemies.kind[id]]:
					_hurt_enemy(id, blast.damage, blast.weapon)
		else:
			if player.distance_to(blast.at) < blast.radius + 6:
				hurt_player(blast.damage)
		add_effect(blast.at, blast.radius, 0.35, 0 if blast.friendly else 1)
		_sound("blast")
		blasts.remove_at(i)

func _hurt_enemy(id: int, amount: float, weapon: int, can_spread: bool = true) -> void:
	if not enemies.alive[id]:
		return
	var bonus := 0.0
	if enemies.burn[id] > 0:
		if weapon == 0:
			bonus += 0.15
		if weapon == 2:
			bonus += 0.20
			enemies.burn[id] = 3.0
	if weapon == 2 and enemies.aux[id] > 0:
		bonus += 0.15
	amount *= 1.0 + minf(bonus, 0.35)
	damage_dealt[weapon] += minf(enemies.health[id], amount)
	enemies.health[id] -= amount
	if enemies.health[id] <= 0:
		var type := enemies.kind[id]
		var at := enemies.position[id]
		if evolved[1] and enemies.burn[id] > 0 and can_spread and fires.size() < 64:
			fires.append({"at": at, "life": 3.0})
		enemies.release(id)
		kills += 1
		_drop_xp(at, 30 if type >= 6 else 8 if type >= 4 else 2 if type > 0 else 1)
		if type == 6 or elite_ids.get(id, -1) == enemies.generation[id]:
			caches.append(at)
			elite_ids.erase(id)
		if type == 7:
			for bullet in hostile.capacity:
				hostile.release(bullet)
			events.append("지휘 전차 격파")
		if rng.randf() < 0.012:
			pickups.spawn(at + Vector2(8, 0), 1, 20)
		add_effect(at, 10 if type < 4 else 28, 0.22, 2)

func _drop_xp(at: Vector2, value: int) -> void:
	var closest := -1
	var distance := INF
	for i in pickups.capacity:
		if pickups.alive[i] and pickups.kind[i] == 0:
			var d := pickups.position[i].distance_squared_to(at)
			if d < distance:
				distance = d
				closest = i
	if closest >= 0 and (distance < 144 or pickups.free.is_empty()):
		pickups.health[closest] += value
	else:
		pickups.spawn(at, 0, value)

func _tick_fires(dt: float) -> void:
	for i in range(fires.size() - 1, -1, -1):
		fires[i].life -= dt
		if fires[i].life <= 0:
			fires.remove_at(i)
	fire_clock -= dt
	if fire_clock > 0 or fires.is_empty():
		return
	fire_clock = 0.2
	var damaged: Dictionary = {}
	for fire in fires:
		for id in nearby(fire.at, 22):
			if enemies.alive[id] and not damaged.has(id) and enemies.position[id].distance_to(fire.at) < 22:
				damaged[id] = true
				_hurt_enemy(id, 1.6, 1, false)

func _collect(dt: float) -> void:
	for i in pickups.capacity:
		if not pickups.alive[i]:
			continue
		var distance := pickups.position[i].distance_to(player)
		if distance < 58:
			pickups.position[i] = pickups.position[i].move_toward(player, 180 * dt)
		if distance < 12:
			if pickups.kind[i] == 0:
				xp += int(pickups.health[i])
			else:
				hp = minf(100, hp + pickups.health[i])
			pickups.release(i)
			_sound("pickup")
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_levels += 1
	for i in range(caches.size() - 1, -1, -1):
		if caches[i].distance_to(player) < 22:
			var eligible := eligible_evolutions()
			if not eligible.is_empty():
				evolved[eligible[0]] = true
				caches.remove_at(i)
				events.append(["케르베로스 진화 완료", "인페르노 진화 완료", "롤링 썬더 진화 완료"][eligible[0]])
				_sound("evolve")

func eligible_evolutions() -> Array[int]:
	var result: Array[int] = []
	for i in 3:
		if weapons[i] == 6 and supports[i] == 2 and not evolved[i]:
			result.append(i)
	return result

func hurt_player(amount: float) -> void:
	if invulnerable > 0 or god_mode:
		return
	hp = maxf(0, hp - amount)
	invulnerable = 0.6
	hit_flash = 0.2
	_sound("hit")

func add_effect(at: Vector2, radius: float, life: float, type: int) -> void:
	if effects.size() >= 100:
		effects.pop_front()
	effects.append({"at": at, "radius": radius, "life": life, "total": life, "kind": type})

func _sound(name: String) -> void:
	if sound_events.size() < 12 and not sound_events.has(name):
		sound_events.append(name)

func snapshot() -> Dictionary:
	return {"version": 1, "enemies": enemies.snapshot(), "shots": shots.snapshot(),
		"hostile": hostile.snapshot(), "pickups": pickups.snapshot(), "player": player,
		"aim": aim, "hp": hp, "elapsed": elapsed, "kills": kills, "level": level,
		"xp": xp, "pending_levels": pending_levels, "invulnerable": invulnerable,
		"weapons": weapons, "supports": supports, "evolved": evolved, "blasts": blasts,
		"caches": caches, "fired_events": fired_events, "rerolls": rerolls,
		"spawn_clock": spawn_clock, "gun_clock": gun_clock, "flame_clock": flame_clock,
		"artillery_clock": artillery_clock, "volley_clock": volley_clock,
		"fire_clock": fire_clock, "fires": fires, "elite_ids": elite_ids, "shot_hits": shot_hits,
		"flame_direction": flame_direction, "damage_dealt": damage_dealt,
		"seed": rng.seed, "rng_state": rng.state}

func restore(data: Dictionary) -> bool:
	if data.get("version", 0) != 1:
		return false
	var schema := snapshot()
	for key in schema.keys():
		if not data.has(key) or typeof(data[key]) != typeof(schema[key]):
			return false
	for key in ["enemies", "shots", "hostile", "pickups"]:
		var pool: EntityPool = get(key)
		var pool_data: Dictionary = data[key]
		var pool_schema := pool.snapshot()
		for key_name in pool_schema:
			if not pool_data.has(key_name) or typeof(pool_data[key_name]) != typeof(pool_schema[key_name]):
				return false
		for buffer in ["alive", "position", "velocity", "health", "kind", "timer", "aux", "burn", "generation", "mode", "target"]:
			if not pool_data.has(buffer) or pool_data[buffer].size() != pool.capacity:
				return false
		if not pool_data.has("free") or not pool_data.has("count"):
			return false
		var active := 0
		var free_slots: Dictionary = {}
		for slot in pool_data.free:
			if not slot is int or slot < 0 or slot >= pool.capacity or free_slots.has(slot) or pool_data.alive[slot] != 0:
				return false
			free_slots[slot] = true
		for slot in pool.capacity:
			if pool_data.alive[slot]:
				active += 1
		if active != pool_data.count or active + free_slots.size() != pool.capacity:
			return false
	for key in ["weapons", "supports", "evolved", "damage_dealt"]:
		if data[key].size() != 3:
			return false
	for i in 3:
		if data.weapons[i] < 0 or data.weapons[i] > 6 or data.supports[i] < 0 or data.supports[i] > 2:
			return false
	if data.weapons[0] < 1 or data.level < 1 or data.pending_levels < 0:
		return false
	if data.elapsed < 0 or data.elapsed >= 600 or data.hp <= 0 or data.hp > 100:
		return false
	for key in ["enemies", "shots", "hostile", "pickups"]:
		get(key).restore(data[key])
	for key in ["player", "aim", "hp", "elapsed", "kills", "level", "xp", "pending_levels", "invulnerable", "fired_events", "rerolls", "spawn_clock", "gun_clock", "flame_clock", "artillery_clock", "volley_clock", "fire_clock", "elite_ids", "shot_hits", "flame_direction"]:
		set(key, data[key])
	weapons.assign(data.weapons)
	supports.assign(data.supports)
	evolved.assign(data.evolved)
	blasts.assign(data.blasts)
	caches.assign(data.caches)
	fires.assign(data.fires)
	damage_dealt.assign(data.damage_dealt)
	rng.seed = data.seed
	rng.state = data.rng_state
	_rebuild_grid()
	return true
