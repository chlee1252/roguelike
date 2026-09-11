class_name Battlefield
extends Node2D

var battle: Battle
var sprites: Array[Texture2D] = []

func _ready() -> void:
	_make_sprites()

func _make_sprites() -> void:
	var soldier := ["....hhhh....", "...hhhhhh...", "...hssssh...", "....ssss....", "...aabbaa...", "..aabbbbaa..", ".a.abbbb.a..", ".s.abbbb.ss.", "...aaaaaa...", "...aa.aa....", "...aa.aa....", "..ddd.ddd..."]
	for palette in [ ["708257", "d8b58a", "43533f", "28352e", "141f21"], ["aa6650", "ba9770", "714f42", "423d39", "242e31"], ["bdad72", "ba9770", "776447", "423d39", "242e31"], ["93665e", "ba9770", "70465a", "423d39", "242e31"] ]:
		var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
		var symbols := "hsabd"
		for y in 12:
			for x in 12:
				var index := symbols.find(soldier[y][x])
				if index >= 0:
					image.set_pixel(x, y, Color(palette[index]))
		sprites.append(ImageTexture.create_from_image(image))

func _draw() -> void:
	if battle == null:
		return
	var cam := battle.camera()
	var shift := Vector2(320, 180) - cam
	_draw_ground(cam, shift)
	var bounds := Rect2(shift, Battle.WORLD)
	draw_rect(bounds, Color("96926c"), false, 3)
	for i in battle.pickups.capacity:
		if not battle.pickups.alive[i]:
			continue
		var at := (battle.pickups.position[i] + shift).round()
		if not Rect2(-20, -20, 680, 400).has_point(at):
			continue
		if battle.pickups.kind[i] == 0:
			draw_rect(Rect2(at - Vector2(2, 3), Vector2(4, 6)), Color("79caba"))
			draw_rect(Rect2(at - Vector2(1, 2), Vector2(2, 2)), Color("d9f2ce"))
		else:
			draw_rect(Rect2(at - Vector2(5, 4), Vector2(10, 8)), Color("e7e6c6"))
			draw_line(at - Vector2(2, 0), at + Vector2(2, 0), Color("a25048"), 2)
			draw_line(at - Vector2(0, 2), at + Vector2(0, 2), Color("a25048"), 2)
	for cache in battle.caches:
		var at: Vector2 = cache + shift
		if not Rect2(12, 55, 616, 265).has_point(at):
			var marker := at.clamp(Vector2(14, 57), Vector2(626, 318))
			var direction := (at - Vector2(320, 180)).normalized()
			draw_line(marker - direction * 6, marker + direction * 6, Color("e9c675"), 2)
			draw_circle(marker, 4, Color("e9c675"), false, 1)
			continue
		draw_rect(Rect2(at - Vector2(8, 6), Vector2(16, 12)), Color("d8ad58"))
		draw_rect(Rect2(at - Vector2(5, 3), Vector2(10, 6)), Color("4d5036"))
		draw_circle(at, 13 + sin(battle.elapsed * 4) * 2, Color("e9c675"), false, 1)
	for fire in battle.fires:
		var at: Vector2 = fire.at + shift
		draw_circle(at, 18, Color(0.8, 0.35, 0.1, 0.22))
		for n in 5:
			var ember := at + Vector2.from_angle(n * 2.4) * (5 + n * 2)
			draw_rect(Rect2(ember.round(), Vector2(3, 5)), Color("e5a657"))
	for blast in battle.blasts:
		var color := Color("7cc6ac") if blast.friendly else Color("f17662")
		var at: Vector2 = blast.at + shift
		draw_circle(at, blast.radius, Color(color, 0.08))
		draw_arc(at, blast.radius, 0, TAU, 40, color, 1.0)
		draw_arc(at, blast.radius * (1.0 - blast.time / blast.total), 0, TAU, 32, color, 1.0)
		draw_line(at - Vector2(5, 0), at + Vector2(5, 0), color)
		draw_line(at - Vector2(0, 5), at + Vector2(0, 5), color)
	for i in battle.enemies.capacity:
		if not battle.enemies.alive[i]:
			continue
		var at := (battle.enemies.position[i] + shift).round()
		if Rect2(-40, -40, 720, 440).has_point(at):
			_draw_enemy(i, at)
	var player := (battle.player + shift).round()
	if battle.flame_active:
		var angle := battle.flame_direction.angle()
		var reach := (90.0 if battle.weapons[1] >= 3 else 70.0) * (1 + battle.supports[1] * 0.1)
		for i in 12:
			var phase := fposmod(battle.elapsed * 3 + i * 0.17, 1.0)
			var spread := sin(i * 7.7) * (0.65 if battle.weapons[1] >= 5 else 0.45)
			var at := player + Vector2.from_angle(angle + spread) * (12 + reach * phase)
			draw_rect(Rect2(at.round(), Vector2.ONE * (3 + phase * 5)), Color(1.0, 0.6 + phase * 0.2, 0.25, 0.65 * (1 - phase)))
	if battle.invulnerable <= 0 or int(battle.elapsed * 20) % 2 == 0:
		_draw_commando(player)
	for pool in [battle.shots, battle.hostile]:
		for i in pool.capacity:
			if not pool.alive[i]:
				continue
			var at: Vector2 = pool.position[i] + shift
			if pool == battle.hostile:
				if pool.aux[i] > 0:
					draw_circle(at, 5, Color("f7c786"), false, 1)
				else:
					draw_circle(at, 4, Color("352225"))
					draw_circle(at, 3, Color("ff836a"))
					draw_circle(at, 1, Color("fff0bf"))
			else:
				draw_line(at, at - pool.velocity[i].normalized() * 5, Color("d3c78f"), 1)
	for effect in battle.effects:
		var phase: float = 1.0 - effect.life / effect.total
		var at: Vector2 = effect.at + shift
		if not Rect2(-64, -64, 768, 488).has_point(at):
			continue
		var color := Color("f9bd69") if effect.kind != 1 else Color("f17662")
		if effect.kind == 2:
			# A brief white core, expanding shock ring and deterministic debris.
			var fade := 1.0 - phase
			draw_circle(at, effect.radius * (0.4 + phase), Color("233139", fade * 0.5))
			draw_arc(at, effect.radius * (0.25 + phase), 0, TAU, 24, Color("eac99a", fade * 0.7), 1, true)
			if phase < 0.25:
				draw_circle(at + Vector2(0, -5), effect.radius * 0.35 * (1 - phase * 3), Color("fff1cc"))
			for n in 8:
				var direction := Vector2.from_angle(n * 2.399 + effect.at.x * 0.1)
				var point: Vector2 = at + direction * effect.radius * (0.25 + phase * 1.3) + Vector2(0, phase * phase * 10 - 5)
				draw_line(point, point - direction * (2 + fade * 4), Color("ffd18c", fade), 2)
				draw_rect(Rect2(point.round(), Vector2(2, 2)), Color("c3cbd0", fade))
		else:
			draw_circle(at, effect.radius * (0.3 + phase), Color(color, (1 - phase) * 0.35))
			draw_arc(at, effect.radius * (0.3 + phase), 0, TAU, 20, Color(color, 1 - phase), 2)

