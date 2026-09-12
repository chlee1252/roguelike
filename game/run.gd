extends Control

const WEAPON_NAMES := ["생선뼈 툭툭", "털뭉치 발자국", "통통 장난감 공"]
const SUPPORT_NAMES := ["간식 자리의 기억", "두꺼운 겨울털", "깨끗한 발바닥"]
const EVOLUTION_NAMES := ["와다다 생선뼈", "온 골목이 내 털", "통통 털실공"]
var collection := CatCollection.new()
var shop := TokenShop.new()
var shop_tab := 0
var run_id := ""
var shop_notice := ""
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
var boss_panel: Control
var boss_bar: ProgressBar
var boss_title: Label
var health_text: Label
var save_path := "user://night-walk.dat"

func _ready() -> void:
	get_tree().auto_accept_quit = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ui_theme := Theme.new()
	ui_theme.default_font = GameSkin.REGULAR
	ui_theme.default_font_size = 12
	theme = ui_theme
	field = Battlefield.new()
	add_child(field)
	battle = Battle.new(42)
	field.battle = battle
	audio = CombatAudio.new()
	add_child(audio)
	_load_settings()
	shop.collection = collection
	shop.preview = OS.is_debug_build() and OS.get_cmdline_user_args().has("--shop-preview")
	shop.endpoint = OS.get_environment("NIGHTCAT_SHOP_URL")
	shop.access_token = OS.get_environment("NIGHTCAT_SHOP_ACCESS_TOKEN")
	add_child(shop)
	collection.open(save_path + (".preview-collection.cfg" if shop.preview else ".collection.cfg"))
	field.set_cat_variant(collection.selected)
	field.theme_id = collection.selected_theme
	_build_hud()
	controls_layer = Node2D.new()
	controls_layer.z_index = 10
	controls_layer.draw.connect(_draw_controls)
	add_child(controls_layer)
	_show_menu()

func _label(parent: Node, text: String, at: Vector2, font_size: int, color := GameSkin.INK) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", GameSkin.BOLD if font_size >= 16 else GameSkin.REGULAR)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, rect: Rect2, action: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_font_override("font", GameSkin.BOLD)
	var normal := GameSkin.box(GameSkin.MINT if primary else Color("514965"), 10)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("c3eddb") if primary else Color("665a7a")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("85c6ac") if primary else Color("413952")
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", GameSkin.box(Color.TRANSPARENT, 10, Color("bedccd")))
	for state_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state_name, Color("183a32") if primary else GameSkin.INK)
	button.pressed.connect(action)
	parent.add_child(button)
	screen_buttons.append(button)
	return button

func _panel(parent: Node, rect: Rect2, color: Color, radius: int = 14) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", GameSkin.box(color, radius))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _backdrop() -> void:
	_panel(overlay, Rect2(0, 0, 640, 360), Color(0.045, 0.075, 0.10, 0.94), 0)

func _chip(parent: Node, text: String, rect: Rect2, color := GameSkin.MINT) -> void:
	_panel(parent, rect, Color(color, 0.10), 8)
	_label(parent, text, rect.position + Vector2(10, 4), 9, color)

func _icon(parent: Node, index: int, at: Vector2, tint := GameSkin.MINT) -> void:
	var glyph := EquipmentGlyph.new()
	glyph.position = at
	glyph.size = Vector2(32, 32)
	glyph.icon = index
	glyph.ink = tint
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(glyph)

