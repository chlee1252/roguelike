class_name ShelterArt
extends Control

var cat_variant := 0
var furniture: Array[int] = []
var reunited := false
var story_stage := -1
var exercise := -1
var recovering := false
var clock := 0.0
var cat: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cat = CatPixel.make(0, true, cat_variant)

func _process(dt: float) -> void:
	clock += dt
	queue_redraw()

func _draw() -> void:
	draw_style_box(GameSkin.box(Color("45415c"), 18), Rect2(0, 0, 235, 200))
	draw_circle(Vector2(188, 27), 12, Color("ead8b1"))
	if story_stage == 0:
		draw_line(Vector2(27, 39), Vector2(27, 119), Color("b5a4ae"), 3)
		draw_rect(Rect2(20, 38, 17, 5), Color("f3d5a5"))
		draw_circle(Vector2(29, 65), 24, Color(1, 0.82, 0.5, 0.08))
		draw_line(Vector2(201, 102), Vector2(191, 143), Color("f3d5a5"), 3)
		draw_colored_polygon(PackedVector2Array([Vector2(201, 105), Vector2(181, 133), Vector2(201, 138)]), Color("e4c175"))
	elif story_stage == 1:
		for x in [24, 49]:
			draw_line(Vector2(x, 32), Vector2(x, 102), Color("b5a4ae"), 2)
		draw_rect(Rect2(18, 99, 37, 5), Color("bd9486"))
		draw_rect(Rect2(158, 56, 61, 21), Color("819b96"))
		draw_string(GameSkin.BOLD, Vector2(164, 71), "별빛시장", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("fff0d0"))
	for x in range(0, 235, 26):
		draw_line(Vector2(x, 133), Vector2(x - 10, 198), Color("544c65"))
	draw_style_box(GameSkin.box(Color("92745e"), 5), Rect2(48, 138, 117, 32))
	if furniture.has(2):
		draw_rect(Rect2(46, 121, 121, 7), Color("be9c76"))
		draw_rect(Rect2(46, 121, 9, 45), Color("be9c76"))
	if furniture.has(3):
		draw_style_box(GameSkin.box(Color("baa6bd"), 8), Rect2(58, 147, 99, 20))
	if cat:
		var bob := sin(clock * (8 if exercise >= 0 else 2)) * (4.0 if exercise >= 0 else 1.0)
		draw_texture_rect(cat, Rect2(59, 59 + bob, 96, 96), false)
		if exercise == 0:
			draw_line(Vector2(126, 91 + bob), Vector2(155, 84), Color("f3d5a5"), 2)
			draw_circle(Vector2(162 + sin(clock * 6) * 8, 84), 5, Color("e8acbf"))
		elif exercise == 1:
			draw_rect(Rect2(73, 133 + bob, 42, 6), Color("efc99f"))
		if recovering:
			draw_rect(Rect2(62, 137, 94, 9), Color("baa6bd"))
		# A short paw-to-cheek grooming gesture after every few idle breaths.
		if fposmod(clock, 5.0) > 3.4:
			draw_rect(Rect2(87, 108 + sin(clock * 15) * 3, 12, 9), [CatPixel.COAT, Color("625e68"), Color("f2e6d1"), Color("f6f0e5")][cat_variant])
	if furniture.has(0):
		draw_colored_polygon(PackedVector2Array([Vector2(15, 163), Vector2(23, 141), Vector2(37, 143), Vector2(45, 170)]), Color("a6c3bb"))
	if furniture.has(1):
		for index in 3:
			draw_circle(Vector2(184 + index * 10, 163), 4, Color("e4c197"))
	if reunited:
		# A familiar hand reaches down to the selected cat, beside its carrier.
		draw_style_box(GameSkin.box(Color("b6b2c7"), 6), Rect2(169, 107, 52, 55))
		draw_rect(Rect2(177, 115, 34, 39), Color("302b40"))
		draw_rect(Rect2(177, 144, 34, 10), Color("e3c394"))
		draw_line(Vector2(173, 40), Vector2(149, 75), Color("bfbece"), 16)
		draw_line(Vector2(149, 75), Vector2(131, 87), Color("efcbb1"), 10)
		draw_circle(Vector2(129, 89), 7, Color("efcbb1"))
	draw_style_box(GameSkin.box(Color("96b9b7"), 4), Rect2(178, 177, 29, 10))
	draw_circle(Vector2(187, 180), 2, Color("ddb388"))
	draw_circle(Vector2(198, 180), 2, Color("ddb388"))
