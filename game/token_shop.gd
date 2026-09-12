class_name TokenShop
extends Node

var collection: CatCollection
var busy := false
var preview := false
var endpoint := ""
var access_token := ""

func available() -> bool:
	return preview or (endpoint.begins_with("https://") and not access_token.is_empty())

func unlock(id: int, background: bool) -> String:
	if busy:
		return "처리 중이에요. 잠시 기다려 주세요."
	if not available():
		return "상점 연결 준비 중이에요. 지금은 미리 볼 수 있어요."
	if id < 0 or id >= 4:
		return "존재하지 않는 상품이에요."
	if preview:
		var snapshot := collection.snapshot()
		var key := "themes" if background else "cats"
		var cost: int = CatCollection.THEME_PRICES[id] if background else CatCollection.PRICES[id]
		if snapshot[key].has(id):
			return ""
		if snapshot.tokens < cost:
			return "토큰이 부족해요. 토큰 상점을 확인해 주세요."
		snapshot.tokens -= cost
		snapshot[key].append(id)
		return "" if collection.apply_snapshot(snapshot) else "저장하지 못했어요. 다시 시도해 주세요."
	return await _request("/unlock", {"kind": "theme" if background else "cat", "id": id})

func refresh() -> String:
	if preview:
		return ""
	if not available():
		return "상점 연결 준비 중이에요."
	return await _request("/wallet", {})

func _request(route: String, body: Dictionary) -> String:
	if busy:
		return "처리 중이에요."
	busy = true
	var request := HTTPRequest.new()
	request.timeout = 15
	add_child(request)
	var error := request.request(endpoint.trim_suffix("/") + route, PackedStringArray(["Content-Type: application/json", "Authorization: Bearer " + access_token]), HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		request.queue_free()
		busy = false
		return "상점에 연결하지 못했어요."
	var result: Array = await request.request_completed
	request.queue_free()
	busy = false
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		return "연결이 끊겼어요. 새로고침으로 구매 내역을 확인해 주세요."
	if result[1] == 409:
		return "토큰이 부족해요. 토큰 상점을 확인해 주세요."
	if result[1] != 200:
		return "구매 내역을 확인하지 못했어요. 다시 시도해 주세요."
	var snapshot: Variant = JSON.parse_string(result[3].get_string_from_utf8())
	return "" if collection.apply_snapshot(snapshot) else "구매 내역을 저장하지 못했어요. 새로고침해 주세요."

func buy_pack(index: int) -> String:
	if index < 0 or index >= CatCollection.PACKS.size():
		return "존재하지 않는 상품이에요."
	if not preview:
		# No client-only cash credits. Enable only after native receipt verification is wired.
		return "현금 결제는 아직 준비 중이에요. 결제되거나 토큰이 지급되지 않았어요."
	var snapshot := collection.snapshot()
	snapshot.tokens += CatCollection.PACKS[index]
	return "테스트 토큰을 받았어요. 실제 결제는 발생하지 않아요." if collection.apply_snapshot(snapshot) else "테스트 토큰을 저장하지 못했어요."
