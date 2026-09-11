class_name GameSkin
extends RefCounted

const REGULAR = preload("res://assets/fonts/Pretendard-Regular.ttf")
const BOLD = preload("res://assets/fonts/Pretendard-Bold.ttf")
const INK := Color("eef4f2")
const MUTED := Color("9eafae")
const MINT := Color("a4dfc6")
const SURFACE := Color("202f35")
const BASE := Color("111d24")

static func box(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 10
	style.anti_aliasing = true
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	return style
