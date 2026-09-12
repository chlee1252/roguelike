class_name Battle
extends RefCounted

const RUN_SECONDS := 600.0
const WORLD := Vector2(2400, 1600)
const VIEW := Vector2(640, 360)
const ENEMY_HP := [16.0, 26.0, 22.0, 45.0, 220.0, 160.0, 480.0, 2400.0]
const ENEMY_SPEED := [29.0, 22.0, 42.0, 19.0, 14.0, 35.0, 25.0, 12.0]
const ENEMY_RADIUS := [8.0, 8.0, 8.0, 9.0, 20.0, 22.0, 13.0, 30.0]
const WAVE_CAP := [55, 75, 100, 120, 145, 175, 200, 230, 260, 290, 330, 370, 410, 450, 500]
const WAVE_RATE := [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 10.0]
const TITLES := ["골목이 낯설다", "꺼진 가로등", "누가 따라온다", "편의점 불빛", "상자 속 숨바꼭질", "낯선 발자국", "비닐이 우는 밤", "밥그릇의 기억", "담장 너머", "잠들지 않는 골목", "빈집의 숨", "돌아오지 않는 사람", "귀가 쫑긋", "거리가 접힌다", "아침을 기다리며"]
const ENEMY_NAMES := ["멍멍 꼬마", "깍깍 까마귀", "우다다 강아지", "칙칙 분무기", "웅웅 청소기", "까마귀 대장", "삐삐 청소대장", "멍멍 꿈대장"]
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
var boss_max_hp := 2400.0
var invulnerable := 0.0
var spawn_clock := 0.0
var paw_clock := 0.0
var trail_clock := 0.0
var cap_clock := 3.0
var weapons: Array[int] = [1, 0, 0, 0, 0, 0, 0, 0]
var supports: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var evolved: Array[bool] = [false, false, false, false, false, false, false, false]
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
var damage_dealt: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var stage_id := 0
var difficulty := 0
var obstacles: Array[Rect2] = NightContent.buildings(0)
var available: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
var extra_clocks := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0])
var still_time := 0.0
var bag_distance := 0.0
var ambush_charge := 0.0
var catnip := 0.0
var lures: Array[Dictionary] = []
var clue_at := Vector2.ZERO
var clue_found := false
var next_event := 90.0
var last_damage := ""

func configure(stage: int, challenge: int, learned: Array[int], starter := 0) -> void:
	stage_id = clampi(stage, 0, 2)
	difficulty = clampi(challenge, 0, 1)
	obstacles = NightContent.buildings(stage_id)
	available.assign(learned)
	weapons.fill(0)
	weapons[starter if available.has(starter) else 0] = 1
	for object in landmarks:
		object.at = open_position(object.at + Vector2(stage_id * 40, stage_id * 20))
	player = open_position(WORLD * 0.5)
	events.append(NightContent.OPENINGS[stage_id])
	spawn_enemy(0, player + Vector2(105, 10))

func open_position(at: Vector2) -> Vector2:
	at = at.clamp(Vector2(24, 24), WORLD - Vector2(24, 24))
	if not _building_at(at):
		return at
	for radius in [32, 64, 96, 128, 180, 240]:
		for direction in 16:
			var candidate: Vector2 = (at + Vector2.from_angle(direction * TAU / 16) * radius).clamp(Vector2(24, 24), WORLD - Vector2(24, 24))
			if not _building_at(candidate):
				return candidate
	return Vector2(1200, 800)

func occupied_weapon_slots() -> int:
	return weapons.filter(func(rank: int) -> bool: return rank > 0).size()

func can_upgrade(id: String) -> bool:
	if id in ["heal", "supply"]:
		return true
	if id.length() < 2 or not id.substr(1).is_valid_int():
		return false
	var index := id.substr(1).to_int()
	if id.begins_with("w"):
		return index >= 0 and index < 8 and available.has(index) and weapons[index] < 6 and (weapons[index] > 0 or occupied_weapon_slots() < 4)
	if id.begins_with("s"):
		return index >= 0 and index < 12 and supports[index] < 2 and (supports[index] > 0 or supports.filter(func(rank: int) -> bool: return rank > 0).size() < 4)
	return false


func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value

func boss_health() -> float:
	for id in enemies.capacity:
		if enemies.alive[id] and enemies.kind[id] == 7:
			return enemies.health[id]
	return -1

