extends Node2D

const Story = preload("res://story.gd")
const World = preload("res://world.gd")
const Hud = preload("res://hud.gd")
const GOLD = Color("e5c365")
const PAPER = Color("e9e2cb")
const MUTED = Color("8e969c")
const RED = Color("d45054")
const BOUNDS = Rect2(36, 87, 408, 139)
const SAVE_PATH = "user://checkpoint.cfg"
var font: Font = preload("res://assets/NotoSansSC.ttf")
var display_font: Font
var world: Node2D
var hud: Node2D
var blur: ColorRect
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var state = "title"
var previous_state = ""
var boss_index = 0
var checkpoint = 0
var saving_enabled = true
var clock = 0.0
var player = Vector2(100, 170)
var facing = Vector2.RIGHT
var player_hp = 100.0
var move_dir = Vector2.ZERO
var attack_cd = 0.0
var slash_time = 0.0
var dash_time = 0.0
var dash_cd = 0.0
var dash_dir = Vector2.RIGHT
var invulnerable = 0.0
var hurt_flash = 0.0
var boss = Vector2(340, 157)
var boss_hp = 160.0
var boss_max_hp = 160.0
var boss_phase = "approach"
var boss_timer = 1.5
var boss_target = Vector2.ZERO
var boss_dir = Vector2.LEFT
var boss_pattern = 0
var attack_count = 0
var boss_flash = 0.0
var projectiles: Array[Dictionary] = []
var waves: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var stains: Array[Dictionary] = []
var death_count = 0
var shake = 0.0
var hitstop = 0.0
var dialogue: Array = []
var dialogue_index = 0
var dialogue_next = ""
var speaker = "灵芝"
var pad_dropped = false
var pad_fixed = false
var pad_pos = Vector2.ZERO
var dragging_pad = false
var glass_pad = Vector2(300, 351)
var doctor_spoken = false
var scanned = false
var scan_time = 0.0
var letter_pos = Vector2.ZERO
var muted = false
var toast = ""
var toast_time = 0.0
var screenshot_path = ""

func _ready() -> void:
	var base_font = font
	var readable_font = FontVariation.new()
	readable_font.base_font = base_font
	readable_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 500.0}
	font = readable_font
	var heavy_font = FontVariation.new()
	heavy_font.base_font = base_font
	heavy_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 900.0}
	display_font = heavy_font
	world = World.new()
	world.game = self
	world.scale = Vector2(2, 2)
	add_child(world)
	blur = ColorRect.new()
	blur.size = Vector2(960, 540)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material = ShaderMaterial.new()
	material.shader = preload("res://blur.gdshader")
	blur.material = material
	blur.visible = false
	add_child(blur)
	hud = Hud.new()
	hud.game = self
	add_child(hud)
	var bindings = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "attack": [KEY_J], "dash": [KEY_SPACE, KEY_K], "interact": [KEY_E], "confirm": [KEY_ENTER], "pause_game": [KEY_ESCAPE], "mute": [KEY_M]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in bindings[action]:
				var event = InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)
	var mouse_attack = InputEventMouseButton.new()
	mouse_attack.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mouse_attack)
	setup_audio()
	load_checkpoint()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			screenshot_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--scene="):
			setup_preview(arg.trim_prefix("--scene="))
	if not screenshot_path.is_empty():
		get_tree().create_timer(0.8).timeout.connect(capture_screen)

func setup_audio() -> void:
	for name in ["slash", "hit", "dash", "pickup", "danger", "click"]:
		sounds[name] = load("res://assets/" + name + ".wav")
	for i in range(6):
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -10
		add_child(voice)
		voices.append(voice)
	music = AudioStreamPlayer.new()
	var stream = load("res://assets/night.wav") as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream = stream
	music.volume_db = -17
	add_child(music)
	if not muted:
		music.play()

func sound(name: String) -> void:
	if muted:
		return
	for voice in voices:
		if not voice.playing:
			voice.stream = sounds[name]
			voice.pitch_scale = randf_range(0.94, 1.06)
			voice.play()
			return

