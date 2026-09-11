class_name Battlefield
extends Node2D

var battle: Battle
var sprites: Array[Texture2D] = []

func _ready() -> void:
	_make_sprites()

func _make_sprites() -> void:
	# A round-cheeked ginger cat, drawn as original stepped pixels.
	for frame in 4:
		var picture := Image.create(28, 22, false, Image.FORMAT_RGBA8)
		var outline := Color("594459")
		var coat := Color("eeb582")
		var cream := Color("fff1d1")
		picture.fill_rect(Rect2i(5, 10, 15, 9), outline)
		picture.fill_rect(Rect2i(6, 9, 13, 9), coat)
		picture.fill_rect(Rect2i(8, 14, 11, 4), cream)
		picture.fill_rect(Rect2i(1, 6 + frame % 2, 3, 8), outline)
		picture.fill_rect(Rect2i(2, 5 + frame % 2, 4, 3), outline)
		picture.fill_rect(Rect2i(2, 7 + frame % 2, 2, 6), coat)
		picture.fill_rect(Rect2i(3, 12, 4, 3), coat)
		for x in [8, 15]:
			var step := frame % 2 if x == 8 else -(frame % 2)
			picture.fill_rect(Rect2i(x + step, 17, 4, 3), outline)
			picture.fill_rect(Rect2i(x + step, 17, 3, 2), cream)
		picture.fill_rect(Rect2i(13, 5, 14, 9), outline)
		picture.fill_rect(Rect2i(15, 3, 10, 13), outline)
		picture.fill_rect(Rect2i(14, 6, 12, 7), coat)
		picture.fill_rect(Rect2i(16, 4, 8, 11), coat)
		for x in [14, 23]:
			picture.fill_rect(Rect2i(x, 1, 3, 5), outline)
			picture.fill_rect(Rect2i(x + 1, 3, 2, 3), Color("efb5b0"))
		for x in [8, 11, 18, 21]:
			picture.fill_rect(Rect2i(x, 10 if x < 13 else 5, 1, 2), Color("c9916b"))
		for x in [16, 22]:
			picture.fill_rect(Rect2i(x, 8, 3, 3), outline)
			picture.set_pixel(x, 8, Color.WHITE)
		picture.fill_rect(Rect2i(15, 11, 2, 1), Color("ec9ba2"))
		picture.fill_rect(Rect2i(24, 11, 2, 1), Color("ec9ba2"))
		picture.fill_rect(Rect2i(18, 11, 5, 3), cream)
		picture.set_pixel(20, 11, Color("c78391"))
		picture.set_pixel(19, 13, outline)
		picture.set_pixel(21, 13, outline)
		sprites.append(ImageTexture.create_from_image(picture))

