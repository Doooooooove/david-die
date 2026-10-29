extends Node2D

const Story = preload("res://story.gd")
const World = preload("res://world.gd")
const Hud = preload("res://hud.gd")
const GOLD = Color("e5c365")
const PAPER = Color("e9e2cb")
const MUTED = Color("8e969c")
const RED = Color("d45054")
const BOUNDS = Rect2(36, 87, 408, 139)
const COW_BOSS = 2
const FINAL_BOSS = 3
const WHALE_LAVA = Rect2(192, 142, 96, 90)
const RADIO_BRIDGE = Rect2(184, 174, 112, 36)
const SAVE_PATH = "user://checkpoint.cfg"
const SUPPORT_SPOT = Vector2(214, 174)
const DIFFICULTY_BUTTONS = [Rect2(615, 473, 88, 31), Rect2(710, 473, 88, 31), Rect2(805, 473, 88, 31)]
const PRACTICE_BUTTONS = [Rect2(147, 145, 318, 116), Rect2(495, 145, 318, 116), Rect2(147, 285, 318, 116), Rect2(495, 285, 318, 116)]
const SUPPORT_BUTTONS = [Rect2(180, 182, 600, 63), Rect2(180, 258, 600, 63), Rect2(180, 334, 600, 63)]
const RESULT_BUTTONS = [Rect2(180, 380, 186, 46), Rect2(387, 380, 186, 46), Rect2(594, 380, 186, 46)]
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
var checkpoint_perk = -1
var difficulty = 1
var cleared_bosses = 0
var best_times: Array = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var practice_mode = false
var practice_selection = 0
var fight_elapsed = 0.0
var hits_taken = 0
var perfect_dodges = 0
var new_record = false
var mechanism_used = false
var lure_armed = false
var reflect_time = 0.0
var active_perk = -1
var pending_perk = -1
var sidequest_done = false
var support_selection = 0
var tuning_frequency = 1000
var cargo_selection = 0
var sidequest_message = ""
var reel_time = 0.0
var reel_hits = 0
var reel_misses = 0
var reel_lock = 0.0
var saving_enabled = true
var save_path = SAVE_PATH
var clock = 0.0
var player = Vector2(100, 170)
var facing = Vector2.RIGHT
var player_hp = 100.0
var player_max_hp = 100.0
var boosted_boss = -1
var death_selection = 0
var death_message = ""
var upgrade_time = 0.0
const UPGRADE_DURATION = 3.2
const DEATH_BUTTONS = [Rect2(224, 225, 512, 55), Rect2(224, 292, 512, 55), Rect2(224, 359, 512, 55)]
const DEATH_OPTIONS = ["是", "否", "直接让高申给你升级"]
const JOURNAL_STATES = ["fight", "street", "hospital", "beach", "route", "dialogue"]
var move_dir = Vector2.ZERO
var attack_cd = 0.0
var slash_time = 0.0
var combo_step = 0
var combo_time = 0.0
var counter_time = 0.0
var dash_buffer = 0.0
var dash_rewarded = false
var heal_charges = 1
var combat_text = ""
var combat_text_time = 0.0
var phase_notice_time = 0.0
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
var boss_enraged = false
var slam_chain = 0
var attack_count = 0
var boss_flash = 0.0
var projectiles: Array[Dictionary] = []
var waves: Array[Dictionary] = []
var red_packets: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var stains: Array[Dictionary] = []
var death_count = 0
var shake = 0.0
var hitstop = 0.0
var dialogue: Array = []
var dialogue_index = 0
var dialogue_visible = 0.0
var journal_open = false
var journal_closed = false
var recovery_staggered = false
var perfume_spray = 0.0
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
var has_letter = false
var has_special_light = false
var special_light_on = false
var uv_active = false
var illumination = 0.0
var birthday_time = 0.0
var birthday_revealed = false
var has_parcel = false
var parcel_opened = false
var parcel_time = 0.0
const BIRTHDAY_PARCEL = Vector2(363, 215)
const ROUTE_EXIT = Vector2(426, 156)
const LETTER_PAGE = Rect2(66, 124, 390, 298)
const DARK_DOOR = Vector2(426, 112)
const LIGHT_STAND = Vector2(133, 132)
const LETTER_TABLE = Vector2(216, 165)
var muted = false
var toast = ""
var toast_time = 0.0
var screenshot_path = ""
var has_fishing_rod = false
var fishing_time = 0.0
const FISHING_ROD = Vector2(104, 187)
const FISHING_SPOT = Vector2(252, 154)

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
	var bindings = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "attack": [KEY_J], "dash": [KEY_SPACE, KEY_K], "heal": [KEY_Q], "interact": [KEY_E], "confirm": [KEY_ENTER], "pause_game": [KEY_ESCAPE], "mute": [KEY_M], "special_light": [KEY_F]}
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
	for name in ["slash", "hit", "dash", "pickup", "danger", "click", "upgrade", "spray"]:
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
	if save.load(save_path) == OK:
		var saved_chapter = int(save.get_value("game", "chapter", 0))
		if int(save.get_value("game", "roster_version", 1)) == 1 and saved_chapter >= 3:
			saved_chapter -= 1
		checkpoint = clampi(saved_chapter, 0, Story.BOSSES.size() - 1)
		difficulty = clampi(int(save.get_value("game", "difficulty", 1)), 0, 2)
		checkpoint_perk = clampi(int(save.get_value("game", "perk", -1)), -1, 2)
		cleared_bosses = int(save.get_value("game", "cleared", 0)) & 15
		for i in range(best_times.size()):
			best_times[i] = maxf(0, float(save.get_value("records", str(i), 0.0)))

func save_checkpoint() -> void:
	if not practice_mode:
		checkpoint = boss_index
		checkpoint_perk = active_perk
	if not saving_enabled:
		return
	var save = ConfigFile.new()
	save.load(save_path)
	save.set_value("game", "chapter", checkpoint)
	save.set_value("game", "roster_version", 2)
	save.set_value("game", "difficulty", difficulty)
	save.set_value("game", "perk", checkpoint_perk)
	save.set_value("game", "cleared", cleared_bosses)
	for i in range(best_times.size()): save.set_value("records", str(i), best_times[i])
	save.save(save_path)

func start_boss(index: int, with_intro = true) -> void:
	journal_open = false
	journal_closed = false
	recovery_staggered = false
	perfume_spray = 0
	if index != boss_index or with_intro:
		boosted_boss = -1
		active_perk = pending_perk
		pending_perk = -1
	mechanism_used = false
	lure_armed = false
	reflect_time = 0
	sidequest_done = false
	sidequest_message = ""
	fight_elapsed = 0
	hits_taken = 0
	perfect_dodges = 0
	new_record = false
	boss_index = index
	player = Vector2(98, 170)
	player_max_hp = 150.0 if boosted_boss == index else 100.0
	player_hp = player_max_hp
	death_selection = 0
	death_message = ""
	facing = Vector2.RIGHT
	boss = Vector2(346, 157)
	boss_max_hp = Story.BOSSES[index].hp * [0.85, 1.0, 1.25][difficulty]
	boss_hp = boss_max_hp
	boss_phase = "approach"
	boss_timer = 1.5
	attack_count = 0
	letter_pos = Vector2.ZERO
	has_letter = false
	has_special_light = false
	special_light_on = false
	uv_active = false
	illumination = 0
	birthday_time = 0
	birthday_revealed = false
	has_parcel = false
	parcel_opened = false
	parcel_time = 0
	boss_pattern = index
	boss_enraged = false
	slam_chain = 0
	attack_cd = 0
	slash_time = 0
	combo_step = 0
	combo_time = 0
	counter_time = 0
	dash_buffer = 0
	dash_rewarded = false
	heal_charges = 1 + (1 if difficulty == 0 else 0) + (1 if active_perk == 0 else 0)
	combat_text_time = 0
	phase_notice_time = 0
	hitstop = 0
	shake = 0
	dash_time = 0
	dash_cd = 0
	invulnerable = 0
	hurt_flash = 0
	boss_flash = 0
	projectiles.clear()
	waves.clear()
	red_packets.clear()
	particles.clear()
	stains.clear()
	has_fishing_rod = false
	fishing_time = 0
	state = "fight"
	if music.stream.resource_path.ends_with("birthday.wav"):
		change_music("night")
	save_checkpoint()
	if index == 1:
		boss = Vector2(314, 180)
	if index == 1 and with_intro:
		state = "beach"
		player = Vector2(65, 193)
		notify("通行牌在海里。先拿鱼竿，找到那只小蓝鲸。")
	elif with_intro:
		begin_dialogue(Story.BOSSES[index].intro, "fight", Story.BOSSES[index].place)

func begin_dialogue(lines: Array, next: String, who = "灵芝") -> void:
	dialogue = lines.duplicate()
	dialogue_index = 0
	dialogue_visible = 0
	dialogue_next = next
	speaker = who
	state = "dialogue"

func begin_story(resume = false) -> void:
	practice_mode = false
	pending_perk = checkpoint_perk if resume else -1
	start_boss(checkpoint if resume else 0)

func open_practice() -> void:
	practice_mode = true
	practice_selection = 0
	state = "practice_select"
	toast_time = 0

func boss_unlocked(index: int) -> bool:
	return index <= checkpoint or (cleared_bosses & (1 << index)) != 0

func start_practice(index: int) -> void:
	if not boss_unlocked(index):
		notify("在主线遇见这位对手后，才能在练习场挑战。")
		return
	practice_mode = true
	active_perk = -1
	pending_perk = -1
	boosted_boss = -1
	start_boss(index, false)