func _draw_commando(at: Vector2) -> void:
	var direction := battle.aim.normalized()
	var hand := at + battle.gun_grip() - battle.player
	var interval := 0.12 if battle.evolved[0] else 0.16 if battle.weapons[0] >= 6 else 0.20 if battle.weapons[0] >= 3 else 0.25
	var recoil := clampf((battle.gun_clock - interval + 0.08) / 0.08, 0, 1)
	var grip := hand - direction * recoil * 2.5
	draw_ellipse_shadow(at, 11)
	# The receiver stays beside the chest; hands connect the stock and foregrip.
	draw_texture_rect(sprites[0], Rect2(at - Vector2(9, 14), Vector2(18, 18)), false)
	var shoulder := at + Vector2(5 if direction.x >= 0 else -5, -9)
	draw_line(shoulder, grip - direction * 2, Color("708257"), 4)
	draw_line(grip - direction * 4, grip + direction * 8, Color("17262e"), 5)
	draw_line(grip - direction * 3 + Vector2(0, -1), grip + direction * 7 + Vector2(0, -1), Color("7d959e"), 2)
	draw_line(grip + direction * 7, grip + direction * 14, Color("b2c1c3"), 2)
	draw_circle(grip, 2, Color("d8b58a"))
	draw_circle(grip + direction * 6 + direction.orthogonal() * 1.5, 1.8, Color("d8b58a"))
	if recoil > 0.25:
		var muzzle := grip + direction * 15
		var side := direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([muzzle - side * 3, muzzle + direction * (5 + recoil * 4), muzzle + side * 3, muzzle - direction * 2]), Color("ffd488"))
		draw_line(muzzle, muzzle + direction * 4, Color("fff7dc"), 2)
		var casing := grip + side * (4 + (1 - recoil) * 10) + Vector2(0, -recoil * 4)
		draw_line(casing, casing + direction * 2, Color("d6b675"), 1)

