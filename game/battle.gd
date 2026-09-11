class_name Battle
extends RefCounted

const RUN_SECONDS := 900.0
const WORLD := Vector2(2400, 1600)
const VIEW := Vector2(640, 360)
const ENEMY_HP := [16.0, 26.0, 22.0, 45.0, 220.0, 160.0, 480.0, 2400.0]
const ENEMY_SPEED := [29.0, 22.0, 42.0, 19.0, 14.0, 35.0, 25.0, 12.0]
const ENEMY_RADIUS := [8.0, 8.0, 8.0, 9.0, 20.0, 22.0, 13.0, 30.0]
const WAVE_CAP := [55, 75, 100, 120, 145, 175, 200, 230, 260, 290, 330, 370, 410, 450, 500]
const WAVE_RATE := [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 10.0]
const TITLES := ["골목이 낯설다", "꺼진 가로등", "누가 따라온다", "편의점 불빛", "상자 속 숨바꼭질", "낯선 발자국", "비닐이 우는 밤", "밥그릇의 기억", "담장 너머", "잠들지 않는 골목", "빈집의 숨", "돌아오지 않는 사람", "귀가 쫑긋", "거리가 접힌다", "아침을 기다리며"]
const ENEMY_NAMES := ["먼지꼬리", "영수증 나풀", "버려진 우산발", "배수구 꿀렁", "빈봉투 배불뚝", "빨래바람", "가로등 깜빡이", "돌아오지 않는 골목"]
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
var paw_clock := 0.0
var trail_clock := 0.0
var cap_clock := 3.0
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
var fur_patches: Array[Dictionary] = []
var volley_clock := 0.0
var fur_tick_clock := 0.0
var trail_direction := Vector2.RIGHT
var trail_active := false
var moving := false
var walk_phase := 0.0
var food_clock := 18.0
var food_boost := 0.0
var food_regen := 0.0
var hidden := false
var hide_charge := 2.0
var interact_clock := 0.0
var landmarks: Array[Dictionary] = [
	{"at": WORLD * 0.5 + Vector2(-95, 40), "kind": 0},
	{"at": WORLD * 0.5 + Vector2(140, 55), "kind": 1},
	{"at": WORLD * 0.5 + Vector2(-155, -110), "kind": 2},
	{"at": WORLD * 0.5 + Vector2(280, -180), "kind": 0},
	{"at": WORLD * 0.5 + Vector2(-310, 240), "kind": 1}]
var damage_dealt: Array[float] = [0.0, 0.0, 0.0]

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

func xp_needed() -> int:
	return 8 + 18 * (level - 1)

func minute() -> int:
	return mini(14, int(elapsed / 60.0))

func camera() -> Vector2:
	return player.clamp(VIEW * 0.5, WORLD - VIEW * 0.5)