func xp_needed() -> int:
	return 8 + 12 * (level - 1)

func minute() -> int:
	return mini(14, int(elapsed / 60.0))

func camera() -> Vector2:
	return player.clamp(VIEW * 0.5, WORLD - VIEW * 0.5)

func step(dt: float, movement: Vector2) -> void:
	if finished or pending_levels > 0:
		return
	elapsed += dt
	invulnerable = maxf(0.0, invulnerable - dt)
	hit_flash = maxf(0.0, hit_flash - dt)
	moving = movement.length_squared() > 0.01
	walk_phase += dt * (12 if moving else 2)
	catnip = maxf(0, catnip - dt)
	food_boost = maxf(0, food_boost - dt)
	food_regen = maxf(0, food_regen - dt)
	if food_regen > 0:
		hp = minf(100, hp + 3 * dt)
	var before_move := player
	var desired := (player + movement.limit_length() * (120.0 if food_boost > 0 or catnip > 0 else 100.0) * (1 + supports[3] * 0.08) * dt).clamp(Vector2(20, 20), WORLD - Vector2(20, 20))
	if not _building_at(Vector2(desired.x, player.y)):
		player.x = desired.x
	if not _building_at(Vector2(player.x, desired.y)):
		player.y = desired.y
	moving = player.distance_squared_to(before_move) > 0.001
	if movement.length_squared() > 0.01:
		aim = movement.normalized()
	still_time = 0.0 if moving else still_time + dt
	bag_distance += player.distance_to(before_move) if weapons[4] > 0 else 0.0
	volley_clock = maxf(0, volley_clock - dt)
	_city_objects(dt)
	_spawn(dt)
	_move_enemies(dt)
	_rebuild_grid()
	_lure_effects(dt)
	_weapons(dt * (1.35 if catnip > 0 else 1.0))
	_night_events(dt)
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
		spawn_clock = 1.0 / (WAVE_RATE[minute()] * (1.2 if difficulty == 1 else 1.0))
		if elapsed < NightContent.DURATIONS[stage_id] and enemies.count < WAVE_CAP[minute()]:
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
			if stage_id == 1 and type == 0 and roll < 0.3:
				type = 1
			if stage_id == 2 and elapsed > 90 and roll > 0.94:
				type = 3
			if type < 3 or _type_count(type) < ([0, 0, 0, 4, 3, 2][type]):
				spawn_enemy(type, _spawn_position())
	var schedule := [[120, 6], [240, 4], [360, 6], [480, 5]]
	if stage_id > 0:
		schedule.append([600, 6])
	if stage_id == 2:
		schedule.append([720, 4])
	schedule.append([NightContent.BOSS_AT[stage_id], 7])
	for event in schedule:
		if elapsed >= event[0] and not fired_events.has(event[0]):
			if enemies.count >= enemies.capacity:
				for i in enemies.capacity:
					if enemies.alive[i] and enemies.kind[i] != 7:
						enemies.release(i)
						break
			if event[1] == 7 and _type_count(7) > 0:
				fired_events[event[0]] = true
				continue
			var spawned := spawn_enemy(event[1], _spawn_position())
			if spawned < 0:
				continue
			if event[1] != 7 and spawned >= 0:
				elite_ids[spawned] = enemies.generation[spawned]
				enemies.health[spawned] *= 1.8
			fired_events[event[0]] = true
			events.append(NightContent.BOSSES[stage_id] + " 등장!" if event[1] == 7 else "큰 괴이가 다가옵니다" if event[1] == 6 else "낯선 기척이 짙어집니다")

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
	var id := enemies.spawn(at, type, (1700.0 + stage_id * 350 if type == 7 else ENEMY_HP[type]) * (1.0 + minute() * 0.1))
	if id >= 0:
		if type == 7:
			boss_max_hp = enemies.health[id]
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
		if type == 7 and stage_id == 1:
			direction = (direction * 0.3 + direction.orthogonal() * 0.7).normalized()
			speed = 30
		if type != 7:
			for lure in lures:
				if lure.kind == 0 and enemies.position[i].distance_to(lure.at) < 115 + supports[10] * 15:
					direction = enemies.position[i].direction_to(lure.at)
					break
		if enemies.fear[i] > 0:
			if type == 2 and enemies.mode[i] > 0:
				enemies.mode[i] = 0
				enemies.timer[i] = maxf(2, enemies.timer[i])
			enemies.fear[i] = maxf(0, enemies.fear[i] - dt)
			direction = -direction
			speed *= 0.4 if type == 7 else 1.2
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
		elif enemies.timer[i] <= 0 and not hidden and enemies.fear[i] <= 0 and distance < 300 and (type == 0 or volley_clock <= 0) and Rect2(camera() - Vector2(300, 120), Vector2(600, 265)).has_point(enemies.position[i]):
			_enemy_attack(i, type, direction)
		if distance < ENEMY_RADIUS[type] + 6:
			hurt_player(20 if type >= 4 else 10, NightContent.BOSSES[stage_id] if type == 7 else ENEMY_NAMES[type])
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
	if type == 7 and stage_id > 0:
		_stage_boss_attack(id)
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
		var excited := enemies.health[id] <= boss_max_hp * 0.5
		amount = (11 if excited else 9) + difficulty * 2
		enemies.timer[id] = 3.2 if excited else 4.5
	if hostile.free.size() < amount:
		return
	# Delayed projectile activation provides a visible muzzle windup.
	for n in amount:
		var angle := (n - (amount - 1) * 0.5) * (0.20 if type != 7 else 0.28)
		var bullet := hostile.spawn(enemies.position[id], type, 8 if type < 4 else 20,
			direction.rotated(angle) * (65 if type < 4 else 55), 7.0)
		hostile.aux[bullet] = (0.65 if type < 4 else 1.0) * (0.85 if difficulty == 1 else 1.0)
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
	if stage_id == 0:
		var cell := Vector2(fposmod(at.x, 320), fposmod(at.y, 320))
		return Rect2(-5, -5, 126, 65).has_point(cell) or Rect2(1300, 683, 138, 66).grow(5).has_point(at)
	for obstacle in obstacles:
		if obstacle.grow(5).has_point(at):
			return true
	return false

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
		hide_charge = minf(2 + supports[7] * 0.5, hide_charge + dt * 0.2)
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
	_extra_weapons(dt)
	if hidden:
		return
	paw_clock -= dt
	if weapons[0] > 0 and paw_clock <= 0:
		var target := nearest(player, 280 if weapons[0] >= 5 else 220)
		if target >= 0:
			aim = player.direction_to(enemies.position[target])
			for n in (2 if evolved[0] else 1):
				var direction := aim.rotated((n - 0.5) * 0.09 if evolved[0] else 0)
				var shot := shots.spawn(player + Vector2(0, -3), 0, (27 if weapons[0] >= 6 else 22 if weapons[0] >= 2 else 18) * (1 + supports[0] * 0.15), direction * 300, 1.0)
				if shot >= 0:
					shots.aux[shot] = 5 if evolved[0] else 3 if weapons[0] >= 4 else 2
					shot_hits[shot] = []
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
			if pool == shots and pool.kind[i] == 5:
				_bottle_reflect(i, before)
				if not pool.alive[i]:
					continue
			pool.timer[i] -= dt
			if pool.timer[i] <= 0:
				pool.release(i)
				continue
			if pool == hostile:
				var closest := Geometry2D.get_closest_point_to_segment(player, before, pool.position[i])
				if closest.distance_squared_to(player) < 81:
					hurt_player(pool.health[i], "괴이의 탄환")
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
						_hurt_enemy(id, pool.health[i], pool.kind[i])
						pool.aux[i] -= 1
						if pool.aux[i] <= 0:
							pool.release(i)
							break
						if pool.kind[i] in [0, 5]:
							continue
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
				hurt_player(blast.damage, "바닥에 예고된 공격")
		add_effect(blast.at, blast.radius, 0.35, 0 if blast.friendly else 1)
		_sound("blast")
		blasts.remove_at(i)

