class_name AlleyTheme
extends RefCounted

const NAMES := ["달빛 골목", "벚꽃 산책길", "비 오는 네온 골목", "포근한 눈꽃 골목"]
const NOTES := ["따뜻한 가로등 아래", "분홍 꽃잎이 사뿐사뿐", "물웅덩이에 비친 불빛", "첫눈이 쌓인 밤 산책"]
const GROUND := ["45435f", "51445f", "293e56", "495e74"]
const TILES := ["4b4866", "594b66", "30465f", "50667c"]
const WALL := ["39354f", "47364f", "263249", "3d4f65"]
const ROOF := ["766980", "a67c95", "50738a", "c1d4df"]
const ACCENT := ["95b6b1", "e7b0c6", "8ed4d5", "b5d3e0"]

static func decorate(canvas: CanvasItem, id: int, rect: Rect2, time: float) -> void:
	# A fixed number of background details; no particle nodes or collision changes.
	for n in 24:
		var point := rect.position + Vector2(fposmod(n * 73.0 + (time * 6 if id == 1 else 0), rect.size.x), fposmod(n * 47.0 + time * (42 if id == 2 else 9), rect.size.y))
		match id:
			1:
				canvas.draw_rect(Rect2(point.round(), Vector2(3, 2)), Color("c996af"))
			2:
				canvas.draw_line(point, point + Vector2(-2, 6), Color(0.58, 0.76, 0.85, 0.22))
			3:
				canvas.draw_rect(Rect2(point.round(), Vector2(2, 2)), Color(0.81, 0.9, 0.96, 0.4))
