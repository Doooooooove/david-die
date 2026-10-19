extends Node2D

var game: Node
const INK = Color("10151d")
const GOLD = Color("e5c365")
const RED = Color("c95054")
const PLAYER = [
	"....hhhhhh......", "...hhhhhhhh.....", "...hhsssshh.....", "...hsggsggh.....",
	"...hsggsggh.....", "....ssssss......", ".....srrs.......", "...yyyyyyyy.....",
	"..yykyyykyyy....", "..sykyyykyys....", "..sykyyykyys....", "..s.yyyyyy.s....",
	"....yyyyyy......", "....kkkkkk......", "....yy..yy......", "....yy..yy......",
	"....yy..yy......", "....kk..kk......", "...kkk..kkk....."
]
const AGENT = [
	"....hhhhhh......", "...hhhhhhhh.....", "...hhsssshh.....", "....sggsgg......",
	"....sggsgg......", "....ssssss......", ".....srrs.......", "...cccccccc.....",
	"..cckccckccc....", "..sckccckccs....", "..sckccckccs....", "..s.cccccc.s....",
	"....cccccc......", "....kkkkkk......", "....cc..cc......", "....cc..cc......",
	"....cc..cc......", "....kk..kk......", "...kkk..kkk....."
]
const COW = [
	"..bb..........bb....", "..ww..........ww....", ".wwww..wwww..wwww...", "..wwwwwwwwwwwwww....",
	"...wwkkwwwwkkww.....", "...wwwkkkkkkwww.....", "...wwwgwwwwgwww.....", "...wwwwwwwwwwww.....",
	"....wppppppppw......", "....ppkppkpppp......", ".....pppppppp.......", "....kkkrkkk.........",
	"..kkkkkrkkkkk.......", "..wwkkkrkkkww.......", "..wwkkkrkkkww.......", "..wwkkkkkkkww.......",
	"....kkkkkkk.........", "....kk...kk.........", "....kk...kk.........", "....ww...ww.........",
	"...kkkk.kkkk........"
]

func rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), w, h), color)

