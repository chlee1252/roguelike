extends Control

const WEAPON_NAMES := ["HEAVY MACHINE GUN", "TACTICAL FLAMETHROWER", "ARTILLERY RADIO"]
const SUPPORT_NAMES := ["AMMO BELT", "PRESSURIZED FUEL", "SIGNAL AMPLIFIER"]
const EVOLUTION_NAMES := ["CERBERUS ROTARY CANNON", "INFERNO PROJECTOR", "ROLLING THUNDER"]
var battle: Battle
var field: Battlefield
var hud: Control
var overlay: Control
var title: Label
var stats: Label
var loadout: Label
var wave_label: Label
var health_bar: ProgressBar
var xp_bar: ProgressBar
var state := "menu"
var joystick_finger := -1
var joystick_origin := Vector2.ZERO
var joystick_position := Vector2.ZERO
var mouse_drag := false
var movement := Vector2.ZERO
var banner_time := 0.0
var last_minute := -1
var options: Array[String] = []
var screen_buttons: Array[Button] = []
var resume_timer := 0.0
var controls_layer: Node2D
var audio: CombatAudio
var save_clock := 0.0
var mirrored := false
var reduced_effects := false
var save_path := "user://deployment.dat"

func _ready() -> void:
	get_tree().auto_accept_quit = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field = Battlefield.new()
	add_child(field)
	battle = Battle.new(42)
	field.battle = battle
	audio = CombatAudio.new()
	add_child(audio)
	_load_settings()
	_build_hud()
	controls_layer = Node2D.new()
	controls_layer.z_index = 10
	controls_layer.draw.connect(_draw_controls)
	add_child(controls_layer)
	_show_menu()

func _label(parent: Node, text: String, at: Vector2, font_size: int, color := Color("e5e8d6")) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 12)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("283d36")
	normal.border_color = Color("819176")
	normal.set_border_width_all(1)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("48624b")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(action)
	parent.add_child(button)
	screen_buttons.append(button)
	return button

func _panel(parent: Node, rect: Rect2, color: Color) -> ColorRect:
	var panel := ColorRect.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.color = color
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _build_hud() -> void:
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	_panel(hud, Rect2(0, 0, 640, 44), Color("111e1e"))
	_panel(hud, Rect2(0, 333, 640, 27), Color("111e1e"))
	title = _label(hud, "OPERATION / LAST COMMANDO", Vector2(14, 7), 10, Color("b4bb9b"))
	stats = _label(hud, "", Vector2(252, 7), 12)
	loadout = _label(hud, "", Vector2(14, 341), 9, Color("aab5a2"))
	wave_label = _label(hud, "", Vector2(210, 53), 14, Color("e5bf72"))
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(14, 26)
	health_bar.size = Vector2(140, 6)
	_style_bar(health_bar, Color("a9b66c"))
	health_bar.show_percentage = false
	health_bar.max_value = 100
	hud.add_child(health_bar)
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(0, 40)
	xp_bar.size = Vector2(640, 3)
	_style_bar(xp_bar, Color("6cbba7"))
	xp_bar.show_percentage = false
	hud.add_child(xp_bar)
	health_bar.size = Vector2(140, 6)
	xp_bar.size = Vector2(640, 3)
	_button(hud, "II", Rect2(584, 4, 42, 31), pause_run)

func _style_bar(bar: ProgressBar, color: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("293d35")
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)

func _clear_overlay() -> void:
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	screen_buttons.clear()