func try_mechanism() -> bool:
	if state != "fight" or mechanism_used or player.distance_to(Story.MECHANISMS[boss_index].pos) > 31:
		return false
	if boss_index == COW_BOSS and not red_packets.any(func(packet): return packet.remaining > 0):
		combat_text = "1006：尚无可退订红包。等红包雨出现再按 E。"
		combat_text_time = 1.8
		return false
	mechanism_used = true
	match boss_index:
		0:
			boss_phase = "recover"
			boss_timer = 4.0
			recovery_staggered = false
			combat_text = "看电影的人：谁按了暂停？现在可以反击！"
		1:
			lure_armed = true
			if boss_phase == "windup": target_whale_slam()
			combat_text = "FM 100.6 开播！下一次飞砸会落在桥中央。"
		2:
			red_packets.clear()
			player_hp = minf(player_max_hp, player_hp + 15)
			boss_phase = "recover"
			boss_timer = 1.8
			recovery_staggered = false
			combat_text = "退订成功！红包取消，恢复 15 体力。"
		3:
			reflect_time = 4.5
			combat_text = "退件反射板开启！附近弹丸将原路退回。"
	combat_text_time = 2.2
	sound("pickup")
	return true

func target_whale_slam() -> void:
	boss_target = RADIO_BRIDGE.get_center() if lure_armed else Vector2(clampf(player.x, 49, 431), clampf(player.y, 150, 214))
	lure_armed = false

func reel_position() -> float:
	return 0.5 - cos(reel_time * 2.5) * 0.5

func reel_window() -> float:
	return minf(0.5, 0.17 + reel_misses * 0.12 + (0.06 if difficulty == 0 else 0.0))

func attempt_reel() -> void:
	if state != "reeling" or reel_lock > 0: return
	reel_lock = 0.45
	if absf(reel_position() - 0.5) <= reel_window():
		reel_hits += 1
		sidequest_message = "稳稳收线！%d / 2" % reel_hits
		sound("pickup")
		if reel_hits >= 2:
			state = "fished"
			fishing_time = 0
	else:
		reel_misses += 1
		sidequest_message = "别急，鱼还在。绿色区变宽了，再试一次。"
		sound("click")

func submit_sidequest() -> void:
	if state != "sidequest": return
	var solved = tuning_frequency == 1006 if boss_index == 1 else cargo_selection == 1
	if solved:
		state = "support"
		support_selection = 0
		sidequest_message = "高申：听到了！给你准备了一份支援。" if boss_index == 1 else "高申：就是这个名字。支援箱归你啦。"
		sound("pickup")
	else:
		sidequest_message = "桥头的频道是 FM 100.6，再调一下。" if boss_index == 1 else "名字差一点。认准高申的“申”，没有多一笔。"
		sound("click")

func choose_support(index: int) -> void:
	if state != "support" or index < 0 or index >= Story.PERKS.size(): return
	pending_perk = index
	sidequest_done = true
	state = "route"
	notify("已备好" + Story.PERKS[index].name + "，下一战生效，重试也保留。")
	sound("pickup")

func advance_dialogue() -> void:
	if dialogue_index < dialogue.size() and dialogue_visible < dialogue[dialogue_index].length():
		dialogue_visible = dialogue[dialogue_index].length()
		return
	sound("click")
	dialogue_index += 1
	dialogue_visible = 0
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
		"route":
			state = "route"
			player = Vector2(60, 181)
			move_dir = Vector2.ZERO
			stains.clear()
			particles.clear()
			toast_time = 0
		"hospital": state = "hospital"
		_: state = dialogue_next

func _process(delta: float) -> void:
	clock += delta
	if not screenshot_path.is_empty():
		refresh()
		return
	if journal_open:
		refresh()
		return
	if journal_closed:
		journal_closed = false
		refresh()
		return
	if Input.is_action_just_pressed("mute"):
		muted = not muted
		music.stream_paused = muted
		if not muted and not music.playing:
			music.play()
	if Input.is_action_just_pressed("pause_game"):
		if state == "paused":
			state = previous_state
		elif state not in ["title", "parcel_opening", "ending", "dead", "upgrading", "practice_select", "practice_result", "sidequest", "support"]:
			previous_state = state
			state = "paused"
	if state == "paused":
		if Input.is_action_just_pressed("confirm"):
			state = previous_state
		refresh()
		return
	if state == "title":
		if Input.is_action_just_pressed("confirm"):
			begin_story()
		elif Input.is_action_just_pressed("interact") and checkpoint > 0:
			begin_story(true)
	elif state == "dialogue":
		dialogue_visible = minf(dialogue[dialogue_index].length(), dialogue_visible + delta * 38)
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
			advance_dialogue()
	elif state == "upgrading":
		update_upgrade(delta)
	elif state == "letter":
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm"):
			state = "aftermath"
	elif state == "illuminate":
		if Input.is_action_just_pressed("special_light"):
			special_light_on = not special_light_on
			sound("click")
		update_special_light(delta, special_light_on, get_global_mouse_position())
		if state == "illuminate" and Input.is_action_just_pressed("interact"):
			state = "darkroom"
			uv_active = false
			special_light_on = false
	elif state == "birthday_reveal":
		update_birthday(delta)
		if birthday_time >= 3 and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("confirm")):
			state = "birthday"
	elif state == "birthday":
		update_player(delta)
		if Input.is_action_just_pressed("interact"):
			interact()
	elif state == "parcel_opening":
		parcel_time += delta
		if parcel_time >= 2.4:
			parcel_opened = true
			state = "ending"
			sound("pickup")
	elif state == "ending":
		perfume_spray = maxf(0, perfume_spray - delta)
		if Input.is_action_just_pressed("interact"):
			perfume_spray = 1.6
			sound("spray")
		if Input.is_action_just_pressed("confirm"):
			state = "title"
	elif state == "ct":
		scan_time += delta
		if scan_time >= 6.0:
			scanned = true
			begin_dialogue(["医生看了看 CT，陷入沉思。", "医生：肚子没找到快递。建议去海边查一下。", "灵芝：……我本来也要去。", "医生：报告收好，坐一会儿再走。出口在右下方。", "高申：人缓过来就好。海边的通行牌，我们慢慢找。"], "hospital", "检查室")
	elif state == "fishing":
		fishing_time += delta
		if Input.is_action_just_pressed("interact"):
			interact()
	elif state == "reeling":
		reel_time += delta
		reel_lock = maxf(0, reel_lock - delta)
		if Input.is_action_just_pressed("interact"):
			attempt_reel()
	elif state == "fished":
		fishing_time += delta
		if fishing_time >= 1.2:
			begin_dialogue(Story.BOSSES[1].intro, "fight", "DeepSeek 小鲸鱼")
	elif state in ["fight", "street", "hospital", "beach", "route", "letter_pickup", "aftermath", "darkroom"]:
		if state == "fight": fight_elapsed += delta
		if state == "fight" and Input.is_action_just_pressed("heal"):
			try_heal()
		if hitstop > 0:
			hitstop -= delta
		else:
			update_player(delta)
			if state == "fight":
				if Input.is_action_just_pressed("interact"): try_mechanism()
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
	reflect_time = maxf(0, reflect_time - delta)
	attack_cd = maxf(attack_cd - delta, 0)
	slash_time = maxf(slash_time - delta, 0)
	dash_cd = maxf(dash_cd - delta, 0)
	invulnerable = maxf(invulnerable - delta, 0)
	combo_time = maxf(combo_time - delta, 0)
	counter_time = maxf(counter_time - delta, 0)
	dash_buffer = maxf(dash_buffer - delta, 0)
	if combo_time <= 0 and slash_time <= 0:
		combo_step = 0
	move_dir = Input.get_vector("left", "right", "up", "down")
	if move_dir.length() > 0:
		facing = move_dir
	if state == "fight" and Input.is_action_just_pressed("dash"):
		dash_buffer = 0.14
	if state == "fight" and dash_buffer > 0 and dash_cd <= 0:
		try_dash()
	var speed = 94.0 if state == "fight" else (116.0 if Input.is_action_pressed("dash") else 80.0)
	if dash_time > 0:
		dash_time = maxf(dash_time - delta, 0)
		player += dash_dir * 310 * delta
		if randf() < 0.6:
			particles.append({"p": player, "v": Vector2.ZERO, "life": 0.22, "color": GOLD})
	else:
		player += move_dir * speed * delta
	player.x = clampf(player.x, BOUNDS.position.x, BOUNDS.end.x)
	player.y = clampf(player.y, BOUNDS.position.y, BOUNDS.end.y)
	if boss_index == 1 and state in ["beach", "fight"]:
		player.y = maxf(player.y, 150)
	if state == "route":
		player.y = clampf(player.y, 143, 198 if boss_index == 1 else 214)
	if state == "fight" and Input.is_action_pressed("attack"):
		try_attack()

func try_dash() -> bool:
	if state != "fight" or dash_cd > 0:
		return false
	dash_dir = move_dir if move_dir.length() > 0 else facing
	dash_time = 0.18
	dash_cd = 0.72 * (0.82 if active_perk == 1 else 1.0)
	dash_buffer = 0
	dash_rewarded = false
	invulnerable = maxf(invulnerable, 0.29)
	sound("dash")
	return true