func _build_hud() -> void:
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	_panel(hud, Rect2(12, 10, 155, 39), Color(0.06, 0.11, 0.14, 0.92), 12)
	_panel(hud, Rect2(235, 10, 300, 36), Color(0.06, 0.11, 0.14, 0.92), 12)
	title = _label(hud, "동네 고양이", Vector2(24, 15), 10, GameSkin.MUTED)
	health_text = _label(hud, "100", Vector2(135, 15), 10, GameSkin.MINT)
	stats = _label(hud, "", Vector2(251, 19), 12)
	_panel(hud, Rect2(12, 324, 616, 26), Color(0.06, 0.11, 0.14, 0.88), 9)
	loadout = _label(hud, "", Vector2(24, 330), 9, GameSkin.MUTED)
	wave_label = _label(hud, "", Vector2(150, 58), 13, Color("e6c69b"))
	wave_label.add_theme_stylebox_override("normal", GameSkin.box(Color(0.06, 0.09, 0.15, 0.94), 8))
	wave_label.size.x = 340
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(24, 35)
	_style_bar(health_bar, GameSkin.MINT)
	health_bar.show_percentage = false
	health_bar.max_value = 100
	hud.add_child(health_bar)
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(245, 43)
	_style_bar(xp_bar, Color("91bbd8"))
	xp_bar.show_percentage = false
	hud.add_child(xp_bar)
	health_bar.size = Vector2(131, 4)
	xp_bar.size = Vector2(280, 3)
	boss_panel = Control.new()
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(boss_panel)
	_panel(boss_panel, Rect2(170, 52, 300, 34), Color("514965"), 10)
	boss_title = _label(boss_panel, "멍멍 꿈대장", Vector2(184, 55), 10, GameSkin.INK)
	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(184, 76)
	_style_bar(boss_bar, Color("efb5c3"))
	boss_bar.show_percentage = false
	boss_panel.add_child(boss_bar)
	boss_bar.size = Vector2(272, 4)
	boss_panel.visible = false
	_button(hud, "Ⅱ", Rect2(580, 10, 48, 38), pause_run)

func _style_bar(bar: ProgressBar, color: Color) -> void:
	bar.add_theme_stylebox_override("background", GameSkin.box(Color("31434a"), 3))
	bar.add_theme_stylebox_override("fill", GameSkin.box(color, 3))

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
	_panel(overlay, Rect2(0, 0, 640, 360), GameSkin.BASE, 0)
	_label(overlay, "골목의 밤냥", Vector2(32, 23), 16)
	_button(overlay, "고양이 · 상점", Rect2(425, 20, 112, 32), _show_cats)
	_button(overlay, "설정", Rect2(548, 20, 60, 32), _show_settings)
	_chip(overlay, "밤 산책  ·  보스 도전", Rect2(32, 67, 144, 24))
	_label(overlay, "말랑한 발로,\n통통 밤 산책.", Vector2(30, 106), 29)
	_label(overlay, "생선뼈 톡, 털실공 통통!\n장난꾸러기 앙숙들과 골목 한 바퀴.", Vector2(32, 204), 12, GameSkin.MUTED)
	var art := MissionArt.new()
	art.position = Vector2(340, 72)
	art.theme_id = collection.selected_theme
	art.cat_texture = CatPixel.make(0, true, collection.selected)
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	overlay.add_child(art)
	_label(overlay, "첫 번째 밤", Vector2(358, 84), 10, GameSkin.MINT)
	_label(overlay, "해솔빌라 골목", Vector2(358, 101), 15)
	_chip(overlay, "가로등 불빛 · 낯선 기척 · 밥 냄새", Rect2(363, 249, 220, 22), Color("d9c7a3"))
	if FileAccess.file_exists(save_path):
		_button(overlay, "이어하기  →", Rect2(32, 269, 158, 44), _continue_run, true)
		_button(overlay, "새 산책", Rect2(200, 269, 108, 44), start_run)
	else:
		_button(overlay, "밤 산책 시작  →", Rect2(32, 269, 244, 44), start_run, true)
	_label(overlay, "목표", Vector2(343, 294), 10, GameSkin.MUTED)
	_label(overlay, "장난꾸러기 보스를 만나러 가요.", Vector2(373, 294), 9)
	var hint := "화면을 누르고 끌어 이동 · 공격은 고양이가 알아서 해요" if OS.has_feature("mobile") else "WASD / 방향키 · 터치 드래그로 이동     Esc 일시정지"
	_label(overlay, hint, Vector2(32, 334), 9, GameSkin.MUTED)