func load_checkpoint() -> void:
	if not saving_enabled:
		return
	var save = ConfigFile.new()
	if save.load(SAVE_PATH) == OK:
		checkpoint = clampi(int(save.get_value("game", "chapter", 0)), 0, 4)

func save_checkpoint() -> void:
	checkpoint = boss_index
	if not saving_enabled:
		return
	var save = ConfigFile.new()
	save.set_value("game", "chapter", checkpoint)
	save.save(SAVE_PATH)

func start_boss(index: int, with_intro = true) -> void:
	boss_index = index
	player = Vector2(98, 170)
	player_hp = 100
	facing = Vector2.RIGHT
	boss = Vector2(346, 157)
	boss_max_hp = Story.BOSSES[index].hp
	boss_hp = boss_max_hp
	boss_phase = "approach"
	boss_timer = 1.5
	attack_count = 0
	letter_pos = Vector2.ZERO
	boss_pattern = index
	attack_cd = 0
	slash_time = 0
	dash_time = 0
	dash_cd = 0
	invulnerable = 0
	hurt_flash = 0
	boss_flash = 0
	projectiles.clear()
	waves.clear()
	particles.clear()
	stains.clear()
	state = "fight"
	save_checkpoint()
	if with_intro:
		begin_dialogue(Story.BOSSES[index].intro, "fight", Story.BOSSES[index].place)

func begin_dialogue(lines: Array, next: String, who = "灵芝") -> void:
	dialogue = lines.duplicate()
	dialogue_index = 0
	dialogue_next = next
	speaker = who
	state = "dialogue"

func advance_dialogue() -> void:
	sound("click")
	dialogue_index += 1
	if dialogue_index < dialogue.size():
		return
	match dialogue_next:
		"street":
			state = "street"
			player = Vector2(62, 168)
			pad_dropped = false
			pad_fixed = false
			stains.clear()
			particles.clear()
		"next_boss": start_boss(boss_index + 1)
		"hospital": state = "hospital"
		_: state = dialogue_next

func _process(delta: float) -> void:
	clock += delta
	if Input.is_action_just_pressed("mute"):
		muted = not muted
		music.stream_paused = muted
	if Input.is_action_just_pressed("pause_game"):
		if state == "paused":
			state = previous_state
		elif state not in ["title", "ending", "dead"]:
			previous_state = state
			state = "paused"
	if state == "paused":
		if Input.is_action_just_pressed("confirm"):
			state = previous_state
		refresh()
		return
	if state == "title":
		if Input.is_action_just_pressed("confirm"):
			start_boss(0)
		elif Input.is_action_just_pressed("interact") and checkpoint > 0:
			start_boss(checkpoint)
	elif state == "dialogue":
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
			advance_dialogue()
	elif state == "dead":
		if Input.is_action_just_pressed("confirm"):
			start_boss(boss_index, false)
	elif state == "letter":
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
			state = "ending"
	elif state == "ending":
		if Input.is_action_just_pressed("confirm"):
			state = "title"
	elif state == "ct":
		scan_time += delta
		if scan_time >= 6.0:
			scanned = true
			begin_dialogue(["检查完成，片子已经留档。", "灵芝拿好报告，走向医院出口。"], "hospital", "检查室")
	elif state in ["fight", "street", "hospital", "letter_pickup"]:
		if hitstop > 0:
			hitstop -= delta
		else:
			update_player(delta)
			if state == "fight":
				update_boss(delta)
				update_attacks(delta)
			elif state == "street":
				if player.x >= 174 and not pad_dropped:
					drop_pad()
				if Input.is_action_just_pressed("interact"):
					interact()
			elif Input.is_action_just_pressed("interact"):
				interact()
	update_effects(delta)
	refresh()

func refresh() -> void:
	blur.visible = pad_dropped and not pad_fixed and state in ["street", "glasses", "paused"]
	(blur.material as ShaderMaterial).set_shader_parameter("amount", 7.5)
	world.position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)).round()
	world.queue_redraw()
	hud.queue_redraw()

