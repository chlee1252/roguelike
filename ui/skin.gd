class_name GameSkin
extends RefCounted

const REGULAR = preload("res://assets/fonts/Pretendard-Regular.ttf")
const BOLD = preload("res://assets/fonts/Pretendard-Bold.ttf")
const INK := Color("fff2e3")
const MUTED := Color("c9bfd2")
const MINT := Color("f1c99f")
const SURFACE := Color("3c3855")
const BASE := Color("29283f")

static func box(color: Color, radius: int = 12, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 10
	style.anti_aliasing = true
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	return style