func _draw() -> void:
	if battle == null:
		return
	var shift := Vector2(320, 180) - battle.camera()
	_ground(shift)
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
				draw_circle(at, 24, Color(0.65, 0.84, 0.72, 0.08))
				draw_style_box(GameSkin.box(Color("789b9e"), 4), Rect2(at - Vector2(10, 5), Vector2(20, 10)))
				for n in 5:
					draw_circle(at + Vector2(n * 3 - 6, -1), 2, Color("dbb28b"))
				if battle.player.distance_to(object.at) < 80:
					_text("누군가 놓은 밥", at + Vector2(-27, 22), 8, Color("a4cfbc"))
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
		else:
			draw_circle(at, 10, Color(0.92, 0.72, 0.4, 0.10))
			var tint := Color("f1c995") if kind == 1 else Color("eba9ac") if kind == 2 else Color("9abecb")
			draw_style_box(GameSkin.box(tint, 3), Rect2(at - Vector2(6, 4), Vector2(12, 8)))
			draw_line(at - Vector2(3, 0), at + Vector2(3, 0), Color("f8ecce"), 2)
	for cache in battle.caches:
		var at: Vector2 = cache + shift
		var marker := at.clamp(Vector2(16, 61), Vector2(624, 310))
		draw_circle(marker, 9, Color("e9c995"), false, 1)
		_text("?", marker + Vector2(-3, 4), 11, Color("e9c995"))
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
	if battle.invulnerable <= 0 or int(battle.elapsed * 20) % 2 == 0:
		_cat(cat)
	for pool in [battle.shots, battle.hostile]:
		for i in pool.capacity:
			if not pool.alive[i]:
				continue
			var at: Vector2 = pool.position[i] + shift
			if not visible_rect.has_point(at):
				continue
			if pool == battle.shots:
				if pool.kind[i] == 0:
					var direction: Vector2 = pool.velocity[i].normalized()
					var side: Vector2 = direction.orthogonal()
					draw_line(at - direction * 7, at + direction * 6, Color("fff0cc"), 2)
					for rib in [-3, 0, 3]:
						var base: Vector2 = at + direction * rib
						draw_line(base - side * 3, base + side * 3, Color("fff0cc"), 1)
					draw_circle(at + direction * 7, 3, Color("fff0cc"))
					draw_circle(at + direction * 8 - side, 1, Color("705775"))
				else:
					draw_circle(at, 5, Color("e8acbf"))
					draw_arc(at, 3, battle.elapsed * 12, battle.elapsed * 12 + PI, 8, Color("fae6bc"), 2)
			else:
				draw_circle(at, 5 if pool.aux[i] > 0 else 4, Color("2a243b"))
				draw_circle(at, 3, Color("f397af"), pool.aux[i] <= 0, -1 if pool.aux[i] <= 0 else 1)
				draw_circle(at, 1, Color("fff0dd"))
	for effect in battle.effects:
		var at: Vector2 = effect.at + shift
		if not visible_rect.has_point(at):
			continue
		var phase: float = 1 - effect.life / effect.total
		if effect.kind == 3:
			for n in 3:
				draw_arc(at + Vector2(n * 3 - 3, 0), effect.radius * (0.7 + phase * 0.3), battle.aim.angle() - 0.6, battle.aim.angle() + 0.6, 12, Color(0.86, 0.97, 0.85, 1 - phase), 2)
		else:
			var tint := Color("f4bfba") if effect.kind == 1 else Color("b5dccf")
			draw_arc(at, effect.radius * (0.2 + phase), 0, TAU, 20, Color(tint, 1 - phase), 1)
			for n in 7:
				var point: Vector2 = at + Vector2.from_angle(n * 2.4) * effect.radius * phase + Vector2(0, -phase * 12)
				draw_rect(Rect2(point.round(), Vector2(2, 2)), Color(tint, 1 - phase))

func _cat(at: Vector2) -> void:
	draw_style_box(GameSkin.box(Color(0.04, 0.05, 0.10, 0.45), 5), Rect2(at + Vector2(-13, 3), Vector2(26, 7)))
	var frame := int(battle.walk_phase) % 4 if battle.moving else 0
	var bounce := absf(sin(battle.walk_phase)) if battle.moving else sin(battle.elapsed * 2) * 0.35
	var left := battle.aim.x < -0.05
	var tint := Color(1, 1, 1, 0.45) if battle.hidden else Color.WHITE
	draw_set_transform(at + Vector2(0, -bounce), 0, Vector2(-1 if left else 1, 1))
	draw_texture_rect(sprites[frame], Rect2(-14, -17, 28, 22), false, tint)
	var paw_interval := 0.36 if battle.evolved[0] else 0.45 if battle.weapons[0] >= 3 else 0.6
	if battle.paw_clock > paw_interval - 0.16:
		draw_rect(Rect2(9, -2, 5, 3), Color("e3d7bd"))
	draw_set_transform(Vector2.ZERO)
	if battle.hidden:
		_text("쉿…", at + Vector2(-8, -24), 9, Color("e5d4b3"))
	if battle.food_boost > 0:
		_text("♪", at + Vector2(14, -18), 11, Color("f0c5a0"))