func start_run() -> void:
	run_id = "%s-%s" % [str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]
	field.set_cat_variant(collection.selected)
	field.theme_id = collection.selected_theme
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
	_backdrop()
	_panel(overlay, Rect2(158, 27, 324, 306), GameSkin.SURFACE, 20)
	_chip(overlay, "잠시 쉬어가세요", Rect2(261, 46, 117, 23))
	_label(overlay, "잠깐 웅크리기", Vector2(216, 80), 27)
	_label(overlay, "골목은 기다려 줄 거예요.", Vector2(224, 122), 11, GameSkin.MUTED)
	_button(overlay, "계속하기", Rect2(182, 161, 276, 42), _resume, true)
	_button(overlay, "저장하고 나가기", Rect2(182, 213, 276, 40), _save_and_menu)
	_button(overlay, "설정", Rect2(182, 263, 276, 40), _show_settings)

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
	var boss_hp := battle.boss_health()
	boss_panel.visible = boss_hp > 0
	if boss_hp > 0:
		boss_bar.max_value = battle.boss_max_hp
		boss_bar.value = boss_hp
		boss_title.text = "멍멍 꿈대장  ·  " + ("더 신났어요!" if boss_hp < battle.boss_max_hp * 0.5 else "골목의 장난꾸러기")
	wave_label.position.y = 90 if boss_hp > 0 else 58
	health_bar.value = battle.hp
	xp_bar.max_value = battle.xp_needed()
	xp_bar.value = battle.xp
	health_text.text = str(int(battle.hp))
	stats.text = "%02d:%02d     ·     레벨 %02d     ·     퇴치 %04d" % [int(battle.elapsed) / 60, int(battle.elapsed) % 60, battle.level, battle.kills]
	var parts: Array[String] = []
	for i in 3:
		if battle.weapons[i] > 0:
			parts.append((EVOLUTION_NAMES[i] + " ★") if battle.evolved[i] else ["생선뼈", "털뭉치", "장난감 공"][i] + " " + str(battle.weapons[i]) + "/6" + " · 기억 " + str(battle.supports[i]))
	loadout.text = "      ".join(parts) + "      |      보스 퇴치 후 귀가"
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
				wave_label.text = "익숙한 냄새 · 버릇 6 + 기억 2레벨 필요"
				banner_time = 0.2
	banner_time -= dt
	wave_label.visible = banner_time > 0 and state == "playing"
	if state == "playing":
		for sound in battle.sound_events:
			audio.play(sound)
	battle.sound_events.clear()

func _draw_controls() -> void:
	if state == "resuming":
		controls_layer.draw_string(GameSkin.BOLD, Vector2(270, 165), "준비하세요", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GameSkin.MINT)
	if state == "playing" and (joystick_finger >= 0 or mouse_drag):
		controls_layer.draw_circle(joystick_origin, 42, Color(0.64, 0.87, 0.78, 0.10))
		controls_layer.draw_arc(joystick_origin, 42, 0, TAU, 40, Color(0.7, 0.8, 0.7, 0.4), 1)
		controls_layer.draw_circle(joystick_origin + (joystick_position - joystick_origin).limit_length(40), 15, Color(0.64, 0.87, 0.78, 0.60))
	if battle != null and battle.hit_flash > 0 and not reduced_effects:
		controls_layer.draw_rect(Rect2(0, 0, 640, 360), Color(0.9, 0.2, 0.1, battle.hit_flash * 0.4))