func _show_menu() -> void:
	state = "menu"
	audio.silence()
	hud.visible = false
	_clear_overlay()
	_panel(overlay, Rect2(0, 0, 640, 360), Color(0.035, 0.075, 0.075, 0.94))
	_panel(overlay, Rect2(33, 36, 3, 284), Color("d5b36a"))
	_label(overlay, "FIELD OPERATIONS DIVISION     /     01", Vector2(53, 36), 10, Color("a9b592"))
	_label(overlay, "LAST\nCOMMANDO", Vector2(50, 68), 44)
	_label(overlay, "ONE SOLDIER. TEN MINUTES. NO BACKUP.", Vector2(54, 185), 10, Color("d5b36a"))
	_label(overlay, "Move through the crossfire. Your weapons handle the rest.\nCollect dog tags. Upgrade your arsenal. Reach extraction.", Vector2(54, 218), 11, Color("aebaa9"))
	_button(overlay, "DEPLOY  →", Rect2(54, 277, 210, 41), start_run)
	if FileAccess.file_exists(save_path):
		_button(overlay, "CONTINUE", Rect2(281, 277, 150, 41), _continue_run)
	_button(overlay, "SETTINGS", Rect2(447, 277, 140, 41), _show_settings)
	_label(overlay, "WASD / ARROWS or drag to move   ·   ESC to pause", Vector2(54, 331), 9, Color("8e9e92"))

func start_run() -> void:
	_clear_save()
	battle = Battle.new()
	field.battle = battle
	state = "playing"
	hud.visible = true
	_clear_overlay()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_input()
	last_minute = -1
	save_clock = 0

func _reset_input() -> void:
	joystick_finger = -1
	mouse_drag = false
	movement = Vector2.ZERO

func pause_run() -> void:
	if state != "playing":
		return
	state = "paused"
	_save_session()
	audio.silence()
	_reset_input()
	_clear_overlay()
	_panel(overlay, Rect2(0, 0, 640, 360), Color(0.035, 0.075, 0.075, 0.92))
	_label(overlay, "OPERATION PAUSED", Vector2(207, 91), 24)
	_label(overlay, "Take a breath. The battlefield can wait.", Vector2(206, 133), 11, Color("b4bb9b"))
	_label(overlay, "EVOLUTION: Weapon 6 + matching Support 2 + gold cache", Vector2(155, 155), 10, Color("d5b36a"))
	_button(overlay, "RESUME", Rect2(215, 180, 210, 42), _resume)
	_button(overlay, "SAVE & BRIEFING", Rect2(215, 237, 210, 36), _save_and_menu)
	_button(overlay, "SETTINGS", Rect2(215, 286, 210, 32), _show_settings)

func _resume() -> void:
	_clear_overlay()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state = "resuming"
	resume_timer = 0.75
	_reset_input()

func _input(event: InputEvent) -> void:
	# Controls still receive emulated mouse events; movement uses the owning touch only.
	if event is InputEventMouse and event.device == -1:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if state == "playing":
				pause_run()
			elif state == "paused":
				_resume()
		if state == "menu" and event.keycode == KEY_ENTER:
			start_run()
		if state == "upgrading" and event.keycode >= KEY_1 and event.keycode <= KEY_3:
			var index: int = event.keycode - KEY_1
			if index < options.size():
				_choose(options[index])
	if state != "playing":
		return
	if event is InputEventScreenTouch:
		if event.pressed and joystick_finger < 0 and event.position.y > 70 and (event.position.x > 320 if mirrored else event.position.x < 320):
			joystick_finger = event.index
			joystick_origin = event.position
			joystick_position = event.position
		elif not event.pressed and event.index == joystick_finger:
			_reset_input()
	elif event is InputEventScreenDrag and event.index == joystick_finger:
		joystick_position = event.position
		movement = (joystick_position - joystick_origin).limit_length(40) / 40
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.y > 60:
			mouse_drag = true
			joystick_origin = event.position
			joystick_position = event.position
		elif not event.pressed:
			mouse_drag = false
			movement = Vector2.ZERO
	elif event is InputEventMouseMotion and mouse_drag:
		joystick_position = event.position
		movement = (joystick_position - joystick_origin).limit_length(40) / 40

