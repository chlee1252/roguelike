class_name MissionArt
extends Control

var theme_id := 0
var cat_texture: Texture2D

func _draw() -> void:
	draw_style_box(GameSkin.box(Color(AlleyTheme.TILES[theme_id]).lightened(0.12), 20), Rect2(0, 0, 268, 206))
	for at in [Vector2(135, 18), Vector2(180, 30), Vector2(99, 21), Vector2(246, 81)]:
		draw_line(at - Vector2(2, 0), at + Vector2(2, 0), Color("f9dfb3"))
		draw_line(at - Vector2(0, 2), at + Vector2(0, 2), Color("f9dfb3"))
	draw_circle(Vector2(229, 28), 11, Color("dfd5b6"))
	draw_rect(Rect2(20, 30, 104, 88), Color("4c455f"))
	for y in 2:
		for x in 3:
			draw_rect(Rect2(30 + x * 29, 42 + y * 31, 17, 21), Color("ad977f") if x == y else Color("96849e"))
	draw_rect(Rect2(149, 57, 103, 58), Color("77838e"))
	draw_rect(Rect2(146, 46, 109, 16), Color(AlleyTheme.ACCENT[theme_id]))
	draw_string(GameSkin.BOLD, Vector2(158, 57), "달빛 편의점", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("f6e5c4"))
	for n in 4:
		draw_rect(Rect2(154 + n * 24, 68, 19, 42), Color("d6bf95"))
	draw_colored_polygon(PackedVector2Array([Vector2(24, 116), Vector2(242, 116), Vector2(259, 183), Vector2(9, 183)]), Color("706582"))
	for n in 5:
		draw_line(Vector2(13, 123 + n * 13), Vector2(255, 123 + n * 13), Color("81738e"), 1)
	draw_circle(Vector2(67, 138), 34, Color(0.94, 0.75, 0.49, 0.055))
	draw_line(Vector2(58, 51), Vector2(58, 131), Color("778394"), 3)
	draw_rect(Rect2(51, 50, 15, 5), Color("efd5a3"))
	draw_style_box(GameSkin.box(Color("aa8968"), 3), Rect2(23, 142, 36, 22))
	draw_rect(Rect2(28, 145, 26, 14), Color("49444a"))
	if cat_texture:
		draw_texture_rect(cat_texture, Rect2(80, 84, 96, 96), false)
	draw_rect(Rect2(207, 107, 19, 31), Color("292539"))
	draw_colored_polygon(PackedVector2Array([Vector2(210, 118), Vector2(222, 118), Vector2(228, 140), Vector2(215, 137), Vector2(203, 140)]), Color("d3cce1"))
	draw_rect(Rect2(211, 111, 11, 13), Color("292539"))
	draw_rect(Rect2(215, 115, 5, 5), Color("f1dfd9"))
	draw_style_box(GameSkin.box(Color("849ea0"), 3), Rect2(174, 155, 19, 8))
	draw_line(Vector2(178, 156), Vector2(189, 156), Color("e8c494"), 2)

	AlleyTheme.decorate(self, theme_id, Rect2(0, 0, 268, 206), 0)