func _hurt_enemy(id: int, amount: float, weapon: int, can_spread: bool = true) -> void:
	if not enemies.alive[id]:
		return
	var bonus := supports[11] * 0.12 if still_time >= 1.0 else 0.0
	if enemies.fear[id] > 0:
		bonus += supports[5] * 0.1
	if enemies.residue[id] > 0:
		if weapon == 0:
			bonus += 0.15
		if weapon == 2:
			bonus += 0.20
			enemies.residue[id] = 3.0
	if weapon == 2 and enemies.aux[id] > 0:
		bonus += 0.15
	amount *= 1.0 + minf(bonus, 0.65)
	damage_dealt[weapon] += minf(enemies.health[id], amount)
	enemies.health[id] -= amount
	if amount >= 12 and enemies.health[id] > 0:
		add_effect(enemies.position[id], 6, 0.12, 5)
	if enemies.health[id] <= 0:
		var type := enemies.kind[id]
		var at := enemies.position[id]
		if evolved[1] and enemies.residue[id] > 0 and can_spread and fur_patches.size() < 64:
			fur_patches.append({"at": at, "life": 3.0})
		enemies.release(id)
		kills += 1
		_drop_xp(at, 30 if type >= 6 else 8 if type >= 4 else 2 if type > 0 else 1)
		if type == 6 or elite_ids.get(id, -1) == enemies.generation[id]:
			caches.append(open_position(at))
			elite_ids.erase(id)
		if type == 7:
			finished = true
			victory = true
			fired_events["boss_defeated"] = true
			for bullet in hostile.capacity:
				hostile.release(bullet)
			clue_found = true
			events.append("보스 처치! 골목이 조용해졌어요.")
		if rng.randf() < 0.012:
			pickups.spawn(at + Vector2(8, 0), 1, 25, Vector2.ZERO, 22)
		add_effect(at, 14 if type < 4 or type == 6 else 30, 0.42, 2)