func _physics_process(dt: float) -> void:
	if state == "resuming":
		resume_timer -= dt
		if resume_timer <= 0:
			state = "playing"
			_reset_input()
	if state == "playing":
		var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		battle.step(dt, keyboard if keyboard.length_squared() > 0 else movement)
		save_clock += dt
		if save_clock >= 10:
			save_clock = 0
			_save_session()
		if battle.finished:
			_show_results()
		elif battle.pending_levels > 0:
			_show_upgrades()
	_update_hud(dt)
	field.queue_redraw()
	controls_layer.queue_redraw()

func _update_hud(dt: float) -> void:
	health_bar.value = battle.hp
	xp_bar.max_value = battle.xp_needed()
	xp_bar.value = battle.xp
	stats.text = "%02d:%02d    LV %02d    %04d KILLS" % [int(battle.elapsed) / 60, int(battle.elapsed) % 60, battle.level, battle.kills]
	var parts: Array[String] = []
	for i in 3:
		if battle.weapons[i] > 0:
			parts.append((EVOLUTION_NAMES[i] + " ★") if battle.evolved[i] else ["HMG", "FLAME", "RADIO"][i] + " " + str(battle.weapons[i]) + "/6" + " S" + str(battle.supports[i]))
	loadout.text = "   /   ".join(parts) + "      ·      EXTRACT AT 10:00"
	if battle.minute() != last_minute and state == "playing":
		last_minute = battle.minute()
		wave_label.text = "%02d / %s" % [last_minute + 1, Battle.TITLES[last_minute]]
		banner_time = 3
	if not battle.events.is_empty():
		wave_label.text = battle.events.pop_front()
		banner_time = 3
	if battle.eligible_evolutions().is_empty():
		for cache in battle.caches:
			if cache.distance_to(battle.player) < 35:
				wave_label.text = "CACHE: WEAPON 6 + SUPPORT 2"
				banner_time = 0.2
	banner_time -= dt
	wave_label.visible = banner_time > 0 and state == "playing"
	if state == "playing":
		for sound in battle.sound_events:
			audio.play(sound)
	battle.sound_events.clear()

