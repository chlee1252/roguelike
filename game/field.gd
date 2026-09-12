class_name Battlefield
extends Node2D

var battle: Battle
var cat_variant := 0
var theme_id := 0
var impact := 0.0
var subtle_effects := false
var sprites: Array[Texture2D] = []

func _ready() -> void:
	_make_sprites()

func set_cat_variant(value: int) -> void:
	cat_variant = clampi(value, 0, 3)
	sprites.clear()
	_make_sprites()
	queue_redraw()

func _make_sprites() -> void:
	for frame in 4:
		sprites.append(CatPixel.make(frame, false, cat_variant))

func _draw() -> void:
	if battle == null:
		return
	var shift := Vector2(320, 180) - battle.camera()
	if not subtle_effects:
		shift += Vector2(sin(battle.elapsed * 71), cos(battle.elapsed * 59)) * impact
	_ground(shift)
	_night_objects(shift)
	if battle.fired_events.get("boss_at") is Vector2 and battle.elapsed < NightContent.BOSS_AT[battle.stage_id]:
		var marker: Vector2 = (battle.fired_events.boss_at + shift).clamp(Vector2(36, 112), Vector2(604, 296))
		draw_arc(marker, 24, 0, TAU, 32, Color("f594a0"), 2)
		_text("보스 %d초" % ceili(NightContent.BOSS_AT[battle.stage_id] - battle.elapsed), marker + Vector2(-22, -30), 11, Color("f594a0"))
	var visible_rect := Rect2(-45, -45, 730, 450)
	for object in battle.landmarks:
		var at: Vector2 = object.at + shift
		if not visible_rect.has_point(at):
			continue
		match object.kind:
			0:
				draw_rect(Rect2(at - Vector2(16, 10), Vector2(32, 22)), Color("b89168"))
				draw_rect(Rect2(at - Vector2(12, 7), Vector2(24, 15)), Color("413c42"))
				draw_line(at + Vector2(-18, -14), at + Vector2(-12, -5), Color("dec39a"), 4)
				draw_line(at + Vector2(18, -14), at + Vector2(12, -5), Color("dec39a"), 4)
				if battle.player.distance_to(object.at) < 80:
					_text("상자 · 멈추면 숨기", at + Vector2(-32, 24), 8, Color("b9b5b2"))
			1:
				draw_circle(at, 22, Color(0.65, 0.84, 0.72, 0.20))
				draw_arc(at, 22, 0, TAU, 32, Color("a4cfbc"), 1)
				draw_style_box(GameSkin.box(Color("789b9e"), 4), Rect2(at - Vector2(10, 5), Vector2(20, 10)))
				for n in 5:
					draw_circle(at + Vector2(n * 3 - 6, -1), 2, Color("dbb28b"))
				if battle.player.distance_to(object.at) < 80:
					var eating := battle.player.distance_to(object.at) <= 22
					var note := "체력 가득!" if eating and battle.hp >= battle.max_hp else "회복 중 · 초당 +2" if eating else "밥그릇 · 원 안에서 체력 회복"
					_text(note, at + Vector2(-48, 35), 9, Color("a4cfbc"))
			2:
				draw_rect(Rect2(at - Vector2(26, 7), Vector2(52, 14)), Color("64717e"))
				for x in range(-24, 25, 8):
					draw_line(at + Vector2(x, -5), at + Vector2(x, 4), Color("8696a0"))
				if battle.player.distance_to(object.at) < 80:
					_text("낮은 담장 · 뛰어넘기", at + Vector2(-36, 24), 8, Color("b9b5b2"))
	for fire in battle.fur_patches:
		var at: Vector2 = fire.at + shift
		if visible_rect.has_point(at):
			draw_circle(at, 24 + battle.supports[1] * 5, Color(0.65, 0.83, 0.78, 0.075))
			for n in 5:
				var tuft := at + Vector2.from_angle(n * 2.4) * (3 + n * 2)
				draw_line(tuft, tuft + Vector2(3, -2), Color("bfcfc5"), 1)
	for i in battle.pickups.capacity:
		if not battle.pickups.alive[i]:
			continue
		var at := (battle.pickups.position[i] + shift).round()
		if not visible_rect.has_point(at):
			continue
		var kind := battle.pickups.kind[i]
		if kind == 0:
			draw_circle(at, 4, Color(0.78, 0.87, 0.98, 0.10))
			draw_rect(Rect2(at, Vector2(2, 3)), Color("c8e4f5"))
			draw_rect(Rect2(at + Vector2(-2, -2), Vector2(1, 1)), Color("ecf2ff"))
		elif kind >= 4:
			draw_circle(at, 10, Color(0.9, 0.8, 0.5, 0.15))
			_text(["", "", "", "", "밥", "풀", "봉", "담", "·"][kind], at + Vector2(-5, 3), 10, Color("f7d69e"))
		else:
			draw_circle(at, 10, Color(0.92, 0.72, 0.4, 0.10))
			var tint := Color("f1c995") if kind == 1 else Color("eba9ac") if kind == 2 else Color("9abecb")
			draw_style_box(GameSkin.box(tint, 3), Rect2(at - Vector2(6, 4), Vector2(12, 8)))
			draw_line(at - Vector2(3, 0), at + Vector2(3, 0), Color("f8ecce"), 2)
	for drop in battle.training_drops:
		var at: Vector2 = drop.at + shift
		var marker := at.clamp(Vector2(20, 108), Vector2(620, 304))
		var tint := Color("f4b5cb") if drop.kind == 0 else Color("eacb83")
		draw_circle(marker, 13, Color(tint, 0.15))
		draw_rect(Rect2(marker - Vector2(7, 8), Vector2(14, 16)), Color("342b45"))
		draw_rect(Rect2(marker - Vector2(5, 7), Vector2(10, 14)), tint)
		draw_line(marker + Vector2(-5, -5), marker + Vector2(5, -5), Color("fff4df"), 2)
		draw_rect(Rect2(marker + Vector2(-3, 0), Vector2(6, 4)), Color("4b4058"))
		_text("츄르" if drop.kind == 0 else "통조림", marker + Vector2(-12, 24), 9, tint)
	for cache in battle.caches:
		var at: Vector2 = cache + shift
		var marker := at.clamp(Vector2(16, 61), Vector2(624, 310))
		draw_rect(Rect2(marker - Vector2(8, 6), Vector2(16, 12)), Color("b89370"))
		draw_line(marker - Vector2(0, 6), marker + Vector2(0, 6), Color("f3d6aa"), 2)
		_text("진화", marker + Vector2(-9, -10), 9, Color("ffe6a6"))
	for blast in battle.blasts:
		var at: Vector2 = blast.at + shift
		var tint := Color("f1c99f") if blast.friendly else Color("f594a0")
		draw_circle(at, blast.radius, Color(tint, 0.08))
		draw_arc(at, blast.radius, 0, TAU, 36, tint, 1)
		draw_arc(at, blast.radius * (1 - blast.time / blast.total), 0, TAU, 24, tint, 1)
	for i in battle.enemies.capacity:
		if battle.enemies.alive[i]:
			var at := (battle.enemies.position[i] + shift).round()
			if visible_rect.has_point(at):
				_ghost(i, at)
	var cat := (battle.player + shift).round()
	_cat(cat)
	for pool in [battle.shots, battle.hostile]:
		for i in pool.capacity:
			if not pool.alive[i]:
				continue
			var at: Vector2 = pool.position[i] + shift
			if not visible_rect.has_point(at):
				continue
			if pool == battle.shots:
				if not subtle_effects:
					draw_line(at - pool.velocity[i].normalized() * 16, at, Color(1, 0.88, 0.65, 0.28), 3)
				if pool.kind[i] == 0:
					var direction: Vector2 = pool.velocity[i].normalized()
					var side: Vector2 = direction.orthogonal()
					draw_line(at - direction * 7, at + direction * 6, Color("fff0cc"), 2)
					for rib in [-3, 0, 3]:
						var base: Vector2 = at + direction * rib
						draw_line(base - side * 3, base + side * 3, Color("fff0cc"), 1)
					draw_circle(at + direction * 7, 3, Color("fff0cc"))
					draw_circle(at + direction * 8 - side, 1, Color("705775"))
				elif pool.kind[i] == 5:
					draw_circle(at, 4, Color("abd9d1"))
					draw_circle(at, 2, Color("426b73"), false, 1)
				else:
					draw_circle(at, 5, Color("e8acbf"))
					draw_arc(at, 3, battle.elapsed * 12, battle.elapsed * 12 + PI, 8, Color("fae6bc"), 2)
			else:
				draw_circle(at, 5 if pool.aux[i] > 0 else 4, Color("2a243b"))
				draw_circle(at, 3, Color("f397af"), pool.aux[i] <= 0, -1 if pool.aux[i] <= 0 else 1)
				draw_circle(at, 1, Color("fff0dd"))
	var number_positions: Array[Vector2] = []
	for effect in battle.effects:
		var at: Vector2 = effect.at + shift
		if not visible_rect.has_point(at):
			continue
		var phase: float = 1 - effect.life / effect.total
		if effect.kind == 5:
			if phase < 0.35:
				for n in 4:
					var ray := Vector2.from_angle(n * PI / 2 + PI / 4)
					draw_line(at + ray * 3, at + ray * (10 - phase * 10), Color("fff4cc"), 2)
			if not subtle_effects and effect.get("damage", 0) >= 25 and number_positions.size() < 12:
				var number_at := at + Vector2(-6, -12 - phase * 16)
				var crowded := false
				for previous in number_positions:
					if absf(previous.x - number_at.x) < 22 and absf(previous.y - number_at.y) < 13:
						crowded = true
						break
				if not crowded:
					number_positions.append(number_at)
					_text(str(effect.damage), number_at, 11, Color(1, 0.9, 0.65, 1 - phase))
		elif effect.kind == 6:
			if not subtle_effects:
				draw_arc(at, effect.radius * phase, 0, TAU, 48, Color(1, 0.86, 0.5, 1 - phase), 3)
				for n in 12:
					var point: Vector2 = at + Vector2.from_angle(n * TAU / 12) * effect.radius * phase
					draw_rect(Rect2(point, Vector2(3, 3)), Color(1, 0.92, 0.7, 1 - phase))
		elif effect.kind == 3:
			for n in 3:
				draw_arc(at + Vector2(n * 3 - 3, 0), effect.radius * (0.7 + phase * 0.3), battle.aim.angle() - 0.6, battle.aim.angle() + 0.6, 12, Color(0.86, 0.97, 0.85, 1 - phase), 2)
		else:
			if effect.kind == 2 and phase < 0.3:
				draw_circle(at, 8 * (1 - phase * 2), Color(1, 0.95, 0.78, (1 - phase * 3) * 0.65))
			var tint := Color("f4bfba") if effect.kind == 1 else Color("ead5ad") if effect.kind == 4 else Color("b5dccf")
			draw_arc(at, effect.radius * (0.2 + phase), 0, TAU, 20, Color(tint, 1 - phase), 1)
			for n in 7:
				var point: Vector2 = at + Vector2.from_angle(n * 2.4) * effect.radius * phase + Vector2(0, -phase * 12)
				draw_rect(Rect2(point.round(), Vector2(2, 2)), Color(tint, 1 - phase))

	_clue_marker(shift)