func update_player(delta: float) -> void:
	attack_cd = maxf(attack_cd - delta, 0)
	slash_time = maxf(slash_time - delta, 0)
	dash_cd = maxf(dash_cd - delta, 0)
	invulnerable = maxf(invulnerable - delta, 0)
	move_dir = Input.get_vector("left", "right", "up", "down")
	if move_dir.length() > 0:
		facing = move_dir
	if state == "fight" and Input.is_action_just_pressed("dash"):
		try_dash()
	var speed = 89.0 if state == "fight" else 67.0
	if dash_time > 0:
		dash_time = maxf(dash_time - delta, 0)
		player += dash_dir * 310 * delta
		if randf() < 0.6:
			particles.append({"p": player, "v": Vector2.ZERO, "life": 0.22, "color": GOLD})
	else:
		player += move_dir * speed * delta
	player.x = clampf(player.x, BOUNDS.position.x, BOUNDS.end.x)
	player.y = clampf(player.y, BOUNDS.position.y, BOUNDS.end.y)
	if state == "fight" and Input.is_action_pressed("attack"):
		try_attack()

func try_dash() -> bool:
	if dash_cd > 0:
		return false
	dash_dir = move_dir if move_dir.length() > 0 else facing
	dash_time = 0.18
	dash_cd = 0.72
	invulnerable = maxf(invulnerable, 0.29)
	sound("dash")
	return true

func try_attack() -> bool:
	if attack_cd > 0 or dash_time > 0:
		return false
	attack_cd = 0.30
	slash_time = 0.15
	# 近距离自动朝向对手，键盘和鼠标攻击拥有相同的命中规则。
	if player.distance_to(boss) < 63:
		facing = (boss - player).normalized()
	sound("slash")
	if player.distance_to(boss) < 49:
		hit_boss(18 if boss_phase == "recover" else 6)
	return true

func hit_boss(damage: float) -> void:
	if state != "fight" or boss_hp <= 0:
		return
	boss_hp = maxf(0, boss_hp - damage)
	boss_flash = 0.13
	shake = 3
	hitstop = 0.045
	blood(boss, 9)
	sound("hit")
	if boss_hp <= 0:
		defeat_boss()

func hurt_player(damage: float) -> bool:
	if state != "fight" or invulnerable > 0:
		return false
	player_hp = maxf(0, player_hp - damage)
	invulnerable = 0.7
	hurt_flash = 0.18
	shake = 4
	blood(player, 7)
	sound("hit")
	if player_hp <= 0:
		death_count += 1
		state = "dead"
	return true

func update_boss(delta: float) -> void:
	boss_timer -= delta
	match boss_phase:
		"approach":
			var distance = boss.distance_to(player)
			if distance > 34:
				boss += (player - boss).normalized() * (35 + boss_index * 3) * delta
			if boss_timer <= 0:
				boss_pattern = attack_count % 4 if boss_index == 4 else boss_index
				if boss_pattern == 4:
					boss_pattern = 0
				boss_phase = "windup"
				boss_timer = 0.78 if boss_index < 4 else 0.64
				boss_target = player
				boss_dir = (player - boss).normalized()
				sound("danger")
		"windup":
			if boss_timer <= 0:
				perform_boss_attack()
		"charge":
			boss += boss_dir * 300 * delta
			if boss.distance_to(player) < 23:
				hurt_player(24)
			if boss_timer <= 0:
				boss_phase = "recover"
				boss_timer = 1.25
		"recover":
			if boss_timer <= 0:
				boss_phase = "approach"
				boss_timer = 0.9
	boss.x = clampf(boss.x, 49, 431)
	boss.y = clampf(boss.y, 97, 214)

