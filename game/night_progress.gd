class_name NightProgress
extends RefCounted

var path := "user://night-progress.cfg"
var memories := 0
var cleared: Array[int] = []
var furniture: Array[int] = []
var clues: Array[int] = []
var settled: Array[String] = []
var starter := 0
var last_notice := ""

func open(file_path: String) -> void:
	path = file_path
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	var value: Variant = config.get_value("progress", "data", {})
	if not value is Dictionary or not value.get("memories") is int or value.memories < 0:
		return
	memories = value.memories
	for pair in [["cleared", 3], ["furniture", 4], ["clues", 3]]:
		var entries: Variant = value.get(pair[0], [])
		if entries is Array:
			for id in entries:
				if id is int and id >= 0 and id < pair[1] and not get(pair[0]).has(id):
					get(pair[0]).append(id)
	var ids: Variant = value.get("settled", [])
	if ids is Array:
		for id in ids:
			if id is String:
				settled.append(id)
	var choice: Variant = value.get("starter", 0)
	starter = choice if choice is int and available_weapons().has(choice) else 0

func available_weapons() -> Array[int]:
	var result: Array[int] = [0, 1, 2, 3]
	for item in furniture:
		result.append(item + 4)
	return result

func stage_open(id: int) -> bool:
	return id >= 0 and id < 3 and (id == 0 or cleared.has(id - 1))

func _save() -> bool:
	var config := ConfigFile.new()
	config.set_value("progress", "data", {"memories": memories, "cleared": cleared, "furniture": furniture, "clues": clues, "settled": settled, "starter": starter})
	if config.save(path + ".tmp") != OK:
		return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func settle(run_id: String, stage: int, won: bool, seconds: float, found: bool) -> bool:
	last_notice = ""
	if settled.has(run_id):
		last_notice = "이미 보상을 받았어요"
		return true
	if run_id.is_empty() or stage < 0 or stage >= 3 or not is_finite(seconds) or seconds < 0:
		return false
	var old_memories := memories
	var old_cleared := cleared.duplicate()
	var old_clues := clues.duplicate()
	var reward := mini(8, int(seconds / 90)) + (3 if won else 0) + (1 if found else 0)
	memories += reward
	if won and not cleared.has(stage):
		cleared.append(stage)
	if (found or won) and not clues.has(stage):
		clues.append(stage)
	settled.append(run_id)
	if _save():
		last_notice = "간식 +%d개 · 쉼터에서 새 무기를 얻을 수 있어요" % reward
		return true
	memories = old_memories
	cleared.assign(old_cleared)
	clues.assign(old_clues)
	settled.erase(run_id)
	return false

func buy_furniture(id: int) -> bool:
	if id < 0 or id >= 4 or furniture.has(id) or memories < NightContent.FURNITURE_COST[id]:
		return false
	memories -= NightContent.FURNITURE_COST[id]
	furniture.append(id)
	if _save():
		return true
	memories += NightContent.FURNITURE_COST[id]
	furniture.erase(id)
	return false

func choose_starter(id: int) -> bool:
	if not available_weapons().has(id):
		return false
	var previous := starter
	starter = id
	if _save():
		return true
	starter = previous
	return false

func record_result(run_id: String, stage: int, won: bool, seconds: float, found: bool) -> bool:
	var record := ConfigFile.new()
	record.set_value("claim", "data", [run_id, stage, won, seconds, found])
	if record.save(path + ".pending.tmp") != OK:
		return false
	if DirAccess.rename_absolute(path + ".pending.tmp", path + ".pending") != OK:
		return false
	return recover_pending()

func recover_pending() -> bool:
	var record := ConfigFile.new()
	if record.load(path + ".pending") != OK:
		return true
	var data: Variant = record.get_value("claim", "data", [])
	if not data is Array or data.size() != 5:
		return false
	if not data[0] is String or not data[1] is int or not data[2] is bool or not data[3] is float or not data[4] is bool:
		return false
	if settle(data[0], data[1], data[2], data[3], data[4]):
		DirAccess.remove_absolute(path + ".pending")
		return true
	return false