func _drop_xp(at: Vector2, value: int) -> void:
	at = open_position(at)
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
		if distance < 58 + supports[4] * 18:
			pickups.position[i] = pickups.position[i].move_toward(player, 180 * dt)
		if distance < 12:
			if pickups.kind[i] == 0:
				xp += int(pickups.health[i])
			else:
				_take_item(pickups.kind[i])
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
				events.append(NightContent.EVOLUTIONS[eligible[0]] + " 완성!")
				_sound("evolve")

func eligible_evolutions() -> Array[int]:
	var result: Array[int] = []
	for i in 8:
		var passive: int = NightContent.EVO_SUPPORT[i]
		if passive >= 0 and weapons[i] == 6 and supports[passive] == 2 and not evolved[i]:
			result.append(i)
	return result

func hurt_player(amount: float, source: String = "괴이와 부딪힘") -> void:
	if invulnerable > 0 or god_mode or hidden:
		return
	last_damage = source
	hp = maxf(0, hp - amount * (1 - supports[9] * 0.08))
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
	return {"version": 4, "enemies": enemies.snapshot(), "shots": shots.snapshot(),
		"hostile": hostile.snapshot(), "pickups": pickups.snapshot(), "player": player,
		"aim": aim, "hp": hp, "elapsed": elapsed, "kills": kills, "level": level,
		"xp": xp, "pending_levels": pending_levels, "invulnerable": invulnerable,
		"weapons": weapons, "supports": supports, "evolved": evolved, "blasts": blasts,
		"caches": caches, "fired_events": fired_events, "rerolls": rerolls,
		"spawn_clock": spawn_clock, "paw_clock": paw_clock, "trail_clock": trail_clock,
		"cap_clock": cap_clock, "volley_clock": volley_clock,
		"fur_tick_clock": fur_tick_clock, "fur_patches": fur_patches, "elite_ids": elite_ids, "shot_hits": shot_hits,
		"trail_direction": trail_direction, "damage_dealt": damage_dealt,
		"boss_max_hp": boss_max_hp, "hide_charge": hide_charge, "food_clock": food_clock, "food_boost": food_boost, "food_regen": food_regen, "interact_clock": interact_clock,
		"stage_id": stage_id, "difficulty": difficulty, "available": available, "landmarks": landmarks,
		"extra_clocks": extra_clocks, "still_time": still_time, "bag_distance": bag_distance, "ambush_charge": ambush_charge,
		"catnip": catnip, "lures": lures, "clue_at": clue_at, "clue_found": clue_found, "next_event": next_event, "last_damage": last_damage,
		"seed": rng.seed, "rng_state": rng.state}