func try_attack() -> bool:
	if state != "fight" or attack_cd > 0 or dash_time > 0:
		return false
	combo_step = combo_step % 3 + 1 if combo_time > 0 else 1
	combo_time = 0.85
	var heavy = combo_step == 3
	attack_cd = 0.42 if heavy else 0.23
	slash_time = 0.20 if heavy else 0.13
	# 近距离自动朝向对手，键盘和鼠标攻击拥有相同的命中规则。
	if player.distance_to(boss) < 63:
		facing = (boss - player).normalized()
	sound("slash")
	if player.distance_to(boss) < (53 if heavy else 44):
		var damage: float = (18 if heavy else 10) if boss_phase == "recover" else (8 if heavy else 4)
		if counter_time > 0:
			damage += 12 + (8 if active_perk == 2 else 0)
		if boosted_boss == boss_index:
			damage *= 1.5
		if hit_boss(damage):
			if heavy and state == "fight" and boss_phase == "recover" and not recovery_staggered:
				recovery_staggered = true
				boss_timer += 0.45
				combat_text = "重斩失衡！破绽延长"
				combat_text_time = 1.1
			if counter_time > 0:
				counter_time = 0
				combat_text = "闪避反击！"
				combat_text_time = 1.1
	return true

func hit_boss(damage: float) -> bool:
	if state != "fight" or boss_hp <= 0 or (boss_index == 1 and boss_phase == "airborne"):
		return false
	boss_hp = maxf(0, boss_hp - damage)
	particles.append({"p": boss - Vector2(5, 30), "v": Vector2(0, -18), "life": 0.65, "color": GOLD, "text": str(int(damage))})
	if boss_hp > 0 and boss_hp <= boss_max_hp * 0.5 and not boss_enraged:
		boss_enraged = true
		combat_text = Story.PHASE_LINES[boss_index]
		combat_text_time = 2.2
		phase_notice_time = 2.2
	boss_flash = 0.13
	shake = 3
	hitstop = 0.045
	blood(boss, 9)
	sound("hit")
	if boss_hp <= 0:
		defeat_boss()
	return true

func try_heal() -> bool:
	if state != "fight" or heal_charges <= 0 or player_hp >= player_max_hp:
		return false
	heal_charges -= 1
	var recovered = minf(35, player_max_hp - player_hp)
	player_hp += recovered
	invulnerable = maxf(invulnerable, 0.3)
	combat_text = "应急补给 · 恢复 %d 体力" % int(recovered)
	combat_text_time = 1.3
	sound("pickup")
	return true

func hurt_player(damage: float) -> bool:
	if state != "fight":
		return false
	if invulnerable > 0:
		if dash_time > 0 and not dash_rewarded:
			perfect_dodges += 1
			dash_rewarded = true
			counter_time = 1.4
			dash_cd = maxf(0, dash_cd - 0.18)
			combat_text = "漂亮闪避！下一击可反击"
			combat_text_time = 1.2
			sound("pickup")
		return false
	hits_taken += 1
	player_hp = maxf(0, player_hp - damage * [0.6, 1.0, 1.25][difficulty])
	invulnerable = 0.7
	hurt_flash = 0.18
	shake = 4
	blood(player, 7)
	sound("hit")
	if player_hp <= 0:
		death_count += 1
		death_selection = 0
		death_message = ""
		state = "dead"
	return true

func choose_death_option(choice: int) -> void:
	if state != "dead" or choice < 0 or choice >= DEATH_OPTIONS.size():
		return
	death_selection = choice
	if choice == 1:
		death_message = "高申：行，我在旁边等你。想好了再叫我。"
		sound("click")
	elif choice == 0:
		start_boss(boss_index, false)
		combat_text = "高申：扶你起来了，再试一次。"
		combat_text_time = 2
		sound("pickup")
	else:
		state = "upgrading"
		upgrade_time = 0
		projectiles.clear()
		waves.clear()
		red_packets.clear()
		particles.clear()
		music.stream_paused = true
		sound("upgrade")

func update_upgrade(delta: float) -> void:
	upgrade_time = minf(UPGRADE_DURATION, upgrade_time + delta)
	if upgrade_time >= UPGRADE_DURATION:
		boosted_boss = boss_index
		start_boss(boss_index, false)
		music.stream_paused = muted
		combat_text = "高申：升级好了，去把快递拿回来。"
		combat_text_time = 2.5

func update_boss(delta: float) -> void:
	boss_timer -= delta
	match boss_phase:
		"approach":
			var distance = boss.distance_to(player)
			if distance > 34:
				boss += (player - boss).normalized() * (35 + boss_index * 3) * delta
			if boss_timer <= 0:
				boss_pattern = attack_count % 4 if boss_index == FINAL_BOSS else boss_index
				if boss_index == 0 and boss_enraged and attack_count % 2 == 1:
					boss_pattern = 3
				if boss_index == FINAL_BOSS and boss_enraged:
					boss_pattern = [1, 3, 2, 3][attack_count % 4]
				if boss_index == COW_BOSS:
					boss_pattern = 4 if attack_count % 2 == 0 else 3
				boss_phase = "windup"
				boss_timer = (0.78 if boss_index < FINAL_BOSS else 0.64) * [1.25, 1.0, 0.9][difficulty]
				boss_target = player
				slam_chain = 0
				if boss_index == 1:
					target_whale_slam()
				boss_dir = (player - boss).normalized()
				if boss_index == 1 and attack_count == 0:
					combat_text = "DeepSeek：正在思考……"
					combat_text_time = 0.8
				sound("danger")
		"windup":
			if boss_timer <= 0:
				perform_boss_attack()
		"airborne":
			if boss_timer <= 0:
				boss = boss_target
				if player.distance_to(boss_target) < 26:
					hurt_player(24)
				shake = 5
				particles.append({"p": boss, "v": Vector2.ZERO, "life": 0.25, "color": Color("85d5e8"), "ring": true})
				if boss_enraged and slam_chain == 0:
					slam_chain = 1
					target_whale_slam()
					boss_phase = "windup"
					boss_timer = 0.7 * [1.25, 1.0, 0.9][difficulty]
					combat_text = "DeepSeek：刚才的回答不够全面。"
					combat_text_time = 0.7
					sound("danger")
				else:
					boss_phase = "recover"
					boss_timer = 1.5 if boss_enraged else 1.3
		"charge":
			boss += boss_dir * 300 * delta
			if boss.distance_to(player) < 23:
				hurt_player(24)
			var hit_wall = boss.x < 49 or boss.x > 431 or boss.y < 97 or boss.y > 214
			if hit_wall or boss_timer <= 0:
				boss_phase = "recover"
				boss_timer = 1.8 if hit_wall else 1.25
				if hit_wall:
					combat_text = "1006：导航未提示有墙。趁现在反击！" if boss_index == COW_BOSS else "撞墙了！靠近打出三连击"
					combat_text_time = 1.5
					shake = 4
		"recover":
			if boss_timer <= 0:
				boss_phase = "approach"
				boss_timer = 0.9
	boss.x = clampf(boss.x, 49, 431)
	boss.y = clampf(boss.y, 97, 214)
	if boss_index == 1:
		boss.y = maxf(boss.y, 150)

func perform_boss_attack() -> void:
	recovery_staggered = false
	attack_count += 1
	boss_phase = "recover"
	boss_timer = 1.08
	match boss_pattern:
		0:
			if boss.distance_to(player) < 53:
				hurt_player(19)
			particles.append({"p": boss, "v": Vector2.ZERO, "life": 0.25, "color": RED, "ring": true})
		1:
			if boss_index == 1:
				boss_phase = "airborne"
				boss_timer = 1.0
				if slam_chain == 1 or attack_count == 1:
					combat_text = "DeepSeek：我补充一下。" if slam_chain == 1 else "DeepSeek：经过深度思考，我决定砸你。"
					combat_text_time = 1.1
			else:
				for angle in [-0.32, 0.0, 0.32]:
					projectiles.append({"p": boss, "v": boss_dir.rotated(angle) * 125, "life": 3.5})
		2:
			waves.append({"p": boss, "radius": 8.0, "hit": false})
		3:
			boss_phase = "charge"
			boss_timer = 0.58
		4:
			if boss_index == COW_BOSS and attack_count == 1:
				combat_text = "1006：恭喜发财，注意躲避！"
				combat_text_time = 1.3
			# Every landing has its own warning; the first envelope targets the
			# player's current position, while the others leave gaps to escape.
			red_packets.append({"p": player, "remaining": 0.9})
			for i in range(8 if boss_enraged else 6):
				var target = Vector2(64 + i * 46, 123 + (i % 3) * 35) if boss_enraged else Vector2(76 + i * 61, 123 + (i % 3) * 35)
				red_packets.append({"p": target, "remaining": 1.05 + i * 0.09})
			boss_timer = 1.7
	sound("slash")