func _ghost(id: int, at: Vector2) -> void:
	var kind := battle.enemies.kind[id]
	var radius: float = Battle.ENEMY_RADIUS[kind]
	var bob := sin(battle.elapsed * 4 + id) * 1.5
	var body := at + Vector2(0, -5 + bob)
	var scale_value := maxf(0.85, radius / 10.0)
	draw_circle(at + Vector2(0, 3), radius * 0.7, Color(0.15, 0.10, 0.22, 0.18))
	draw_set_transform(body.round(), 0, Vector2.ONE * scale_value)
	var outline := Color("55445f")
	if kind in [0, 2, 7]:
		var coat := Color("d0ae9f") if kind == 0 else Color("efcea1") if kind == 2 else Color("d7b4cf")
		# Floppy ears, round muzzle and little paws: a puppy-shaped nuisance spirit.
		draw_rect(Rect2(-9, -7, 18, 15), outline)
		draw_rect(Rect2(-7, -9, 14, 19), outline)
		draw_rect(Rect2(-8, -6, 16, 13), coat)
		draw_rect(Rect2(-6, -8, 12, 17), coat)
		for side in [-1, 1]:
			draw_rect(Rect2(side * 10 - 2, -8, 4, 10), Color("a18495"))
			draw_rect(Rect2(side * 4 - 1, -3, 2, 3), outline)
			draw_rect(Rect2(side * 5 - 2, 7, 4, 3), Color("f4e4d0"))
		draw_rect(Rect2(-4, 1, 8, 5), Color("f6e7ce"))
		draw_rect(Rect2(-1, 1, 3, 2), outline)
		draw_rect(Rect2(0, 4, 2, 2), Color("e5a1b0"))
		if kind == 7:
			draw_rect(Rect2(-6, 8, 12, 2), Color("bc94b9"))
			draw_rect(Rect2(-1, 9, 2, 3), Color("f5df9b"))
	elif kind in [1, 5]:
		var wing := sin(battle.elapsed * 8 + id) * 3
		draw_rect(Rect2(-7, -7, 14, 15), Color("9290bc"))
		draw_rect(Rect2(-5, -9, 10, 18), Color("aba6cf"))
		draw_line(Vector2(-6, 0), Vector2(-13, -3 + wing), Color("7778a0"), 4)
		draw_line(Vector2(6, 0), Vector2(13, -3 + wing), Color("7778a0"), 4)
		for side in [-1, 1]:
			draw_rect(Rect2(side * 3 - 1, -4, 2, 3), outline)
			draw_rect(Rect2(side * 3 - 1, 8, 3, 2), Color("ebc090"))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, 1), Vector2(4, 1), Vector2(1, 5)]), Color("ebc090"))
	elif kind == 3:
		draw_rect(Rect2(-6, -5, 12, 15), Color("9cc6c5"))
		draw_rect(Rect2(-4, -10, 8, 6), Color("d7ebe0"))
		draw_rect(Rect2(-3, -12, 12, 3), Color("d7ebe0"))
		draw_rect(Rect2(-4, 0, 8, 6), Color("e6e8ce"))
		draw_rect(Rect2(-2, 1, 1, 2), outline)
		draw_rect(Rect2(2, 1, 1, 2), outline)
	else:
		# A toy-like robot vacuum, with a handle and a sleepy bumper face.
		draw_rect(Rect2(-10, -4, 20, 12), outline)
		draw_rect(Rect2(-8, -7, 16, 18), outline)
		draw_rect(Rect2(-9, -3, 18, 10), Color("e2b5c4") if kind == 6 else Color("a5c8ca"))
		draw_rect(Rect2(-7, -6, 14, 16), Color("e2b5c4") if kind == 6 else Color("a5c8ca"))
		draw_rect(Rect2(-6, 0, 12, 5), Color("6e6b8e"))
		for side in [-1, 1]:
			draw_rect(Rect2(side * 3 - 1, 1, 2, 1), Color("eee7cf"))
		draw_rect(Rect2(-3, -5, 6, 3), Color("f4d598"))
	draw_set_transform(Vector2.ZERO)
	if battle.elite_ids.has(id):
		draw_arc(body, radius + 6, 0, TAU, 24, Color("e8d3a5"), 1)
	if battle.enemies.mode[id] == 1:
		draw_line(at, battle.enemies.target[id] + Vector2(320, 180) - battle.camera(), Color("ffa0b3"), 1)