func _cat(at: Vector2) -> void:
	draw_style_box(GameSkin.box(Color(0.04, 0.05, 0.10, 0.45), 5), Rect2(at + Vector2(-13, 3), Vector2(26, 7)))
	var frame := int(battle.walk_phase) % 4 if battle.moving else 0
	var bounce := absf(sin(battle.walk_phase)) if battle.moving else sin(battle.elapsed * 2) * 0.35
	var left := battle.aim.x < -0.05
	var tint := Color(1, 1, 1, 0.55) if battle.hidden else Color(1, 1, 1, 0.7) if battle.invulnerable > 0 and int(battle.elapsed * 20) % 2 == 1 else Color.WHITE
	draw_set_transform(at + Vector2(0, -bounce), 0, Vector2(-1 if left else 1, 1))
	draw_texture_rect(sprites[frame], Rect2(-16, -25, 32, 32), false, tint)
	var paw_interval := 0.36 if battle.evolved[0] else 0.45 if battle.weapons[0] >= 3 else 0.6
	if battle.paw_clock > paw_interval - 0.16:
		draw_rect(Rect2(9, -2, 4, 3), [CatPixel.COAT, Color("625e68"), Color("f2e6d1"), Color("f6f0e5")][cat_variant])
	draw_set_transform(Vector2.ZERO)
	if battle.ambush_charge > 0.2:
		draw_rect(Rect2(at + Vector2(-13, -4), Vector2(26, 10)), Color("b89370"))
		_text("웅크리기…", at + Vector2(-19, -30), 8, Color("f0c5a0"))
	if battle.hidden:
		_text("쉿…", at + Vector2(-8, -24), 9, Color("e5d4b3"))
	if battle.food_boost > 0:
		_text("♪", at + Vector2(14, -18), 11, Color("f0c5a0"))