func perform_boss_attack() -> void:
	attack_count += 1
	boss_phase = "recover"
	boss_timer = 1.08
	match boss_pattern:
		0:
			if boss.distance_to(player) < 53:
				hurt_player(19)
			particles.append({"p": boss, "v": Vector2.ZERO, "life": 0.25, "color": RED, "ring": true})
		1:
			for angle in [-0.32, 0.0, 0.32]:
				projectiles.append({"p": boss, "v": boss_dir.rotated(angle) * 125, "life": 3.5})
		2:
			waves.append({"p": boss, "radius": 8.0, "hit": false})
		3:
			boss_phase = "charge"
			boss_timer = 0.58
	sound("slash")

func update_attacks(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var shot = projectiles[i]
		shot.p += shot.v * delta
		shot.life -= delta
		if shot.p.distance_to(player) < 11:
			hurt_player(13)
			projectiles.remove_at(i)
		elif shot.life < 0 or not BOUNDS.grow(15).has_point(shot.p):
			projectiles.remove_at(i)
	for i in range(waves.size() - 1, -1, -1):
		var wave = waves[i]
		wave.radius += 96 * delta
		if absf(player.distance_to(wave.p) - wave.radius) < 7 and not wave.hit:
			if hurt_player(20):
				wave.hit = true
		if wave.radius > 155:
			waves.remove_at(i)

func defeat_boss() -> void:
	projectiles.clear()
	waves.clear()
	blood(boss, 24)
	if boss_index == 4:
		letter_pos = boss + Vector2(-17, 13)
		state = "letter_pickup"
		notify("David 倒下了。一封信落在地上。")
	else:
		var next = "street" if boss_index == 0 else "next_boss"
		begin_dialogue(Story.BOSSES[boss_index].outro, next, "1006" if boss_index == 3 else "灵芝")

func drop_pad() -> void:
	pad_dropped = true
	pad_pos = player + Vector2(-21, 10)
	sound("pickup")
	notify("鼻托掉了！靠近地上的闪光，按 E 拾起。")

func interact() -> void:
	if state == "street":
		if pad_dropped and not pad_fixed and player.distance_to(pad_pos) < 28:
			state = "glasses"
			glass_pad = Vector2(300, 351)
			dragging_pad = false
		elif player.distance_to(Vector2(424, 114)) < 36:
			if not pad_fixed:
				notify("先找到鼻托，把眼镜修好。")
			else:
				state = "hospital"
				player = Vector2(73, 179)
				doctor_spoken = false
				scanned = false
	elif state == "hospital":
		if player.distance_to(Vector2(139, 131)) < 35:
			doctor_spoken = true
			begin_dialogue(["灵芝：刚才打完架，肚子突然很痛。", "医生：先去右边检查室做 CT。躺上检查床，保持不动。"], "hospital", "医院")
		elif player.distance_to(Vector2(325, 143)) < 43:
			if not doctor_spoken:
				notify("先到左侧诊台找医生。")
			elif not scanned:
				state = "ct"
				scan_time = 0
				player = Vector2(325, 155)
			else:
				notify("CT 检查已完成，前往右下方出口。")
		elif player.distance_to(Vector2(433, 198)) < 30:
			if scanned:
				start_boss(1)
			else:
				notify("完成检查后再离开医院。")
	elif state == "letter_pickup" and player.distance_to(letter_pos) < 30:
		state = "letter"
		sound("pickup")

func fit_pad(position_on_screen: Vector2) -> bool:
	if position_on_screen.distance_to(Vector2(491, 278)) > 28:
		glass_pad = Vector2(300, 351)
		return false
	pad_fixed = true
	dragging_pad = false
	state = "street"
	sound("pickup")
	notify("咔哒。看清楚了。继续去医院。")
	return true

func _input(event: InputEvent) -> void:
	if state == "title" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Rect2(56, 390, 435, 49).has_point(event.position):
		start_boss(0)
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if state != "glasses":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.distance_to(glass_pad) < 36:
			dragging_pad = true
		elif not event.pressed and dragging_pad:
			dragging_pad = false
			fit_pad(event.position)
	elif event is InputEventMouseMotion and dragging_pad:
		glass_pad = event.position

func blood(pos: Vector2, count: int) -> void:
	for i in range(count):
		particles.append({"p": pos, "v": Vector2.from_angle(randf() * TAU) * randf_range(18, 75), "life": randf_range(0.2, 0.5), "color": Color("b23e48")})
	stains.append({"p": pos + Vector2(randf_range(-10, 10), randf_range(-4, 7)), "size": Vector2(randf_range(5, 17), randf_range(3, 6))})
	if stains.size() > 65:
		stains.pop_front()

func notify(message: String) -> void:
	toast = message
	toast_time = 4.5

func update_effects(delta: float) -> void:
	shake = maxf(0, shake - delta * 24)
	hurt_flash = maxf(0, hurt_flash - delta)
	boss_flash = maxf(0, boss_flash - delta)
	toast_time = maxf(0, toast_time - delta)
	for i in range(particles.size() - 1, -1, -1):
		particles[i].p += particles[i].v * delta
		particles[i].life -= delta
		if particles[i].life <= 0:
			particles.remove_at(i)

func text_at(c: Node2D, text: String, pos: Vector2, size = 18, color = PAPER) -> void:
	c.draw_string(display_font if size >= 64 else font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(c: Node2D, text: String, y: float, size = 18, color = PAPER) -> void:
	var chosen_font = display_font if size >= 64 else font
	text_at(c, text, Vector2((960 - chosen_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x) / 2, y), size, color)

func panel(c: Node2D, rect: Rect2, color = Color("121820")) -> void:
	c.draw_rect(rect, color)
	c.draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), GOLD)