func label(text: String, x: float, y: float, size = 8, color = GOLD) -> void:
	draw_string(game.font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if game.state == "title":
		draw_title()
		return
	var scene = game.state
	if scene == "paused": scene = game.previous_state
	if scene == "dialogue":
		if game.dialogue_next == "hospital": scene = "hospital"
		elif game.dialogue_next == "street": scene = "fight"
	if scene in ["street", "glasses"]:
		draw_street()
	elif scene in ["hospital", "ct"]:
		draw_hospital()
	else:
		draw_arena()
	for stain in game.stains:
		draw_rect(Rect2(stain.p, stain.size), Color("77333d"))
	for wave in game.waves:
		draw_arc(wave.p, wave.radius, 0, TAU, 52, Color("c27cbb"), 3)
		draw_arc(wave.p, maxf(1, wave.radius - 4), 0, TAU, 52, Color("703b69"), 1)
	if scene in ["fight", "dead", "letter_pickup", "letter", "ending", "dialogue"] and game.dialogue_next != "hospital":
		if game.boss_hp > 0:
			draw_tell()
			draw_actor(game.boss, "cow" if game.boss_index == 3 else "agent", game.Story.BOSSES[game.boss_index].color, game.boss_phase == "approach", game.boss_flash > 0, game.boss.x > game.player.x)
			if game.boss_phase == "recover":
				rect(game.boss.x - 2, game.boss.y - 36, 4, 4, GOLD)
		else:
			draw_corpse()
	if scene == "ct":
		draw_actor(Vector2(325, 161), "player", "e5c365")
	else:
		if not (game.invulnerable > 0 and int(game.clock * 18) % 2 == 0):
			draw_actor(game.player, "player", "e5c365", game.move_dir.length() > 0, game.hurt_flash > 0, game.facing.x < 0)
	if game.slash_time > 0 and scene == "fight":
		var angle = game.facing.angle()
		var center = game.player - Vector2(0, 10)
		draw_arc(center, 31, angle - 0.95, angle + 0.95, 12, GOLD, 4)
		draw_arc(center, 36, angle - 0.75, angle + 0.75, 12, Color("f1edc7"), 2)
	for shot in game.projectiles:
		draw_line(shot.p, shot.p - shot.v.normalized() * 8, Color("b04b54"), 3)
		rect(shot.p.x - 2, shot.p.y - 2, 4, 4, GOLD)
	for particle in game.particles:
		if particle.get("ring", false):
			draw_arc(particle.p, (0.26 - particle.life) * 200, 0, TAU, 24, RED, 3)
		else:
			rect(particle.p.x, particle.p.y, 2, 2, particle.color)
	if scene == "letter_pickup":
		draw_letter_drop()
	if scene == "street" and game.pad_dropped and not game.pad_fixed:
		draw_pad_drop()
	if scene == "hospital":
		if game.scanned:
			prompt(Vector2(433, 198), "E 离开医院")
		elif game.doctor_spoken:
			prompt(Vector2(325, 143), "E 做 CT")
		else:
			prompt(Vector2(139, 131), "E 找医生")

func draw_actor(pos: Vector2, kind: String, coat: String, walking = false, flash = false, flip = false, rotation_angle = 0.0) -> void:
	var step = 1 if walking and int(game.clock * 9) % 2 == 0 else 0
	var rows = COW if kind == "cow" else (PLAYER if kind == "player" else AGENT)
	var colors = {"h": Color("24222d"), "s": Color("d5a58b"), "g": Color("181c26"), "r": Color("b84750"), "y": GOLD, "k": Color("262b37"), "c": Color(coat), "b": Color("bdb09a"), "w": Color("e0e4d5"), "p": Color("bd9291")}
	if kind == "player":
		colors.g = Color("7cc5c5")
	draw_ellipse_shadow(pos, 13 if kind == "cow" else 10)
	draw_set_transform(pos.round() + Vector2(0, step), rotation_angle, Vector2(1.5, 1.5))
	var width = rows[0].length()
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var pixel = rows[y][x]
			if pixel == ".": continue
			var px = width - x - 1 if flip else x
			var leg_offset = step if y > rows.size() - 6 and x < width / 2 else 0
			rect(px - width / 2, y - rows.size() - leg_offset, 1, 1, Color("f2eacc") if flash else colors[pixel])
	if kind == "player" and game.state != "ct":
		var side = -1 if flip else 1
		rect(side * 8, -15, 2, 13, Color("cbd8d3"))
		rect(side * 8 - 2, -7, 6, 2, GOLD)
		rect(side * 8, -4, 2, 4, RED)
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(pos: Vector2, width: float) -> void:
	rect(pos.x - width, pos.y - 2, width * 2, 4, Color(0.02, 0.025, 0.04, 0.4))
	rect(pos.x - width + 3, pos.y - 4, width * 2 - 6, 7, Color(0.02, 0.025, 0.04, 0.25))

func draw_arena() -> void:
	var palettes = [
		["211f27", "302c32", "3b3034", "876349"],
		["182833", "243945", "26333f", "4b7380"],
		["272331", "35303e", "383242", "766479"],
		["1f302e", "2b3d3b", "33423e", "688f81"],
		["301e2a", "3f2c35", "422c35", "9d5c63"]
	]
	var pal = palettes[game.boss_index]
	rect(0, 0, 480, 270, Color("0c121b"))
	rect(16, 41, 448, 193, Color(pal[0]))
	rect(21, 93, 438, 137, Color(pal[1]))
	for y in range(94, 230, 17):
		for x in range(22, 459, 25):
			rect(x, y, minf(24, 459 - x), 16, Color(pal[2]))
			rect(x + 3, y + 1, minf(19, 459 - x - 3), 1, Color(pal[1]).lightened(0.07))
	for x in range(27, 454, 46):
		rect(x, 48, 3, 43, Color(pal[3]).darkened(0.52))
		rect(x + 3, 48, 32, 39, Color(pal[0]).lightened(0.04))
	rect(20, 90, 440, 4, Color(pal[3]))
	rect(18, 229, 444, 4, Color(pal[0]).darkened(0.3))
	rect(18, 233, 444, 3, Color("0c121b"))
	# A framed combat floor keeps attacks readable against the pixel scenery.
	rect(79, 116, 326, 1, Color(pal[3]).darkened(0.4))
	rect(79, 215, 326, 1, Color(pal[3]).darkened(0.4))
	for x in [79, 404]: rect(x, 116, 1, 100, Color(pal[3]).darkened(0.4))
	match game.boss_index:
		0: draw_cinema()
		1: draw_alley()
		2: draw_machines()
		3: draw_archive()
		4: draw_final_room()
	wall_lamp(52, 65, Color(pal[3]))
	wall_lamp(429, 65, Color(pal[3]))
	label(game.Story.BOSSES[game.boss_index].place, 27, 250, 7, Color("5d646d"))

func wall_lamp(x: float, y: float, color: Color) -> void:
	rect(x - 8, y - 9, 17, 23, Color(color, 0.07))
	rect(x - 5, y - 6, 11, 17, Color(color, 0.13))
	rect(x - 3, y - 3, 7, 9, color)
	rect(x - 2, y - 2, 5, 7, color.lightened(0.3))

func draw_cinema() -> void:
	rect(176, 43, 132, 53, Color("131a23"))
	rect(182, 47, 120, 43, Color("71622f"))
	rect(186, 50, 112, 36, Color("d8b850"))
	rect(186, 81, 112, 5, Color("b23342"))
	label("KILL BILL", 210, 72, 15, Color("22202a"))
	for i in range(9): rect(186, 51 + i * 4, 112, 1, Color(0, 0, 0, 0.09))
	rect(234, 96, 17, 4, Color("131a23"))
	rect(315, 75, 57, 21, Color("693e3e"))
	rect(319, 80, 20, 14, Color("84504a"))
	rect(345, 80, 23, 14, Color("84504a"))
	rect(312, 84, 5, 14, Color("4e3339"))
	rect(371, 84, 5, 14, Color("4e3339"))
	poster(89, 48, "01", Color("cfad5d"))
	plant(410, 101)
	rect(119, 202, 25, 9, Color("513a37"))
	rect(121, 200, 22, 3, Color("80614a"))
	rect(128, 195, 4, 5, PAPER_COLOR())

func PAPER_COLOR() -> Color:
	return Color("d5d0b8")

func poster(x: int, y: int, title: String, color: Color) -> void:
	rect(x - 2, y - 2, 28, 39, Color("141922"))
	rect(x, y, 24, 35, color)
	rect(x + 4, y + 5, 16, 3, Color("27212a"))
	label(title, x + 3, y + 27, 13, Color("27212a"))

func plant(x: int, y: int) -> void:
	rect(x - 5, y - 5, 12, 8, Color("866951"))
	rect(x - 2, y - 23, 3, 19, Color("4b7160"))
	rect(x - 10, y - 21, 9, 5, Color("496c58"))
	rect(x + 1, y - 18, 9, 5, Color("5a8264"))
	rect(x - 5, y - 28, 7, 9, Color("608b68"))

func draw_alley() -> void:
	for x in [103, 204, 305]:
		rect(x, 49, 60, 39, Color("111e2b"))
		for dx in [7, 21, 35, 49]: rect(x + dx, 52, 2, 33, Color("374e5a"))
	rect(211, 57, 39, 17, Color("5a364f"))
	label("雨 巷", 215, 69, 8, Color("d394b5"))
	for i in range(12):
		var x = 29 + fposmod(i * 31.7, 405)
		var y = 110 + fposmod(i * 23.1, 108)
		rect(x, y, 14 + i % 12, 2, Color("405866"))
	for i in range(55):
		var x = 21 + fposmod(i * 71.3 + game.clock * 7, 433)
		var y = 43 + fposmod(i * 47.1 + game.clock * 111, 183)
		draw_line(Vector2(x, y), Vector2(x - 2, y + 6), Color(0.46, 0.62, 0.7, 0.23), 1)

func draw_machines() -> void:
	for x in [94, 164, 234, 304]:
		rect(x, 45, 49, 51, Color("191c29"))
		rect(x + 4, 49, 41, 24, Color("38424b"))
		for y in [53, 60, 67]:
			rect(x + 8, y, 25, 2, Color("4d6970"))
			rect(x + 37, y, 3, 2, Color("d9bf6e") if int(game.clock * 2 + x + y) % 3 else Color("be6479"))
		rect(x + 5, 81, 38, 2, Color("464459"))
	for x in range(55, 431, 18): rect(x, 219, 9, 4, Color("a28d51"))

func draw_archive() -> void:
	for x in [99, 146, 193, 286, 333, 380]:
		rect(x, 48, 33, 44, Color("4a5c55"))
		for y in [53, 65, 77]:
			rect(x + 2, y, 29, 10, Color("3a4946"))
			rect(x + 12, y + 3, 8, 2, Color("8e9c8b"))
	rect(233, 47, 41, 37, Color("13282a"))
	label("1006", 238, 65, 11, Color("91bca4"))
	rect(240, 70, 27, 2, Color("63796a"))
	rect(391, 181, 37, 20, Color("31443e"))
	for i in range(4): rect(395 + i * 6, 181 - i % 2 * 2, 5, 13, Color("a5a990"))

func draw_final_room() -> void:
	rect(160, 43, 160, 48, Color("1a1e2b"))
	for x in [163, 216, 269]:
		rect(x + 2, 45, 47, 42, Color("343647"))
		rect(x + 6, 48, 37, 32, Color("484356"))
		for i in range(5): rect(x + 7 + i * 7, 61 + i % 3 * 4, 5, 19, Color("222738"))
		rect(x + 17, 66, 2, 3, Color("cbb987"))
	rect(189, 103, 106, 115, Color("573039"))
	rect(193, 105, 98, 111, Color("64353b"))
	for x in [194, 288]: rect(x, 105, 2, 111, Color("9a6b57"))
	label("DAVID", 221, 83, 9, GOLD)
	plant(113, 101)
	plant(369, 101)

func draw_street() -> void:
	rect(0, 0, 480, 270, Color("101b27"))
	rect(20, 43, 440, 61, Color("23323d"))
	for x in range(25, 326, 49):
		rect(x, 51, 40, 46, Color("18232e"))
		rect(x + 5, 57, 30, 30, Color("3d4b50"))
		rect(x + 19, 57, 2, 30, Color("192631"))
		rect(x + 5, 71, 30, 2, Color("192631"))
	rect(328, 42, 133, 64, Color("536a6b"))
	rect(345, 49, 99, 18, Color("253a40"))
	label("医 院  /  HOSPITAL", 352, 61, 7, Color("c2d9c8"))
	rect(414, 73, 30, 35, Color("172b35"))
	rect(418, 75, 22, 30, Color("78a2a1"))
	rect(428, 75, 2, 30, Color("36515a"))
	rect(351, 79, 31, 21, Color("8eaaa2"))
	rect(363, 81, 6, 17, Color("d5e1c9"))
	rect(357, 87, 18, 5, Color("d5e1c9"))
	rect(20, 106, 440, 123, Color("283b47"))
	for y in range(109, 227, 17):
		for x in range(22, 458, 28):
			rect(x, y, 26, 15, Color("2e424e"))
	for x in range(42, 453, 43): rect(x, 219, 20, 2, Color("77765e"))
	for x in [102, 300]:
		rect(x, 89, 3, 52, Color("141f2a"))
		rect(x - 7, 86, 17, 4, Color("e0c382"))
		rect(x - 13, 90, 29, 8, Color(0.85, 0.71, 0.41, 0.08))
	label("医院 →", 340, 206, 10, Color("88b7ae"))
	prompt(Vector2(424, 114), "E 进入")
	label("鼻托掉落后，世界会变模糊。", 27, 250, 7, Color("5d727f"))

func draw_hospital() -> void:
	rect(0, 0, 480, 270, Color("101c27"))
	rect(18, 42, 444, 51, Color("a4b7b0"))
	rect(18, 81, 444, 13, Color("6e9890"))
	rect(18, 94, 444, 137, Color("8b9e9a"))
	for y in range(95, 230, 18):
		for x in range(20, 462, 22):
			rect(x, y, minf(21, 462 - x), minf(17, 231 - y), Color("94a8a2") if (x / 22 + y / 18) % 2 else Color("8fa39e"))
	rect(220, 42, 4, 96, Color("607e7c"))
	rect(220, 185, 4, 46, Color("607e7c"))
	label("门 诊", 112, 67, 13, Color("28494c"))
	label("CT  /  检查室", 295, 67, 12, Color("28494c"))
	rect(85, 111, 104, 20, Color("587c78"))
	rect(82, 108, 110, 7, Color("c4c8b0"))
	rect(107, 91, 22, 17, Color("273e4a"))
	rect(110, 94, 16, 10, Color("72a99e"))
	draw_actor(Vector2(145, 106), "agent", "dbe0d0")
	rect(172, 101, 12, 5, Color("e4dfc8"))
	plant(52, 101)
	for x in [50, 76, 102]:
		rect(x, 184, 22, 8, Color("547d7d"))
		rect(x + 2, 176, 18, 9, Color("678e89"))
		rect(x + 2, 192, 2, 5, Color("435d61"))
		rect(x + 18, 192, 2, 5, Color("435d61"))
	# Squared pixel donut and moving bed for the CT interaction.
	rect(292, 94, 68, 58, Color("546e75"))
	rect(288, 97, 76, 49, Color("b8c9bd"))
	rect(296, 90, 60, 62, Color("c7d0c1"))
	rect(304, 101, 44, 39, Color("6f898b"))
	rect(310, 107, 32, 28, Color("263f4a"))
	rect(316, 133, 20, 44, Color("b4c4b6"))
	rect(310, 143, 32, 25, Color("d0d4c2"))
	rect(313, 146, 26, 20, Color("8aa69b"))
	rect(312, 172, 29, 5, Color("4d7273"))
	rect(369, 111, 48, 26, Color("47646b"))
	rect(373, 114, 39, 18, Color("19353f"))
	for i in range(4): rect(378 + i * 7, 117 + (i % 2) * 2, 3, 10 - (i % 2) * 4, Color("82bbac"))
	if game.state == "ct":
		var scan_y = 110 + fposmod(game.scan_time * 12, 54)
		rect(308, scan_y, 35, 2, Color("73e0cc"))
		rect(308, scan_y - 4, 35, 9, Color(0.3, 0.9, 0.8, 0.12))
	rect(418, 185, 30, 44, Color("254d54"))
	label("EXIT", 422, 199, 7, Color("b8d1bc"))
	rect(441, 204, 3, 3, GOLD)
	label("检查结束后，从右下方出口离开。", 27, 250, 7, Color("6d888d"))

func draw_tell() -> void:
	if game.boss_phase != "windup": return
	var pos = game.boss
	var alpha = 0.12 + (sin(game.clock * 23) + 1) * 0.06
	match game.boss_pattern:
		0:
			draw_circle(pos, 53, Color(0.8, 0.17, 0.23, alpha))
			draw_arc(pos, 53, 0, TAU, 48, RED, 1)
		1:
			for angle in [-0.32, 0.0, 0.32]:
				draw_line(pos, pos + game.boss_dir.rotated(angle) * 210, Color(0.85, 0.3, 0.33, alpha + 0.15), 2)
		2:
			draw_arc(pos, 65, 0, TAU, 48, Color("c27cbb"), 2)
			draw_arc(pos, 35, 0, TAU, 36, Color(0.7, 0.3, 0.5, alpha + 0.2), 1)
		3:
			var perpendicular = game.boss_dir.orthogonal() * 13
			draw_colored_polygon(PackedVector2Array([pos + perpendicular, pos - perpendicular, pos - perpendicular + game.boss_dir * 190, pos + perpendicular + game.boss_dir * 190]), Color(0.8, 0.2, 0.25, alpha))
			draw_line(pos, pos + game.boss_dir * 190, RED, 1)
	label("!", pos.x - 2, pos.y - 33, 12, GOLD)

func draw_corpse() -> void:
	rect(game.boss.x - 13, game.boss.y - 5, 28, 9, Color(game.Story.BOSSES[game.boss_index].color).darkened(0.2))
	rect(game.boss.x + 12, game.boss.y - 3, 7, 7, Color("b8907e"))
	if game.boss_index == 3:
		rect(game.boss.x + 12, game.boss.y - 3, 7, 7, Color("d7ded6"))

func draw_pad_drop() -> void:
	var p = game.pad_pos
	var pulse = (sin(game.clock * 4) + 1) * 0.5
	draw_circle(p, 9 + pulse * 3, Color(0.9, 0.8, 0.4, 0.12))
	rect(p.x - 2, p.y - 2, 4, 5, GOLD)
	draw_line(p - Vector2(7, 0), p + Vector2(7, 0), Color("f7e3a1"), 1)
	draw_line(p - Vector2(0, 7), p + Vector2(0, 7), Color("f7e3a1"), 1)
	prompt(p, "E 鼻托")

func draw_letter_drop() -> void:
	var p = game.letter_pos + Vector2(0, sin(game.clock * 3) * 1.5)
	draw_circle(p, 13, Color(0.9, 0.8, 0.4, 0.12))
	rect(p.x - 7, p.y - 4, 14, 9, Color("e7debf"))
	draw_line(p - Vector2(7, 4), p + Vector2(0, 1), Color("aa8b68"), 1)
	draw_line(p + Vector2(7, -4), p + Vector2(0, 1), Color("aa8b68"), 1)
	prompt(game.letter_pos, "E 拾取信件")

func prompt(pos: Vector2, message: String) -> void:
	if game.player.distance_to(pos) > 45: return
	var width = game.font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10
	rect(pos.x - width / 2, pos.y - 43, width, 13, Color("101c29"))
	label(message, pos.x - width / 2 + 5, pos.y - 34, 7, GOLD)

func draw_title() -> void:
	rect(0, 0, 480, 270, Color("17232c"))
	for i in range(18):
		var x = 278 + i * 13
		var height = 39 + fposmod(i * 21, 49)
		rect(x, 95 - height, 11, height + 110, Color("1e303b"))
		for y in range(40, 173, 14):
			if (i + y) % 3: rect(x + 3, y, 2, 4, Color("766d50"))
	rect(280, 181, 200, 89, Color("263541"))
	for y in range(185, 270, 14): rect(280, y, 200, 1, Color("344451"))
	for i in range(35):
		var x = 281 + fposmod(i * 31.7 + game.clock * 4, 199)
		var y = fposmod(i * 41.3 + game.clock * 80, 260)
		draw_line(Vector2(x, y), Vector2(x - 2, y + 7), Color(0.5, 0.6, 0.7, 0.17), 1)
	draw_set_transform(Vector2(369, 185), 0, Vector2(4, 4))
	draw_actor_portrait()
	draw_set_transform(Vector2.ZERO)
	rect(318, 193, 113, 2, Color("bd4f55"))
	label("01 — 05", 350, 240, 8, Color("667984"))

func draw_actor_portrait() -> void:
	var colors = {"h": Color("24222d"), "s": Color("d5a58b"), "g": Color("7cc5c5"), "r": RED, "y": GOLD, "k": Color("262b37")}
	for y in range(PLAYER.size()):
		for x in range(PLAYER[y].length()):
			var pixel = PLAYER[y][x]
			if pixel != ".": rect(x - 8, y - 19, 1, 1, colors[pixel])
	rect(9, -17, 2, 15, Color("cbd8d3"))
	rect(7, -8, 6, 2, GOLD)
	rect(9, -5, 2, 5, RED)
