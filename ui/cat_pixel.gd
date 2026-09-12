class_name CatPixel
extends RefCounted

const OUTLINE := Color("57483f")
const COAT := Color("e6aa70")
const CHEST := Color("f9dfb4")
const STRIPE := Color("c98d58")
const EAR := Color("efb8b1")

const NAMES := ["치즈냥", "턱시도냥", "삼색냥", "눈송이냥"]
const DESCRIPTIONS := ["햇볕 냄새가 나는 골목 친구", "하얀 양말을 신은 조용한 친구", "세 가지 색의 호기심 많은 친구", "새하얀 털의 느긋한 친구"]

static func make(frame: int = 0, sitting: bool = false, variant: int = 0) -> Texture2D:
	var picture := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	if sitting:
		picture.fill_rect(Rect2i(10, 16, 13, 14), OUTLINE)
		picture.fill_rect(Rect2i(11, 17, 11, 12), COAT)
		picture.fill_rect(Rect2i(11, 19, 4, 7), CHEST)
		picture.fill_rect(Rect2i(14, 23, 2, 4), CHEST)
		picture.fill_rect(Rect2i(15, 28, 2, 2), OUTLINE)
		picture.fill_rect(Rect2i(22, 25, 5, 3), OUTLINE)
		picture.fill_rect(Rect2i(25, 22, 4, 5), OUTLINE)
		picture.fill_rect(Rect2i(27, 20, 4, 4), OUTLINE)
		picture.fill_rect(Rect2i(23, 25, 3, 2), COAT)
		picture.fill_rect(Rect2i(26, 23, 2, 3), COAT)
		picture.fill_rect(Rect2i(28, 21, 2, 2), COAT)
		_face(picture, Vector2i(4, 2))
	else:
		# Four short paws and a swishing tail; facial pixels never change while walking.
		picture.fill_rect(Rect2i(4, 16, 21, 12), OUTLINE)
		picture.fill_rect(Rect2i(5, 16, 19, 11), COAT)
		picture.fill_rect(Rect2i(8, 23, 15, 4), CHEST)
		for x in [7, 19]:
			var offset := frame % 2 if x == 7 else -(frame % 2)
			picture.fill_rect(Rect2i(x + offset, 26, 4, 4), OUTLINE)
			picture.fill_rect(Rect2i(x + offset, 26, 3, 2), COAT)
		picture.fill_rect(Rect2i(1, 12 + frame % 2, 3, 10), OUTLINE)
		picture.fill_rect(Rect2i(2, 13 + frame % 2, 2, 8), COAT)
		picture.fill_rect(Rect2i(3, 20, 4, 3), COAT)
		picture.fill_rect(Rect2i(7, 17, 2, 3), STRIPE)
		picture.fill_rect(Rect2i(11, 17, 2, 3), STRIPE)
		_face(picture, Vector2i(8, 1))
	variant = clampi(variant, 0, 3)
	if variant > 0:
		var coats := [COAT, Color("625e68"), Color("f2e6d1"), Color("f6f0e5")]
		var stripes := [STRIPE, Color("504d57"), Color("e3ae78"), Color("d5ccc5")]
		var chests := [CHEST, Color("f1eee4"), Color("fff3dc"), Color("ede5da")]
		for y in 32:
			for x in 32:
				var color := picture.get_pixel(x, y)
				if color.is_equal_approx(COAT):
					picture.set_pixel(x, y, coats[variant])
				elif color.is_equal_approx(STRIPE):
					picture.set_pixel(x, y, stripes[variant])
				elif color.is_equal_approx(CHEST):
					picture.set_pixel(x, y, chests[variant])
		var face_at := Vector2i(4, 2) if sitting else Vector2i(8, 1)
		if variant == 1:
			for x in [6, 15]:
				picture.fill_rect(Rect2i(face_at + Vector2i(x, 9), Vector2i(1, 2)), Color("efca84"))
			picture.set_pixelv(face_at + Vector2i(10, 12), EAR)
		if variant == 2:
			picture.fill_rect(Rect2i(face_at + Vector2i(2, 6), Vector2i(3, 4)), Color("dda56f"))
			picture.fill_rect(Rect2i(face_at + Vector2i(16, 5), Vector2i(3, 3)), Color("75695f"))
			picture.fill_rect(Rect2i(18, 22, 3, 4), Color("dda56f"))
	return ImageTexture.create_from_image(picture)

static func _face(picture: Image, at: Vector2i) -> void:
	# Broad uninterrupted coat, tiny eyes and one nose. No white muzzle or mouth grid.
	for rect in [Rect2i(4, 3, 14, 14), Rect2i(1, 5, 20, 11), Rect2i(0, 7, 22, 7), Rect2i(0, 0, 5, 7), Rect2i(17, 0, 5, 7)]:
		picture.fill_rect(Rect2i(at + rect.position, rect.size), OUTLINE)
	for rect in [Rect2i(4, 4, 14, 12), Rect2i(2, 5, 18, 10), Rect2i(1, 7, 20, 7), Rect2i(1, 1, 3, 6), Rect2i(18, 1, 3, 6)]:
		picture.fill_rect(Rect2i(at + rect.position, rect.size), COAT)
	for x in [2, 18]:
		picture.fill_rect(Rect2i(at + Vector2i(x, 2), Vector2i(2, 3)), EAR)
	for x in [8, 12]:
		picture.fill_rect(Rect2i(at + Vector2i(x, 4), Vector2i(1, 2)), STRIPE)
	for x in [6, 15]:
		picture.fill_rect(Rect2i(at + Vector2i(x, 9), Vector2i(1, 2)), OUTLINE)
	picture.set_pixelv(at + Vector2i(10, 12), OUTLINE)
	for x in [-2, 21]:
		for y in [10, 13]:
			picture.fill_rect(Rect2i(at + Vector2i(x, y), Vector2i(3, 1)), OUTLINE)