func _ghost(id: int, at: Vector2) -> void:
	var kind := battle.enemies.kind[id]
	var boss := kind == 7
	var radius: float = Battle.ENEMY_RADIUS[kind]
	var body := at + Vector2(0, -5 + sin(battle.elapsed * 4 + id) * 1.5)
	draw_circle(at + Vector2(0, 3), radius * 0.7, Color(0.10, 0.08, 0.18, 0.3))
	draw_set_transform(body.round(), 0, Vector2.ONE * maxf(0.85, radius / 10.0))
	var ink := Color("30283f")
	var pale := Color("d8d5ef")
	if boss and battle.stage_id == 0:
		# A wooden jangseung face rising out of a long alley shadow.
		draw_rect(Rect2(-8, -17, 16, 31), ink)
		draw_rect(Rect2(-6, -15, 12, 27), Color("98768b"))
		draw_rect(Rect2(-10, -17, 20, 4), Color("d8b687"))
		for side in [-1, 1]:
			draw_line(Vector2(side * 2, -7), Vector2(side * 6, -9), pale, 2)
		draw_rect(Rect2(-5, 2, 10, 5), ink)
		for tooth in 4:
			draw_rect(Rect2(-4 + tooth * 2, 2, 1, 3), Color("e9d4b6"))
	elif boss and battle.stage_id == 2:
		# Horns and a broad mask distinguish the market dokkaebi.
		draw_colored_polygon(PackedVector2Array([Vector2(-9, -4), Vector2(-10, -17), Vector2(-3, -7), Vector2(3, -7), Vector2(10, -17), Vector2(9, 8), Vector2(-9, 8)]), Color("81c1c0"))
		draw_rect(Rect2(-7, -4, 14, 12), Color("a9ded1"))
		for side in [-1, 1]:
			draw_line(Vector2(side * 2, -1), Vector2(side * 6, -3), ink, 2)
		draw_rect(Rect2(-5, 4, 10, 2), ink)
		draw_circle(Vector2(-13, 6), 3, Color("c2eff0"))
	elif kind in [1, 5] or boss:
		# White sleeves and long dark hair; the park spirit sits on a swing.
		if boss:
			for side in [-1, 1]:
				draw_line(Vector2(side * 10, -20), Vector2(side * 10, 11), Color("c0aac9"), 1)
			draw_rect(Rect2(-12, 10, 24, 3), Color("b5948c"))
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -8), Vector2(5, -8), Vector2(9, 10), Vector2(2, 8), Vector2(-2, 11), Vector2(-8, 9)]), pale)
		var sway := sin(battle.elapsed * 5 + id) * 3
		for side in [-1, 1]:
			draw_line(Vector2(side * 4, -2), Vector2(side * 12, 3 + sway), pale, 4)
		draw_rect(Rect2(-6, -12, 12, 13), ink)
		draw_rect(Rect2(-2, -8, 5, 6), Color("f1e7e4"))
		draw_rect(Rect2(-1, -6, 1, 1), ink)
		draw_rect(Rect2(2, -6, 1, 1), ink)
	elif kind == 2:
		draw_line(Vector2(0, -14), Vector2(0, 13), Color("f4c5d0"), 2)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -12), Vector2(-7, 5), Vector2(7, 5)]), Color("be799f"))
		draw_line(Vector2(0, 13), Vector2(4, 10), Color("f4c5d0"), 2)
		draw_circle(Vector2(0, 0), 2, pale)
	elif kind == 3:
		draw_colored_polygon(PackedVector2Array([Vector2(0, -14), Vector2(3, -5), Vector2(8, -8), Vector2(7, 6), Vector2(0, 10), Vector2(-7, 5), Vector2(-5, -7)]), Color("78c7cd"))
		draw_circle(Vector2(0, 2), 4, Color("d9faf0"))
	elif kind in [4, 6]:
		draw_rect(Rect2(-5, -12, 10, 5), Color("ddbd8f"))
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -7), Vector2(5, -7), Vector2(10, 3), Vector2(7, 10), Vector2(-7, 10), Vector2(-10, 3)]), Color("ac8e9d"))
		for row in 3:
			draw_line(Vector2(-7, row * 4 - 2), Vector2(7, row * 4 - 2), Color("ddbd8f"), 1)
		draw_rect(Rect2(-4, -3, 2, 3), ink)
		draw_rect(Rect2(3, -3, 2, 3), ink)
	else:
		draw_circle(Vector2.ZERO, 8, Color("a79abc"))
		draw_circle(Vector2(0, 1), 6, ink)
		for side in [-1, 1]:
			draw_circle(Vector2(side * 4, 8), 3, Color("867797"))
			draw_rect(Rect2(side * 3 - 1, -2, 2, 2), pale)
	draw_set_transform(Vector2.ZERO)
	if battle.elite_ids.has(id):
		draw_arc(body, radius + 6, 0, TAU, 24, Color("e8d3a5"), 1)
	if battle.enemies.fear[id] > 0:
		_text("!", at + Vector2(-3, -radius - 8), 13, Color("f1d89d"))
	if kind == 2 and battle.enemies.mode[id] == 1:
		draw_line(at, battle.enemies.target[id] + Vector2(320, 180) - battle.camera(), Color("ffa0b3"), 1)