func update_attacks(delta: float) -> void:
	if state == "fight" and boss_index == 1 and WHALE_LAVA.has_point(player) and not RADIO_BRIDGE.has_point(player) and invulnerable <= 0:
		if hurt_player(12):
			combat_text = "烫烫烫！回到收音机桥或两侧岸边"
			combat_text_time = 1.4
	for i in range(red_packets.size() - 1, -1, -1):
		var packet = red_packets[i]
		var before: float = packet.remaining
		packet.remaining -= delta
		if before > 0 and packet.remaining <= 0:
			if player.distance_to(packet.p) < 18:
				if hurt_player(16) and boss_index == COW_BOSS and attack_count == 1:
					combat_text = "灵芝：红包怎么还扣血？  1006：运费到付。"
					combat_text_time = 1.6
			for j in range(8):
				particles.append({"p": packet.p, "v": Vector2.from_angle(j * TAU / 8) * 28, "life": 0.4, "color": GOLD if j % 2 else RED})
		if packet.remaining < -0.3:
			red_packets.remove_at(i)
	for i in range(projectiles.size() - 1, -1, -1):
		var shot = projectiles[i]
		shot.p += shot.v * delta
		shot.life -= delta
		if not shot.get("friendly", false) and reflect_time > 0 and shot.p.distance_to(player) < 30:
			shot.friendly = true
			shot.v = (boss - shot.p).normalized() * 190
			sound("pickup")
		if shot.get("friendly", false):
			if shot.p.distance_to(boss) < 18:
				hit_boss(18)
				if state != "fight": return
				projectiles.remove_at(i)
			elif shot.life < 0 or not BOUNDS.grow(15).has_point(shot.p): projectiles.remove_at(i)
		elif shot.p.distance_to(player) < 11:
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
	red_packets.clear()
	blood(boss, 24)
	if practice_mode:
		var record = difficulty * 4 + boss_index
		if boosted_boss != boss_index and fight_elapsed > 0 and (best_times[record] == 0 or fight_elapsed < best_times[record]):
			best_times[record] = fight_elapsed
			new_record = true
		state = "practice_result"
		save_checkpoint()
		return
	cleared_bosses |= 1 << boss_index
	save_checkpoint()
	if boss_index == FINAL_BOSS:
		letter_pos = boss + Vector2(-17, 13)
		begin_dialogue(Story.BOSSES[FINAL_BOSS].outro, "letter_pickup", "David")
	else:
		var next = "street" if boss_index == 0 else "route"
		begin_dialogue(Story.BOSSES[boss_index].outro, next, "1006" if boss_index == COW_BOSS else "灵芝")

func drop_pad() -> void:
	pad_dropped = true
	pad_pos = player + Vector2(-21, 10)
	sound("pickup")
	notify("您的鼻托已离职。靠近地上闪光，按 E 追回。")

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
	elif state == "beach":
		if not has_fishing_rod and player.distance_to(FISHING_ROD) < 30:
			has_fishing_rod = true
			sound("pickup")
			notify("拿到鱼竿。走到海边的钓鱼点，按 E 抛竿。")
		elif player.distance_to(FISHING_SPOT) < 30:
			if not has_fishing_rod:
				notify("先拿起沙滩上的鱼竿。")
			else:
				state = "fishing"
				player = FISHING_SPOT
				fishing_time = 0
				move_dir = Vector2.ZERO
				slash_time = 0
				toast_time = 0
				sound("click")
	elif state == "fishing":
		if fishing_time >= 1.8:
			state = "reeling"
			reel_time = 0
			reel_hits = 0
			reel_misses = 0
			reel_lock = 0
			sidequest_message = "游标进入绿色区时按 E / 点击收线，成功两次就能钓起。"
	elif state == "route":
		if not sidequest_done and player.distance_to(SUPPORT_SPOT) < 30:
			state = "sidequest"
			tuning_frequency = 1000
			cargo_selection = 0
			sidequest_message = ""
		elif player.distance_to(ROUTE_EXIT) < 30:
			start_boss(boss_index + 1)
	elif state == "letter_pickup" and player.distance_to(letter_pos) < 30:
		has_letter = true
		has_parcel = true
		state = "letter"
		sound("pickup")
	elif state == "aftermath" and player.distance_to(DARK_DOOR) < 32 and has_letter:
		state = "darkroom"
		player = Vector2(62, 181)
		move_dir = Vector2.ZERO
		stains.clear()
		particles.clear()
		toast_time = 0
		notify("很暗。左侧有一盏泛着紫光的小灯。")
	elif state == "darkroom":
		if player.distance_to(LIGHT_STAND) < 34 and not has_special_light:
			has_special_light = true
			sound("pickup")
			notify("获得特殊光源。走到桌边按 E 放下信。")
		elif player.distance_to(LETTER_TABLE) < 37:
			if has_special_light and has_letter:
				state = "illuminate"
				illumination = 0
				special_light_on = false
				move_dir = Vector2.ZERO
				toast_time = 0
			else:
				notify("先找到房间左侧的特殊光源。")
	elif state == "birthday" and player.distance_to(BIRTHDAY_PARCEL) < 32 and has_parcel and birthday_revealed:
		state = "parcel_opening"
		parcel_time = 0
		move_dir = Vector2.ZERO
		sound("click")

func update_special_light(delta: float, light_on: bool, aim: Vector2) -> void:
	uv_active = state == "illuminate" and has_letter and has_special_light and light_on and LETTER_PAGE.has_point(aim)
	if not uv_active:
		if state == "illuminate": illumination = maxf(0, illumination - delta)
		return
	illumination = minf(2.2, illumination + delta)
	if illumination >= 2.2:
		state = "birthday_reveal"
		birthday_time = 0
		uv_active = false
		special_light_on = false
		music.stream_paused = true

func update_birthday(delta: float) -> void:
	birthday_time += delta
	if birthday_time >= 1 and not birthday_revealed:
		birthday_revealed = true
		change_music("birthday")
		sound("pickup")

func change_music(track: String) -> void:
	var stream = load("res://assets/" + track + ".wav") as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.stream = stream
	music.stream_paused = muted
	if not muted:
		music.play()

func fit_pad(position_on_screen: Vector2) -> bool:
	if position_on_screen.distance_to(Vector2(491, 278)) > 28:
		glass_pad = Vector2(300, 351)
		return false
	pad_fixed = true
	dragging_pad = false
	state = "street"
	sound("pickup")
	notify("返聘成功。看清楚了，继续去医院。")
	return true

func _input(event: InputEvent) -> void:
	if state == "title":
		if event is InputEventKey and event.pressed and not event.echo:
			var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if key in [KEY_LEFT, KEY_A]: difficulty = posmod(difficulty - 1, 3)
			elif key in [KEY_RIGHT, KEY_D]: difficulty = (difficulty + 1) % 3
			elif key == KEY_R:
				open_practice()
				return
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for i in range(3):
				if DIFFICULTY_BUTTONS[i].has_point(event.position):
					difficulty = i
					return
			if Rect2(56, 465, 435, 28).has_point(event.position):
				open_practice()
				return
	if state in ["practice_select", "practice_result", "sidequest", "support"]:
		if event is InputEventKey and event.pressed and not event.echo:
			var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if key == KEY_ESCAPE:
				state = "title" if practice_mode else "route"
				practice_mode = false
				journal_closed = true
			elif state == "practice_result":
				if key == KEY_R: start_practice(boss_index)
				elif key in [KEY_E, KEY_ENTER]: open_practice()
			elif key in [KEY_A, KEY_LEFT, KEY_W, KEY_UP, KEY_D, KEY_RIGHT, KEY_S, KEY_DOWN]:
				var direction = -1 if key in [KEY_A, KEY_LEFT, KEY_W, KEY_UP] else 1
				if state == "practice_select" and key in [KEY_W, KEY_UP, KEY_S, KEY_DOWN]: direction *= 2
				change_activity_choice(direction)
			elif key in [KEY_ENTER, KEY_E]:
				if state == "practice_select": start_practice(practice_selection)
				elif state == "support": choose_support(support_selection)
				else: submit_sidequest()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if state == "practice_select":
				for i in range(4):
					if PRACTICE_BUTTONS[i].has_point(event.position):
						practice_selection = i
						start_practice(i)
			elif state == "support":
				for i in range(3):
					if SUPPORT_BUTTONS[i].has_point(event.position): choose_support(i)
			elif state == "practice_result":
				if RESULT_BUTTONS[0].has_point(event.position): start_practice(boss_index)
				elif RESULT_BUTTONS[1].has_point(event.position): open_practice()
				elif RESULT_BUTTONS[2].has_point(event.position):
					state = "title"
					practice_mode = false
			else:
				if Rect2(236, 241, 70, 58).has_point(event.position): change_activity_choice(-1)
				elif Rect2(654, 241, 70, 58).has_point(event.position): change_activity_choice(1)
				elif Rect2(330, 363, 300, 46).has_point(event.position): submit_sidequest()
		return
	if state == "reeling" and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(330, 376, 300, 43).has_point(event.position): attempt_reel()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if journal_open:
			if key in [KEY_TAB, KEY_ESCAPE]:
				journal_open = false
				journal_closed = true
			return
		if key == KEY_TAB and state in JOURNAL_STATES:
			journal_open = true
			return
	if journal_open:
		return
	if state == "dead":
		if event.is_action_pressed("up"):
			death_selection = posmod(death_selection - 1, DEATH_OPTIONS.size())
		elif event.is_action_pressed("down"):
			death_selection = (death_selection + 1) % DEATH_OPTIONS.size()
		elif event.is_action_pressed("confirm") or event.is_action_pressed("interact"):
			choose_death_option(death_selection)
		elif event is InputEventKey and event.pressed and not event.echo:
			var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if key in [KEY_1, KEY_2, KEY_3]:
				choose_death_option(key - KEY_1)
		elif event is InputEventMouseMotion:
			for i in range(DEATH_BUTTONS.size()):
				if DEATH_BUTTONS[i].has_point(event.position): death_selection = i
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			for i in range(DEATH_BUTTONS.size()):
				if DEATH_BUTTONS[i].has_point(event.position):
					choose_death_option(i)
		return
	if state == "fight" and event.is_action_pressed("dash"):
		dash_buffer = 0.14
	if state == "illuminate" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and LETTER_PAGE.has_point(event.position):
		special_light_on = true
		sound("click")
	if state == "title" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Rect2(56, 390, 435, 49).has_point(event.position):
		begin_story()
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