func paint_ui(c: Node2D) -> void:
	if state == "title":
		paint_title(c)
		return
	# Letterboxing leaves the world visible between the two editorial strips.
	c.draw_rect(Rect2(0, 0, 960, 77), Color("0b1018"))
	c.draw_rect(Rect2(0, 473, 960, 67), Color("0b1018"))
	text_at(c, "灵芝", Vector2(31, 29), 18, GOLD)
	c.draw_rect(Rect2(31, 41, 166, 7), Color("30333a"))
	c.draw_rect(Rect2(31, 41, 166 * player_hp / 100, 7), GOLD if player_hp > 30 else RED)
	text_at(c, "%02d" % int(player_hp), Vector2(207, 49), 14, MUTED)
	text_at(c, "DAVID DIE", Vector2(31, 66), 10, MUTED)
	var chapter = Story.BOSSES[boss_index]
	var heading = chapter.tag
	var ui_scene = "hospital" if state == "dialogue" and dialogue_next == "hospital" else state
	if ui_scene in ["street", "glasses"]:
		heading = "INTERLUDE / 去医院"
	elif ui_scene in ["hospital", "ct"]:
		heading = "INTERLUDE / CT 检查"
	text_at(c, heading, Vector2(300, 32), 17, GOLD)
	text_at(c, objective(), Vector2(300, 57), 13, MUTED)
	for i in range(5):
		c.draw_rect(Rect2(852 + i * 16, 26, 9, 9), GOLD if i <= boss_index else Color("343942"))
	text_at(c, "M " + ("静音" if muted else "声音"), Vector2(853, 59), 11, MUTED)
	if state == "fight" or (state == "dialogue" and dialogue_next == "fight"):
		centered(c, chapter.name, 103, 16)
		c.draw_rect(Rect2(320, 111, 320, 5), Color("34303a"))
		c.draw_rect(Rect2(320, 111, 320 * boss_hp / boss_max_hp, 5), RED)
		var ready_dash = dash_cd <= 0
		text_at(c, "闪避 " + ("就绪" if ready_dash else "%.1fs" % dash_cd), Vector2(750, 504), 14, GOLD if ready_dash else MUTED)
	text_at(c, "WASD / 方向键  移动     J / 左键  攻击     空格 / K  闪避", Vector2(31, 501), 13, MUTED)
	text_at(c, "E  互动 / 对话     ESC  暂停     F11  全屏", Vector2(31, 524), 12, MUTED)
	if toast_time > 0 and state not in ["dialogue", "glasses", "letter"]:
		panel(c, Rect2(140, 412, 680, 40))
		centered(c, toast, 438, 15)
	if state == "dialogue":
		panel(c, Rect2(48, 354, 864, 105), Color("121820"))
		text_at(c, speaker, Vector2(70, 381), 14, GOLD)
		text_at(c, dialogue[dialogue_index], Vector2(70, 412), 19)
		text_at(c, "%d / %d     E / ENTER  继续" % [dialogue_index + 1, dialogue.size()], Vector2(681, 443), 12, MUTED)
	elif state == "glasses":
		paint_glasses(c)
	elif state == "ct":
		panel(c, Rect2(260, 365, 440, 79))
		centered(c, "CT 扫描中 · 请保持不动", 394, 18, GOLD)
		c.draw_rect(Rect2(290, 414, 380, 6), Color("343e47"))
		c.draw_rect(Rect2(290, 414, 380 * minf(scan_time / 6, 1), 6), Color("7dbeb1"))
	elif state == "letter":
		paint_letter(c)
	elif state == "dead":
		c.draw_rect(Rect2(0, 77, 960, 396), Color(0.03, 0.04, 0.07, 0.85))
		centered(c, "再来一次。", 237, 46, RED)
		centered(c, "观察红色预警，在出招瞬间闪避。", 287, 18)
		centered(c, "ENTER  从这场战斗重试", 341, 17, GOLD)
	elif state == "paused":
		c.draw_rect(Rect2(0, 77, 960, 396), Color(0.03, 0.04, 0.07, 0.85))
		centered(c, "暂停", 251, 40, GOLD)
		centered(c, "ESC / ENTER  继续     M  切换声音", 305, 18)
	elif state == "ending":
		c.draw_rect(Rect2(0, 0, 960, 540), Color("0b1018"))
		centered(c, "DAVID DIED.", 219, 72, GOLD)
		centered(c, "灵芝收起了那封信。", 280, 23)
		centered(c, "五个对手。一副眼镜。一封信。", 328, 15, MUTED)
		centered(c, "ENTER  返回标题", 421, 17, GOLD)
	if hurt_flash > 0:
		c.draw_rect(Rect2(0, 0, 960, 540), Color(0.8, 0.13, 0.16, hurt_flash * 0.9))