func _text(value: String, at: Vector2, size: int, tint: Color) -> void:
	draw_string(GameSkin.REGULAR, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)

func _ground(shift: Vector2) -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(AlleyTheme.GROUND[theme_id]))
	var origin := Vector2i(((battle.camera() - Vector2(320, 180)) / 64).floor())
	for y in range(origin.y - 1, origin.y + 7):
		for x in range(origin.x - 1, origin.x + 12):
			var at := Vector2(x * 64, y * 64) + shift
			var hash_value := posmod(x * 17 + y * 31, 9)
			draw_rect(Rect2(at, Vector2(63, 63)), Color(AlleyTheme.TILES[theme_id]) if hash_value < 3 else Color(AlleyTheme.GROUND[theme_id]).lightened(0.02))
			if hash_value == 0:
				draw_style_box(GameSkin.box(Color("6b6380"), 4), Rect2(at + Vector2(11, 27), Vector2(32, 9)))
				draw_line(at + Vector2(17, 29), at + Vector2(33, 29), Color("9a89a5"))
	for obstacle in battle.obstacles:
		var at := obstacle.position + shift
		if not Rect2(-200, -180, 1040, 720).has_point(at):
			continue
		if battle.stage_id == 1:
			draw_style_box(GameSkin.box(Color("637b78"), 8), Rect2(at, obstacle.size))
			draw_style_box(GameSkin.box(Color("81998a"), 8), Rect2(at + Vector2(6, 6), obstacle.size - Vector2(12, 12)))
			for flower in 5:
				draw_circle(at + Vector2(18 + (flower % 2) * 31, 18 + flower * 19), 5, Color("c7b5bd"))
		else:
			draw_rect(Rect2(at, obstacle.size), Color(AlleyTheme.WALL[theme_id]))
			draw_rect(Rect2(at, Vector2(obstacle.size.x, 9)), Color(AlleyTheme.ROOF[theme_id]))
			if battle.stage_id == 2:
				for stripe in int(obstacle.size.x / 18):
					draw_rect(Rect2(at + Vector2(stripe * 18, 0), Vector2(9, 15)), Color("bc9b9c"))
				for box in 4:
					draw_rect(Rect2(at + Vector2(12 + box * 38, 24), Vector2(28, 25)), Color("9d826f"))
					draw_circle(at + Vector2(24 + box * 38, 30), 5, Color("cdb48b"))
			else:
				for window in 3:
					draw_rect(Rect2(at + Vector2(12 + window * 32, 19), Vector2(18, 22)), Color("b18e71") if window == 1 else Color("887993"))
					draw_line(at + Vector2(20 + window * 32, 19), at + Vector2(20 + window * 32, 41), Color("252d43"), 2)
			if theme_id == 3:
				draw_style_box(GameSkin.box(Color("b9ccd9"), 4), Rect2(at + Vector2(2, -2), Vector2(obstacle.size.x - 4, 6)))
		var lamp := at + Vector2(obstacle.size.x + 32, 65)
		draw_circle(lamp, 27, Color(0.94, 0.73, 0.46, 0.06))
		draw_line(lamp - Vector2(0, 35), lamp, Color("747588"), 2)
		draw_rect(Rect2(lamp - Vector2(5, 37), Vector2(10, 4)), Color("efd5a2"))
		if theme_id == 1:
			for petal in 3:
				draw_circle(at + Vector2(-8 + petal * 10, 8 - (petal % 2) * 8), 9, Color("b68b9f"))
		elif theme_id == 2:
			draw_style_box(GameSkin.box(Color("45647b"), 6), Rect2(at + Vector2(12, obstacle.size.y + 8), Vector2(60, 8)))
	var center := Battle.WORLD * 0.5 + shift
	if battle.stage_id == 0:
		draw_rect(Rect2(center + Vector2(100, -132), Vector2(138, 16)), Color(AlleyTheme.ACCENT[theme_id]))
		_text("달빛 편의점 24", center + Vector2(112, -120), 10, Color("fff0d3"))
	elif battle.stage_id == 1:
		draw_line(center + Vector2(85, -90), center + Vector2(105, -130), Color("a59a9b"), 3)
		draw_line(center + Vector2(145, -90), center + Vector2(125, -130), Color("a59a9b"), 3)
		draw_line(center + Vector2(105, -130), center + Vector2(125, -130), Color("a59a9b"), 3)
		draw_line(center + Vector2(115, -126), center + Vector2(115, -100), Color("bfac99"), 1)
		draw_rect(Rect2(center + Vector2(105, -100), Vector2(22, 4)), Color("c7afa3"))
	else:
		_text("별빛시장 · 밤에도 따뜻한 자리", center + Vector2(-90, -85), 12, Color("dac799"))
	draw_rect(Rect2(shift, Battle.WORLD), Color("606c86"), false, 3)

	AlleyTheme.decorate(self, theme_id, Rect2(0, 0, 640, 360), battle.elapsed)

