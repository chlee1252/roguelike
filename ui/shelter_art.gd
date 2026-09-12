class_name ShelterArt
extends Control

var cat_variant := 0
var furniture: Array[int] = []
var reunited := false
var clock := 0.0
var cat: Texture2D
var kitten: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	kitten = CatPixel.make(0, true, 2)
	cat = CatPixel.make(0, true, cat_variant)

func _process(dt: float) -> void:
	clock += dt
	queue_redraw()

func _draw() -> void:
	draw_style_box(GameSkin.box(Color("45415c"), 18), Rect2(0, 0, 235, 200))
	draw_circle(Vector2(188, 27), 12, Color("ead8b1"))
	for x in range(0, 235, 26):
		draw_line(Vector2(x, 133), Vector2(x - 10, 198), Color("544c65"))
	draw_style_box(GameSkin.box(Color("92745e"), 5), Rect2(48, 138, 117, 32))
	if furniture.has(2):
		draw_rect(Rect2(46, 121, 121, 7), Color("be9c76"))
		draw_rect(Rect2(46, 121, 9, 45), Color("be9c76"))
	if furniture.has(3):
		draw_style_box(GameSkin.box(Color("baa6bd"), 8), Rect2(58, 147, 99, 20))
	if cat:
		var bob := sin(clock * 2) * 1.0
		draw_texture_rect(cat, Rect2(59, 59 + bob, 96, 96), false)
		# A short paw-to-cheek grooming gesture after every few idle breaths.
		if fposmod(clock, 5.0) > 3.4:
			draw_rect(Rect2(87, 108 + sin(clock * 15) * 3, 12, 9), [CatPixel.COAT, Color("625e68"), Color("f2e6d1"), Color("f6f0e5")][cat_variant])
	if furniture.has(0):
		draw_colored_polygon(PackedVector2Array([Vector2(15, 163), Vector2(23, 141), Vector2(37, 143), Vector2(45, 170)]), Color("a6c3bb"))
	if furniture.has(1):
		for index in 3:
			draw_circle(Vector2(184 + index * 10, 163), 4, Color("e4c197"))
	if reunited:
		draw_texture_rect(kitten, Rect2(161, 101, 48, 48), false)
		draw_line(Vector2(197, 79), Vector2(197, 88), Color("f1c5cd"), 2)
		draw_line(Vector2(192, 84), Vector2(202, 84), Color("f1c5cd"), 2)
	draw_style_box(GameSkin.box(Color("96b9b7"), 4), Rect2(178, 177, 29, 10))
	draw_circle(Vector2(187, 180), 2, Color("ddb388"))
	draw_circle(Vector2(198, 180), 2, Color("ddb388"))