func objective() -> String:
	var ui_scene = "hospital" if state == "dialogue" and dialogue_next == "hospital" else state
	match ui_scene:
		"street": return "找回并装好鼻托" if pad_dropped and not pad_fixed else "沿街走向右侧医院 · 门口按 E"
		"glasses": return "拖动鼻托，放进眼镜中央的虚线槽"
		"hospital": return "出口在右下方 · E 离开" if scanned else ("右侧 CT 检查床 · E 开始检查" if doctor_spoken else "左侧诊台 · E 找医生")
		"ct": return "完成 CT 检查"
		"letter_pickup": return "靠近地上的信 · E 拾取"
		_: return "击败 " + Story.BOSSES[boss_index].name + " · 躲开红色预警，收招时反击"

func paint_title(c: Node2D) -> void:
	c.draw_rect(Rect2(0, 0, 960, 540), Color(0.025, 0.035, 0.055, 0.32))
	c.draw_rect(Rect2(0, 0, 561, 540), Color("10151d"))
	c.draw_rect(Rect2(31, 33, 38, 3), RED)
	text_at(c, "一部关于灵芝的像素复仇短片", Vector2(82, 42), 14, MUTED)
	text_at(c, "DAVID", Vector2(54, 185), 100, GOLD)
	text_at(c, "DIE", Vector2(54, 283), 100, GOLD)
	c.draw_rect(Rect2(55, 301, 260, 8), RED)
	c.draw_rect(Rect2(274, 309, 8, 28), RED)
	text_at(c, "五个对手 / 一副眼镜 / 一封信", Vector2(59, 351), 17, PAPER)
	panel(c, Rect2(56, 390, 435, 49), GOLD)
	text_at(c, "ENTER     开始游戏", Vector2(78, 422), 22, Color("111820"))
	if checkpoint > 0:
		text_at(c, "E  继续第 %d 场战斗" % (checkpoint + 1), Vector2(59, 468), 15, GOLD)
	else:
		text_at(c, "WASD 移动 · J 攻击 · 空格闪避 · E 互动", Vector2(59, 469), 13, MUTED)
	text_at(c, "像素动作 / 单人     v0.1", Vector2(59, 511), 12, MUTED)
	text_at(c, "LINGZHI", Vector2(683, 412), 17, GOLD)
	text_at(c, "今晚，先找到 David。", Vector2(634, 440), 15)