func _night_objects(shift: Vector2) -> void:
	for lure in battle.lures:
		var at: Vector2 = lure.at + shift
		if lure.kind == 2:
			draw_style_box(GameSkin.box(Color("a9a2ba"), 7), Rect2(at - Vector2(38, 27), Vector2(76, 54)))
			_text("잠깐 쉬어도 괜찮아", at + Vector2(-33, -32), 8, Color("dfd9d2"))
		elif lure.kind == 1:
			draw_circle(at, 55, Color(0.7, 0.84, 0.77, 0.1))
			draw_circle(at, 6, Color("eccb8f"))
			draw_line(at + Vector2(-3, 1), at + Vector2(3, 1), Color("735f72"), 1)
		else:
			draw_colored_polygon(PackedVector2Array([at + Vector2(-7, 5), at + Vector2(-4, -8), at + Vector2(6, -6), at + Vector2(8, 5)]), Color("bad6d0"))
			_text("바스락", at + Vector2(-12, -12), 8, Color("cce3d8"))

func _clue_marker(shift: Vector2) -> void:
	if battle.clue_at != Vector2.ZERO and not battle.clue_found:
		var at := (battle.clue_at + shift).clamp(Vector2(100, 100), Vector2(540, 275))
		if battle.stage_id == 0:
			draw_arc(at, 12, PI, TAU, 12, Color("e4c486"), 5)
			draw_line(at, at + Vector2(0, 12), Color("bdb9b3"), 2)
			draw_arc(at + Vector2(-3, 12), 3, 0, PI, 8, Color("bdb9b3"), 2)
		elif battle.stage_id == 1:
			draw_style_box(GameSkin.box(Color("9ebeba"), 4), Rect2(at - Vector2(12, 5), Vector2(24, 12)))
			_text("★", at + Vector2(-4, 3), 8, Color("f2d49d"))
		else:
			draw_style_box(GameSkin.box(Color("baa6bd"), 4), Rect2(at - Vector2(13, 8), Vector2(26, 16)))
			draw_line(at + Vector2(-8, -4), at + Vector2(8, 4), Color("d8c4d4"), 2)
		var direction := (battle.clue_at - battle.player).normalized()
		var arrow := at - direction * 26
		draw_colored_polygon(PackedVector2Array([arrow + direction * 9, arrow - direction * 5 + direction.orthogonal() * 6, arrow - direction * 5 - direction.orthogonal() * 6]), Color("ffe3a1"))
		draw_arc(at, 19, 0, TAU, 32, Color("ffe3a1"), 2)
		_text(NightContent.CLUES[battle.stage_id], at + Vector2(-32, 24), 9, Color("eee0c2"))