func restore(data: Dictionary) -> bool:
	if data.get("version", 0) == 3:
		data = _migrate_v3(data)
	if data.get("version", 0) != 4:
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
		for buffer in ["alive", "position", "velocity", "health", "kind", "timer", "aux", "fear", "residue", "generation", "mode", "target"]:
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
		if data[key].size() != (12 if key == "supports" else 8):
			return false
	for i in 8:
		if not data.weapons[i] is int or data.weapons[i] < 0 or data.weapons[i] > 6:
			return false
	for rank in data.supports:
		if not rank is int or rank < 0 or rank > 2:
			return false
	if data.stage_id < 0 or data.stage_id > 2 or data.difficulty < 0 or data.difficulty > 1 or data.extra_clocks.size() != 8:
		return false
	for id in data.available:
		if not id is int or id < 0 or id > 7:
			return false
	if data.weapons.filter(func(rank: int) -> bool: return rank > 0).size() not in [1, 2, 3, 4] or data.level < 1 or data.pending_levels < 0:
		return false
	if data.elapsed < 0 or data.hp <= 0 or data.hp > 100:
		return false
	if data.lures.size() > 12 or data.landmarks.size() > 32 or not data.clue_at.is_finite():
		return false
	for lure in data.lures:
		if not lure is Dictionary or not lure.get("at") is Vector2 or not lure.at.is_finite() or not lure.get("kind") is int or lure.kind < 0 or lure.kind > 2:
			return false
		for key in ["life", "tick"]:
			if not (lure.get(key) is float or lure.get(key) is int) or not is_finite(lure[key]):
				return false
	for landmark in data.landmarks:
		if not landmark is Dictionary or not landmark.get("at") is Vector2 or not landmark.at.is_finite() or not landmark.get("kind") is int or landmark.kind < 0 or landmark.kind > 2:
			return false
	for key in ["elapsed", "hp", "still_time", "bag_distance", "ambush_charge", "catnip", "next_event"]:
		if not is_finite(data[key]):
			return false
	for key in ["enemies", "shots", "hostile", "pickups"]:
		for id in data[key].alive.size():
			if data[key].alive[id] and (data[key].kind[id] < 0 or data[key].kind[id] > (8 if key == "pickups" else 7)):
				return false
	for key in ["enemies", "shots", "hostile", "pickups"]:
		get(key).restore(data[key])
	for key in ["player", "aim", "hp", "elapsed", "kills", "level", "xp", "pending_levels", "invulnerable", "fired_events", "rerolls", "spawn_clock", "paw_clock", "trail_clock", "cap_clock", "volley_clock", "fur_tick_clock", "elite_ids", "shot_hits", "trail_direction", "food_clock", "food_boost", "food_regen", "interact_clock", "hide_charge", "boss_max_hp", "stage_id", "difficulty", "extra_clocks", "still_time", "bag_distance", "ambush_charge", "catnip", "clue_at", "clue_found", "next_event", "last_damage"]:
		set(key, data[key])
	available.assign(data.available)
	landmarks.assign(data.landmarks)
	lures.assign(data.lures)
	obstacles = NightContent.buildings(stage_id)
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

