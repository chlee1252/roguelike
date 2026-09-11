class_name Battlefield
extends Node2D

var battle: Battle
var sprites: Array[Texture2D] = []

func _ready() -> void:
	_make_sprites()

func _make_sprites() -> void:
	# Original four-legged tabby. The reference guides readability, not source pixels.
	for frame in 4:
		var picture := Image.create(28, 22, false, Image.FORMAT_RGBA8)
		var outline := Color("17232e")
		var coat := Color("929da1")
		var cream := Color("e3d7bd")
		picture.fill_rect(Rect2i(5, 8, 15, 11), outline)
		picture.fill_rect(Rect2i(6, 8, 13, 9), coat)
		picture.fill_rect(Rect2i(9, 14, 9, 4), cream)
		# Raised tail, ears and distinct paws preserve the feline silhouette.
		picture.fill_rect(Rect2i(2, 4 + frame % 2, 3, 10), outline)
		picture.fill_rect(Rect2i(3, 5 + frame % 2, 2, 8), coat)
		picture.fill_rect(Rect2i(4, 12, 4, 3), coat)
		for x in [8, 15]:
			picture.fill_rect(Rect2i(x + (frame % 2 if x == 8 else -(frame % 2)), 17, 4, 4 - frame % 2), outline)
			picture.fill_rect(Rect2i(x + (frame % 2 if x == 8 else -(frame % 2)), 17, 3, 2), cream)
		picture.fill_rect(Rect2i(15, 4, 11, 11), outline)
		picture.fill_rect(Rect2i(16, 5, 9, 9), coat)
		picture.fill_rect(Rect2i(15, 1, 4, 6), outline)
		picture.fill_rect(Rect2i(22, 1, 4, 6), outline)
		picture.fill_rect(Rect2i(16, 3, 2, 3), Color("d7a5a0"))
		picture.fill_rect(Rect2i(23, 3, 2, 3), Color("d7a5a0"))
		for x in [8, 12, 18, 21]:
			picture.fill_rect(Rect2i(x, 8 if x < 15 else 6, 2, 3), Color("576674"))
		picture.fill_rect(Rect2i(18, 9, 2, 2), Color("efd594"))
		picture.fill_rect(Rect2i(23, 9, 2, 2), Color("efd594"))
		picture.set_pixel(19, 9, outline)
		picture.set_pixel(24, 9, outline)
		picture.fill_rect(Rect2i(20, 12, 3, 2), cream)
		picture.set_pixel(22, 12, Color("c48e8b"))
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
				_text("상자 · 멈추면 숨기", at + Vector2(-32, 24), 8, Color("b9b5b2"))
			1:
				draw_circle(at, 24, Color(0.65, 0.84, 0.72, 0.08))
				draw_style_box(GameSkin.box(Color("789b9e"), 4), Rect2(at - Vector2(10, 5), Vector2(20, 10)))
				for n in 5:
					draw_circle(at + Vector2(n * 3 - 6, -1), 2, Color("dbb28b"))
				_text("누군가 놓은 밥", at + Vector2(-27, 22), 8, Color("a4cfbc"))
			2:
				draw_rect(Rect2(at - Vector2(26, 7), Vector2(52, 14)), Color("64717e"))
				for x in range(-24, 25, 8):
					draw_line(at + Vector2(x, -5), at + Vector2(x, 4), Color("8696a0"))
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
		var tint := Color("a4dfc6") if blast.friendly else Color("f594a0")
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
				draw_circle(at, 4, Color("a4dfc6"))
				draw_arc(at, 2, battle.elapsed * 12, battle.elapsed * 12 + PI, 8, Color("425f62"), 1)
			else:
				draw_circle(at, 5 if pool.aux[i] > 0 else 4, Color("2a243b"))
				draw_circle(at, 3, Color("f397af"), pool.aux[i] <= 0, 1)
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
	var bob := sin(battle.elapsed * 3 + id) * 2
	var radius: float = Battle.ENEMY_RADIUS[kind]
	var tint: Color = [Color("7f8fae"), Color("b3a9bd"), Color("9b90b4"), Color("718fa8"), Color("8b9b9f"), Color("bcb8c7"), Color("d6be8d"), Color("8d839d")][kind]
	draw_circle(at + Vector2(0, 3), radius * 0.7, Color(0.03, 0.05, 0.10, 0.20))
	var body := at + Vector2(0, -6 + bob)
	if kind == 2:
		draw_colored_polygon(PackedVector2Array([body + Vector2(-12, 0), body + Vector2(0, -14), body + Vector2(12, 0)]), tint)
		draw_line(body, body + Vector2(2, 9), tint, 2)
	elif kind == 3:
		draw_style_box(GameSkin.box(tint, 3), Rect2(body - Vector2(11, 5), Vector2(22, 11)))
		for n in 4:
			draw_line(body + Vector2(n * 5 - 8, -3), body + Vector2(n * 5 - 8, 3), Color("354456"), 2)
	elif kind == 7:
		# An abandoned alley folded into a small walking facade, never a human enemy.
		draw_rect(Rect2(body - Vector2(29, 36), Vector2(58, 52)), Color("514e67"))
		draw_rect(Rect2(body - Vector2(23, 29), Vector2(46, 38)), tint)
		draw_rect(Rect2(body + Vector2(-6, -6), Vector2(12, 26)), Color("2c3048"))
		_text("귀가길", body + Vector2(-13, -36), 9, Color("e9cb9c"))
	else:
		draw_rect(Rect2((body - Vector2(radius - 3, radius)).round(), Vector2(radius * 2 - 6, radius * 1.7)), tint)
		draw_rect(Rect2((body - Vector2(radius, radius - 3)).round(), Vector2(radius * 2, radius * 1.7 - 6)), tint)
		for n in 3:
			draw_rect(Rect2(body + Vector2(n * radius * 0.65 - radius, radius * 0.55), Vector2(radius * 0.5, 3 + n % 2 * 3)), tint)
		if kind == 4:
			draw_arc(body + Vector2(0, -radius), 7, PI, TAU, 12, tint, 2)
		if kind == 5:
			draw_line(body + Vector2(-20, -16), body + Vector2(20, -16), Color("8a829c"))
		if kind == 6:
			draw_circle(body + Vector2(0, -14), 6, Color("e6cf94"))
	for side in [-1, 1]:
		draw_rect(Rect2(body + Vector2(side * radius * 0.35 - 1, -4), Vector2(2, 3)), Color("303347"))
	if battle.elite_ids.has(id):
		draw_arc(body, radius + 6, 0, TAU, 24, Color("d7bc8e"), 1)
	if battle.enemies.mode[id] == 1:
		draw_line(at, battle.enemies.target[id] + Vector2(320, 180) - battle.camera(), Color("ed9aad"), 1)

