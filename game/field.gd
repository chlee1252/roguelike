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
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color("202b2a"))
	# Deterministic terrain detail; no per-frame random allocations.
	var origin := Vector2i((cam - Vector2(320, 180)) / 32)
	for y in range(origin.y - 1, origin.y + 13):
		for x in range(origin.x - 1, origin.x + 22):
			var tile := Vector2(x * 32, y * 32) + shift
			var hash_value := absi(x * 374761 + y * 668265)
			if hash_value % 7 == 0:
				draw_rect(Rect2(tile + Vector2(4, 7), Vector2(3, 2)), Color("37403a"))
			if hash_value % 11 == 0:
				draw_line(tile + Vector2(15, 15), tile + Vector2(21, 18), Color("172423"), 2)
	# Broad road and drainage stripes are decoration, never invisible obstacles.
	for road in [640, 1280, 1920]:
		var x: float = road + shift.x
		draw_rect(Rect2(x, 0, 82, 360), Color("303936"))
		for y in range(-1, 12):
			var offset := fposmod(shift.y, 40) + y * 40
			draw_rect(Rect2(x + 39, offset, 3, 16), Color("77745a"))
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
		draw_ellipse_shadow(player, 11)
		draw_texture_rect(sprites[0], Rect2(player - Vector2(9, 14), Vector2(18, 18)), false)
		draw_line(player - Vector2(0, 2), player + battle.aim * 13, Color("b8beb0"), 3)
		draw_circle(player + Vector2(0, 2), 2, Color("eaf1d2"))
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
		var color := Color("f9bd69") if effect.kind != 1 else Color("f17662")
		draw_circle(effect.at + shift, effect.radius * (0.3 + phase), Color(color, (1 - phase) * 0.35))
		draw_arc(effect.at + shift, effect.radius * (0.3 + phase), 0, TAU, 20, Color(color, 1 - phase), 2)

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
