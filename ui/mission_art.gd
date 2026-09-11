class_name MissionArt
extends Control

var commando: Texture2D

func _draw() -> void:
	# A small tactical diorama keeps the military setting without stock artwork.
	draw_style_box(GameSkin.box(Color("2b4145"), 20), Rect2(0, 0, 268, 206))
	for x in range(18, 268, 24):
		draw_line(Vector2(x, 12), Vector2(x, 194), Color(0.65, 0.85, 0.8, 0.045), 1, true)
	for y in range(14, 200, 24):
		draw_line(Vector2(12, y), Vector2(256, y), Color(0.65, 0.85, 0.8, 0.045), 1, true)
	var island := PackedVector2Array([Vector2(26, 113), Vector2(126, 58), Vector2(243, 110), Vector2(152, 172)])
	var depth := PackedVector2Array([Vector2(26, 113), Vector2(152, 172), Vector2(243, 110), Vector2(243, 123), Vector2(152, 187), Vector2(26, 126)])
	draw_colored_polygon(depth, Color("263735"))
	draw_colored_polygon(island, Color("71877a"))
	draw_polyline(PackedVector2Array([Vector2(26, 113), Vector2(152, 172), Vector2(243, 110)]), Color("9eb9a1"), 1, true)
	draw_colored_polygon(PackedVector2Array([Vector2(85, 82), Vector2(113, 66), Vector2(214, 130), Vector2(188, 148)]), Color("4d6260"))
	for n in 4:
		var at := Vector2(112, 88) + Vector2(20, 12) * n
		draw_line(at, at + Vector2(8, 5), Color("c4c8a0"), 2, true)
	for at in [Vector2(62, 116), Vector2(196, 103), Vector2(166, 147)]:
		draw_style_box(GameSkin.box(Color("566c57"), 3), Rect2(at, Vector2(24, 8)))
		draw_line(at + Vector2(2, 1), at + Vector2(21, 1), Color("93a87e"), 2, true)
	# Soft rings frame the player; the actual commando remains pixel art.
	draw_circle(Vector2(128, 116), 34, Color(0.69, 0.89, 0.77, 0.09), true, -1, true)
	draw_arc(Vector2(128, 116), 34, 0, TAU, 64, Color(0.69, 0.89, 0.77, 0.35), 1, true)
	draw_circle(Vector2(128, 126), 14, Color(0.05, 0.1, 0.1, 0.22), true, -1, true)
	if commando:
		draw_texture_rect(commando, Rect2(104, 75, 48, 48), false)
		draw_line(Vector2(134, 103), Vector2(155, 95), Color("d4dcc6"), 5)
	for at in [Vector2(72, 90), Vector2(209, 119), Vector2(173, 80)]:
		draw_circle(at, 3, Color("e6b599"), true, -1, true)
		draw_arc(at, 7, 0, TAU, 20, Color(0.9, 0.7, 0.6, 0.35), 1, true)
	draw_circle(Vector2(231, 29), 3, GameSkin.MINT, true, -1, true)