func paint_glasses(c: Node2D) -> void:
	c.draw_rect(Rect2(0, 77, 960, 396), Color(0.025, 0.04, 0.07, 0.82))
	panel(c, Rect2(174, 114, 612, 334))
	centered(c, "先把眼镜修好。", 158, 25, GOLD)
	centered(c, "拖动下方的鼻托，放进中央金色虚线槽。", 191, 15, MUTED)
	for x in [296, 493]:
		c.draw_rect(Rect2(x, 222, 166, 86), Color("9aa6a8"), false, 5)
		c.draw_rect(Rect2(x + 9, 230, 148, 70), Color("223944"))
		c.draw_line(Vector2(x + 18, 284), Vector2(x + 60, 241), Color("4b626a"), 3)
	c.draw_line(Vector2(462, 244), Vector2(493, 244), GOLD, 4)
	c.draw_line(Vector2(296, 235), Vector2(253, 221), GOLD, 4)
	c.draw_line(Vector2(659, 235), Vector2(700, 221), GOLD, 4)
	c.draw_rect(Rect2(480, 262, 22, 31), Color("d7b85f"), false, 2)
	for y in range(265, 291, 7):
		c.draw_rect(Rect2(481, y, 3, 3), Color("121820"))
	c.draw_rect(Rect2(glass_pad - Vector2(8, 12), Vector2(16, 24)), PAPER)
	c.draw_rect(Rect2(glass_pad - Vector2(4, 8), Vector2(8, 16)), Color("a8b5b1"))
	text_at(c, "鼻托", Vector2(280, 394), 14, MUTED)
	text_at(c, "拿起 → 对准 → 松开", Vector2(449, 397), 14, GOLD)

func paint_letter(c: Node2D) -> void:
	c.draw_rect(Rect2(0, 0, 960, 540), Color(0.02, 0.025, 0.04, 0.91))
	c.draw_rect(Rect2(244, 63, 472, 410), Color("e7debf"))
	c.draw_rect(Rect2(258, 77, 444, 382), Color("d3c8a6"), false, 1)
	text_at(c, "一封信", Vector2(286, 126), 30, Color("252b31"))
	text_at(c, "从 David 身上掉落", Vector2(287, 155), 13, Color("6d6d63"))
	c.draw_line(Vector2(286, 175), Vector2(673, 175), Color("bab08f"), 1)
	var y = 218
	for line in Story.LETTER.split("\n"):
		text_at(c, line, Vector2(286, y), 17, Color("343a3d"))
		y += 31
	text_at(c, "E / ENTER  收好这封信", Vector2(286, 428), 15, Color("6d5145"))

func setup_preview(scene: String) -> void:
	saving_enabled = false
	match scene:
		"fight": start_boss(0, false)
		"cow": start_boss(3, false)
		"david": start_boss(4, false)
		"street":
			state = "street"
			player = Vector2(185, 161)
			drop_pad()
		"glasses":
			state = "glasses"
			pad_dropped = true
		"hospital", "ct":
			state = scene
			player = Vector2(256, 175)
			pad_fixed = true
			pad_dropped = true
			if scene == "ct": scan_time = 2.2
		"letter":
			boss_index = 4
			state = "letter"

func capture_screen() -> void:
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	image.save_png(screenshot_path)
	get_tree().quit()