func _draw_controls() -> void:
	if state == "resuming":
		controls_layer.draw_string(ThemeDB.fallback_font, Vector2(278, 165), "READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("e5bf72"))
	if state == "playing" and (joystick_finger >= 0 or mouse_drag):
		controls_layer.draw_circle(joystick_origin, 42, Color(0.7, 0.8, 0.7, 0.1))
		controls_layer.draw_arc(joystick_origin, 42, 0, TAU, 40, Color(0.7, 0.8, 0.7, 0.4), 1)
		controls_layer.draw_circle(joystick_origin + (joystick_position - joystick_origin).limit_length(40), 15, Color(0.8, 0.9, 0.75, 0.45))
	if battle != null and battle.hit_flash > 0 and not reduced_effects:
		controls_layer.draw_rect(Rect2(0, 0, 640, 360), Color(0.9, 0.2, 0.1, battle.hit_flash * 0.4))

func _show_upgrades(keep_options: bool = false) -> void:
	state = "upgrading"
	_reset_input()
	if not keep_options:
		options = _roll_options()
	_clear_overlay()
	_panel(overlay, Rect2(0, 0, 640, 360), Color(0.035, 0.075, 0.075, 0.96))
	_label(overlay, "FIELD PROMOTION", Vector2(32, 27), 10, Color("d5b36a"))
	_label(overlay, "UPGRADE YOUR ARSENAL", Vector2(32, 48), 25)
	_label(overlay, "LEVEL %02d   /   Choose one requisition. Combat is paused." % battle.level, Vector2(33, 85), 11, Color("aebaa9"))
	for i in options.size():
		var id := options[i]
		var x := 32 + i * 196
		_panel(overlay, Rect2(x, 117, 184, 151), Color("21332e"))
		_label(overlay, "0%d / REQUISITION" % (i + 1), Vector2(x + 12, 129), 9, Color("d5b36a"))
		var description := _describe(id)
		_label(overlay, description[0], Vector2(x + 12, 151), 11)
		_label(overlay, description[1], Vector2(x + 12, 183), 10, Color("aebaa9"))
		_button(overlay, "SELECT  [%d]" % (i + 1), Rect2(x, 276, 184, 39), _choose.bind(id))
	if battle.rerolls > 0:
		_button(overlay, "REROLL · 1", Rect2(470, 32, 135, 33), _reroll)

func _roll_options() -> Array[String]:
	var candidates: Array[String] = []
	for i in 3:
		if battle.weapons[i] < 6:
			candidates.append("w" + str(i))
		if battle.supports[i] < 2:
			candidates.append("s" + str(i))
	if candidates.size() < 3:
		candidates.append("heal")
	if candidates.size() < 3:
		candidates.append("supply")
	var result: Array[String] = []
	if battle.level > 3:
		for i in 3:
			if battle.weapons[i] > 0 and battle.weapons[i] < 6:
				result.append("w" + str(i))
				break
	if battle.level <= 3:
		for id in ["w1", "w2"]:
			if battle.weapons[int(id[1])] == 0:
				result.append(id)
	while result.size() < mini(3, candidates.size()):
		var id: String = candidates[battle.rng.randi_range(0, candidates.size() - 1)]
		if not result.has(id):
			result.append(id)
	return result

func _describe(id: String) -> Array[String]:
	if id == "heal":
		return ["MEDICAL SUPPLIES", "Restore 30 HP."]
	if id == "supply":
		return ["EMERGENCY AIRDROP", "Restore 15 HP.\nCollect all field XP."]
	var index := int(id[1])
	if id[0] == "w":
		var names := ["HEAVY MACHINE GUN", "TACTICAL\nFLAMETHROWER", "ARTILLERY RADIO"]
		var details := [
			["Auto-fire at nearby threats.", "Damage 10 → 13", "Fire interval .25 → .20s", "Bullets pierce one enemy", "Damage 13 → 17\nRange 260 → 300", "Fire interval .20 → .16s"],
			["Short-range flame cone.\n5 damage per tick.", "Tick damage 5 → 7", "Range 70 → 90", "Ignite: 4 damage/sec\nBurn lasts 3 seconds", "Cone 60° → 90°\nShorter cooling period", "Tick damage 7 → 9\nLonger firing cycle"],
			["Automatic area strike.\n80 damage every 8s.", "Blast damage 80 → 110", "Blast radius 48 → 60", "Two shells per salvo", "Cooldown 8 → 6.5s", "Damage 110 → 140\nBlast radius 60 → 68"]]
		return [names[index], "LEVEL %d → %d\n%s" % [battle.weapons[index], battle.weapons[index] + 1, details[index][battle.weapons[index]]]]
	return [SUPPORT_NAMES[index], "LEVEL %d → %d\n%s\nEvolution needs W6 + S2." % [battle.supports[index], battle.supports[index] + 1, ["+10% projectile damage", "+10% flame range", "−10% artillery cooldown"][index]]]

func _choose(id: String) -> void:
	if state != "upgrading" or not options.has(id):
		return
	if id.begins_with("w"):
		battle.weapons[int(id[1])] += 1
	elif id.begins_with("s"):
		battle.supports[int(id[1])] += 1
	elif id == "heal":
		battle.hp = minf(100, battle.hp + 30)
	else:
		battle.hp = minf(100, battle.hp + 15)
		for i in battle.pickups.capacity:
			if battle.pickups.alive[i]:
				battle.pickups.position[i] = battle.player
	battle.pending_levels -= 1
	audio.play("evolve")
	if battle.pending_levels > 0:
		_show_upgrades()
	else:
		_resume()

func _reroll() -> void:
	if battle.rerolls > 0:
		battle.rerolls -= 1
		_show_upgrades()

func _show_results() -> void:
	_clear_save()
	state = "results"
	_reset_input()
	_clear_overlay()
	_panel(overlay, Rect2(0, 0, 640, 360), Color(0.035, 0.075, 0.075, 0.94))
	_label(overlay, "AFTER ACTION REPORT", Vector2(54, 44), 10, Color("d5b36a"))
	_label(overlay, "EXTRACTION COMPLETE" if battle.victory else "SOLDIER DOWN", Vector2(50, 75), 32)
	_label(overlay, "SURVIVED       %02d:%02d\nELIMINATIONS   %d\nFIELD LEVEL    %d" % [int(battle.elapsed) / 60, int(battle.elapsed) % 60, battle.kills, battle.level], Vector2(54, 137), 16)
	_label(overlay, "Every deployment is a new chance.", Vector2(54, 226), 11, Color("aebaa9"))
	_button(overlay, "DEPLOY AGAIN", Rect2(54, 278, 230, 42), start_run)
	_button(overlay, "BRIEFING", Rect2(305, 278, 180, 42), _show_menu)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		audio.silence()
		_save_session()
		get_tree().quit()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(audio):
			audio.silence()
		if state == "playing":
			pause_run()
		elif state == "resuming":
			state = "playing"
			pause_run()
		elif state == "upgrading":
			_save_session()

func _save_session() -> void:
	if battle == null or battle.finished or state in ["menu", "results"]:
		return
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_var({"battle": battle.snapshot(), "options": options if state == "upgrading" else []})
	file.flush()
	file.close()
	DirAccess.rename_absolute(save_path + ".tmp", save_path)

func _clear_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)

