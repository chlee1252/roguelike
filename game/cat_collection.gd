class_name CatCollection
extends RefCounted

# Cached entitlements only. Paid credits and unlocks are decided by the server.
const PRICES := [0, 80, 140, 180]
const THEME_PRICES := [0, 100, 140, 180]
const PACKS := [100, 300, 700]
var path := "user://collection.cfg"
var tokens := 0
var unlocked: Array[int] = [0]
var themes: Array[int] = [0]
var selected := 0
var selected_theme := 0

func open(save_file: String) -> void:
	path = save_file
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	apply_snapshot(config.get_value("collection", "snapshot", {}), false)
	var cat: Variant = config.get_value("collection", "cat", 0)
	var background: Variant = config.get_value("collection", "theme", 0)
	selected = cat if cat is int and unlocked.has(cat) else 0
	selected_theme = background if background is int and themes.has(background) else 0

func apply_snapshot(value: Variant, persist := true) -> bool:
	if not value is Dictionary or not value.get("tokens") is float and not value.get("tokens") is int:
		return false
	var balance := float(value.tokens)
	if not is_finite(balance) or balance < 0 or balance != floor(balance) or balance > 2147483647:
		return false
	if not value.get("cats") is Array or not value.get("themes") is Array:
		return false
	var previous := snapshot()
	tokens = int(balance)
	unlocked = _ids(value.cats)
	themes = _ids(value.themes)
	if persist and not _save():
		apply_snapshot(previous, false)
		return false
	if not unlocked.has(selected):
		selected = 0
	if not themes.has(selected_theme):
		selected_theme = 0
	return true

func _ids(values: Array) -> Array[int]:
	var result: Array[int] = [0]
	for id in values:
		if (id is int or id is float) and id == floor(id) and id >= 0 and id < 4 and not result.has(int(id)):
			result.append(int(id))
	return result

func snapshot() -> Dictionary:
	return {"tokens": tokens, "cats": unlocked.duplicate(), "themes": themes.duplicate()}

func _save() -> bool:
	var config := ConfigFile.new()
	config.set_value("collection", "snapshot", snapshot())
	config.set_value("collection", "cat", selected)
	config.set_value("collection", "theme", selected_theme)
	if config.save(path + ".tmp") != OK:
		return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

func choose(id: int, background := false) -> bool:
	if not (themes if background else unlocked).has(id):
		return false
	var previous := selected_theme if background else selected
	if background:
		selected_theme = id
	else:
		selected = id
	if _save():
		return true
	if background:
		selected_theme = previous
	else:
		selected = previous
	return false