func _extra_weapons(dt: float) -> void:
	for index in 8:
		extra_clocks[index] = maxf(0, extra_clocks[index] - dt)
	if weapons[6] > 0:
		var charge_needed := maxf(0.6, (0.9 if weapons[6] >= 5 else 1.3) - supports[7] * 0.15)
		if not moving and extra_clocks[6] <= 0:
			ambush_charge = minf(charge_needed, ambush_charge + dt)
		elif moving:
			if ambush_charge >= charge_needed:
				var radius := 85.0 if weapons[6] >= 3 else 60.0
				_add_blast(player, radius, 35 + weapons[6] * 8, 0.12, true, 6)
				if weapons[6] >= 6:
					_add_blast(player + aim * 40, radius, 40, 0.4, true, 6)
				if weapons[6] >= 4:
					invulnerable = maxf(invulnerable, 0.5)
				if evolved[6]:
					_frighten(player, radius + 20, 2.0, 25)
					invulnerable = maxf(invulnerable, 0.8)
				extra_clocks[6] = 2
				_sound("paw")
			ambush_charge = 0
	if hidden:
		return
	if weapons[3] > 0 and extra_clocks[3] <= 0:
		var radius := 100.0 if evolved[3] else 80.0 if weapons[3] >= 3 else 60.0
		if nearest(player, radius) >= 0:
			for id in nearby(player, radius):
				if enemies.alive[id] and player.distance_to(enemies.position[id]) <= radius:
					_hurt_enemy(id, 13 + weapons[3] * 3, 3)
			_frighten(player, radius, (1.4 if weapons[3] >= 4 else 0.8) + supports[5] * 0.4, 30 + weapons[3] * 5)
			if weapons[3] >= 6:
				for id in hostile.capacity:
					if hostile.alive[id] and hostile.position[id].distance_to(player) < radius:
						hostile.release(id)
			extra_clocks[3] = 1.8 if evolved[3] else 2.6 if weapons[3] >= 5 else 3.5
			add_effect(player, radius, 0.45, 4)
			_sound("paw")
	if weapons[4] > 0 and bag_distance >= (65 if weapons[4] >= 5 else 90):
		bag_distance = 0
		_add_lure(player - aim * 30, 0, 2 + weapons[4] * 0.35)
		if weapons[4] >= 6:
			_add_lure(player - aim * 30 + aim.orthogonal() * 45, 0, 3)
	if weapons[5] > 0 and extra_clocks[5] <= 0:
		var target := nearest(player, 300)
		if target >= 0:
			for n in (2 if weapons[5] >= 4 else 1):
				var shot := shots.spawn(player, 5, 18 + weapons[5] * 3, player.direction_to(enemies.position[target]).rotated(n * 0.2) * 280, 2.8)
				if shot >= 0:
					shots.aux[shot] = 6
					shots.mode[shot] = 1 + supports[6] + (1 if weapons[5] >= 3 else 0) + (2 if evolved[5] else 0)
					shot_hits[shot] = []
			extra_clocks[5] = 0.8 if weapons[5] >= 5 else 1.3
	if weapons[7] > 0 and extra_clocks[7] <= 0:
		var target := dense_target(220)
		if target >= 0:
			_add_lure(enemies.position[target], 1, 2.5 + weapons[7] * 0.25)
			extra_clocks[7] = 4 if weapons[7] >= 5 else 5

func _frighten(at: Vector2, radius: float, duration: float, force: float) -> void:
	for id in nearby(at, radius + 30):
		if enemies.alive[id] and enemies.position[id].distance_to(at) <= radius:
			var resistance := 0.2 if enemies.kind[id] == 7 else 1.0
			enemies.fear[id] = maxf(enemies.fear[id], duration * resistance)
			enemies.position[id] += at.direction_to(enemies.position[id]) * force * resistance

func _add_lure(at: Vector2, kind: int, life: float) -> void:
	if lures.size() >= 12:
		return
	lures.append({"at": open_position(at), "kind": kind, "life": life, "tick": 0.0})

func _lure_effects(dt: float) -> void:
	for index in range(lures.size() - 1, -1, -1):
		var lure := lures[index]
		lure.life -= dt
		lure.tick -= dt
		var radius := (85 if lure.kind == 1 else 65) + supports[10] * 15
		if lure.kind == 1:
			for id in nearby(lure.at, radius):
				if enemies.alive[id] and enemies.position[id].distance_to(lure.at) < radius:
					enemies.position[id] = enemies.position[id].move_toward(lure.at, dt * (5 if enemies.kind[id] == 7 else 25 + weapons[7] * 3))
		if lure.tick <= 0:
			lure.tick = 0.5
			if lure.kind == 1:
				_add_blast(lure.at, radius * 0.65, 5 + weapons[7] * 2, 0.1, true, 7)
			elif lure.kind == 2 and player.distance_to(lure.at) < 45:
				hp = minf(100, hp + 2)
				invulnerable = maxf(invulnerable, 0.55)
		if lure.life <= 0:
			if lure.kind == 0:
				_add_blast(lure.at, 45 + weapons[4] * 5, 18 + weapons[4] * 6, 0.2, true, 4)
			lures.remove_at(index)

func _bottle_reflect(id: int, before: Vector2) -> void:
	var at := shots.position[id]
	var hit_x := at.x < 8 or at.x > WORLD.x - 8 or _building_at(Vector2(at.x, before.y))
	var hit_y := at.y < 8 or at.y > WORLD.y - 8 or _building_at(Vector2(before.x, at.y))
	if not hit_x and not hit_y:
		return
	if shots.mode[id] <= 0:
		shots.release(id)
		return
	shots.mode[id] -= 1
	shots.position[id] = before
	if hit_x:
		shots.velocity[id].x *= -1
	if hit_y:
		shots.velocity[id].y *= -1
	shots.health[id] *= 1.3 if weapons[5] >= 2 else 1.15
	shot_hits[id] = []
	add_effect(before, 12, 0.3, 2)
	if weapons[5] >= 6:
		_add_blast(before, 60 if evolved[5] else 35, shots.health[id] * 0.5, 0.12, true, 5)

