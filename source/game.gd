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
var combo_step = 0
var combo_time = 0.0
var counter_time = 0.0
var dash_buffer = 0.0
var dash_rewarded = false
var heal_charges = 1
var combat_text = ""
var combat_text_time = 0.0
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
		var saved_chapter = int(save.get_value("game", "chapter", 0))
		if int(save.get_value("game", "roster_version", 1)) == 1 and saved_chapter >= 3:
			saved_chapter -= 1
		checkpoint = clampi(saved_chapter, 0, Story.BOSSES.size() - 1)

func save_checkpoint() -> void:
	checkpoint = boss_index
	if not saving_enabled:
		return
	var save = ConfigFile.new()
	save.set_value("game", "chapter", checkpoint)
	save.set_value("game", "roster_version", 2)
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
	heal_charges = 1
	combat_text_time = 0
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
	if Input.is_action_just_pressed("mute"):
		muted = not muted
		music.stream_paused = muted
		if not muted and not music.playing:
			music.play()
	if Input.is_action_just_pressed("pause_game"):
		if state == "paused":
			state = previous_state
		elif state not in ["title", "parcel_opening", "ending", "dead"]:
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
		if Input.is_action_just_pressed("confirm"):
			state = "title"
	elif state == "ct":
		scan_time += delta
		if scan_time >= 6.0:
			scanned = true
			begin_dialogue(["检查完成，片子已经留档。", "医生：先休息一下。出门沿滨海路走，就是旧码头。", "灵芝收好报告，想起了海里那枚通行牌。"], "hospital", "检查室")
	elif state == "fishing":
		fishing_time += delta
		if Input.is_action_just_pressed("interact"):
			interact()
	elif state == "fished":
		fishing_time += delta
		if fishing_time >= 1.2:
			begin_dialogue(Story.BOSSES[1].intro, "fight", "DeepSeek 小鲸鱼")
	elif state in ["fight", "street", "hospital", "beach", "route", "letter_pickup", "aftermath", "darkroom"]:
		if state == "fight" and Input.is_action_just_pressed("heal"):
			try_heal()
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
	dash_cd = 0.72
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
		var damage = (18 if heavy else 10) if boss_phase == "recover" else (8 if heavy else 4)
		if counter_time > 0:
			damage += 12
		if hit_boss(damage) and counter_time > 0:
			counter_time = 0
			combat_text = "闪避反击！ +12 伤害"
			combat_text_time = 1.1
	return true

func hit_boss(damage: float) -> bool:
	if state != "fight" or boss_hp <= 0 or (boss_index == 1 and boss_phase == "airborne"):
		return false
	boss_hp = maxf(0, boss_hp - damage)
	particles.append({"p": boss - Vector2(5, 30), "v": Vector2(0, -18), "life": 0.65, "color": GOLD, "text": str(int(damage))})
	if boss_hp > 0 and boss_hp <= boss_max_hp * 0.5 and not boss_enraged:
		boss_enraged = true
		combat_text = "第二阶段 · 留意新的出招节奏"
		combat_text_time = 1.6
	boss_flash = 0.13
	shake = 3
	hitstop = 0.045
	blood(boss, 9)
	sound("hit")
	if boss_hp <= 0:
		defeat_boss()
	return true

func try_heal() -> bool:
	if state != "fight" or heal_charges <= 0 or player_hp >= 100:
		return false
	heal_charges -= 1
	var recovered = minf(35, 100 - player_hp)
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
			dash_rewarded = true
			counter_time = 1.4
			dash_cd = maxf(0, dash_cd - 0.18)
			combat_text = "漂亮闪避！下一击可反击"
			combat_text_time = 1.2
			sound("pickup")
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
				boss_pattern = attack_count % 4 if boss_index == FINAL_BOSS else boss_index
				if boss_index == 0 and boss_enraged and attack_count % 2 == 1:
					boss_pattern = 3
				if boss_index == FINAL_BOSS and boss_enraged:
					boss_pattern = [1, 3, 2, 3][attack_count % 4]
				if boss_index == COW_BOSS:
					boss_pattern = 4 if attack_count % 2 == 0 else 3
				boss_phase = "windup"
				boss_timer = 0.78 if boss_index < FINAL_BOSS else 0.64
				boss_target = player
				slam_chain = 0
				if boss_index == 1:
					boss_target.x = clampf(boss_target.x, 49, 431)
					boss_target.y = clampf(boss_target.y, 150, 214)
				boss_dir = (player - boss).normalized()
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
					boss_target = Vector2(clampf(player.x, 49, 431), clampf(player.y, 150, 214))
					boss_phase = "windup"
					boss_timer = 0.7
					sound("danger")
				else:
					boss_phase = "recover"
					boss_timer = 1.5 if boss_enraged else 1.3
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
	if boss_index == 1:
		boss.y = maxf(boss.y, 150)

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
			if boss_index == 1:
				boss_phase = "airborne"
				boss_timer = 1.0
			else:
				for angle in [-0.32, 0.0, 0.32]:
					projectiles.append({"p": boss, "v": boss_dir.rotated(angle) * 125, "life": 3.5})
		2:
			waves.append({"p": boss, "radius": 8.0, "hit": false})
		3:
			boss_phase = "charge"
			boss_timer = 0.58
		4:
			# Every landing has its own warning; the first envelope targets the
			# player's current position, while the others leave gaps to escape.
			red_packets.append({"p": player, "remaining": 0.9})
			for i in range(8 if boss_enraged else 6):
				var target = Vector2(64 + i * 46, 123 + (i % 3) * 35) if boss_enraged else Vector2(76 + i * 61, 123 + (i % 3) * 35)
				red_packets.append({"p": target, "remaining": 1.05 + i * 0.09})
			boss_timer = 1.7
	sound("slash")