func _save_and_menu() -> void:
	_save_session()
	_show_menu()

func _continue_run() -> void:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
	var data: Variant = file.get_var(false)
	file.close()
	if not data is Dictionary or not data.get("battle") is Dictionary:
		return
	var restored := Battle.new(1)
	if not restored.restore(data.battle):
		return
	battle = restored
	field.battle = battle
	hud.visible = true
	last_minute = -1
	if battle.pending_levels > 0:
		options.assign(data.get("options", []))
		_show_upgrades(not options.is_empty())
	else:
		state = "playing"
		pause_run()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		audio.enabled = config.get_value("accessibility", "sound", true)
		mirrored = config.get_value("accessibility", "mirrored", false)
		reduced_effects = config.get_value("accessibility", "reduced_effects", false)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("accessibility", "sound", audio.enabled)
	config.set_value("accessibility", "mirrored", mirrored)
	config.set_value("accessibility", "reduced_effects", reduced_effects)
	config.save("user://settings.cfg")

func _show_settings() -> void:
	var return_to_menu := state == "menu"
	_reset_input()
	_clear_overlay()
	_panel(overlay, Rect2(0, 0, 640, 360), Color(0.035, 0.075, 0.075, 0.98))
	_label(overlay, "FIELD SETTINGS", Vector2(195, 47), 27)
	_button(overlay, "SOUND: " + ("ON" if audio.enabled else "OFF"), Rect2(180, 110, 280, 40), _toggle_setting.bind("sound"))
	_button(overlay, "JOYSTICK: " + ("RIGHT" if mirrored else "LEFT"), Rect2(180, 163, 280, 40), _toggle_setting.bind("mirrored"))
	_button(overlay, "HIT FLASH: " + ("OFF" if reduced_effects else "ON"), Rect2(180, 216, 280, 40), _toggle_setting.bind("effects"))
	_button(overlay, "BACK", Rect2(180, 282, 280, 40), _show_menu if return_to_menu else _return_pause)

func _return_pause() -> void:
	state = "playing"
	pause_run()

func _toggle_setting(key: String) -> void:
	match key:
		"sound": audio.enabled = not audio.enabled
		"mirrored": mirrored = not mirrored
		"effects": reduced_effects = not reduced_effects
	_save_settings()
	_show_settings()
