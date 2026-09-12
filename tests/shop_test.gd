extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var path := "user://shop-unit.cfg"
	DirAccess.remove_absolute(path)
	var collection := CatCollection.new()
	collection.open(path)
	assert(collection.tokens == 0 and collection.unlocked == [0] and collection.themes == [0])
	var shop := TokenShop.new()
	shop.collection = collection
	root.add_child(shop)
	assert(not shop.buy_pack(2).is_empty())
	assert(collection.tokens == 0)
	assert(not (await shop.unlock(1, false)).is_empty())
	assert(not collection.choose(1))
	shop.preview = true
	shop.buy_pack(1)
	assert(collection.tokens == 300)
	assert((await shop.unlock(1, false)).is_empty())
	assert((await shop.unlock(1, true)).is_empty())
	assert(collection.tokens == 120)
	assert((await shop.unlock(1, false)).is_empty())
	assert(collection.tokens == 120)
	assert(not (await shop.unlock(3, true)).is_empty())
	assert(collection.tokens == 120 and not collection.themes.has(3))
	assert(collection.choose(1) and collection.choose(1, true))
	var restored := CatCollection.new()
	restored.open(path)
	assert(restored.tokens == 120 and restored.selected == 1 and restored.selected_theme == 1)
	assert(not restored.apply_snapshot({"tokens": -2, "cats": [0], "themes": [0]}))
	assert(not restored.apply_snapshot({"tokens": "fake", "cats": [0], "themes": [0]}))
	assert(restored.tokens == 120)
	restored.path = "user://missing-shop-directory/save.cfg"
	assert(not restored.choose(0))
	assert(restored.selected == 1)
	assert(not restored.apply_snapshot({"tokens": 999, "cats": [0], "themes": [0]}))
	assert(restored.tokens == 120 and restored.unlocked.has(1))
	DirAccess.remove_absolute(path)
	shop.queue_free()
	await process_frame
	print("SHOP_TEST_OK")
	quit()