func step(dt: float, movement: Vector2) -> void:
	if finished or pending_levels > 0:
		return
	elapsed = minf(RUN_SECONDS, elapsed + dt)
	if elapsed >= RUN_SECONDS:
		finished = true
		victory = true
		return
	invulnerable = maxf(0.0, invulnerable - dt)
	hit_flash = maxf(0.0, hit_flash - dt)
	moving = movement.length_squared() > 0.01
	walk_phase += dt * (12 if moving else 2)
	food_boost = maxf(0, food_boost - dt)
	food_regen = maxf(0, food_regen - dt)
	if food_regen > 0:
		hp = minf(100, hp + 3 * dt)
	var before_move := player
	var desired := (player + movement.limit_length() * (120.0 if food_boost > 0 else 100.0) * dt).clamp(Vector2(20, 20), WORLD - Vector2(20, 20))
	if not _building_at(Vector2(desired.x, player.y)):
		player.x = desired.x
	if not _building_at(Vector2(player.x, desired.y)):
		player.y = desired.y
	moving = player.distance_squared_to(before_move) > 0.001
	if movement.length_squared() > 0.01:
		aim = movement.normalized()
	volley_clock = maxf(0, volley_clock - dt)
	_city_objects(dt)
	_spawn(dt)
	_move_enemies(dt)
	_rebuild_grid()
	_weapons(dt)
	_projectiles(dt)
	_explosions(dt)
	_tick_fur(dt)
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
	for event in [[180, 6], [300, 4], [360, 3], [420, 5], [540, 6], [660, 4], [780, 6], [840, 7]]:
		if elapsed >= event[0] and not fired_events.has(event[0]):
			if enemies.count >= enemies.capacity:
				for i in enemies.capacity:
					if enemies.alive[i] and enemies.kind[i] == 0:
						enemies.release(i)
						break
			var spawned := spawn_enemy(event[1], _spawn_position())
			if event[0] in [180, 300, 540, 660, 780] and spawned >= 0:
				elite_ids[spawned] = enemies.generation[spawned]
				enemies.health[spawned] *= 1.8
			fired_events[event[0]] = true
			events.append("돌아오지 않는 골목이 깨어납니다" if event[1] == 7 else "큰 괴이가 다가옵니다" if event[1] == 6 else "낯선 기척이 짙어집니다")

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
		if hidden:
			speed *= 0.25
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
		if enemies.residue[i] > 0:
			enemies.residue[i] -= dt
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
		elif enemies.timer[i] <= 0 and not hidden and distance < 300 and (type == 0 or volley_clock <= 0) and Rect2(camera() - Vector2(300, 120), Vector2(600, 265)).has_point(enemies.position[i]):
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

func _building_at(at: Vector2) -> bool:
	var cell := Vector2(fposmod(at.x, 320), fposmod(at.y, 320))
	if Rect2(-5, -5, 126, 65).has_point(cell):
		return true
	return Rect2(WORLD * 0.5 + Vector2(100, -117), Vector2(138, 66)).has_point(at)

func _city_objects(dt: float) -> void:
	hidden = false
	var in_box := false
	interact_clock = maxf(0, interact_clock - dt)
	for object in landmarks:
		if player.distance_to(object.at) > 22:
			continue
		match object.kind:
			0:
				in_box = true
				hidden = not moving and hide_charge > 0
			1:
				hp = minf(100, hp + 2 * dt)
			2:
				if moving and interact_clock <= 0:
					_add_blast(player, 55, 35, 0.25, true, 0)
					interact_clock = 8
	if hidden:
		hide_charge = maxf(0, hide_charge - dt)
	elif not in_box:
		hide_charge = minf(2, hide_charge + dt * 0.2)
	food_clock -= dt
	if food_clock <= 0:
		food_clock = rng.randf_range(23, 32)
		var at := player
		for attempt in 12:
			var candidate := (player + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(75, 145)).clamp(Vector2(24, 24), WORLD - Vector2(24, 24))
			if not _building_at(candidate):
				at = candidate
				break
		pickups.spawn(at, rng.randi_range(1, 3), 20, Vector2.ZERO, 22)

