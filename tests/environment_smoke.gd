extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var version := Engine.get_version_info()
	if version.major != 4:
		_fail("Expected Godot 4")
		return
	var scene := load("res://app/bootstrap.tscn") as PackedScene
	if scene == null:
		_fail("Bootstrap scene failed to load")
		return
	var instance := scene.instantiate()
	root.add_child(instance)
	await process_frame
	var label := instance.get_node_or_null("Status") as Label
	if label == null or not label.is_visible_in_tree():
		_fail("Bootstrap label is missing or hidden")
		return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		if capture == null or capture.is_empty():
			_fail("Renderer produced no image")
			return
		var result := capture.save_png("res://build/environment-smoke.png")
		if result != OK:
			_fail("Could not save rendering evidence")
			return
	print("ENVIRONMENT_SMOKE_OK Godot %s display=%s" % [version.string, DisplayServer.get_name()])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