func update_attacks(delta: float) -> void:
	for i in range(red_packets.size() - 1, -1, -1):
		var packet = red_packets[i]
		var before: float = packet.remaining
		packet.remaining -= delta
		if before > 0 and packet.remaining <= 0:
			if player.distance_to(packet.p) < 18:
				hurt_player(16)
			for j in range(8):
				particles.append({"p": packet.p, "v": Vector2.from_angle(j * TAU / 8) * 28, "life": 0.4, "color": GOLD if j % 2 else RED})
		if packet.remaining < -0.3:
			red_packets.remove_at(i)
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
	red_packets.clear()
	blood(boss, 24)
	if boss_index == FINAL_BOSS:
		letter_pos = boss + Vector2(-17, 13)
		state = "letter_pickup"
		notify("David 倒下了。高申的快递旁，落着一封信。")
	else:
		var next = "street" if boss_index == 0 else "route"
		begin_dialogue(Story.BOSSES[boss_index].outro, next, "1006" if boss_index == COW_BOSS else "灵芝")

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
			state = "fished"
			fishing_time = 0
			sound("pickup")
	elif state == "route" and player.distance_to(ROUTE_EXIT) < 30:
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
	notify("咔哒。看清楚了。继续去医院。")
	return true

func _input(event: InputEvent) -> void:
	if state == "fight" and event.is_action_pressed("dash"):
		dash_buffer = 0.14
	if state == "illuminate" and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and LETTER_PAGE.has_point(event.position):
		special_light_on = true
		sound("click")
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
	combat_text_time = maxf(0, combat_text_time - delta)
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
		c.draw_rect(Rect2(31, 41, 166 * player_hp / 100, 7), GOLD if player_hp > 30 else RED)
		text_at(c, "%02d" % int(player_hp), Vector2(207, 49), 14, MUTED)
	text_at(c, "DAVID DIE", Vector2(31, 66), 10, secondary)
	var chapter = Story.BOSSES[boss_index]
	var heading = chapter.tag
	var ui_scene = "hospital" if state == "dialogue" and dialogue_next == "hospital" else state
	if ui_scene in ["street", "glasses"]:
		heading = "INTERLUDE / 去医院"
	elif ui_scene in ["hospital", "ct"]:
		heading = "INTERLUDE / CT 检查"
	elif ui_scene == "route":
		heading = "ON THE TRAIL / 追回快递"
	elif ui_scene in ["beach", "fishing", "fished"]:
		heading = "02 / 海边的发现"
	elif finale:
		heading = "HAPPY 20TH BIRTHDAY" if birthday_revealed else "THE LAST LETTER / 暗室"
	text_at(c, heading, Vector2(300, 32), 17, accent)
	text_at(c, objective(), Vector2(300, 57), 13, secondary)
	for i in range(Story.BOSSES.size()):
		c.draw_rect(Rect2(852 + i * 16, 26, 9, 9), accent if i <= boss_index else Color("343942"))
	text_at(c, "M " + ("静音" if muted else "声音"), Vector2(853, 59), 11, secondary)
	if state == "fight" or (state == "dialogue" and dialogue_next == "fight"):
		c.draw_rect(Rect2(280, 81, 400, 47), Color("111820"))
		centered(c, chapter.name, 101, 16)
		if boss_enraged:
			text_at(c, "II", Vector2(560, 101), 12, GOLD)
		text_at(c, "%d / %d" % [int(boss_hp), int(boss_max_hp)], Vector2(587, 101), 11, MUTED)
		c.draw_rect(Rect2(300, 110, 360, 9), Color("34303a"))
		c.draw_rect(Rect2(300, 110, 360 * boss_hp / boss_max_hp, 9), RED)
		c.draw_line(Vector2(480, 110), Vector2(480, 119), Color("111820"), 1)
		if boss_phase in ["windup", "charge"]:
			var tells = ["近身挥击 · 离开红圈", "三向弹道 · 从空隙穿过", "扩散冲击 · 闪避穿过边缘", "直线冲撞 · 让开红线", "红包雨 · 躲开落点"]
			if boss_index != 1:
				centered(c, tells[boss_pattern], 146, 13, GOLD)
		if boss_index == 1 and boss_phase in ["windup", "airborne"]:
			centered(c, ("二连砸落 %d/2 · 连续离开红圈" % (slam_chain + 1)) if boss_enraged else "飞起砸落 · 离开红色落点", 146, 13, GOLD)
		if boss_phase == "recover":
			centered(c, "破绽 · 靠近用三连击反击", 146, 13, Color("9ed5c5"))
		var ready_dash = dash_cd <= 0
		text_at(c, "闪避 " + ("就绪" if ready_dash else "%.1fs" % dash_cd), Vector2(750, 504), 14, GOLD if ready_dash else MUTED)
		text_at(c, "Q 补给 +35" if heal_charges > 0 else "Q 补给已用完", Vector2(750, 526), 12, GOLD if heal_charges > 0 else MUTED)
		text_at(c, "连击", Vector2(580, 525), 12, MUTED)
		for i in range(3):
			c.draw_rect(Rect2(615 + i * 17, 515, 11, 11), GOLD if i < combo_step else Color("343942"))
	if scene == "fight":
		text_at(c, "WASD / 方向键 移动   J / 左键 三连击   空格 / K 闪避", Vector2(31, 501), 13, secondary)
		text_at(c, "第三击重斩 · 成功闪避后反击更强     ESC 暂停", Vector2(31, 524), 12, secondary)
		if combat_text_time > 0:
			centered(c, combat_text, 460, 17, GOLD)
	else:
		text_at(c, "WASD / 方向键 移动   按住空格快走   E 互动" if not finale else "WASD / 方向键 移动   E 互动   F / 点击信纸开灯", Vector2(31, 501), 13, secondary)
		text_at(c, "ENTER 返回标题   F11 全屏" if scene == "ending" else "E / ENTER 对话   ESC 暂停   F11 全屏", Vector2(31, 524), 12, secondary)
	if toast_time > 0 and state not in ["dialogue", "glasses", "letter", "illuminate", "birthday_reveal"]:
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
	elif state in ["illuminate", "birthday_reveal"]:
		paint_uv_letter(c)
	elif state in ["parcel_opening", "ending"]:
		paint_parcel(c)
	elif state == "dead":
		c.draw_rect(Rect2(0, 77, 960, 396), Color(0.03, 0.04, 0.07, 0.85))
		centered(c, "再来一次。", 237, 46, RED)
		centered(c, "观察红色预警，在出招瞬间闪避。", 287, 18)
		centered(c, "ENTER  从这场战斗重试", 341, 17, GOLD)
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
		"fished": return "钓上来的是……DeepSeek 小鲸鱼！"
		"route": return "沿栈道到右侧档案室 · 门前按 E" if boss_index == 1 else "沿走廊找到 04 号仓库 · 门前按 E"
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
		text_at(c, "E  继续第 %d 场战斗" % (checkpoint + 1), Vector2(59, 468), 15, GOLD)
	else:
		text_at(c, "WASD 移动 · J 攻击 · 空格闪避 · E 互动", Vector2(59, 469), 13, MUTED)
	text_at(c, "像素动作 / 单人     v0.4", Vector2(59, 511), 12, MUTED)
	text_at(c, "LINGZHI", Vector2(683, 412), 17, GOLD)
	text_at(c, "David 偷了高申的快递。", Vector2(634, 440), 15)

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
	c.draw_circle(box + Vector2(80, 21), 75, Color(1, 0.85, 0.55, opened * 0.16))
	c.draw_rect(Rect2(box, Vector2(160, 76)), Color("d9b48a"))
	c.draw_rect(Rect2(box + Vector2(4, 5), Vector2(152, 65)), Color("e8c99e"))
	if opened > 0.01:
		c.draw_colored_polygon(PackedVector2Array([box, box + Vector2(160, 0), box + Vector2(160 + opened * 24, -opened * 44), box + Vector2(-opened * 24, -opened * 44)]), Color("cfa47e"))
	else:
		c.draw_rect(Rect2(box - Vector2(0, 4), Vector2(160, 8)), Color("cfa47e"))
	if opened > 0.6:
		c.draw_rect(Rect2(box + Vector2(38, -52 * opened), Vector2(85, 52 * opened)), Color("fff0dd"))
		text_at(c, "20", box + Vector2(55, -12 * opened), 28, Color("c79b55"))
	c.draw_rect(Rect2(box + Vector2(71, 0), Vector2(17, 76)), Color("f8ead0"))
	text_at(c, "高申", box + Vector2(13, 53), 16, Color("8f765d"))
	text_at(c, "高申的快递，已签收。" if parcel_opened else "正在拆开封条……", Vector2(86, 397), 17, Color("a77a91"))
	text_at(c, "灵芝，20 岁生日快乐。" if parcel_opened else "你追回的惊喜，就在里面。", Vector2(86, 424), 15, Color("a77a91"))
	if parcel_opened:
		text_at(c, "ENTER 返回标题", Vector2(744, 500), 14, Color("a77a91"))

func setup_preview(scene: String) -> void:
	saving_enabled = false
	match scene:
		"fight": start_boss(0, false)
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