func _text(value: String, at: Vector2, size: int, tint: Color) -> void:
	draw_string(GameSkin.REGULAR, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)

func _ground(shift: Vector2) -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("242e43"))
	var origin := Vector2i(((battle.camera() - Vector2(320, 180)) / 64).floor())
	for y in range(origin.y - 1, origin.y + 7):
		for x in range(origin.x - 1, origin.x + 12):
			var at := Vector2(x * 64, y * 64) + shift
			var hash_value := posmod(x * 17 + y * 31, 9)
			draw_rect(Rect2(at, Vector2(63, 63)), Color("283249") if hash_value < 3 else Color("263047"))
			if hash_value == 0:
				draw_style_box(GameSkin.box(Color("35465b"), 4), Rect2(at + Vector2(11, 27), Vector2(32, 9)))
				draw_line(at + Vector2(17, 29), at + Vector2(33, 29), Color("52617a"))
	# Building edges sit outside the open central alley, with readable crossing gaps.
	for x in range(0, 2400, 320):
		for y in range(0, 1600, 320):
			var at := Vector2(x, y) + shift
			if not Rect2(-170, -100, 980, 560).has_point(at):
				continue
			draw_rect(Rect2(at, Vector2(116, 55)), Color("1b2338"))
			draw_rect(Rect2(at + Vector2(0, 2), Vector2(116, 8)), Color("495064"))
			for n in 3:
				draw_rect(Rect2(at + Vector2(12 + n * 32, 19), Vector2(18, 22)), Color("b18e71") if n == 1 else Color("3f4c64"))
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
	draw_rect(Rect2(store, Vector2(128, 56)), Color("363d57"))
	draw_rect(Rect2(store + Vector2(0, -15), Vector2(128, 16)), Color("536d79"))
	_text("달빛 편의점  ·  24", store + Vector2(12, -3), 10, Color("efe0bf"))
	for n in 4:
		draw_rect(Rect2(store + Vector2(6 + n * 30, 7), Vector2(25, 43)), Color("898e91"))
		draw_rect(Rect2(store + Vector2(9 + n * 30, 10), Vector2(19, 34)), Color("ddc69e"))
	_text("해솔빌라  골목 03", Battle.WORLD * 0.5 + Vector2(-125, -86) + shift, 10, Color("7c8ba2"))
	draw_rect(Rect2(shift, Battle.WORLD), Color("606c86"), false, 3)
