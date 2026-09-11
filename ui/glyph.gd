class_name EquipmentGlyph
extends Control
var icon := 0
var ink := GameSkin.MINT

func _draw() -> void:
	match icon:
		0:
			draw_line(Vector2(5, 16), Vector2(23, 16), ink, 2, true)
			for x in [9, 14, 19]:
				draw_line(Vector2(x - 2, 10), Vector2(x + 2, 22), ink, 1.5, true)
			draw_circle(Vector2(25, 16), 4, ink, false, 1.5, true)
			draw_circle(Vector2(26, 15), 1, ink)
			draw_line(Vector2(5, 16), Vector2(2, 12), ink, 1.5, true)
			draw_line(Vector2(5, 16), Vector2(2, 20), ink, 1.5, true)
		1, 4:
			for n in 7:
				var at := Vector2(16, 16) + Vector2.from_angle(n * 2.4) * 7
				draw_arc(at, 5, 0, PI * 1.5, 12, ink, 1.5, true)
		2:
			draw_circle(Vector2(16, 16), 10, ink, false, 2, true)
			draw_circle(Vector2(16, 16), 6, ink, false, 1, true)
			for n in 8:
				var direction := Vector2.from_angle(n * TAU / 8)
				draw_line(Vector2(16, 16) + direction * 10, Vector2(16, 16) + direction * 12, ink, 1, true)
		3:
			for n in 3:
				draw_line(Vector2(10 + n * 6, 7), Vector2(5 + n * 6, 26), ink, 2, true)
		5:
			for n in 3:
				var at := Vector2(8 + n * 8, 21 - n * 5)
				draw_circle(at, 3, ink, false, 1.5, true)
		_:
			draw_style_box(GameSkin.box(Color.TRANSPARENT, 5, ink), Rect2(5, 10, 23, 15))
			draw_arc(Vector2(16, 11), 7, PI, TAU, 16, ink, 1.5, true)