func _weapons(dt: float) -> void:
	if hidden:
		return
	paw_clock -= dt
	if paw_clock <= 0:
		var reach := 78.0 if weapons[0] >= 5 else 62.0
		var target := nearest(player, reach)
		if target >= 0:
			aim = player.direction_to(enemies.position[target])
			var angle := 1.4 if weapons[0] >= 4 else 0.95
			for id in nearby(player, reach + 22):
				var diff := enemies.position[id] - player
				if enemies.alive[id] and diff.length() < reach + ENEMY_RADIUS[enemies.kind[id]] and (evolved[0] or absf(aim.angle_to(diff)) < angle):
					_hurt_enemy(id, (27 if weapons[0] >= 6 else 22 if weapons[0] >= 2 else 18) * (1 + supports[0] * 0.15), 0)
					if enemies.alive[id] and weapons[0] >= 4:
						enemies.position[id] += diff.normalized() * (3 if enemies.kind[id] >= 6 else 10)
			add_effect(player + aim * 22, reach * 0.48, 0.16, 3)
			paw_clock = 0.36 if evolved[0] else 0.45 if weapons[0] >= 3 else 0.6
			_sound("paw")
	# Loose fur is left behind while moving: circle back to lure pursuers into it.
	trail_active = weapons[1] > 0 and moving
	trail_clock -= dt
	if trail_active and trail_clock <= 0:
		trail_clock = 0.30 if weapons[1] >= 5 else 0.45
		if fur_patches.size() < 64:
			fur_patches.append({"at": player, "life": 5.0 if weapons[1] >= 3 else 3.0})
	cap_clock -= dt
	if weapons[2] > 0 and cap_clock <= 0:
		var target := nearest(player, 240)
		if target >= 0:
			var count := 2 if weapons[2] >= 4 else 1
			for n in count:
				var direction := player.direction_to(enemies.position[target]).rotated(n * 0.12)
				var shot := shots.spawn(player, 2, 34 if weapons[2] >= 6 else 27 if weapons[2] >= 2 else 22, direction * 230, 3)
				if shot >= 0:
					shots.aux[shot] = 6 if evolved[2] else 4 if weapons[2] >= 3 else 3
					shot_hits[shot] = []
			cap_clock = (1.2 if weapons[2] >= 5 else 1.8) * (1.0 - supports[2] * 0.12)

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
						_hurt_enemy(id, pool.health[i], 2)
						pool.aux[i] -= 1
						if pool.aux[i] <= 0:
							pool.release(i)
							break
						var next_target := -1
						var best := 150.0 * 150.0
						for other in nearby(pool.position[i], 150):
							var distance: float = pool.position[i].distance_squared_to(enemies.position[other])
							if enemies.alive[other] and not shot_hits[i].has(Vector2i(other, enemies.generation[other])) and distance < best:
								best = distance
								next_target = other
						if next_target >= 0:
							pool.velocity[i] = pool.position[i].direction_to(enemies.position[next_target]) * 230
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
	if enemies.residue[id] > 0:
		if weapon == 0:
			bonus += 0.15
		if weapon == 2:
			bonus += 0.20
			enemies.residue[id] = 3.0
	if weapon == 2 and enemies.aux[id] > 0:
		bonus += 0.15
	amount *= 1.0 + minf(bonus, 0.35)
	damage_dealt[weapon] += minf(enemies.health[id], amount)
	enemies.health[id] -= amount
	if enemies.health[id] <= 0:
		var type := enemies.kind[id]
		var at := enemies.position[id]
		if evolved[1] and enemies.residue[id] > 0 and can_spread and fur_patches.size() < 64:
			fur_patches.append({"at": at, "life": 3.0})
		enemies.release(id)
		kills += 1
		_drop_xp(at, 30 if type >= 6 else 8 if type >= 4 else 2 if type > 0 else 1)
		if type == 6 or elite_ids.get(id, -1) == enemies.generation[id]:
			caches.append(at)
			elite_ids.erase(id)
		if type == 7:
			for bullet in hostile.capacity:
				hostile.release(bullet)
			events.append("골목에 아침 냄새가 돌아옵니다")
		if rng.randf() < 0.012:
			pickups.spawn(at + Vector2(8, 0), 1, 25, Vector2.ZERO, 22)
		add_effect(at, 14 if type < 4 or type == 6 else 30, 0.42, 2)

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

func _tick_fur(dt: float) -> void:
	for i in range(fur_patches.size() - 1, -1, -1):
		fur_patches[i].life -= dt
		if fur_patches[i].life <= 0:
			fur_patches.remove_at(i)
	fur_tick_clock -= dt
	if fur_tick_clock > 0 or fur_patches.is_empty():
		return
	fur_tick_clock = 0.2
	var damaged: Dictionary = {}
	for fire in fur_patches:
		for id in nearby(fire.at, 24 + supports[1] * 5):
			if enemies.alive[id] and not damaged.has(id) and enemies.position[id].distance_to(fire.at) < 24 + supports[1] * 5:
				damaged[id] = true
				if weapons[1] >= 4:
					enemies.aux[id] = 1.0
				if evolved[1]:
					enemies.residue[id] = 2.0
				_hurt_enemy(id, 5.0 if weapons[1] >= 6 else 3.5 if weapons[1] >= 2 else 2.5, 1, false)