func _text(value: String, at: Vector2, size: int, tint: Color) -> void:
	draw_string(GameSkin.REGULAR, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)

func _ground(shift: Vector2) -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("45435f"))
	var origin := Vector2i(((battle.camera() - Vector2(320, 180)) / 64).floor())
	for y in range(origin.y - 1, origin.y + 7):
		for x in range(origin.x - 1, origin.x + 12):
			var at := Vector2(x * 64, y * 64) + shift
			var hash_value := posmod(x * 17 + y * 31, 9)
			draw_rect(Rect2(at, Vector2(63, 63)), Color("4b4866") if hash_value < 3 else Color("494561"))
			if hash_value == 0:
				draw_style_box(GameSkin.box(Color("6b6380"), 4), Rect2(at + Vector2(11, 27), Vector2(32, 9)))
				draw_line(at + Vector2(17, 29), at + Vector2(33, 29), Color("9a89a5"))
	# Building edges sit outside the open central alley, with readable crossing gaps.
	for x in range(0, 2400, 320):
		for y in range(0, 1600, 320):
			var at := Vector2(x, y) + shift
			if not Rect2(-170, -100, 980, 560).has_point(at):
				continue
			draw_rect(Rect2(at, Vector2(116, 55)), Color("39354f"))
			draw_rect(Rect2(at + Vector2(0, 2), Vector2(116, 8)), Color("766980"))
			for n in 3:
				draw_rect(Rect2(at + Vector2(12 + n * 32, 19), Vector2(18, 22)), Color("b18e71") if n == 1 else Color("887993"))
				draw_line(at + Vector2(20 + n * 32, 19), at + Vector2(20 + n * 32, 41), Color("252d43"), 2)
			draw_rect(Rect2(at + Vector2(120, 10), Vector2(27, 21)), Color("5d6675"))
			for n in 5:
				draw_line(at + Vector2(124, 13 + n * 3), at + Vector2(141, 13 + n * 3), Color("333e51"))
			var lamp := at + Vector2(162, 60)
			draw_circle(lamp, 33, Color(0.94, 0.73, 0.46, 0.045))
			draw_circle(lamp, 22, Color(0.94, 0.73, 0.46, 0.06))
			draw_line(lamp - Vector2(0, 35), lamp, Color("62687b"), 2)
			draw_rect(Rect2(lamp - Vector2(5, 37), Vector2(10, 4)), Color("efd5a2"))
	var store := Battle.WORLD * 0.5 + Vector2(105, -112) + shift
	draw_rect(Rect2(store, Vector2(128, 56)), Color("756881"))
	draw_rect(Rect2(store + Vector2(0, -15), Vector2(128, 16)), Color("95b6b1"))
	_text("달빛 편의점  ·  24", store + Vector2(12, -3), 10, Color("efe0bf"))
	for n in 4:
		draw_rect(Rect2(store + Vector2(6 + n * 30, 7), Vector2(25, 43)), Color("898e91"))
		draw_rect(Rect2(store + Vector2(9 + n * 30, 10), Vector2(19, 34)), Color("ddc69e"))
	_text("해솔빌라  골목 03", Battle.WORLD * 0.5 + Vector2(-125, -86) + shift, 10, Color("7c8ba2"))
	draw_rect(Rect2(shift, Battle.WORLD), Color("606c86"), false, 3)