func change_activity_choice(direction: int) -> void:
	if state == "practice_select": practice_selection = posmod(practice_selection + direction, 4)
	elif state == "support": support_selection = posmod(support_selection + direction, 3)
	elif state == "sidequest":
		if boss_index == 1: tuning_frequency = clampi(tuning_frequency + direction, 980, 1030)
		else: cargo_selection = posmod(cargo_selection + direction, 3)

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
	combat_text_time = maxf(0, combat_text_time - delta)
	phase_notice_time = maxf(0, phase_notice_time - delta)
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

func paint_death(c: Node2D) -> void:
	c.draw_rect(Rect2(0, 77, 960, 396), Color(0.025, 0.035, 0.065, 0.96))
	centered(c, "灵芝暂时掉线了", 145, 16, RED)
	centered(c, "要不要让高申帮你复活？", 195, 29, PAPER)
	var descriptions = ["恢复体力，重试当前 Boss", "先躺一会儿，想好了还能改主意", "本关体力上限 150 · 攻击 ×1.5"]
	if boosted_boss == boss_index:
		descriptions[2] = "本关强化已开启 · 再次升级不叠加"
	for i in range(DEATH_BUTTONS.size()):
		var button: Rect2 = DEATH_BUTTONS[i]
		var selected = i == death_selection
		var accent = Color("99e5ee") if i < 2 else Color("caabff")
		c.draw_rect(button, Color("24243e") if selected else Color("151c2a"))
		c.draw_rect(button, accent if selected else Color("3b4358"), false, 2 if selected else 1)
		c.draw_rect(Rect2(button.position, Vector2(4, button.size.y)), accent)
		text_at(c, str(i + 1), button.position + Vector2(18, 33), 20, accent)
		text_at(c, DEATH_OPTIONS[i], button.position + Vector2(57, 24), 20, accent if selected else PAPER)
		text_at(c, descriptions[i], button.position + Vector2(57, 44), 12, MUTED)
	centered(c, death_message if not death_message.is_empty() else "↑↓ / W S 选择 · Enter / E 确认 · 数字 1 / 2 / 3 或鼠标直接选", 446, 13, GOLD if not death_message.is_empty() else MUTED)