func _show_upgrades(keep_options: bool = false) -> void:
	state = "upgrading"
	_reset_input()
	if not keep_options:
		options = _roll_options()
	_clear_overlay()
	_backdrop()
	_chip(overlay, "%d레벨 달성" % battle.level, Rect2(28, 21, 94, 24))
	_label(overlay, "다음 한 수를 고르세요", Vector2(28, 54), 26)
	_label(overlay, "새로운 버릇 하나를 고르세요. 고르는 동안 밤은 멈춥니다.", Vector2(29, 91), 11, GameSkin.MUTED)
	for i in options.size():
		var id := options[i]
		var x := 28 + i * 198
		var tint: Color = [GameSkin.MINT, Color("efc79d"), Color("aebeed")][i]
		_panel(overlay, Rect2(x, 123, 188, 171), GameSkin.SURFACE, 14)
		_panel(overlay, Rect2(x + 14, 137, 40, 38), Color(tint, 0.10), 10)
		var icon_index := int(id[1]) + (3 if id.begins_with("s") else 0) if id.length() == 2 else 6
		_icon(overlay, icon_index, Vector2(x + 18, 139), tint)
		var rank_text := "간식"
		if id.length() == 2:
			var rank: int = battle.weapons[int(id[1])] if id.begins_with("w") else battle.supports[int(id[1])]
			rank_text = "새로운 버릇" if rank == 0 else "%d → %d 레벨" % [rank, rank + 1]
		_label(overlay, rank_text, Vector2(x + 69, 148), 10, tint)
		var description := _describe(id)
		_label(overlay, description[0], Vector2(x + 14, 185), 16)
		_label(overlay, description[1], Vector2(x + 14, 214), 11, GameSkin.MUTED)
		_button(overlay, "선택하기  ·  %d" % (i + 1), Rect2(x, 304, 188, 36), _choose.bind(id), i == 0)
	if battle.rerolls > 0:
		_button(overlay, "다시 뽑기 · 1회", Rect2(482, 27, 130, 34), _reroll)

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
		return ["남겨둔 참치캔", "체력을 30 회복합니다.\n다시 버틸 힘을 얻으세요."]
	if id == "supply":
		return ["동네 사람의 간식", "체력을 15 회복하고\n전장의 경험치를 모두 수집합니다."]
	var index := int(id[1])
	if id[0] == "w":
		var details := [
			["앞발로 생선뼈를 톡 밀어요.\n피해 18 · 두 마리 관통", "피해 18 → 22", "공격 주기 0.6 → 0.45초", "생선뼈가 세 마리를 관통해요.", "생선뼈 조준 거리\n220 → 280", "피해 22 → 27"],
			["움직인 자리에 털이 남아요.\n따라오는 괴이에게 지속 피해", "털뭉치 피해 2.5 → 3.5", "털이 남는 시간 3 → 5초", "털에 걸린 괴이가 느려져요.", "털을 남기는 주기\n0.45 → 0.30초", "털뭉치 피해 3.5 → 5"],
			["앞발로 굴린 공이\n괴이 셋 사이를 튕겨요.", "피해 22 → 27", "세 번 → 네 번 명중", "한 번에 장난감 공 두 개를 굴려요.", "굴리는 주기 1.8 → 1.2초", "피해 27 → 34"]]
		return [WEAPON_NAMES[index], details[index][battle.weapons[index]]]
	return [SUPPORT_NAMES[index], ["생선뼈 피해 +15%", "털뭉치 범위 +5", "장난감 공 재사용 시간 −12%"][index] + "\n\n버릇 6 · 기억 2레벨 + 냄새 발견"]

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
	_backdrop()
	_panel(overlay, Rect2(60, 28, 520, 300), GameSkin.SURFACE, 20)
	_chip(overlay, "밤 산책 기록", Rect2(84, 47, 76, 23))
	_label(overlay, "골목 산책 완료!" if battle.victory else "잠시 쉬어가는 밤", Vector2(84, 86), 29)
	_label(overlay, "작은 발자국이 골목을 조금 바꿨습니다.", Vector2(85, 128), 12, GameSkin.MUTED)
	var values := ["%02d:%02d" % [int(battle.elapsed) / 60, int(battle.elapsed) % 60], str(battle.kills), str(battle.level)]
	for i in 3:
		var x := 84 + i * 156
		_panel(overlay, Rect2(x, 164, 146, 76), Color("293d43"), 12)
		_label(overlay, ["산책 시간", "돌려보낸 괴이", "도달 레벨"][i], Vector2(x + 14, 174), 10, GameSkin.MUTED)
		_label(overlay, values[i], Vector2(x + 14, 195), 25, GameSkin.MINT)
	_button(overlay, "다시 도전하기", Rect2(84, 265, 244, 40), start_run, true)
	_button(overlay, "처음 화면", Rect2(340, 265, 216, 40), _show_menu)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		audio.silence()
		_save_session()
		get_tree().quit()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if is_instance_valid(audio):
			audio.silence()
		_save_session()
		_pause_for_background.call_deferred()