func _draw_ground(cam: Vector2, shift: Vector2) -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color("26353e"))
	# Seamless service-yard panels; all floor markings remain traversable.
	var origin := Vector2i((cam - Vector2(320, 180)) / 96)
	for y in range(origin.y - 1, origin.y + 6):
		for x in range(origin.x - 1, origin.x + 9):
			var tile := Vector2(x * 96, y * 96) + shift
			var variant := posmod(x * 17 + y * 31, 5)
			draw_rect(Rect2(tile + Vector2.ONE, Vector2(94, 94)), Color("2b3a43") if variant < 2 else Color("293740"))
			draw_line(tile + Vector2(4, 95), tile + Vector2(93, 95), Color("34444d"), 1)
			for corner in [Vector2(5, 5), Vector2(91, 91)]:
				draw_rect(Rect2(tile + corner, Vector2.ONE), Color("50616a"))
			if variant == 0:
				draw_rect(Rect2(tile + Vector2(60, 68), Vector2(24, 12)), Color("202e37"))
				for n in 6:
					draw_line(tile + Vector2(63 + n * 3, 70), tile + Vector2(63 + n * 3, 77), Color("42535c"), 1)
	for road in [640, 1280, 1920]:
		var x: float = road + shift.x
		if x < -112 or x > 640:
			continue
		draw_rect(Rect2(x, 0, 104, 360), Color("202e38"))
		draw_rect(Rect2(x + 3, 0, 1, 360), Color("607b80"))
		draw_rect(Rect2(x + 100, 0, 1, 360), Color("607b80"))
		for n in range(-1, 7):
			var y := fposmod(shift.y, 72) + n * 72
			draw_rect(Rect2(x + 51, y, 2, 22), Color("788989"))
			draw_rect(Rect2(x + 6, y + 38, 3, 9), Color("83ada7"))
			draw_rect(Rect2(x + 95, y + 38, 3, 9), Color("83ada7"))
	# Painted landing-zone emblem gives the starting area a clear identity.
	var pad := Battle.WORLD * 0.5 + shift
	if Rect2(-100, -100, 840, 560).has_point(pad):
		draw_arc(pad, 78, 0, TAU, 64, Color("52666c"), 2, true)
		draw_arc(pad, 73, 0, TAU, 64, Color("394e57"), 1, true)
		for side in [-1, 1]:
			draw_line(pad + Vector2(side * 14, -21), pad + Vector2(side * 14, 21), Color("52666c"), 5)
		draw_line(pad + Vector2(-14, 0), pad + Vector2(14, 0), Color("52666c"), 5)

func draw_ellipse_shadow(at: Vector2, radius: float) -> void:
	draw_rect(Rect2(at + Vector2(-radius, 4), Vector2(radius * 2, 5)), Color(0.04, 0.07, 0.07, 0.5))

func _draw_enemy(id: int, at: Vector2) -> void:
	var type := battle.enemies.kind[id]
	if battle.enemies.mode[id] == 1:
		draw_line(at, battle.enemies.target[id] + Vector2(320, 180) - battle.camera(), Color(0.95, 0.5, 0.4, 0.6), 2)
	if battle.elite_ids.has(id):
		draw_arc(at, Battle.ENEMY_RADIUS[type] + 5, 0, TAU, 24, Color("e0b95e"), 1)
	draw_ellipse_shadow(at, 10 if type < 4 else 24)
	if type < 4 or type == 6:
		var scale_value := 24.0 if type == 6 else 18.0
		draw_texture_rect(sprites[mini(3, type + 1)], Rect2(at - Vector2(scale_value / 2, scale_value - 4), Vector2.ONE * scale_value), false)
		if type == 6:
			draw_arc(at, 16, 0, TAU, 16, Color("d8ad58"), 1)
	elif type == 5:
		draw_rect(Rect2(at - Vector2(5, 24), Vector2(10, 38)), Color("555f59"))
		draw_rect(Rect2(at - Vector2(12, 15), Vector2(24, 20)), Color("7a8570"))
		draw_rect(Rect2(at - Vector2(7, 17), Vector2(14, 8)), Color("293e41"))
		var direction := Vector2.from_angle(battle.elapsed * 35)
		draw_line(at - direction * 30, at + direction * 30, Color("c0c1a8"), 2)
		draw_line(at - direction.orthogonal() * 30, at + direction.orthogonal() * 30, Color("c0c1a8"), 2)
	else:
		var size := 1.4 if type == 7 else 1.0
		draw_rect(Rect2(at - Vector2(20, 21) * size, Vector2(10, 42) * size), Color("171f20"))
		draw_rect(Rect2(at + Vector2(10, -21) * size, Vector2(10, 42) * size), Color("171f20"))
		for y in 6:
			draw_line(at + Vector2(-19, -18 + y * 7) * size, at + Vector2(-11, -18 + y * 7) * size, Color("626b5b"), 2)
			draw_line(at + Vector2(11, -18 + y * 7) * size, at + Vector2(19, -18 + y * 7) * size, Color("626b5b"), 2)
		draw_rect(Rect2(at - Vector2(12, 17) * size, Vector2(24, 34) * size), Color("787b54"))
		draw_rect(Rect2(at - Vector2(9, 9) * size, Vector2(18, 18) * size), Color("a09b68"))
		draw_line(at, at + battle.enemies.position[id].direction_to(battle.player) * 28 * size, Color("bbb488"), 5 * size)
	if battle.enemies.burn[id] > 0:
		draw_rect(Rect2(at + Vector2(-4, -10), Vector2(3, 6)), Color("f6ad50"))