func wrapped_text(c: Node2D, value: String, pos: Vector2, width: float, size: int, color: Color) -> void:
	var line = ""
	for character in value:
		if character == "\n" or font.get_string_size(line + character, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			text_at(c, line, pos, size, color)
			pos.y += size + 7
			line = "" if character == "\n" else character
		else:
			line += character
	text_at(c, line, pos, size, color)

func journal_stage() -> int:
	var scene = dialogue_next if state == "dialogue" else state
	if boss_index == 0:
		return 1 if scene in ["street", "glasses", "hospital", "ct"] else 0
	if boss_index == 1:
		return 3 if scene == "route" else 2
	return 4 if boss_index == FINAL_BOSS or scene == "route" else 3

func paint_journal(c: Node2D) -> void:
	c.draw_rect(Rect2(0, 0, 960, 540), Color(0.02, 0.03, 0.05, 0.9))
	panel(c, Rect2(91, 73, 778, 398), Color("17212b"))
	text_at(c, "快递追踪", Vector2(125, 118), 29, GOLD)
	text_at(c, "收件人：高申   /   查件员：灵芝", Vector2(125, 145), 14, MUTED)
	var stage = journal_stage()
	for i in range(Story.TASKS.size()):
		var y = 185 + i * 50
		var color = GOLD if i == stage else (Color("9ed5c5") if i < stage else MUTED)
		if i == stage: c.draw_rect(Rect2(115, y - 23, 295, 40), Color("2c3942"))
		text_at(c, "完成" if i < stage else ("当前" if i == stage else "待查"), Vector2(128, y), 12, color)
		text_at(c, Story.TASKS[i].title, Vector2(171, y), 16, color)
	c.draw_line(Vector2(431, 171), Vector2(431, 408), Color("38434c"), 1)
	text_at(c, "已知线索", Vector2(459, 187), 17, GOLD)
	wrapped_text(c, Story.TASKS[stage].clue, Vector2(459, 218), 365, 17, PAPER)
	text_at(c, "接下来", Vector2(459, 326), 17, GOLD)
	wrapped_text(c, Story.MECHANISMS[boss_index].description if state == "fight" and not mechanism_used else (Story.COMBAT_HINTS[boss_index] if state == "fight" else ("读完对话，按 E / Enter 继续行动。" if state == "dialogue" else objective())), Vector2(459, 355), 365, 15, PAPER)
	text_at(c, "已暂停 · TAB / ESC 收起手账", Vector2(459, 443), 13, MUTED)

func paint_dialogue(c: Node2D) -> void:
	var line: String = dialogue[dialogue_index]
	var separator = line.find("：")
	if line.substr(0, separator) not in ["灵芝", "高申", "医生", "DeepSeek", "1006", "David", "看电影的人"]:
		separator = -1
	var voice = line.substr(0, separator) if separator >= 0 else "旁白"
	var prefix = separator + 1 if separator >= 0 else 0
	var body = line.substr(prefix, maxi(0, int(dialogue_visible) - prefix))
	panel(c, Rect2(48, 344, 864, 116), Color("121d28"))
	c.draw_rect(Rect2(65, 360, 79, 80), Color("263842"))
	var rows = World.PLAYER if voice == "灵芝" else (World.COW if voice == "1006" else (World.WHALE if voice == "DeepSeek" else World.AGENT))
	var colors = {"h": Color("24222d"), "s": Color("e1b69b"), "g": Color("85c9ce"), "r": RED, "y": GOLD, "k": Color("475278"), "c": Color("88b5aa") if voice == "高申" else (Color("e0e5d8") if voice == "医生" else RED), "b": Color("4d6bfe") if voice == "DeepSeek" else Color("bdb09a"), "w": Color("e0e4d5"), "p": Color("bd9291")}
	if voice == "旁白":
		c.draw_rect(Rect2(82, 383, 46, 35), Color("d6b58b"))
		c.draw_rect(Rect2(101, 383, 7, 35), Color("fff0d0"))
		text_at(c, "快递", Vector2(85, 407), 12, Color("725548"))
	else:
		var scale = 1.7 if voice == "DeepSeek" else 3.0
		var origin = Vector2(104 - rows[0].length() * scale / 2, 430 - rows.size() * scale)
		for y in range(rows.size()):
			for x in range(rows[y].length()):
				if rows[y][x] != ".": c.draw_rect(Rect2(origin + Vector2(x, y) * scale, Vector2.ONE * scale), colors[rows[y][x]])
	text_at(c, voice, Vector2(166, 376), 16, GOLD)
	wrapped_text(c, body, Vector2(166, 402), 710, 18, PAPER)
	text_at(c, "%d / %d   E / ENTER  %s" % [dialogue_index + 1, dialogue.size(), "继续" if dialogue_visible >= line.length() else "显示整句"], Vector2(657, 448), 12, MUTED)

func paint_upgrade(c: Node2D) -> void:
	var t = upgrade_time
	var center = Vector2(480, 275)
	var cyan = Color("85efff")
	var violet = Color("b48aff")
	c.draw_rect(Rect2(0, 0, 960, 540), Color("080c1e"))
	for i in range(60):
		var p = Vector2(36 + fposmod(i * 83.7, 888), 70 + fposmod(i * 31.9 - t * (20 + i % 17), 430))
		c.draw_rect(Rect2(p, Vector2(2, 3 + i % 7)), Color(0.4, 0.7, 1, 0.14 + (i % 3) * 0.08))
	for x in range(48, 960, 48):
		c.draw_line(Vector2(x, 75), Vector2(x, 451), Color(0.2, 0.35, 0.7, 0.08), 1)
	c.draw_circle(center, 153 + sin(t * 4) * 8, Color(0.36, 0.18, 0.8, 0.08))
	c.draw_circle(center, 109 + sin(t * 5) * 9, Color(0.12, 0.65, 0.9, 0.10))
	c.draw_rect(Rect2(412, 170, 136, 220), Color(0.35, 0.5, 1, 0.06))
	for band in range(3):
		var angle = t * (0.7 if band % 2 else -0.8) + band * 1.7
		c.draw_arc(center, 98 + band * 28, angle, angle + PI * 1.45, 64, cyan if band % 2 else violet, 2)
	for i in range(16):
		var direction = Vector2.from_angle(i * TAU / 16 + t * 0.55)
		var distance = 132 + (i % 3) * 16
		c.draw_line(center + direction * distance, center + direction * (distance + 12), Color(0.5, 0.8, 1, 0.55), 2)
		c.draw_rect(Rect2(center + direction * (83 + (i % 3) * 7) - Vector2(2, 2), Vector2(4, 4)), GOLD if i % 3 == 0 else cyan)
	if t > 0.6:
		for side in [-1, 1]:
			var jitter = sin(t * 7) * 8
			var points = PackedVector2Array([center + Vector2(side * 179, 81), center + Vector2(side * (132 + jitter), 31), center + Vector2(side * 156, 5), center + Vector2(side * (108 - jitter), -31), center + Vector2(side * 128, -91)])
			c.draw_polyline(points, cyan, 2)
	c.draw_set_transform(Vector2(480, 366), 0, Vector2(1, 0.25))
	c.draw_arc(Vector2.ZERO, 92, 0, TAU, 64, cyan, 3)
	c.draw_arc(Vector2.ZERO, 72, 0, TAU, 64, violet, 2)
	c.draw_set_transform(Vector2.ZERO)
	var origin = Vector2(480, 350 - sin(clampf(t / 2.3, 0, 1) * PI * 0.5) * 16)
	var colors = {"h": Color("24222d"), "s": Color("e1b69b"), "g": cyan, "r": RED, "y": GOLD, "k": Color("475278")}
	for y in range(World.PLAYER.size()):
		for x in range(World.PLAYER[y].length()):
			var pixel = World.PLAYER[y][x]
			if pixel != ".":
				var color: Color = colors[pixel]
				if absf(y - fposmod(t * 12, 24)) < 1: color = cyan
				c.draw_rect(Rect2(origin + Vector2((x - 8) * 5, (y - 19) * 5), Vector2(5, 5)), color)
	if t >= 2.3:
		var burst = clampf((t - 2.3) / 0.9, 0, 1)
		c.draw_arc(center, 90 + burst * 270, 0, TAU, 96, Color(0.8, 0.9, 1, (1 - burst) * 0.8), 3)
		c.draw_rect(Rect2(0, 0, 960, 540), Color(0.7, 0.85, 1, maxf(0, 1 - absf(t - 2.42) / 0.15) * 0.15))
	centered(c, "GAOSHEN // SUPPORT ONLINE", 51, 14, cyan)
	centered(c, "高申正在连接" if t < 0.75 else ("升级中" if t < 2.3 else "升级完成！"), 127, 36 if t < 0.75 else 44, GOLD if t >= 2.3 else PAPER)
	centered(c, "高申已接单 · 正在给灵芝加点" if t < 2.3 else "本关体力上限 150 · 攻击 ×1.5", 423, 20, cyan if t < 2.3 else GOLD)
	c.draw_rect(Rect2(210, 465, 540, 6), Color("28314c"))
	c.draw_rect(Rect2(210, 465, 540 * t / UPGRADE_DURATION, 6), cyan)
	centered(c, "高申代练中 · 即将返回战斗", 507, 13, MUTED)

func paint_ui(c: Node2D) -> void:
	if state in ["practice_select", "practice_result", "sidequest", "support"]:
		paint_activity(c)
		return
	if journal_open:
		paint_journal(c)
		return
	if state == "upgrading":
		paint_upgrade(c)
		return
	if state == "title":
		paint_title(c)
		return
	# Letterboxing leaves the world visible between the two editorial strips.
	var scene = previous_state if state == "paused" else state
	var finale = scene in ["darkroom", "illuminate", "birthday_reveal", "birthday", "parcel_opening", "ending"]
	var bright = birthday_revealed and finale
	var accent = Color("b57194") if bright else GOLD
	var secondary = Color("8f858b") if bright else MUTED
	c.draw_rect(Rect2(0, 0, 960, 77), Color("fff8ef") if bright else Color("0b1018"))
	c.draw_rect(Rect2(0, 473, 960, 67), Color("fff8ef") if bright else Color("0b1018"))
	text_at(c, "灵芝", Vector2(31, 29), 18, accent)
	if finale:
		text_at(c, "一封来自 David 的信", Vector2(31, 49), 13, secondary)
	else:
		c.draw_rect(Rect2(31, 41, 166, 7), Color("30333a"))
		c.draw_rect(Rect2(31, 41, 166 * player_hp / player_max_hp, 7), GOLD if player_hp > player_max_hp * 0.3 else RED)
		text_at(c, "%02d" % int(player_hp), Vector2(207, 49), 14, MUTED)
	var perk_label = Story.PERKS[active_perk].name if state == "fight" and active_perk >= 0 else "DAVID DIE"
	text_at(c, "高申强化 / 本关" if state == "fight" and boosted_boss == boss_index else perk_label, Vector2(31, 66), 10, GOLD if state == "fight" and (boosted_boss == boss_index or active_perk >= 0) else secondary)
	var chapter = Story.BOSSES[boss_index]
	var heading = chapter.tag
	var ui_scene = "hospital" if state == "dialogue" and dialogue_next == "hospital" else state
	if ui_scene in ["street", "glasses"]:
		heading = "INTERLUDE / 去医院"
	elif ui_scene in ["hospital", "ct"]:
		heading = "INTERLUDE / CT 检查"
	elif ui_scene == "route":
		heading = "ON THE TRAIL / 追回快递"
	elif ui_scene in ["beach", "fishing", "reeling", "fished"]:
		heading = "02 / 海边的发现"
	elif finale:
		heading = "HAPPY 20TH BIRTHDAY" if birthday_revealed else "THE LAST LETTER / 暗室"
	text_at(c, heading, Vector2(300, 32), 17, accent)
	text_at(c, "E / ENTER 阅读对话 · TAB 回顾线索" if state == "dialogue" else objective(), Vector2(300, 57), 13, secondary)
	for i in range(Story.BOSSES.size()):
		c.draw_rect(Rect2(852 + i * 16, 26, 9, 9), accent if i <= boss_index else Color("343942"))
	text_at(c, "M " + ("静音" if muted else "声音"), Vector2(853, 59), 11, secondary)
	if state in JOURNAL_STATES: text_at(c, "TAB 手账", Vector2(759, 59), 11, secondary)
	if state == "fight" or (state == "dialogue" and dialogue_next == "fight"):
		c.draw_rect(Rect2(280, 81, 400, 47), Color("111820"))
		centered(c, chapter.name, 101, 16)
		if boss_enraged:
			text_at(c, "II", Vector2(560, 101), 12, GOLD)
		text_at(c, "%d / %d" % [int(boss_hp), int(boss_max_hp)], Vector2(587, 101), 11, MUTED)
		c.draw_rect(Rect2(300, 110, 360, 9), Color("34303a"))
		c.draw_rect(Rect2(300, 110, 360 * boss_hp / boss_max_hp, 9), RED)
		c.draw_line(Vector2(480, 110), Vector2(480, 119), Color("111820"), 1)
		c.draw_rect(Rect2(280, 130, 400, 33), Color(0.04, 0.08, 0.12, 0.91))
		if boss_phase in ["windup", "charge"]:
			var tells = ["近身挥击 · 离开红圈", "三向弹道 · 从空隙穿过", "扩散冲击 · 闪避穿过边缘", "直线冲撞 · 让开红线", "红包雨 · 躲开落点"]
			if boss_index != 1:
				centered(c, tells[boss_pattern], 146, 13, GOLD)
		if boss_index == 1 and boss_phase in ["windup", "airborne"]:
			centered(c, ("二连砸落 %d/2 · 连续离开红圈" % (slam_chain + 1)) if boss_enraged else "飞起砸落 · 离开红色落点", 146, 13, GOLD)
		if boss_phase == "recover":
			centered(c, "破绽 · 靠近用三连击反击", 146, 13, Color("9ed5c5"))
			c.draw_rect(Rect2(380, 153, 200, 3), Color("303c43"))
			c.draw_rect(Rect2(380, 153, 200 * clampf(boss_timer / 1.8, 0, 1), 3), Color("9ed5c5"))
		elif boss_phase == "approach":
			centered(c, "留意预警 · 收招时第三击可延长破绽", 146, 12, MUTED)
		var ready_dash = dash_cd <= 0
		text_at(c, "闪避 " + ("就绪" if ready_dash else "%.1fs" % dash_cd), Vector2(750, 504), 14, GOLD if ready_dash else MUTED)
		text_at(c, "Q 补给 +35 ×%d" % heal_charges if heal_charges > 0 else "Q 补给已用完", Vector2(750, 526), 12, GOLD if heal_charges > 0 else MUTED)
		text_at(c, "连击", Vector2(580, 525), 12, MUTED)
		for i in range(3):
			c.draw_rect(Rect2(615 + i * 17, 515, 11, 11), GOLD if i < combo_step else Color("343942"))
	if scene == "dead":
		text_at(c, "↑↓ / W S 选择   Enter / E 确认   数字 1 / 2 / 3 或鼠标直接选", Vector2(31, 501), 13, secondary)
		text_at(c, "高申售后 · 复活无次数限制 · 选否后仍可改主意", Vector2(31, 524), 12, secondary)
	elif scene == "dialogue":
		text_at(c, "E / ENTER 显示整句，再按继续", Vector2(31, 501), 13, secondary)
		text_at(c, "TAB 查看任务手账 · 阅读时行动暂停", Vector2(31, 524), 12, secondary)
	elif scene == "reeling":
		text_at(c, "E / 点击 收线 · 成功两次钓起", Vector2(31, 501), 13, secondary)
		text_at(c, "失误会放宽绿色区域 · 不损失体力 · ESC 暂停", Vector2(31, 524), 12, secondary)
	elif scene == "fight":
		text_at(c, "WASD / 方向键 移动   J / 左键 三连击   空格 / K 闪避", Vector2(31, 501), 13, secondary)
		text_at(c, "岩浆会烫伤 · 踩收音机桥过河 · 两岸可躲砸落     ESC 暂停" if boss_index == 1 else "第三击重斩 · 成功闪避后反击更强     ESC 暂停", Vector2(31, 524), 12, secondary)
		if not mechanism_used:
			text_at(c, "E 场景机关", Vector2(580, 501), 12, Color("9ed5c5"))
		else:
			text_at(c, "机关已使用", Vector2(580, 501), 12, MUTED)
		if combat_text_time > 0 or phase_notice_time > 0:
			c.draw_rect(Rect2(125, 436, 710, 32), Color(0.04, 0.07, 0.11, 0.94))
			centered(c, Story.PHASE_LINES[boss_index] if phase_notice_time > 0 else combat_text, 460, 17, GOLD)
	else:
		text_at(c, "WASD / 方向键 移动   按住空格快走   E 互动" if not finale else "WASD / 方向键 移动   E 互动   F / 点击信纸开灯", Vector2(31, 501), 13, secondary)
		text_at(c, "ENTER 返回标题   F11 全屏" if scene == "ending" else "E / ENTER 对话   ESC 暂停   F11 全屏", Vector2(31, 524), 12, secondary)
	if toast_time > 0 and state not in ["dialogue", "glasses", "letter", "illuminate", "birthday_reveal"]:
		panel(c, Rect2(140, 412, 680, 40))
		centered(c, toast, 438, 15)
	if state == "dialogue":
		paint_dialogue(c)
	elif state == "glasses":
		paint_glasses(c)
	elif state == "ct":
		panel(c, Rect2(260, 365, 440, 79))
		centered(c, "CT 扫描中 · 请保持不动", 394, 18, GOLD)
		c.draw_rect(Rect2(290, 414, 380, 6), Color("343e47"))
		c.draw_rect(Rect2(290, 414, 380 * minf(scan_time / 6, 1), 6), Color("7dbeb1"))
	elif state == "reeling":
		panel(c, Rect2(177, 283, 606, 169), Color("132a34"))
		centered(c, "稳住鱼竿！收线 %d / 2" % reel_hits, 312, 21, GOLD)
		c.draw_rect(Rect2(250, 333, 460, 22), Color("344955"))
		c.draw_rect(Rect2(250 + (0.5 - reel_window()) * 460, 333, reel_window() * 920, 22), Color("83bba9"))
		c.draw_rect(Rect2(247 + reel_position() * 460, 328, 6, 32), PAPER)
		panel(c, Rect2(330, 376, 300, 43), Color("31515b"))
		centered(c, "E / 点击  收线", 404, 18, PAPER)
		centered(c, sidequest_message, 440, 12, MUTED)
	elif state == "letter":
		paint_letter(c)
	elif state in ["illuminate", "birthday_reveal"]:
		paint_uv_letter(c)
	elif state in ["parcel_opening", "ending"]:
		paint_parcel(c)
	elif state == "dead":
		paint_death(c)
	elif state == "paused":
		c.draw_rect(Rect2(0, 77, 960, 396), Color(0.03, 0.04, 0.07, 0.85))
		centered(c, "暂停", 251, 40, GOLD)
		centered(c, "ESC / ENTER  继续     M  切换声音", 305, 18)
	if hurt_flash > 0:
		c.draw_rect(Rect2(0, 0, 960, 540), Color(0.8, 0.13, 0.16, hurt_flash * 0.9))

func objective() -> String:
	var ui_scene = "hospital" if state == "dialogue" and dialogue_next == "hospital" else state
	match ui_scene:
		"street": return "找回并装好鼻托" if pad_dropped and not pad_fixed else "沿街走向右侧医院 · 门口按 E"
		"glasses": return "拖动鼻托，放进眼镜中央的虚线槽"
		"hospital": return "出口在右下方 · E 离开" if scanned else ("右侧 CT 检查床 · E 开始检查" if doctor_spoken else "左侧诊台 · E 找医生")
		"ct": return "完成 CT 检查"
		"beach": return "走到海边钓鱼点 · E 抛竿" if has_fishing_rod else "沙滩上有一根鱼竿 · 靠近按 E 拿起"
		"fishing": return "咬钩了！按 E 收竿！" if fishing_time >= 1.8 else "等一等……海里有什么在靠近"
		"reeling": return "游标进入绿色区时按 E 收线 · 成功两次即可钓起"
		"fished": return "钓上来的是……DeepSeek 小鲸鱼！"
		"route": return ("前往右侧档案室" if boss_index == 1 else "前往右侧 04 号仓库") + (" · 支援已领取" if sidequest_done else " · 途中可按 E 做支援任务")
		"letter_pickup": return "找到高申的快递和信 · 靠近按 E 取回"
		"letter", "aftermath": return "信纸上没有字 · 走向右上方暗门，按 E 进入"
		"darkroom": return "在左侧寻找特殊光源 · 靠近按 E" if not has_special_light else "靠近桌子按 E 放下信"
		"illuminate": return "F / 点击信纸开灯 · 移动光斑照亮信纸"
		"birthday_reveal": return "现在，看看你的右手边。" if birthday_revealed else "信上的字，终于出现了……"
		"birthday": return "快递终于追回来了 · 走进拱门，按 E 亲手拆开"
		"parcel_opening": return "拆开封条……"
		"ending": return "快递已签收 · 灵芝，20 岁生日快乐。"
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
	text_at(c, "四个对手 / 一件快递 / 一封信", Vector2(59, 351), 17, PAPER)
	panel(c, Rect2(56, 390, 435, 49), GOLD)
	text_at(c, "ENTER     开始游戏", Vector2(78, 422), 22, Color("111820"))
	if checkpoint > 0:
		text_at(c, "E  继续第 %d 场战斗" % (checkpoint + 1), Vector2(59, 458), 15, GOLD)
	else:
		text_at(c, "WASD 移动 · J 攻击 · 空格闪避 · E 互动", Vector2(59, 458), 13, MUTED)
	text_at(c, "R  Boss 练习场 · 挑战最好成绩", Vector2(59, 487), 16, Color("9ed5c5"))
	text_at(c, "像素动作 / 单人     v0.7", Vector2(59, 520), 12, MUTED)
	text_at(c, "LINGZHI", Vector2(683, 412), 17, GOLD)
	text_at(c, "David 偷了高申的快递。", Vector2(634, 440), 15)
	text_at(c, "← → / 点击选择难度", Vector2(650, 463), 12, MUTED)
	for i in range(3):
		c.draw_rect(DIFFICULTY_BUTTONS[i], Color("465e5a") if difficulty == i else Color("202c36"))
		text_at(c, Story.DIFFICULTIES[i], DIFFICULTY_BUTTONS[i].position + Vector2(27, 22), 16, GOLD if difficulty == i else MUTED)
	text_at(c, ["伤害更低 · 预警更长 · 双份补给", "标准战斗 · 保留全部高申支援", "更强对手 · 更快预警 · 练习手感"][difficulty], Vector2(615, 524), 12, MUTED)

func paint_activity(c: Node2D) -> void:
	c.draw_rect(Rect2(0, 0, 960, 540), Color("0d1722"))
	if state == "practice_select":
		centered(c, "BOSS 练习场", 74, 34, GOLD)
		centered(c, Story.DIFFICULTIES[difficulty] + "难度 · 已遇见的对手可直接重打，不改变主线进度", 105, 15, MUTED)
		for i in range(4):
			var card: Rect2 = PRACTICE_BUTTONS[i]
			var unlocked = boss_unlocked(i)
			c.draw_rect(card, Color("2c4147") if i == practice_selection else Color("182630"))
			if i == practice_selection: c.draw_rect(card, GOLD, false, 2)
			text_at(c, "%02d / %s" % [i + 1, Story.BOSSES[i].name if unlocked else "尚未遇见"], card.position + Vector2(22, 35), 22, PAPER if unlocked else MUTED)
			var best: float = best_times[difficulty * 4 + i]
			text_at(c, ("最好 %.2f 秒" % best if best > 0 else "暂无成绩 · 试试无伤通关") if unlocked else "继续主线后解锁", card.position + Vector2(22, 71), 14, GOLD if best > 0 else MUTED)
			text_at(c, "点击 / Enter 开始" if unlocked else "LOCKED", card.position + Vector2(22, 96), 12, MUTED)
		centered(c, "方向键选择 · E / Enter 开始 · Esc 返回标题调整难度", 453, 14, PAPER)
		if toast_time > 0: centered(c, toast, 491, 14, GOLD)
	elif state == "practice_result":
		centered(c, "练习完成 · " + Story.BOSSES[boss_index].name, 88, 30, GOLD)
		var assisted = boosted_boss == boss_index
		var grade = "高申支援通关" if assisted else ("S · 无伤签收" if hits_taken == 0 else ("A · 漂亮收件" if hits_taken <= 2 else "B · 成功送达"))
		centered(c, grade, 165, 34, Color("9ed5c5"))
		centered(c, "%.2f 秒   /   受伤 %d 次   /   成功闪避 %d 次" % [fight_elapsed, hits_taken, perfect_dodges], 222, 22, PAPER)
		centered(c, Story.DIFFICULTIES[difficulty] + "难度 · " + ("支援成绩单独展示，不覆盖普通最好成绩" if assisted else ("刷新最好成绩！" if new_record else "可以再试一次，减少受伤或缩短用时")), 272, 15, GOLD)
		for i in range(3):
			panel(c, RESULT_BUTTONS[i], Color("233943"))
			text_at(c, ["R 再来一次", "E 更换对手", "Esc 返回标题"][i], RESULT_BUTTONS[i].position + Vector2(23, 30), 17, PAPER)
		centered(c, "主线存档已保留。", 468, 14, MUTED)
	elif state == "sidequest":
		centered(c, "支援任务 / " + ("调到 FM 100.6" if boss_index == 1 else "认准高申的快递"), 91, 30, GOLD)
		centered(c, "可选任务 · 完成后为下一战选择一份支援 · Esc 可直接离开", 127, 14, MUTED)
		if boss_index == 1:
			centered(c, "桥头收音机写着 FM 100.6，高申正在这个频道等你。", 192, 17, PAPER)
			c.draw_rect(Rect2(327, 222, 306, 91), Color("263e44"))
			centered(c, "FM %.1f" % (tuning_frequency / 10.0), 280, 38, Color("9ed5c5"))
		else:
			centered(c, "三个名字有点像。选出面单写着“高申”的那一件。", 192, 17, PAPER)
			c.draw_rect(Rect2(327, 222, 306, 91), Color("b69776"))
			centered(c, ["高升", "高申", "高伸"][cargo_selection], 279, 38, Color("24343b"))
			centered(c, "包裹 %d / 3" % (cargo_selection + 1), 338, 14, MUTED)
		for x in [236, 654]:
			panel(c, Rect2(x, 241, 70, 58), Color("2a414a"))
			text_at(c, "−" if x == 236 else "+", Vector2(x + 25, 280), 28, GOLD)
		panel(c, Rect2(330, 363, 300, 46), Color("31534f"))
		centered(c, "E / Enter  确认", 394, 19, PAPER)
		centered(c, sidequest_message if not sidequest_message.is_empty() else "← → / A D 调整，也可点击两侧按钮", 450, 14, GOLD if not sidequest_message.is_empty() else MUTED)
	elif state == "support":
		centered(c, "高申支援 · 三选一", 83, 32, GOLD)
		centered(c, sidequest_message, 118, 15, PAPER)
		for i in range(3):
			var card: Rect2 = SUPPORT_BUTTONS[i]
			c.draw_rect(card, Color("2f4c4d") if i == support_selection else Color("1a2d37"))
			if i == support_selection: c.draw_rect(card, GOLD, false, 2)
			text_at(c, Story.PERKS[i].name, card.position + Vector2(23, 25), 20, GOLD)
			text_at(c, Story.PERKS[i].description, card.position + Vector2(23, 49), 14, PAPER)
		centered(c, "方向键选择 · E / Enter 或点击确认 · 下一战重试保留，不叠加", 447, 14, MUTED)
		centered(c, "Esc 暂时离开，仍可回来选择", 478, 12, MUTED)

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
	for line in ["高申的快递找回来了，封条完好。", "夹在封条下的信，纸面却是空白。", "角落画着一盏小小的紫色灯。", "也许应该去没有其他光的地方。"]:
		text_at(c, line, Vector2(286, y), 17, Color("343a3d"))
		y += 31
	text_at(c, "E / ENTER  收好信，去右上方的暗门", Vector2(286, 428), 15, Color("6d5145"))

func paint_uv_letter(c: Node2D) -> void:
	var lit = uv_active or state == "birthday_reveal"
	var bright = birthday_revealed
	c.draw_rect(LETTER_PAGE, Color("fffaf0") if bright else (Color("262039") if lit else Color("161a26")))
	c.draw_rect(LETTER_PAGE.grow(-7), Color("d9c0d1") if bright else (Color("8763ad") if lit else Color("343643")), false, 1)
	text_at(c, "特殊光下的一封信", Vector2(90, 160), 20, Color("ae7a9e") if bright else Color("c9a4ed"))
	text_at(c, "信上的字，终于出现了。" if bright else "按 F 或点击信纸开灯，移动光斑", Vector2(90, 189), 13, Color("9c8d94") if bright else MUTED)
	var y = 236
	var line_index = 0
	for line in Story.LETTER.split("\n"):
		if lit and (state == "birthday_reveal" or illumination > 0.2 + line_index * 0.25):
			text_at(c, line, Vector2(90, y), 18, Color("8f6c91") if bright else Color("e0c8ff"))
		else:
			c.draw_line(Vector2(91, y), Vector2(422, y), Color("303343"), 1)
		y += 29
		line_index += 1
	if state == "illuminate":
		c.draw_rect(Rect2(90, 385, 340, 5), Color("393043"))
		c.draw_rect(Rect2(90, 385, 340 * illumination / 2.2, 5), Color("b48bdf"))
		if uv_active:
			c.draw_circle(get_global_mouse_position(), 41, Color(0.65, 0.37, 0.97, 0.13))
		text_at(c, "E  暂时收起", Vector2(90, 411), 12, MUTED)
	elif birthday_time >= 3:
		text_at(c, "E / ENTER  收好信，走进拱门", Vector2(90, 400), 14, Color("b77b94") if bright else GOLD)

func paint_parcel(c: Node2D) -> void:
	c.draw_rect(Rect2(52, 108, 432, 342), Color("fffaf0"))
	c.draw_rect(Rect2(60, 116, 416, 326), Color("dfc8ce"), false, 1)
	text_at(c, "终于追回来的快递", Vector2(85, 159), 23, Color("a87592"))
	text_at(c, "面单上的名字：高申", Vector2(86, 190), 14, Color("998a86"))
	var opened = clampf(parcel_time / 1.8, 0, 1)
	var box = Vector2(176, 283)
	c.draw_circle(box + Vector2(80, -15), 77, Color(0.40, 0.83, 0.77, opened * 0.14))
	if opened > 0.01:
		c.draw_colored_polygon(PackedVector2Array([box, box + Vector2(160, 0), box + Vector2(160 + opened * 24, -opened * 44), box + Vector2(-opened * 24, -opened * 44)]), Color("cfa47e"))
	else:
		c.draw_rect(Rect2(box - Vector2(0, 4), Vector2(160, 8)), Color("cfa47e"))
	if opened > 0.45:
		World.paint_perfume(c, Vector2(256, 346 - 46 * opened), 2.6)
		for i in range(12):
			var x = 190 + fposmod(i * 29.0, 132)
			var y = 283 - fposmod(i * 17.0 + clock * 10, 70)
			c.draw_rect(Rect2(x, y, 2, 3), Color(0.4, 0.72, 0.68, 0.25 + 0.2 * sin(clock * 2 + i)))
	c.draw_rect(Rect2(box, Vector2(160, 76)), Color("d9b48a"))
	c.draw_rect(Rect2(box + Vector2(4, 5), Vector2(152, 65)), Color("e8c99e"))
	c.draw_rect(Rect2(box + Vector2(71, 0), Vector2(17, 76)), Color("f8ead0"))
	text_at(c, "高申", box + Vector2(13, 53), 16, Color("8f765d"))
	if parcel_opened:
		text_at(c, "一瓶清爽香水 · 像风一样轻盈", Vector2(86, 378), 15, Color("6b9a94"))
		if perfume_spray > 0:
			var t = 1.6 - perfume_spray
			for i in range(22):
				var p = Vector2(256, 213) + Vector2((i % 7 - 3) * (5 + t * 15), -t * (14 + i % 9) + sin(i * 3.0) * 10)
				c.draw_circle(p, 2 + i % 3, Color(0.47, 0.77, 0.73, perfume_spray * 0.2))
	text_at(c, "高申的快递，已签收。" if parcel_opened else "正在拆开封条……", Vector2(86, 397), 17, Color("a77a91"))
	text_at(c, "灵芝，20 岁生日快乐。" if parcel_opened else "你追回的惊喜，就在里面。", Vector2(86, 424), 15, Color("a77a91"))
	if parcel_opened:
		text_at(c, "ENTER 返回标题", Vector2(744, 500), 14, Color("a77a91"))
		text_at(c, "E 轻喷一下", Vector2(744, 525), 13, Color("6b9a94"))

func setup_preview(scene: String) -> void:
	saving_enabled = false
	match scene:
		"fight": start_boss(0, false)
		"dead", "upgrade":
			start_boss(COW_BOSS, false)
			hurt_player(100)
			if scene == "upgrade":
				choose_death_option(2)
				upgrade_time = 1.9
		"combat":
			start_boss(0, false)
			player = boss - Vector2(30, 0)
			boss_phase = "recover"
			combo_step = 2
			combo_time = 0.5
			counter_time = 1.2
			try_attack()
		"whale_phase2":
			start_boss(1, false)
			hit_boss(boss_max_hp * 0.6)
			player = Vector2(238, 181)
			boss = Vector2(360, 177)
			boss_target = player
			perform_boss_attack()
			boss_timer = 0.5
		"radio_bridge":
			start_boss(1, false)
			player = Vector2(153, 191)
			boss = Vector2(338, 185)
			boss_phase = "approach"
		"beach", "fishing", "fished", "deepseek":
			start_boss(1, false)
			if scene == "deepseek":
				player = Vector2(238, 181)
				boss = Vector2(360, 177)
				boss_target = player
				perform_boss_attack()
				boss_timer = 0.5
			else:
				state = scene
				has_fishing_rod = scene != "beach"
				player = FISHING_SPOT if has_fishing_rod else Vector2(67, 193)
				fishing_time = 2.1 if scene == "fishing" else 0.8
		"pier", "corridor":
			start_boss(1 if scene == "pier" else COW_BOSS, false)
			boss_hp = 0
			begin_dialogue([], "route")
			advance_dialogue()
			player = Vector2(250, 181)
		"cow": start_boss(COW_BOSS, false)
		"cow_rain":
			start_boss(COW_BOSS, false)
			boss_pattern = 4
			perform_boss_attack()
			for i in range(red_packets.size()): red_packets[i].remaining = 0.3 + i * 0.11
		"david": start_boss(FINAL_BOSS, false)
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
			boss_index = FINAL_BOSS
			state = "letter"
		"darkroom", "illuminate", "birthday_reveal", "birthday", "parcel_opening", "ending":
			boss_index = FINAL_BOSS
			boss_hp = 0
			has_letter = true
			has_parcel = true
			has_special_light = scene != "darkroom"
			state = scene
			player = Vector2(170, 179)
			if scene == "illuminate":
				uv_active = true
				illumination = 1.7
			if scene in ["birthday_reveal", "birthday", "parcel_opening", "ending"]:
				birthday_time = 3.2
				birthday_revealed = true
			if scene in ["parcel_opening", "ending"]:
				parcel_time = 1.1 if scene == "parcel_opening" else 2.4
				parcel_opened = scene == "ending"
				player = BIRTHDAY_PARCEL - Vector2(25, -5)

func capture_screen() -> void:
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	image.save_png(screenshot_path)
	get_tree().quit()
