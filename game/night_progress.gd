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
var training_churu := 0
var training_can := 0
var whisker_level := 0
var body_level := 0
var load_ok := true

func open(file_path: String) -> void:
	path = file_path
	var config := ConfigFile.new()
	if not FileAccess.file_exists(path):
		return
	load_ok = false
	if config.load(path) != OK:
		return
	var value: Variant = config.get_value("progress", "data", {})
	if not value is Dictionary or not value.get("memories") is int or value.memories < 0:
		return
	if value.get("version", 1) not in [1, 2]:
		return
	for key in ["training_churu", "training_can", "whisker_level", "body_level"]:
		var entry: Variant = value.get(key, 0)
		if not entry is int or entry < 0 or entry > (20 if key.ends_with("level") else 1000000000):
			return
	for key in ["training_churu", "training_can", "whisker_level", "body_level"]:
		set(key, value.get(key, 0))
	memories = value.memories
	load_ok = true
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
	if not load_ok:
		return false
	var config := ConfigFile.new()
	config.set_value("progress", "data", {"version": 2, "training_churu": training_churu, "training_can": training_can, "whisker_level": whisker_level, "body_level": body_level, "memories": memories, "cleared": cleared, "furniture": furniture, "clues": clues, "settled": settled, "starter": starter})
	if config.save(path + ".tmp") != OK:
		return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func settle(run_id: String, stage: int, won: bool, seconds: float, found: bool, churu := 0, cans := 0, bonus_churu := 0, bonus_can := 0) -> bool:
	last_notice = ""
	if settled.has(run_id):
		last_notice = "이미 보상을 받았어요"
		return true
	if run_id.is_empty() or stage < 0 or stage >= 3 or not is_finite(seconds) or seconds < 0:
		return false
	if churu < 0 or churu > 18 + stage * 4 or cans < 0 or cans > 4 + stage or bonus_churu not in [0, 4] or bonus_can not in [0, 2] or (not won and (bonus_churu > 0 or bonus_can > 0)):
		return false
	var old_memories := memories
	var old_churu := training_churu
	var old_can := training_can
	training_churu += churu + bonus_churu
	training_can += cans + bonus_can
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
		last_notice = "보관 완료 · 츄르 +%d · 통조림 +%d · 간식 +%d" % [churu + bonus_churu, cans + bonus_can, reward]
		return true
	memories = old_memories
	training_churu = old_churu
	training_can = old_can
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

func training_cost(id: int) -> int:
	return 4 + whisker_level * 2 if id == 0 else body_level + 1

func buy_training(id: int) -> bool:
	if id not in [0, 1] or not recover_pending():
		return false
	var rank_key := "whisker_level" if id == 0 else "body_level"
	var money_key := "training_churu" if id == 0 else "training_can"
	var rank: int = get(rank_key)
	var balance: int = get(money_key)
	var cost := training_cost(id)
	if rank >= 20 or balance < cost:
		return false
	set(rank_key, rank + 1)
	set(money_key, balance - cost)
	if _save():
		last_notice = "운동 완료! 다음 밤부터 더 튼튼하게."
		return true
	set(rank_key, rank)
	set(money_key, balance)
	last_notice = "저장하지 못했어요. 재료는 사용하지 않았어요."
	return false

func record_result(run_id: String, stage: int, won: bool, seconds: float, found: bool, churu := 0, cans := 0) -> bool:
	if run_id.is_empty() or stage not in [0, 1, 2] or not is_finite(seconds) or seconds < 0 or churu < 0 or churu > 18 + stage * 4 or cans < 0 or cans > 4 + stage:
		return false
	if not recover_pending():
		return false
	var record := ConfigFile.new()
	record.set_value("claim", "data", [run_id, stage, won, seconds, found, churu, cans, 4 if won else 0, 2 if won else 0])
	if record.save(path + ".pending.tmp") != OK:
		return false
	if DirAccess.rename_absolute(path + ".pending.tmp", path + ".pending") != OK:
		return false
	return recover_pending()

func recover_pending() -> bool:
	if not load_ok:
		return false
	var record := ConfigFile.new()
	if not FileAccess.file_exists(path + ".pending"):
		return true
	if record.load(path + ".pending") != OK:
		return false
	var data: Variant = record.get_value("claim", "data", [])
	if not data is Array or data.size() not in [5, 9]:
		return false
	if not data[0] is String or not data[1] is int or not data[2] is bool or not data[3] is float or not data[4] is bool:
		return false
	if data.size() == 5:
		data.append_array([0, 0, 0, 0])
	for i in range(5, 9):
		if not data[i] is int:
			return false
	if settle(data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8]):
		DirAccess.remove_absolute(path + ".pending")
		return true
	return false