func _pause_for_background() -> void:
	if not is_inside_tree():
		return
	if state == "resuming":
		state = "playing"
	if state == "playing":
		pause_run()

func _save_session() -> void:
	if battle == null or battle.finished or state in ["menu", "cats", "results"]:
		return
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_var({"run_id": run_id, "battle": battle.snapshot(), "options": options if state == "upgrading" else []})
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
	run_id = str(data.get("run_id", "legacy-%s" % str(restored.rng.seed)))
	field.set_cat_variant(collection.selected)
	field.theme_id = collection.selected_theme
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
	_backdrop()
	_panel(overlay, Rect2(130, 25, 380, 310), GameSkin.SURFACE, 20)
	_label(overlay, "나에게 맞는 플레이", Vector2(154, 47), 25)
	_label(overlay, "편안하게 조작할 수 있도록 설정하세요.", Vector2(155, 86), 11, GameSkin.MUTED)
	for i in 3:
		var y := 118 + i * 52
		_panel(overlay, Rect2(150, y, 340, 44), Color("293b43"), 10)
		_label(overlay, ["효과음", "조이스틱 위치", "피격 시 화면 효과"][i], Vector2(166, y + 13), 12)
		var value := ("켜짐" if audio.enabled else "꺼짐") if i == 0 else ("오른쪽" if mirrored else "왼쪽") if i == 1 else ("꺼짐" if reduced_effects else "켜짐")
		_button(overlay, value, Rect2(395, y + 6, 84, 32), _toggle_setting.bind(["sound", "mirrored", "effects"][i]), (i == 0 and audio.enabled) or (i == 2 and not reduced_effects))
	_button(overlay, "돌아가기", Rect2(150, 283, 340, 34), _show_menu if return_to_menu else _return_pause)

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

func _show_cats() -> void:
	state = "cats"
	_reset_input()
	hud.visible = false
	_clear_overlay()
	_panel(overlay, Rect2(0, 0, 640, 360), GameSkin.BASE, 0)
	_label(overlay, "골목의 작은 상점", Vector2(25, 18), 25)
	_chip(overlay, ("테스트 토큰  " if shop.preview else "보유 토큰  ") + str(collection.tokens), Rect2(26, 57, 150, 25))
	_button(overlay, "돌아가기", Rect2(520, 23, 94, 34), _show_menu)
	for tab in 3:
		_button(overlay, ["고양이", "배경 테마", "토큰 구매"][tab], Rect2(202 + tab * 102, 56, 96, 28), _change_shop_tab.bind(tab), shop_tab == tab)
	if shop_tab == 2:
		_show_token_packs()
	else:
		_show_cosmetics()
	var caption := "[테스트 상점] 가상 토큰만 사용하며 실제 결제·구매 내역과 분리됩니다." if shop.preview else "토큰으로 고양이와 배경을 해금해요 · 현금 결제 준비 중 · 능력치는 모두 같아요"
	_label(overlay, shop_notice if not shop_notice.is_empty() else caption, Vector2(26, 321), 10, GameSkin.MUTED)