func _collect(dt: float) -> void:
	for i in pickups.capacity:
		if not pickups.alive[i]:
			continue
		if pickups.kind[i] > 0:
			pickups.timer[i] -= dt
			if pickups.timer[i] <= 0:
				pickups.release(i)
				continue
		var distance := pickups.position[i].distance_to(player)
		if distance < 58:
			pickups.position[i] = pickups.position[i].move_toward(player, 180 * dt)
		if distance < 12:
			if pickups.kind[i] == 0:
				xp += int(pickups.health[i])
			else:
				var kind := pickups.kind[i]
				hp = minf(100, hp + (12 if kind == 2 else 8 if kind == 3 else 25))
				if kind == 2:
					food_boost = 4
				if kind == 3:
					food_regen = 6
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
				events.append(["우다다 연속냥펀치", "온 골목이 내 털", "골목 핀볼 완성"][eligible[0]])
				_sound("evolve")

func eligible_evolutions() -> Array[int]:
	var result: Array[int] = []
	for i in 3:
		if weapons[i] == 6 and supports[i] == 2 and not evolved[i]:
			result.append(i)
	return result

func hurt_player(amount: float) -> void:
	if invulnerable > 0 or god_mode or hidden:
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
	return {"version": 2, "enemies": enemies.snapshot(), "shots": shots.snapshot(),
		"hostile": hostile.snapshot(), "pickups": pickups.snapshot(), "player": player,
		"aim": aim, "hp": hp, "elapsed": elapsed, "kills": kills, "level": level,
		"xp": xp, "pending_levels": pending_levels, "invulnerable": invulnerable,
		"weapons": weapons, "supports": supports, "evolved": evolved, "blasts": blasts,
		"caches": caches, "fired_events": fired_events, "rerolls": rerolls,
		"spawn_clock": spawn_clock, "paw_clock": paw_clock, "trail_clock": trail_clock,
		"cap_clock": cap_clock, "volley_clock": volley_clock,
		"fur_tick_clock": fur_tick_clock, "fur_patches": fur_patches, "elite_ids": elite_ids, "shot_hits": shot_hits,
		"trail_direction": trail_direction, "damage_dealt": damage_dealt,
		"hide_charge": hide_charge, "food_clock": food_clock, "food_boost": food_boost, "food_regen": food_regen, "interact_clock": interact_clock,
		"seed": rng.seed, "rng_state": rng.state}

func restore(data: Dictionary) -> bool:
	if data.get("version", 0) != 2:
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
		for buffer in ["alive", "position", "velocity", "health", "kind", "timer", "aux", "residue", "generation", "mode", "target"]:
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
	if data.elapsed < 0 or data.elapsed >= RUN_SECONDS or data.hp <= 0 or data.hp > 100:
		return false
	for key in ["enemies", "shots", "hostile", "pickups"]:
		get(key).restore(data[key])
	for key in ["player", "aim", "hp", "elapsed", "kills", "level", "xp", "pending_levels", "invulnerable", "fired_events", "rerolls", "spawn_clock", "paw_clock", "trail_clock", "cap_clock", "volley_clock", "fur_tick_clock", "elite_ids", "shot_hits", "trail_direction", "food_clock", "food_boost", "food_regen", "interact_clock", "hide_charge"]:
		set(key, data[key])
	weapons.assign(data.weapons)
	supports.assign(data.supports)
	evolved.assign(data.evolved)
	blasts.assign(data.blasts)
	caches.assign(data.caches)
	fur_patches.assign(data.fur_patches)
	damage_dealt.assign(data.damage_dealt)
	rng.seed = data.seed
	rng.state = data.rng_state
	_rebuild_grid()
	return true
