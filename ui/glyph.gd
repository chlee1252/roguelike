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
		1:
			for n in 7:
				var at := Vector2(16, 16) + Vector2.from_angle(n * 2.4) * 7
				draw_arc(at, 5, 0, PI * 1.5, 12, ink, 1.5, true)
		2:
			draw_circle(Vector2(16, 16), 10, ink, false, 2, true)
			draw_arc(Vector2(16, 16), 7, 0, PI, 16, ink, 1, true)
		3:
			for n in 3:
				draw_arc(Vector2(6, 16), 7 + n * 6, -0.8, 0.8, 12, ink, 2, true)
		4:
			draw_polyline(PackedVector2Array([Vector2(5, 26), Vector2(8, 9), Vector2(13, 6), Vector2(20, 9), Vector2(24, 6), Vector2(28, 27), Vector2(5, 26)]), ink, 2, true)
		5:
			draw_circle(Vector2(16, 16), 8, ink, false, 2, true)
			for n in 8:
				var direction := Vector2.from_angle(n * TAU / 8)
				draw_line(Vector2(16, 16) + direction * 8, Vector2(16, 16) + direction * 11, ink, 2, true)
		6:
			draw_rect(Rect2(6, 13, 22, 14), ink, false, 2)
			draw_line(Vector2(6, 13), Vector2(2, 7), ink, 2)
			draw_line(Vector2(28, 13), Vector2(31, 7), ink, 2)
		7:
			draw_circle(Vector2(16, 6), 3, ink, false, 2)
			draw_arc(Vector2(16, 19), 10, PI, TAU, 16, ink, 2)
			draw_line(Vector2(5, 23), Vector2(27, 23), ink, 2)
			draw_circle(Vector2(16, 26), 2, ink)
		_:
			draw_circle(Vector2(16, 20), 7, ink)
			for n in 3:
				draw_circle(Vector2(7 + n * 9, 8), 3, ink)