func _change_shop_tab(tab: int) -> void:
	shop_tab = tab
	shop_notice = ""
	_show_cats()

func _show_cosmetics() -> void:
	var background := shop_tab == 1
	for id in 4:
		var x := 26 + id * 150
		_panel(overlay, Rect2(x, 96, 138, 206), GameSkin.SURFACE, 14)
		if background:
			var art := MissionArt.new()
			art.theme_id = id
			art.cat_texture = CatPixel.make(0, true, collection.selected)
			art.position = Vector2(x + 7, 112)
			art.scale = Vector2.ONE * 0.46
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.add_child(art)
		else:
			var preview := TextureRect.new()
			preview.texture = CatPixel.make(0, true, id)
			preview.position = Vector2(x + 21, 112)
			preview.size = Vector2(96, 96)
			preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.add_child(preview)
		_label(overlay, AlleyTheme.NAMES[id] if background else CatPixel.NAMES[id], Vector2(x + 10, 213), 12 if background else 17)
		var owned := (collection.themes if background else collection.unlocked).has(id)
		var selected := id == (collection.selected_theme if background else collection.selected)
		_label(overlay, "선택한 산책길" if selected and background else "함께 산책 중" if selected else "보유 중" if owned else "미리 보는 산책길" if background else "아직 만나지 않은 친구", Vector2(x + 10, 241), 9, GameSkin.MUTED)
		var price: int = CatCollection.THEME_PRICES[id] if background else CatCollection.PRICES[id]
		var button := _button(overlay, "선택됨" if selected else "선택하기" if owned else "%d 토큰 · 해금" % price, Rect2(x + 10, 268, 118, 27), _cat_action.bind(id, background), selected)
		button.disabled = selected or shop.busy

func _show_token_packs() -> void:
	_label(overlay, "토큰 한 지갑으로, 고양이도 골목도", Vector2(28, 104), 17)
	for index in 3:
		var x := 26 + index * 198
		_panel(overlay, Rect2(x, 142, 188, 135), GameSkin.SURFACE, 14)
		_label(overlay, "%d 토큰" % CatCollection.PACKS[index], Vector2(x + 18, 158), 24)
		_label(overlay, "고양이 · 배경 공용", Vector2(x + 18, 197), 11, GameSkin.MUTED)
		var button := _button(overlay, "가상 구매 · 무료 테스트" if shop.preview else "결제 준비 중", Rect2(x + 12, 230, 164, 32), _buy_tokens.bind(index), shop.preview)
		button.disabled = not shop.preview or shop.busy
	_button(overlay, "구매 내역 새로고침", Rect2(26, 284, 160, 28), _refresh_shop)
	_label(overlay, "현금 결제는 Apple / Google 상점 연결 후 열려요.", Vector2(205, 292), 11, GameSkin.MUTED)

func _cat_action(id: int, background := false) -> void:
	if shop.busy:
		return
	shop_notice = ""
	if not (collection.themes if background else collection.unlocked).has(id):
		shop_notice = await shop.unlock(id, background)
		if not shop_notice.is_empty():
			if state == "cats":
				_show_cats()
			return
	if collection.choose(id, background):
		field.set_cat_variant(collection.selected)
		field.theme_id = collection.selected_theme
		shop_notice = (AlleyTheme.NAMES[id] if background else CatPixel.NAMES[id]) + " 선택했어요."
	else:
		shop_notice = "선택을 저장하지 못했어요. 다시 시도해 주세요."
	if state == "cats":
		_show_cats()

func _buy_tokens(index: int) -> void:
	shop_notice = shop.buy_pack(index)
	_show_cats()

func _refresh_shop() -> void:
	shop_notice = await shop.refresh()
	if shop_notice.is_empty():
		shop_notice = "보유 토큰과 해금 내역을 확인했어요."
	if state == "cats":
		_show_cats()
