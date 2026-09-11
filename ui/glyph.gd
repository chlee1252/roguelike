class_name EquipmentGlyph
extends Control

var icon := 0
var ink := GameSkin.MINT

func _draw() -> void:
	var c := ink
	var line_width := 1.7
	match icon:
		0:
			draw_polyline(PackedVector2Array([Vector2(4, 11), Vector2(24, 11), Vector2(24, 15), Vector2(11, 15), Vector2(8, 21), Vector2(4, 21), Vector2(6, 14)]), c, line_width, true)
			draw_line(Vector2(23, 12), Vector2(30, 12), c, line_width, true)
			draw_line(Vector2(15, 15), Vector2(17, 21), c, line_width, true)
		1:
			draw_polyline(PackedVector2Array([Vector2(17, 3), Vector2(11, 11), Vector2(8, 17), Vector2(9, 23), Vector2(15, 27), Vector2(21, 24), Vector2(24, 18), Vector2(21, 10), Vector2(18, 15), Vector2(17, 3)]), c, line_width, true)
			draw_line(Vector2(16, 19), Vector2(14, 23), c, line_width, true)
		2:
			draw_style_box(GameSkin.box(Color.TRANSPARENT, 3, c), Rect2(7, 10, 18, 17))
			draw_line(Vector2(11, 10), Vector2(11, 3), c, line_width, true)
			draw_line(Vector2(11, 15), Vector2(20, 15), c, line_width, true)
			draw_circle(Vector2(13, 21), 2, c, false, line_width, true)
			draw_arc(Vector2(14, 8), 7, -PI / 2, -0.1, 14, c, line_width, true)
		3:
			for x in [7, 15, 23]:
				draw_style_box(GameSkin.box(Color.TRANSPARENT, 3, c), Rect2(x - 2, 7, 5, 17))
		4:
			draw_style_box(GameSkin.box(Color.TRANSPARENT, 4, c), Rect2(7, 10, 18, 17))
			draw_line(Vector2(12, 10), Vector2(12, 5), c, line_width, true)
			draw_line(Vector2(12, 5), Vector2(22, 5), c, line_width, true)
			draw_line(Vector2(12, 16), Vector2(20, 23), c, line_width, true)
		5:
			draw_circle(Vector2(16, 21), 2, c, true, -1, true)
			draw_line(Vector2(16, 21), Vector2(16, 28), c, line_width, true)
			for radius in [7, 12]:
				draw_arc(Vector2(16, 21), radius, -PI * 0.85, -PI * 0.15, 20, c, line_width, true)
		_:
			draw_style_box(GameSkin.box(Color.TRANSPARENT, 5, c), Rect2(5, 7, 23, 20))
			draw_line(Vector2(16, 12), Vector2(16, 22), c, line_width, true)
			draw_line(Vector2(11, 17), Vector2(21, 17), c, line_width, true)