func _take_item(kind: int) -> void:
	var healing := [0, 25, 12, 8, 6, 0, 0, 0, 4]
	hp = minf(100, hp + healing[kind] * (1 + supports[8] * 0.2))
	match kind:
		2: food_boost = 4
		3: food_regen = 6
		4:
			for n in 3:
				pickups.spawn(open_position(player + Vector2.from_angle(n * TAU / 3) * 50), 8, 4, Vector2.ZERO, 12)
		5: catnip = 8
		6:
			_frighten(player, 150, 3, 40)
			add_effect(player, 150, 0.6, 4)
		7: _add_lure(player, 2, 6)
	if kind > 3 and kind < 8:
		events.append(NightContent.ITEM_NAMES[kind] + " 발견!")

func _night_events(_dt: float) -> void:
	if elapsed >= 45 and clue_at == Vector2.ZERO and not clue_found:
		clue_at = open_position(player + Vector2(115, 45))
		events.append("단서가 나타났어요! 발자국 표시를 따라가세요.")
	if not clue_found and clue_at != Vector2.ZERO and player.distance_to(clue_at) < 26:
		clue_found = true
		events.append(NightContent.CLUE_NOTES[stage_id])
		_sound("evolve")
	if elapsed >= next_event and elapsed < NightContent.BOSS_AT[stage_id]:
		next_event += 120
		var at := open_position(player + Vector2.from_angle(rng.randf() * TAU) * 105)
		pickups.spawn(at, rng.randi_range(4, 7), 0, Vector2.ZERO, 35)
		events.append(["누군가 사료를 놓고 갔어요", "풀숲에서 바스락!", "좌판 밑에서 좋은 냄새가 나요"][stage_id])

func _stage_boss_attack(id: int) -> void:
	var excited := enemies.health[id] <= boss_max_hp * 0.5
	enemies.timer[id] = 3.3 if excited else 4.5
	enemies.mode[id] += 1
	if stage_id == 1:
		# Alternating feather lanes leave a broad gap around the cat's captured position.
		var vertical := enemies.mode[id] % 2 == 0
		var axis := Vector2.RIGHT if vertical else Vector2.DOWN
		var travel := Vector2.DOWN if vertical else Vector2.RIGHT
		var start := player - travel * 140
		for n in range(-7, 8):
			if absi(n) <= (0 if difficulty == 1 and excited else 1):
				continue
			var bullet := hostile.spawn(start + axis * n * 20, 5, 12, travel * (80 if excited else 65), 5)
			if bullet >= 0:
				hostile.aux[bullet] = 1.0
		if excited:
			_add_blast(player, 30, 15, 1.3, false, 0)
	else:
		# A rotating ring has a three-projectile opening; the next opening rotates visibly.
		var opening := posmod(enemies.mode[id] * 3, 16)
		for n in 16:
			if posmod(n - opening, 16) in [0, 1, 2]:
				continue
			var direction := Vector2.from_angle(n * TAU / 16)
			var bullet := hostile.spawn(enemies.position[id] + direction * 35, 4, 14, direction * (70 if excited else 55), 6)
			if bullet >= 0:
				hostile.aux[bullet] = 1.1
		if excited or difficulty == 1:
			_add_blast(player, 38, 18, 1.4, false, 0)
		if excited and difficulty == 1:
			_add_blast(player + aim * 60, 30, 18, 1.7, false, 0)

func _migrate_v3(old: Dictionary) -> Dictionary:
	var data := old.duplicate(true)
	for key in ["weapons", "supports", "evolved", "damage_dealt"]:
		if not data.get(key) is Array or data[key].size() != 3:
			return {}
		while data[key].size() < (12 if key == "supports" else 8):
			data[key].append(false if key == "evolved" else 0.0 if key == "damage_dealt" else 0)
	var current := snapshot()
	for key in current:
		if not data.has(key):
			data[key] = current[key]
	for key in ["enemies", "shots", "hostile", "pickups"]:
		if not data.get(key) is Dictionary:
			return {}
		var fear := PackedFloat32Array()
		fear.resize(get(key).capacity)
		data[key]["fear"] = fear
	data.version = 4
	return data
